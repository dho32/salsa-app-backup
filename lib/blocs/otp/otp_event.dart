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
  final String shipTo;
  final String isFirst; // tetap string "1"/"0" sesuai API saat ini.

  const RequestOtp(this.shipTo, this.isFirst);

  @override
  List<Object?> get props => [shipTo, isFirst];
}

/// “Resend OTP”
///
/// * [shipTo]   - kode toko.
/// * [isFirst]  - selalu "0" (backend pakai flag yang sama).
class ResendOtp extends OtpEvent {
  final String shipTo;
  final String isFirst;

  const ResendOtp(this.shipTo, this.isFirst);

  @override
  List<Object?> get props => [shipTo, isFirst];
}

/// Verifikasi kode yang diketik user
class VerifyOtp extends OtpEvent {
  final String shipTo;
  final String otp;

  const VerifyOtp(this.shipTo, this.otp);

  @override
  List<Object?> get props => [shipTo, otp];
}

/// Tick 1-detik sekali untuk update countdown
class OtpTick extends OtpEvent {
  final String shipTo;

  const OtpTick(this.shipTo);

  @override
  List<Object?> get props => [shipTo];
}
