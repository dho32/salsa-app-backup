import 'package:equatable/equatable.dart';

/// ---  BASE  -----------------------------------------------------------------
abstract class OtpState extends Equatable {
  const OtpState();

  @override
  List<Object?> get props => const [];
}

/// ---  VARIANT STATE  ---------------------------------------------------------

/// Awal ― belum ada aksi apa-apa
class OtpInitial extends OtpState {
  const OtpInitial();
}

/// Sedang kontak server (request / resend / verify)
class OtpLoading extends OtpState {
  const OtpLoading();
}

/// OTP berhasil dikirim atau di-resend
class OtpSent extends OtpState {
  final int secondsRemaining;
  final int resendCooldown;
  final int retryLeft;

  final bool hasOtp;

  const OtpSent({
    required this.secondsRemaining,
    required this.resendCooldown,
    required this.retryLeft,
    required this.hasOtp, // ← tambahkan
  });

  /// Tombol “Kirim Ulang” aktif jika cooldown habis, masih ada retry,
  /// dan OTP memang sudah pernah dikirim.
  bool get canResend => hasOtp && resendCooldown == 0 && retryLeft > 0;

  @override
  List<Object?> get props =>
      [secondsRemaining, resendCooldown, retryLeft, hasOtp];
}

/// OTP diverifikasi valid di server
class OtpVerified extends OtpState {
  const OtpVerified();
}

/// OTP salah / server mengembalikan error
class OtpError extends OtpState {
  final String message;
  final int? secondsRemaining;
  final int? resendCooldown;
  final int? retryLeft;
  final bool? hasOtp;

  const OtpError(
    this.message, {
    this.secondsRemaining,
    this.resendCooldown,
    this.retryLeft,
    this.hasOtp,
  });

  @override
  List<Object?> get props =>
      [message, secondsRemaining, resendCooldown, retryLeft, hasOtp];
}

/// Masa berlaku OTP habis
class OtpExpired extends OtpState {
  const OtpExpired();
}

/// User di-lock (mis. 1 jam) karena sudah resend 3 ×
class OtpLocked extends OtpState {
  final Duration lockedFor;
  final String? temporaryError;

  const OtpLocked(this.lockedFor, {this.temporaryError});

  @override
  List<Object?> get props => [lockedFor, temporaryError];
}
