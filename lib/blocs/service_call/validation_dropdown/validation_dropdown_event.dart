// lib/blocs/service_call/validation_dropdown/validation_dropdown_event.dart
import 'package:equatable/equatable.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
// import '../../../models/service_call/problem_source_model.dart'; // Tidak diperlukan di sini
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart'; // Diperlukan untuk SaveValidationData
import 'package:salsa/blocs/service_call/validation_dropdown/validation_dropdown_state.dart';

import '../../../models/common/measurement_limits.dart';
import '../../../models/service_call/problem_source_model.dart';
import '../../../models/service_call/service_call_detail_model.dart'; // BARU: Import ValidationViewMode

enum NoteType { indoor, outdoor, outdoorPsi }

abstract class ValidationDropdownEvent extends Equatable {
  const ValidationDropdownEvent();

  @override
  List<Object?> get props => [];
}

class FetchValidationDropdownData extends ValidationDropdownEvent {
  final ServiceCallValidationEntryModel? initialData;
  final String transNo;
  final String currentIndoorSerial;
  final List<String> allAvailableOutdoorSerials;
  final List<ProblemSourceModel> problemSources;
  final ServiceCallDetailModel detailData;
  final Map<String, MeasurementLimits> limitsScBefore;
  final Map<String, MeasurementLimits> limitsScAfter;

  const FetchValidationDropdownData({
    this.initialData,
    required this.transNo,
    required this.currentIndoorSerial,
    required this.allAvailableOutdoorSerials,
    required this.problemSources,
    required this.detailData,
    required this.limitsScBefore,
    required this.limitsScAfter,
  });

  @override
  List<Object?> get props => [
    initialData,
    transNo,
    currentIndoorSerial,
    allAvailableOutdoorSerials,
    detailData,
    limitsScBefore,
    limitsScAfter,
  ];
}

class NoteChanged extends ValidationDropdownEvent {
  final String? note;
  final NoteType noteType;
  final bool isBefore;

  const NoteChanged(this.note, {required this.noteType, required this.isBefore});

  @override
  List<Object?> get props => [note, noteType, isBefore];
}

class SelectUnitType extends ValidationDropdownEvent {
  final String unitType;
  const SelectUnitType(this.unitType);

  @override
  List<Object?> get props => [unitType];
}

class AddProblemCard extends ValidationDropdownEvent {
  final String problemId;
  final List<String> solutionIds;

  const AddProblemCard({required this.problemId, required this.solutionIds});

  @override
  List<Object?> get props => [problemId, solutionIds];
}

class RemoveProblemCard extends ValidationDropdownEvent {
  final String problemId;
  const RemoveProblemCard({required this.problemId});

  @override
  List<Object?> get props => [problemId];
}

class SelectOutdoorSerial extends ValidationDropdownEvent {
  final String serialNo;

  const SelectOutdoorSerial(this.serialNo);

  @override
  List<Object?> get props => [serialNo];
}

class SelectProblemForCard extends ValidationDropdownEvent {
  final int index;
  final String problemId;
  const SelectProblemForCard(this.index, this.problemId);

  @override
  List<Object?> get props => [index, problemId];
}

class SelectSolutionsForCard extends ValidationDropdownEvent {
  final int index;
  final List<String> solutionIds;
  const SelectSolutionsForCard(this.index, this.solutionIds);

  @override
  List<Object?> get props => [index, solutionIds];
}

class MarkUnitAsInvalid extends ValidationDropdownEvent {
  final String transNo;
  final String serialNo;
  final List<CapturedImageDetail> proofPhotos;
  final String reason;

  const MarkUnitAsInvalid({
    required this.transNo,
    required this.serialNo,
    required this.proofPhotos,
    required this.reason,
  });

  @override
  List<Object?> get props => [transNo, serialNo, proofPhotos, reason];
}

// ============= Event untuk Data SEBELUM =============
class AddCapturedPhotoBefore extends ValidationDropdownEvent {
  final CapturedImageDetail imageDetail;
  const AddCapturedPhotoBefore(this.imageDetail);

  @override
  List<Object?> get props => [imageDetail];
}

class RemoveCapturedPhotoBefore extends ValidationDropdownEvent {
  final String imagePath;
  const RemoveCapturedPhotoBefore(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class UpdateMeasurementBefore extends ValidationDropdownEvent {
  final MeasurementEntry measurement;
  const UpdateMeasurementBefore(this.measurement);

  @override
  List<Object?> get props => [measurement];
}

// ============= Event untuk Data SESUDAH (Foto dan Pengukuran) =============
class AddCapturedPhotoAfter extends ValidationDropdownEvent {
  final CapturedImageDetail imageDetail;
  const AddCapturedPhotoAfter(this.imageDetail);

  @override
  List<Object?> get props => [imageDetail];
}

class RemoveCapturedPhotoAfter extends ValidationDropdownEvent {
  final String imagePath;
  const RemoveCapturedPhotoAfter(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class UpdateMeasurementAfter extends ValidationDropdownEvent {
  final MeasurementEntry measurement;
  const UpdateMeasurementAfter(this.measurement);

  @override
  List<Object?> get props => [measurement];
}

class ChangeValidationStep extends ValidationDropdownEvent {
  final int step;
  const ChangeValidationStep(this.step);

  @override
  List<Object?> get props => [step];
}

// BARU: Event untuk mengubah mode tampilan
class ChangeValidationViewMode extends ValidationDropdownEvent {
  final ValidationViewMode mode;

  const ChangeValidationViewMode(this.mode);

  @override
  List<Object?> get props => [mode];
}

// BARU: Event untuk menyimpan data validasi
class SaveValidationData extends ValidationDropdownEvent {
  final String transNo; // Menggunakan transNo dari ServiceCallValidationEntryModel
  final String serialNo; // Menggunakan serialNo dari ServiceCallValidationEntryModel
  final bool markAsCompleted;
  final bool showNotification;

  const SaveValidationData({
    required this.transNo,
    required this.serialNo,
    this.markAsCompleted = false,
    this.showNotification = true,
  });

  @override
  List<Object?> get props => [transNo, serialNo, markAsCompleted, showNotification];
}