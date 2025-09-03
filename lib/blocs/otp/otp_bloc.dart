import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'otp_event.dart';
import 'otp_state.dart';
import 'otp_repository.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final OtpRepository repository;

  // ───────────────────────── Business rules ─────────────────────────
  static const int _maxResend = 3;// batas resend
  static const Duration _lockDuration   = Duration(hours: 1);

  // ───────────────────────── In-memory storage ──────────────────────
  final Map<String, String>   _latestOtp           = {};
  final Map<String, int>      _retryUsed           = {};
  final Map<String, DateTime> _expiredAt           = {};
  final Map<String, DateTime> _resendAvailableAt   = {};
  final Map<String, DateTime> _lockedUntil         = {};

  String? _currentShipTo;
  DateTime targetTime = DateTime.now();
  late final Timer _ticker;

  // ───────────────────────── Constructor ────────────────────────────
  OtpBloc({required this.repository}) : super(const OtpInitial()) {
    on<RequestOtp>(_onRequestOtp);
    on<ResendOtp>(_onResendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<OtpTick>(_onTick);

    // Kirim 1× tick per detik ke shipTo aktif
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentShipTo != null) add(OtpTick(_currentShipTo!));
    });
  }

  // ─────────────────────── Event handlers ───────────────────────────

  /// Kirim OTP pertama kali atau fetch status dari server
  Future<void> _onRequestOtp(RequestOtp e, Emitter<OtpState> emit) async {
    if (_isLocked(e.shipTo)) {
      return emit(OtpLocked(_lockedUntil[e.shipTo]!.difference(DateTime.now())));
    }

    emit(const OtpLoading());

    final res = await repository.sendOtp(e.shipTo, e.isFirst);
    if (res == null) return emit(const OtpError('Gagal mengirim OTP'));
    _currentShipTo = e.shipTo;
    if (res['otp'] == ""){
      emit(OtpInitial());
    }else{
      _hydrateFromServer(e.shipTo, res, resetCooldown: true);

      if (_retryUsed[e.shipTo]! >= _maxResend) {
        return emit(OtpLocked(_lockDuration));
      }
      emit(_buildSentState(e.shipTo));
    }
  }

  /// Resend OTP — aturan sama seperti request, tapi menambah retryUsed
  Future<void> _onResendOtp(ResendOtp e, Emitter<OtpState> emit) async {
    if (_isLocked(e.shipTo)) {
      return emit(OtpLocked(_lockedUntil[e.shipTo]!.difference(DateTime.now())));
    }
    if (!_canResend(e.shipTo)) return;

    emit(const OtpLoading());

    final res = await repository.sendOtp(e.shipTo, e.isFirst);
    if (res == null) return emit(const OtpError('Gagal mengirim OTP'));
    _currentShipTo = e.shipTo;

    // Tambah hitungan retry & refresh data
    _retryUsed[e.shipTo] = (_retryUsed[e.shipTo] ?? 0) + 1;
    _hydrateFromServer(e.shipTo, res, resetCooldown: true);

    if (_retryUsed[e.shipTo]! >= _maxResend) {
      _lockedUntil[e.shipTo] = DateTime.now().add(_lockDuration);
      return emit(OtpLocked(_lockDuration));
    }
    emit(_buildSentState(e.shipTo));
  }

  /// Verifikasi kode yang diketik user
  void _onVerifyOtp(VerifyOtp e, Emitter<OtpState> emit) {
    // 1. Cek kedaluwarsa lebih dulu
    if (_expiredAt.containsKey(e.shipTo) &&
        DateTime.now().isAfter(_expiredAt[e.shipTo]!)) {
      emit(const OtpExpired());          // ← tampil hanya sesudah user klik Verifikasi
      return;
    }
    final serverOtp = _latestOtp[e.shipTo];
    if (serverOtp == null) {
      emit(const OtpError('Silakan minta OTP terlebih dahulu'));
      return;
    }

    if (serverOtp == e.otp.trim()) {
      _cleanup(e.shipTo);
      emit(const OtpVerified());
    } else {
      emit(const OtpError('Kode OTP salah'));
    }
  }

  /// Tick 1-detik untuk update countdown
  void _onTick(OtpTick e, Emitter<OtpState> emit) {
    if (e.shipTo != _currentShipTo) return;

    // 1. Masih lock → urus lock count-down saja
    if (state is OtpLocked) {
      final remaining = _lockedUntil[e.shipTo]!.difference(DateTime.now());
      if (remaining.isNegative) {
        _lockedUntil.remove(e.shipTo);
        emit(_buildSentState(e.shipTo));
      } else {
        emit(OtpLocked(remaining));           // update detik lock (optional)
      }
      return;
    }

    // 2. Cek apakah OTP BENAR-BENAR pernah dikirim
    final expiredAt = _expiredAt[e.shipTo];
    final sudahPernahKirim =
        (_retryUsed[e.shipTo] ?? 0) > 0 || (_latestOtp[e.shipTo]?.isNotEmpty ?? false);

    // 3. Perbarui hitung-mundur normal (juga menutupi kasus "OTP belum dikirim")
    if (state is OtpSent) emit(_buildSentState(e.shipTo));
  }

  // ─────────────────────── Helper methods ───────────────────────────

  /// Simpan data dari server + atur cooldown
  void _hydrateFromServer(String shipTo, Map<String, dynamic> res,
      {required bool resetCooldown}) {
    final otpStr = (res['otp'] as String).trim();
    _latestOtp[shipTo] = otpStr;
    _expiredAt[shipTo] = res['expired_date'] as DateTime;
    _retryUsed[shipTo] = res['retry_count'] as int;

    // Cool-down hanya dipasang kalau server BENAR-BENAR mengirim OTP
    if (resetCooldown && otpStr.isNotEmpty) {
      _resendAvailableAt[shipTo] = _expiredAt[shipTo]!.subtract(Duration(minutes: 4));

    } else if (_resendAvailableAt[shipTo] == null) {
      // pastikan tidak null supaya _buildSentState aman
      _resendAvailableAt[shipTo] = DateTime.now();
    }

    if (_retryUsed[shipTo]! >= _maxResend) {
      _lockedUntil[shipTo] = DateTime.now().add(_lockDuration);
    }
  }

  bool _isLocked(String shipTo) =>
      DateTime.now().isBefore(_lockedUntil[shipTo] ?? DateTime(1970));

  bool _canResend(String shipTo) =>
      DateTime.now().isAfter(_resendAvailableAt[shipTo] ?? DateTime(1970)) &&
          (_retryUsed[shipTo] ?? 0) < _maxResend;

  OtpSent _buildSentState(String shipTo) {
    final now = DateTime.now();

    final secondsRemaining =
    max(0, _expiredAt[shipTo]!.difference(now).inSeconds);

    final resendCooldown =
    max(0, _resendAvailableAt[shipTo]!.difference(now).inSeconds);

    final retryLeft = max(0, _maxResend - (_retryUsed[shipTo] ?? 0));

    final hasOtp = _latestOtp[shipTo]?.isNotEmpty ?? false;

    return OtpSent(
      secondsRemaining: secondsRemaining,
      resendCooldown: resendCooldown,
      retryLeft: retryLeft,
      hasOtp: hasOtp,                                         // ← baru
    );
  }

  void _cleanup(String shipTo) {
    _latestOtp.remove(shipTo);
    _retryUsed.remove(shipTo);
    _expiredAt.remove(shipTo);
    _resendAvailableAt.remove(shipTo);
    _lockedUntil.remove(shipTo);
    if (shipTo == _currentShipTo) _currentShipTo = null;
  }

  // ───────────────────────── dispose ────────────────────────────────
  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
