import 'package:equatable/equatable.dart';

enum RROCutOffSubmitStatus {
  initial,
  loading,
  uploading,
  success,
  uploadPartial,
  failure
}

class RROCutOffSubmitState extends Equatable {
  final RROCutOffSubmitStatus status;
  final String errorMessage;
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;

  const RROCutOffSubmitState({
    this.status = RROCutOffSubmitStatus.initial,
    this.errorMessage = '',
    this.successCount = 0,
    this.failureCount = 0,
    this.failedFiles = const [],
  });

  RROCutOffSubmitState copyWith({
    RROCutOffSubmitStatus? status,
    String? errorMessage,
    int? successCount,
    int? failureCount,
    List<String>? failedFiles,
  }) {
    return RROCutOffSubmitState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      failedFiles: failedFiles ?? this.failedFiles,
    );
  }

  @override
  List<Object> get props => [status, errorMessage, successCount, failureCount, failedFiles];
}