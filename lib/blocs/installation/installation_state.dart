import 'package:equatable/equatable.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/components/widgets/measurement_note_dropdown.dart';
import '../../models/common/measurement_limits.dart';

enum InstallationStatus {
  initial,
  loading,
  success,      // Semua sukses (JSON + Upload + Confirm)
  failure,      // Error blocking (misal koneksi mati saat submit JSON)
  validatingSN, // Cek SN ke server
  snValidationSuccess,

  submitting,   // Step 1: Sedang kirim JSON Metadata
  uploading,    // Step 2: Sedang kirim File Fisik ke S3 (Trigger Dialog Progress)
  uploadPartial // Step 3: Selesai tapi ada file gagal (Trigger Dialog Partial)
}

class InstallationState extends Equatable {
  final InstallationStatus status;
  final String errorMessage;

  // Data Utama
  final InstallationDetailModel? taskDetail;
  final InstallationEntryModel? draftEntry;

  // Data Pendukung
  final List<String> availableIndoors;
  final List<String> invalidSerialNumbers;
  final Map<String, MeasurementLimits> measurementLimits;
  final List<MeasurementNoteOption> skipReasons;

  // Data Upload Result (Untuk Dialog)
  final int successCount;
  final int failureCount;
  final List<String> failedFiles;

  const InstallationState({
    this.status = InstallationStatus.initial,
    this.errorMessage = '',
    this.taskDetail,
    this.draftEntry,
    this.availableIndoors = const [],
    this.invalidSerialNumbers = const [],
    this.measurementLimits = const {},
    this.skipReasons = const [],
    this.successCount = 0,
    this.failureCount = 0,
    this.failedFiles = const [],
  });

  InstallationState copyWith({
    InstallationStatus? status,
    String? errorMessage,
    InstallationDetailModel? taskDetail,
    InstallationEntryModel? draftEntry,
    List<String>? availableIndoors,
    List<String>? invalidSerialNumbers,
    Map<String, MeasurementLimits>? measurementLimits,
    List<MeasurementNoteOption>? skipReasons,
    int? successCount,
    int? failureCount,
    List<String>? failedFiles,
  }) {
    return InstallationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? '', // Reset error message jika tidak ada
      taskDetail: taskDetail ?? this.taskDetail,
      draftEntry: draftEntry ?? this.draftEntry,
      availableIndoors: availableIndoors ?? this.availableIndoors,
      invalidSerialNumbers: invalidSerialNumbers ?? this.invalidSerialNumbers,
      measurementLimits: measurementLimits ?? this.measurementLimits,
      skipReasons: skipReasons ?? this.skipReasons,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      failedFiles: failedFiles ?? this.failedFiles,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    taskDetail,
    draftEntry,
    availableIndoors,
    invalidSerialNumbers,
    measurementLimits,
    skipReasons,
    successCount,
    failureCount,
    failedFiles
  ];
}