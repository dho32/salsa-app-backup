part of 'posf_closed_bloc.dart';

enum PosfClosedStatus {
  initial,
  loading,
  uploading,
  partialFailure,
  success,
  failure,
}

class PosfClosedState extends Equatable {
  final PosfClosedStatus status;
  final List<CapturedImageDetail> proofImages;
  final String? selectedReason;
  final String notes;
  final String? errorMessage;

  // Data retry upload (bila sebagian foto gagal naik ke S3).
  final List<dynamic> presignedDetail;
  final List<String> failedFiles;
  final int successCount;
  final int failureCount;

  const PosfClosedState({
    this.status = PosfClosedStatus.initial,
    this.proofImages = const [],
    this.selectedReason,
    this.notes = '',
    this.errorMessage,
    this.presignedDetail = const [],
    this.failedFiles = const [],
    this.successCount = 0,
    this.failureCount = 0,
  });

  bool get isReadyToSubmit =>
      proofImages.isNotEmpty &&
      selectedReason != null &&
      selectedReason!.isNotEmpty;

  PosfClosedState copyWith({
    PosfClosedStatus? status,
    List<CapturedImageDetail>? proofImages,
    String? selectedReason,
    String? notes,
    String? errorMessage,
    List<dynamic>? presignedDetail,
    List<String>? failedFiles,
    int? successCount,
    int? failureCount,
    bool clearPartial = false,
  }) {
    return PosfClosedState(
      status: status ?? this.status,
      proofImages: proofImages ?? this.proofImages,
      selectedReason: selectedReason ?? this.selectedReason,
      notes: notes ?? this.notes,
      errorMessage: errorMessage,
      presignedDetail:
          clearPartial ? const [] : (presignedDetail ?? this.presignedDetail),
      failedFiles: clearPartial ? const [] : (failedFiles ?? this.failedFiles),
      successCount: clearPartial ? 0 : (successCount ?? this.successCount),
      failureCount: clearPartial ? 0 : (failureCount ?? this.failureCount),
    );
  }

  @override
  List<Object?> get props => [
        status,
        proofImages,
        selectedReason,
        notes,
        errorMessage,
        presignedDetail,
        failedFiles,
        successCount,
        failureCount,
      ];
}
