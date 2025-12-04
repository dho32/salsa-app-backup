import 'package:equatable/equatable.dart';

/// ---  BASE  -----------------------------------------------------------------
abstract class OtpState extends Equatable {
  const OtpState();

  @override
  List<Object?> get props => const [];
}

class OtpInitial extends OtpState {}

class OtpLoading extends OtpState {}

class OtpSent extends OtpState {
  final int cooldown;
  final int retryLeft;
  final bool canReset; // <--- TAMBAHAN: Penanda sudah > 1 jam

  const OtpSent({
    required this.cooldown,
    required this.retryLeft,
    this.canReset = false, // Default false
  });

  @override
  List<Object> get props => [cooldown, retryLeft, canReset];
}

/// OTP diverifikasi valid di server
class OtpVerified extends OtpState {}

class OtpLimitReached extends OtpState {}

class OtpError extends OtpState {
  final String message;
  const OtpError(this.message);
  @override
  List<Object> get props => [message];
}

class OtpLocked extends OtpState {}
