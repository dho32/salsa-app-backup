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

  String? _currentKey;
  DateTime targetTime = DateTime.now();
  late final Timer _ticker;
  String _getCompositeKey(String shipTo, String transNo) => '$shipTo-$transNo';

  // ───────────────────────── Constructor ────────────────────────────
  OtpBloc({required this.repository}) : super(const OtpInitial()) {
    on<RequestOtp>(_onRequestOtp);
    on<ResendOtp>(_onResendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<OtpTick>(_onTick);

    // Kirim 1× tick per detik ke shipTo aktif
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      // Jika ada sesi aktif, kirim tick
      if (_currentKey != null) {
        final parts = _currentKey!.split('-');
        if (parts.length == 2) {
          add(OtpTick(parts[0], parts[1]));
        }
      }
    });
  }

  // ─────────────────────── Event handlers ───────────────────────────

  /// Kirim OTP pertama kali atau fetch status dari server
  Future<void> _onRequestOtp(RequestOtp e, Emitter<OtpState> emit) async {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    if (_isLocked(key)) {
      return emit(OtpLocked(_lockedUntil[key]!.difference(DateTime.now())));
    }

    emit(const OtpLoading());

    final res = await repository.sendOtp(e.transNo, e.shipTo, e.isFirst);
    if (res == null) return emit(const OtpError('Gagal mengirim OTP'));
    _currentKey = key;
    if (res['otp'] == ""){
      emit(OtpInitial());
    }else{
      _hydrateFromServer(key, res, resetCooldown: true);

      if ((_retryUsed[key] ?? 0) >= _maxResend) {
        return emit(OtpLocked(_lockDuration));
      }
      emit(_buildSentState(key));
    }
  }

  /// Resend OTP — aturan sama seperti request, tapi menambah retryUsed
  Future<void> _onResendOtp(ResendOtp e, Emitter<OtpState> emit) async {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    if (_isLocked(key)) {
      return emit(OtpLocked(_lockedUntil[key]!.difference(DateTime.now())));
    }
    if (!_canResend(key)) return;

    emit(const OtpLoading());

    final res = await repository.sendOtp(e.transNo, e.shipTo, e.isFirst);
    if (res == null) return emit(const OtpError('Gagal mengirim OTP'));
    _currentKey = key;

    // Tambah hitungan retry & refresh data
    _retryUsed[key] = (_retryUsed[key] ?? 0) + 1;
    _hydrateFromServer(key, res, resetCooldown: true);

    if ((_retryUsed[key] ?? 0) >= _maxResend) {
      _lockedUntil[key] = DateTime.now().add(_lockDuration);
      return emit(OtpLocked(_lockDuration));
    }
    emit(_buildSentState(key));
  }

  /// Verifikasi kode yang diketik user
  void _onVerifyOtp(VerifyOtp e, Emitter<OtpState> emit) {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    // 1. Cek kedaluwarsa lebih dulu
    if (_expiredAt.containsKey(key) &&
        DateTime.now().isAfter(_expiredAt[key]!)) {
      emit(const OtpExpired());
      return;
    }
    final serverOtp = _latestOtp[key];
    if (serverOtp == null) {
      emit(const OtpError('Silakan minta OTP terlebih dahulu'));
      return;
    }

    if (serverOtp == e.otp.trim()) {
      _cleanup(key);
      emit(const OtpVerified());
    } else {
      emit(const OtpError('Kode OTP salah'));
    }
  }

  /// Tick 1-detik untuk update countdown
  void _onTick(OtpTick e, Emitter<OtpState> emit) {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    if (key != _currentKey) return;

    // 1. Masih lock → urus lock count-down saja
    if (state is OtpLocked) {
      final remaining = _lockedUntil[key]!.difference(DateTime.now());
      if (remaining.isNegative) {
        _lockedUntil.remove(key);
        emit(_buildSentState(key));
      } else {
        emit(OtpLocked(remaining));
      }
      return;
    }

    // 2. Perbarui hitung-mundur normal (juga menutupi kasus "OTP belum dikirim")
    if (state is OtpSent) emit(_buildSentState(key));
  }

  // ─────────────────────── Helper methods ───────────────────────────

  /// Simpan data dari server + atur cooldown
  void _hydrateFromServer(String key, Map<String, dynamic> res,
      {required bool resetCooldown}) {
    final otpStr = (res['otp'] as String).trim();
    _latestOtp[key] = otpStr;
    _expiredAt[key] = res['expired_date'] as DateTime;
    _retryUsed[key] = res['retry_count'] as int;

    // Cool-down hanya dipasang kalau server BENAR-BENAR mengirim OTP
    if (resetCooldown && otpStr.isNotEmpty) {
      _resendAvailableAt[key] = _expiredAt[key]!.subtract(Duration(minutes: 59));

    } else if (_resendAvailableAt[key] == null) {
      // pastikan tidak null supaya _buildSentState aman
      _resendAvailableAt[key] = DateTime.now();
    }

    if (_retryUsed[key]! >= _maxResend) {
      _lockedUntil[key] = DateTime.now().add(_lockDuration);
    }
  }

  bool _isLocked(String key) =>
      DateTime.now().isBefore(_lockedUntil[key] ?? DateTime(1970));

  bool _canResend(String key) =>
      DateTime.now().isAfter(_resendAvailableAt[key] ?? DateTime(1970)) &&
          (_retryUsed[key] ?? 0) < _maxResend;

  OtpSent _buildSentState(String key) {
    final now = DateTime.now();

    final secondsRemaining =
    max(0, _expiredAt[key]!.difference(now).inSeconds);

    final resendCooldown =
    max(0, _resendAvailableAt[key]!.difference(now).inSeconds);

    final retryLeft = max(0, _maxResend - (_retryUsed[key] ?? 0));

    final hasOtp = _latestOtp[key]?.isNotEmpty ?? false;

    return OtpSent(
      secondsRemaining: secondsRemaining,
      resendCooldown: resendCooldown,
      retryLeft: retryLeft,
      hasOtp: hasOtp,                                         // ← baru
    );
  }

  void _cleanup(String key) {
    _latestOtp.remove(key);
    _retryUsed.remove(key);
    _expiredAt.remove(key);
    _resendAvailableAt.remove(key);
    _lockedUntil.remove(key);
    if (key == _currentKey) _currentKey = null;
  }

  // ───────────────────────── dispose ────────────────────────────────
  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
