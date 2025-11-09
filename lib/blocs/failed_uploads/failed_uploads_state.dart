part of 'failed_uploads_bloc.dart';

enum FailedUploadsStatus { initial, loading, loaded, uploading, error }

enum SuccessAction { stayAndRefresh, popToHome }

class FailedUploadsState extends Equatable {
  final FailedUploadsStatus status;
  final List<Map<String, dynamic>> failedTransactions;
  final String? uploadingTransNo;
  final String? errorMessage;
  final String? snackbarMessage;
  final String? successMessage;
  final SuccessAction successAction;
  final int? retrySuccessCount;
  final int? retryFailureCount;
  final List<String>? retryFailedFiles;
  final String? lastSuccessfulRetryTransNo;
  final String? lastSuccessfulRetryModuleType;

  const FailedUploadsState({
    this.status = FailedUploadsStatus.initial,
    this.failedTransactions = const [],
    this.uploadingTransNo,
    this.errorMessage,
    this.snackbarMessage,
    this.successMessage,
    this.successAction = SuccessAction.stayAndRefresh,
    this.retrySuccessCount,
    this.retryFailureCount,
    this.retryFailedFiles,
    this.lastSuccessfulRetryTransNo,
    this.lastSuccessfulRetryModuleType,
  });

  FailedUploadsState copyWith({
    FailedUploadsStatus? status,
    List<Map<String, dynamic>>? failedTransactions,
    String? uploadingTransNo,
    bool clearUploadingTransNo = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? snackbarMessage,
    bool clearSnackbarMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    SuccessAction? successAction,
    int? retrySuccessCount,
    int? retryFailureCount,
    List<String>? retryFailedFiles,
    bool clearRetryResult = false,
    String? lastSuccessfulRetryTransNo,
    String? lastSuccessfulRetryModuleType,
    bool clearLastSuccessfulRetry = false,
  }) {
    return FailedUploadsState(
      status: status ?? this.status,
      failedTransactions: failedTransactions ?? this.failedTransactions,
      uploadingTransNo: clearUploadingTransNo
          ? null
          : (uploadingTransNo ?? this.uploadingTransNo),
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      snackbarMessage: clearSnackbarMessage
          ? null
          : (snackbarMessage ?? this.snackbarMessage),
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      successAction: successAction ?? this.successAction,
      retrySuccessCount: clearRetryResult
          ? null
          : (retrySuccessCount ?? this.retrySuccessCount),
      retryFailureCount: clearRetryResult
          ? null
          : (retryFailureCount ?? this.retryFailureCount),
      retryFailedFiles:
          clearRetryResult ? null : (retryFailedFiles ?? this.retryFailedFiles),
      lastSuccessfulRetryTransNo: clearLastSuccessfulRetry
          ? null
          : (lastSuccessfulRetryTransNo ?? this.lastSuccessfulRetryTransNo),
      lastSuccessfulRetryModuleType: clearLastSuccessfulRetry
          ? null
          : (lastSuccessfulRetryModuleType ??
              this.lastSuccessfulRetryModuleType),
    );
  }

  @override
  List<Object?> get props => [
        status,
        failedTransactions,
        uploadingTransNo,
        errorMessage,
        snackbarMessage,
        successMessage,
        successAction,
        retrySuccessCount,
        retryFailureCount,
        retryFailedFiles,
        lastSuccessfulRetryTransNo,
        lastSuccessfulRetryModuleType,
      ];
}
