part of 'scf_submitted_bloc.dart';

abstract class ScfSubmittedState extends Equatable {
  const ScfSubmittedState();

  @override
  List<Object?> get props => [];
}

class ScfSubmittedInitial extends ScfSubmittedState {}

class ScfFinalValidationLoading extends ScfSubmittedState {}

/// Butuh input nomor AHO sebelum OTP.
class ScfProceedToAhoDialog extends ScfSubmittedState {
  final ScfFormState formState;
  final String? initialAho;

  const ScfProceedToAhoDialog(this.formState, {this.initialAho});

  @override
  List<Object?> get props => [formState, initialAho];
}

/// Lanjut ke dialog OTP (dengan/atau tanpa AHO).
class ScfProceedToOtpDialog extends ScfSubmittedState {
  final ScfFormState formState;
  final String? ahoNumber;

  const ScfProceedToOtpDialog(this.formState, {this.ahoNumber});

  @override
  List<Object?> get props => [formState, ahoNumber];
}

class ScfSubmitting extends ScfSubmittedState {}

class ScfUploadInProgress extends ScfSubmittedState {}

class ScfSubmitSuccess extends ScfSubmittedState {
  final String transNo;

  const ScfSubmitSuccess(this.transNo);

  @override
  List<Object?> get props => [transNo];
}

class ScfSubmitFailure extends ScfSubmittedState {
  final String error;

  const ScfSubmitFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class ScfUploadPartial extends ScfSubmittedState {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;
  final String transNo;
  final List<dynamic> presignedDetail;

  const ScfUploadPartial({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
    required this.transNo,
    required this.presignedDetail,
  });

  @override
  List<Object?> get props =>
      [successCount, failureCount, failedFiles, transNo, presignedDetail];
}
