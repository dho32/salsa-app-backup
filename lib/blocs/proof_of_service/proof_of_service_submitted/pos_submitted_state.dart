abstract class PosSubmittedState {}

class PosValidationInitial extends PosSubmittedState {}
class PosValidationSubmitting extends PosSubmittedState {}
class PosValidationUploadInProgress extends PosSubmittedState {}
class PosValidationSuccess extends PosSubmittedState {}
class PosValidationFailure extends PosSubmittedState {
  final String error;
  PosValidationFailure(this.error);
}
class PosValidationUploadPartial extends PosSubmittedState {
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;
  final String transNo;
  final List<dynamic> presignedDetail;

  PosValidationUploadPartial({
    required this.successCount,
    required this.failureCount,
    required this.failedFiles,
    required this.transNo,
    required this.presignedDetail,
  });
}