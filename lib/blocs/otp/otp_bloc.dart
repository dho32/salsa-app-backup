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
  static const int _initialTimer = 180; // 3 Menit

  OtpBloc({required this.repository}) : super(OtpInitial()) {
    on<CheckOtpStatus>(_onCheckOtpStatus);
    on<RequestOtp>(_onRequestOtp);
    on<ResendOtp>(_onResendOtp);
    on<VerifyOtp>(_onVerifyOtp);
    on<OtpTimerTicked>(_onTimerTicked);
    on<ResetOtp>(_onResetOtp);
  }

  String _getHiveKey(String transNo) {
    return transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  void _onCheckOtpStatus(CheckOtpStatus event, Emitter<OtpState> emit) {
    final String hiveKey = _getHiveKey(event.transNo); // ✅ Pakai Helper
    final OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    final DateTime now = DateTime.now();
    final DateTime? lastRequest = trackingEntry.lastRequestTime;
    _retryCount = trackingEntry.retryCount;

    bool isExpiredOneHour = false;
    if (lastRequest != null) {
      if (now.difference(lastRequest).inHours >= 1) {
        isExpiredOneHour = true;
      }
    }

    // Auto Reset jika expired & tidak ada foto
    if (isExpiredOneHour && !event.hasExistingPhoto) {
      print("🕒 [OTP] Expired > 1 Jam & No Photo -> AUTO RESET.");
      _performReset(hiveKey, trackingEntry);
      emit(OtpInitial());
      return;
    }

    // Resume Timer
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

    // State Default
    if(_retryCount > 0){
      emit(OtpSent(
          cooldown: 0,
          retryLeft: (_maxRetries - _retryCount).clamp(0, _maxRetries),
          canReset: isExpiredOneHour
      ));
    }else{
      emit(OtpInitial());
    }
  }

  void _performReset(String hiveKey, OtpTrackingModel entry) {
    entry.retryCount = 0;
    entry.lastRequestTime = null;
    _otpBox.put(hiveKey, entry); // Save to Hive

    _retryCount = 0;
    _cooldown = 0;
    _timer?.cancel();
    print("♻️ OTP Data Reset for Key: $hiveKey");
  }

  void _onResetOtp(ResetOtp event, Emitter<OtpState> emit) {
    final String hiveKey = _getHiveKey(event.transNo); // ✅ Pakai Helper
    final OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    _performReset(hiveKey, trackingEntry);
    emit(OtpInitial());
  }

  Future<void> _onRequestOtp(RequestOtp event, Emitter<OtpState> emit) async {
    _startOptimisticFlow(event.transNo, event.shipTo, '1', emit);
  }

  Future<void> _onResendOtp(ResendOtp event, Emitter<OtpState> emit) async {
    _startOptimisticFlow(event.transNo, event.shipTo, '0', emit);
  }

  void _startOptimisticFlow(
      String transNo, String shipTo, String isFirst, Emitter<OtpState> emit) {
    final String hiveKey = _getHiveKey(transNo); // ✅ Pakai Helper

    OtpTrackingModel trackingEntry =
        _otpBox.get(hiveKey) ?? OtpTrackingModel(transNo: hiveKey);

    // Cek Limit
    if (trackingEntry.retryCount >= _maxRetries) {
      _retryCount = trackingEntry.retryCount;

      final bool isExpired = trackingEntry.lastRequestTime != null &&
          DateTime.now().difference(trackingEntry.lastRequestTime!).inHours >= 1;

      emit(OtpSent(
          cooldown: 0,
          retryLeft: 0,
          canReset: isExpired
      ));
      return;
    }

    // Update Data
    _retryCount = trackingEntry.retryCount + 1;
    trackingEntry.retryCount = _retryCount;
    trackingEntry.lastRequestTime = DateTime.now();
    _otpBox.put(hiveKey, trackingEntry);

    // Timer
    _cooldown = _initialTimer;
    _startTimer();

    emit(OtpSent(
        cooldown: _cooldown,
        retryLeft: _maxRetries - _retryCount,
        canReset: false
    ));

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
    }
    if (_cooldown == 0) {
      _timer?.cancel();
    }
    emit(OtpSent(
      cooldown: _cooldown,
      retryLeft: _maxRetries - _retryCount,
      canReset: false,
    ));
  }

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<OtpState> emit) async {
    emit(OtpLoading());

    try {
      final isValid =
      await repository.validateOtp(event.transNo, event.shipTo, event.otp);

      if (isValid) {
        _timer?.cancel();
        emit(OtpVerified());
      } else {
        emit(const OtpError("Kode OTP Salah. Silakan cek lagi."));
        emit(OtpSent(
            cooldown: _cooldown,
            retryLeft: _maxRetries - _retryCount,
            canReset: false
        ));
      }
    } catch (e) {
      emit(OtpError(e.toString()));
      emit(OtpSent(
          cooldown: _cooldown,
          retryLeft: _maxRetries - _retryCount,
          canReset: false
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}