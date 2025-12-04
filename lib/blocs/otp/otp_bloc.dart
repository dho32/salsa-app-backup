import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../components/constants.dart';
import '../../models/common/otp_tracking_model.dart';
import 'otp_event.dart';
import 'otp_state.dart';
import 'otp_repository.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final OtpRepository repository;
  final Box<OtpTrackingModel> _otpBox =
      Hive.box<OtpTrackingModel>(kOtpTrackingBox);
  Timer? _timer;
  int _cooldown = 0;
  int _retryCount = 0;
  static const int _maxRetries = 4;
  static const int _initialTimer = 10; // 3 Menit

  // ───────────────────────── Constructor ────────────────────────────
  OtpBloc({required this.repository}) : super(OtpInitial()) {
    on<CheckOtpStatus>(_onCheckOtpStatus);
    on<RequestOtp>(_onRequestOtp);
    on<ResendOtp>(_onResendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<OtpTimerTicked>(_onTimerTicked);
    on<ResetOtp>(_onResetOtp);
  }

  // ─────────────────────── Event handlers ───────────────────────────

  void _onCheckOtpStatus(CheckOtpStatus event, Emitter<OtpState> emit) {
    final String hiveKey = event.transNo
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    final DateTime now = DateTime.now();
    final DateTime? lastRequest = trackingEntry.lastRequestTime;
    _retryCount = trackingEntry.retryCount;
    bool isExpiredOneHour = false;

    // Cek Reset 1 Jam
    if (lastRequest != null) {
      if (now.difference(lastRequest).inSeconds >= 10) {
        isExpiredOneHour = true;
      }
    }

    if (isExpiredOneHour && !event.hasExistingPhoto) {
      print("🕒 [OTP] Expired > 1 Jam & No Photo -> AUTO RESET.");
      _performReset(hiveKey, trackingEntry);
      emit(OtpInitial());
      return; // Selesai, user langsung bisa minta OTP
    }

    if (!isExpiredOneHour && lastRequest != null && _retryCount > 0) {
      final int secondsPassed = now.difference(lastRequest).inSeconds;
      if (secondsPassed < _initialTimer) {
        _cooldown = _initialTimer - secondsPassed;
        _startTimer();
        emit(OtpSent(
            cooldown: _cooldown,
            retryLeft: _maxRetries - _retryCount,
            canReset: false));
        return;
      }
    }

    if (_retryCount >= _maxRetries) {
      // Limit habis, tapi kalau expired, user bisa pilih reset
      emit(OtpSent(cooldown: 0, retryLeft: 0, canReset: isExpiredOneHour));
    } else if (_retryCount > 0) {
      // Timer habis, retry masih ada
      emit(OtpSent(
          cooldown: 0,
          retryLeft: _maxRetries - _retryCount,
          canReset: isExpiredOneHour));
    } else {
      emit(OtpInitial());
    }
  }

  void _performReset(String hiveKey, OtpTrackingModel entry) {
    entry.retryCount = 0;
    entry.lastRequestTime = null;
    _otpBox.put(hiveKey, entry);

    _retryCount = 0;
    _cooldown = 0;
    _timer?.cancel();
  }

  void _onResetOtp(ResetOtp event, Emitter<OtpState> emit) {
    final String hiveKey =
        event.transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    _performReset(hiveKey, trackingEntry); // Panggil helper

    emit(OtpInitial());
  }

  /// Kirim OTP pertama kali atau fetch status dari server
  Future<void> _onRequestOtp(RequestOtp event, Emitter<OtpState> emit) async {
    _startOptimisticFlow(event.transNo, event.shipTo, '1', emit);
  }

  /// Resend OTP — aturan sama seperti request, tapi menambah retryUsed
  Future<void> _onResendOtp(ResendOtp event, Emitter<OtpState> emit) async {
    _startOptimisticFlow(event.transNo, event.shipTo, '0', emit);
  }

  void _startOptimisticFlow(
      String transNo, String shipTo, String isFirst, Emitter<OtpState> emit) {
    final String hiveKey =
        transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    final DateTime now = DateTime.now();
    final DateTime? lastRequest = trackingEntry.lastRequestTime;

    if (lastRequest != null) {
      final difference = now.difference(lastRequest);
      if (difference.inHours >= 1) {
        // RESET COUNTER JIKA SUDAH > 1 JAM
        trackingEntry.retryCount = 0;
        print("🕒 OTP Reset: Sudah 1 jam berlalu.");
      }
    }

    // A. Cek Limit
    if (trackingEntry.retryCount >= _maxRetries) {
      // Limit Habis -> Emit state dengan retryLeft 0 agar UI memunculkan tombol Lokasi
      _retryCount = trackingEntry.retryCount;
      emit(OtpSent(cooldown: 0, retryLeft: 0));
      return;
    }

    // Update Data
    _retryCount = trackingEntry.retryCount + 1;
    trackingEntry.retryCount = _retryCount;
    trackingEntry.lastRequestTime = DateTime.now();
    _otpBox.put(hiveKey, trackingEntry);

    // Set Timer Baru
    _cooldown = _initialTimer;
    _startTimer();

    // Emit State
    emit(OtpSent(cooldown: _cooldown, retryLeft: _maxRetries - _retryCount));

    // Fire API
    repository.sendOtp(transNo, shipTo, isFirst);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(const OtpTimerTicked());
    });
  }

  void _onTimerTicked(OtpTimerTicked event, Emitter<OtpState> emit) {
    if (_cooldown > 0) {
      _cooldown--;
      emit(OtpSent(cooldown: _cooldown, retryLeft: _maxRetries - _retryCount));
    } else {
      _timer?.cancel();
      // Timer habis, cooldown 0 -> Tombol Resend aktif
      emit(OtpSent(cooldown: 0, retryLeft: _maxRetries - _retryCount));
    }
  }

  /// Verifikasi kode yang diketik user
  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<OtpState> emit) async {
    emit(OtpLoading());

    try {
      final isValid =
          await repository.validateOtp(event.transNo, event.shipTo, event.otp);

      if (isValid) {
        _timer?.cancel();
        emit(OtpVerified());
      } else {
        // Gagal: Emit Error dulu buat Snackbar
        emit(const OtpError("Kode OTP Salah. Silakan cek lagi."));
        // Lalu Balik ke Sent agar timer tetap kelihatan jalan
        emit(
            OtpSent(cooldown: _cooldown, retryLeft: _maxRetries - _retryCount));
      }
    } catch (e) {
      emit(OtpError(e.toString()));
      emit(OtpSent(cooldown: _cooldown, retryLeft: _maxRetries - _retryCount));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
