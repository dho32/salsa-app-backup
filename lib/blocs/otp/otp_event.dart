// lib/blocs/otp/otp_event.dart
import 'package:equatable/equatable.dart';

/// Base-class semua event OTP
abstract class OtpEvent extends Equatable {
  const OtpEvent();

  // default, tidak ada field
  @override
  List<Object?> get props => const [];
}

/// “Kirim OTP” pertama kali - atau fetch status tanpa reset cooldown
///
/// * [shipTo]   - kode toko.
/// * [isFirst]  - "1" kalau benar-benar request pertama,
///                 "0" kalau hanya ingin **fetch** status (dipakai di dialog init).
class RequestOtp extends OtpEvent {
  final String transNo;
  final String shipTo;
  final String isFirst; // tetap string "1"/"0" sesuai API saat ini.

  const RequestOtp(this.transNo, this.shipTo, this.isFirst);

  @override
  List<Object?> get props => [transNo, shipTo, isFirst];
}

/// “Resend OTP”
///
/// * [shipTo]   - kode toko.
/// * [isFirst]  - selalu "0" (backend pakai flag yang sama).
class ResendOtp extends OtpEvent {
  final String transNo;
  final String shipTo;
  final String isFirst;

  const ResendOtp(this.transNo, this.shipTo, this.isFirst);

  @override
  List<Object?> get props => [transNo, shipTo, isFirst];
}

/// Verifikasi kode yang diketik user
class VerifyOtp extends OtpEvent {
  final String transNo;
  final String shipTo;
  final String otp;

  const VerifyOtp(this.transNo, this.shipTo, this.otp);

  @override
  List<Object?> get props => [transNo, shipTo, otp];
}

/// Tick 1-detik sekali untuk update countdown
class OtpTick extends OtpEvent {
  final String transNo;
  final String shipTo;

  const OtpTick(this.transNo, this.shipTo);

  @override
  List<Object?> get props => [transNo, shipTo];
}

class OtpTimerTicked extends OtpEvent {
  const OtpTimerTicked();
}

class CheckOtpStatus extends OtpEvent {
  final String transNo;
  final bool hasExistingPhoto;
  const CheckOtpStatus(this.transNo, {this.hasExistingPhoto = false});
  @override
  List<Object> get props => [transNo, hasExistingPhoto];
}

class ResetOtp extends OtpEvent {
  final String transNo;
  const ResetOtp(this.transNo);
  @override
  List<Object> get props => [transNo];
}
