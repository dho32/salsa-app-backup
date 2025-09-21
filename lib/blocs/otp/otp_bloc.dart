import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import 'otp_event.dart';
import 'otp_state.dart';
import 'otp_repository.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final OtpRepository repository;

  // ───────────────────────── Business rules ─────────────────────────
  static const int _maxResend = 4; // batas resend
  static const Duration _lockDuration = Duration(hours: 1);

  // ───────────────────────── In-memory storage ──────────────────────
  final Map<String, String> _latestOtp = {};
  final Map<String, int> _retryUsed = {};
  final Map<String, DateTime?> _expiredAt = {};
  final Map<String, DateTime?> _resendAvailableAt = {};
  final Map<String, DateTime?> _lockedUntil = {};

  String? _currentKey;
  late final Timer _ticker;

  String _getCompositeKey(String shipTo, String transNo) => '$transNo-$shipTo';

  // ───────────────────────── Constructor ────────────────────────────
  OtpBloc({required this.repository}) : super(const OtpInitial()) {
    // Restore state dari Hive saat bloc dibuat
    final box = Hive.box('otp_state');
    for (var entry in box.toMap().entries) {
      final k = entry.key.toString();
      if (k.startsWith('otp_')) {
        final key = k.replaceFirst('otp_', '');
        _latestOtp[key] = entry.value as String;
      }
      if (k.startsWith('expiredAt_')) {
        final key = k.replaceFirst('expiredAt_', '');
        _expiredAt[key] = DateTime.parse(entry.value as String);
      }
      if (k.startsWith('retryCount_')) {
        final key = k.replaceFirst('retryCount_', '');
        _retryUsed[key] = entry.value as int;
      }
      if (k.startsWith('resendAt_')) {
        final key = k.replaceFirst('resendAt_', '');
        _resendAvailableAt[key] = DateTime.parse(entry.value as String);
      }
      if (k.startsWith('lockedUntil_')) {
        final key = k.replaceFirst('lockedUntil_', '');
        _lockedUntil[key] = DateTime.parse(entry.value as String);
      }
    }

    on<RequestOtp>(_onRequestOtp);
    on<ResendOtp>(_onResendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<OtpTick>(_onTick);

    // Timer tick tiap 1 detik
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
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

    // 🚩 1. Kalau user masih lock
    if (_isLocked(key)) {
      _currentKey = key;
      return emit(OtpLocked(_lockedUntil[key]!.difference(DateTime.now())));
    }

    // 🚩 2. Kalau user cuma "fetch status" (isFirst=0)
    if (e.isFirst == '0') {
      final otp = _latestOtp[key];
      final expired = _expiredAt[key];

      if (otp != null && expired != null) {
        if (DateTime.now().isBefore(expired)) {
          _currentKey = key;
          emit(_buildSentState(key));
          return;
        }

        // 🚩 Kalau OTP expired → reset semua supaya bisa mulai dari nol
        _cleanup(key);
        _retryUsed[key] = 0;
        _lockedUntil[key] = null;

        emit(const OtpInitial());
        return;
      }

      // Kalau cache kosong → jangan langsung kirim OTP
      emit(const OtpInitial());
      return;
    }

    // 🚩 3. Kalau user memang minta OTP baru (isFirst=1)
    emit(const OtpLoading());
    final res = await repository.sendOtp(e.transNo, e.shipTo, '1');
    if (res == null) return emit(const OtpError('Gagal mengirim OTP'));
    _currentKey = key;

    if (res['otp'] == "") {
      emit(const OtpInitial());
    } else {
      _hydrateFromServer(key, res, resetCooldown: true);
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

    _retryUsed[key] = (_retryUsed[key] ?? 0) + 1;
    _hydrateFromServer(key, res, resetCooldown: true);

    if ((_retryUsed[key] ?? 0) >= _maxResend) {
      final lockedUntil = DateTime.now().add(_lockDuration);
      _lockedUntil[key] = lockedUntil;
      Hive.box('otp_state').put('lockedUntil_$key', lockedUntil.toIso8601String());
      return emit(OtpLocked(_lockDuration));
    }

    emit(_buildSentState(key));
  }

  /// Verifikasi kode yang diketik user
  void _onVerifyOtp(VerifyOtp e, Emitter<OtpState> emit) {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    final serverOtp = _latestOtp[key];

    if (_isLocked(key)) {
      if (serverOtp != null && serverOtp == e.otp.trim()) {
        _cleanup(key);
        emit(const OtpVerified());
      } else {
        final remaining = _lockedUntil[key]!.difference(DateTime.now());
        if (!remaining.isNegative) {
          emit(OtpLocked(remaining, temporaryError: 'Kode OTP salah'));
        }
      }
      return;
    }

    if (_expiredAt.containsKey(key) && DateTime.now().isAfter(_expiredAt[key]!)) {
      emit(const OtpExpired());
      return;
    }
    if (serverOtp == null) {
      emit(const OtpError('Silakan minta OTP terlebih dahulu'));
      return;
    }

    if (serverOtp == e.otp.trim()) {
      _cleanup(key);
      emit(const OtpVerified());
    } else {
      final currentState = state;
      if (currentState is OtpSent) {
        emit(OtpError(
          'Kode OTP salah, silahkan masukan ulang menggunakan kode yang benar',
          secondsRemaining: currentState.secondsRemaining,
          resendCooldown: currentState.resendCooldown,
          retryLeft: currentState.retryLeft,
          hasOtp: currentState.hasOtp,
        ));
      } else {
        emit(const OtpError('Kode OTP salah, silahkan masukan ulang menggunakan kode yang benar'));
      }
    }
  }

  /// Tick 1-detik untuk update countdown
  void _onTick(OtpTick e, Emitter<OtpState> emit) {
    final key = _getCompositeKey(e.shipTo, e.transNo);
    if (key != _currentKey) return;

    if (state is OtpLocked) {
      final remaining = _lockedUntil[key]!.difference(DateTime.now());
      if (remaining.isNegative) {
        _lockedUntil.remove(key);
        Hive.box('otp_state').delete('lockedUntil_$key');
        emit(_buildSentState(key));
      } else {
        emit(OtpLocked(remaining));
      }
      return;
    }

    if (state is OtpSent) emit(_buildSentState(key));

    if (state is OtpError) {
      final currentMessage = (state as OtpError).message;
      final now = DateTime.now();
      final secondsRemaining = max(0, (_expiredAt[key] ?? now).difference(now).inSeconds);
      final resendCooldown = max(0, (_resendAvailableAt[key] ?? now).difference(now).inSeconds);
      final retryLeft = max(0, _maxResend - (_retryUsed[key] ?? 0));
      final hasOtp = _latestOtp[key]?.isNotEmpty ?? false;

      emit(OtpError(
        currentMessage,
        secondsRemaining: secondsRemaining,
        resendCooldown: resendCooldown,
        retryLeft: retryLeft,
        hasOtp: hasOtp,
      ));
    }
  }

  // ─────────────────────── Helper methods ───────────────────────────

  void _hydrateFromServer(String key, Map<String, dynamic> res, {required bool resetCooldown}) {
    final otpStr = (res['otp'] as String).trim();
    final expiredAt = res['expired_date'] as DateTime;
    final retryCount = res['retry_count'] as int;

    _latestOtp[key] = otpStr;
    _expiredAt[key] = expiredAt;
    _retryUsed[key] = retryCount;

    final box = Hive.box('otp_state');
    box.put('otp_$key', otpStr);
    box.put('expiredAt_$key', expiredAt.toIso8601String());
    box.put('retryCount_$key', retryCount);

    if (resetCooldown && otpStr.isNotEmpty) {
      _resendAvailableAt[key] = expiredAt.subtract(const Duration(minutes: 57));
      box.put('resendAt_$key', _resendAvailableAt[key]!.toIso8601String());
    } else if (_resendAvailableAt[key] == null) {
      _resendAvailableAt[key] = DateTime.now();
      box.put('resendAt_$key', _resendAvailableAt[key]!.toIso8601String());
    }

    if (_retryUsed[key]! >= _maxResend) {
      final lockedUntil = DateTime.now().add(_lockDuration);
      _lockedUntil[key] = lockedUntil;
      box.put('lockedUntil_$key', lockedUntil.toIso8601String());
    }
  }

  bool _isLocked(String key) => DateTime.now().isBefore(_lockedUntil[key] ?? DateTime(1970));

  bool _canResend(String key) =>
      DateTime.now().isAfter(_resendAvailableAt[key] ?? DateTime(1970)) &&
          (_retryUsed[key] ?? 0) < _maxResend;

  OtpSent _buildSentState(String key) {
    final now = DateTime.now();
    final secondsRemaining = max(0, _expiredAt[key]!.difference(now).inSeconds);
    final resendCooldown = max(0, _resendAvailableAt[key]!.difference(now).inSeconds);
    final retryLeft = max(0, _maxResend - (_retryUsed[key] ?? 0));
    final hasOtp = _latestOtp[key]?.isNotEmpty ?? false;

    return OtpSent(
      secondsRemaining: secondsRemaining,
      resendCooldown: resendCooldown,
      retryLeft: retryLeft,
      hasOtp: hasOtp,
    );
  }

  void _cleanup(String key) {
    _latestOtp.remove(key);
    _retryUsed.remove(key);
    _expiredAt.remove(key);
    _resendAvailableAt.remove(key);
    _lockedUntil.remove(key);

    final box = Hive.box('otp_state');
    box.delete('otp_$key');
    box.delete('expiredAt_$key');
    box.delete('retryCount_$key');
    box.delete('resendAt_$key');
    box.delete('lockedUntil_$key');

    if (key == _currentKey) _currentKey = null;
  }

  @override
  Future<void> close() {
    _ticker.cancel();
    return super.close();
  }
}
