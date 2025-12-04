import '../sc_form/sc_form_state.dart';

abstract class ServiceCallSubmittedState {}

class ValidationInitial extends ServiceCallSubmittedState {}

class ValidationUploadInProgress extends ServiceCallSubmittedState {}

class ValidationSubmitting extends ServiceCallSubmittedState {}

class ValidationSuccess extends ServiceCallSubmittedState {
  final String transNo;
  final List<dynamic> presignedDetail;

  ValidationSuccess({
    required this.transNo,
    required this.presignedDetail,
  });
}

class ValidationFailure extends ServiceCallSubmittedState {
  final String error;

  ValidationFailure(this.error);
}

class ValidationUploadPartial extends ServiceCallSubmittedState {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;
  final String transNo;
  final List<dynamic> presignedDetail;

  ValidationUploadPartial({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
    required this.transNo,
    required this.presignedDetail,
  });

  List<Object?> get props =>
      [successCount, failureCount, failedFiles, transNo, presignedDetail];
}

class ScProceedToOtpDialog extends ServiceCallSubmittedState {
  final ScFormState formState;
  final String? ahoNumber;

  ScProceedToOtpDialog(this.formState, {this.ahoNumber});
}

class ScProceedToAhoDialog extends ServiceCallSubmittedState {
  final ScFormState formState;
  final String? initialAho;
  ScProceedToAhoDialog(this.formState, {this.initialAho});
}

class ScFinalValidationLoading extends ServiceCallSubmittedState {}
