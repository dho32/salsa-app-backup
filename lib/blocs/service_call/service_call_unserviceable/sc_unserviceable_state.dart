import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

enum UnserviceableStatus {
  initial,
  loading,
  uploading,
  partialFailure,
  success,
  failure
}

class SCUnserviceableState extends Equatable {
  final UnserviceableStatus status;
  final List<CapturedImageDetail> proofImages;
  final String? selectedReason;
  final String notes;
  final String? errorMessage;
  final Map<String, dynamic>? partialUploadData;

  const SCUnserviceableState({
    this.status = UnserviceableStatus.initial,
    this.proofImages = const [],
    this.selectedReason,
    this.notes = '',
    this.errorMessage,
    this.partialUploadData,
  });

  SCUnserviceableState copyWith({
    UnserviceableStatus? status,
    List<CapturedImageDetail>? proofImages,
    String? selectedReason,
    String? notes,
    String? errorMessage,
    Map<String, dynamic>? partialUploadData,
    bool clearPartialUploadData = false,
  }) {
    return SCUnserviceableState(
      status: status ?? this.status,
      proofImages: proofImages ?? this.proofImages,
      selectedReason: selectedReason ?? this.selectedReason,
      notes: notes ?? this.notes,
      errorMessage: errorMessage ?? this.errorMessage,
      partialUploadData: clearPartialUploadData ? null : partialUploadData ?? this.partialUploadData,
    );
  }

  @override
  List<Object?> get props => [
    status,
    proofImages,
    selectedReason,
    notes,
    errorMessage,
    partialUploadData
  ];
}