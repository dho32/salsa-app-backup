// lib/blocs/service_call/validation_dropdown/validation_dropdown_state.dart
import 'package:equatable/equatable.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/service_call/problem_source_model.dart';

// BARU: Enum untuk mode tampilan
enum ValidationViewMode {
  before,
  after,
}

enum ValidationSaveStatus {
  initial,
  saving,
  successDraft,
  successSilent,
  successFinal,
  error
}

abstract class ValidationDropdownState extends Equatable {
  const ValidationDropdownState();

  @override
  List<Object?> get props => [];
}

class ValidationDropdownInitial extends ValidationDropdownState {}

class ValidationDropdownLoading extends ValidationDropdownState {}

class ValidationDropdownError extends ValidationDropdownState {
  final String message;

  const ValidationDropdownError(this.message);

  @override
  List<Object?> get props => [message];
}

class ValidationDropdownLoaded extends ValidationDropdownState {
  final List<ProblemSourceModel> data; // Ini List<ProblemSourceModel>
  final String? selectedUnitType;
  final List<String> outdoorSerialNumbers;
  final String unitLocation;
  final String? selectedOutdoorSerialNo;

  // Data "Sebelum"
  final List<CapturedImageDetail> capturedPhotosBefore;
  final List<MeasurementEntry> capturedMeasurementsBefore;

  // Data "Sesudah"
  final List<SelectedProblemCard> selectedProblemCards;
  final List<CapturedImageDetail> capturedPhotosAfter;
  final List<MeasurementEntry> capturedMeasurementsAfter;

  // Daftar Opsi Catatan (dari API)
  final List<String> noteIndoorBeforeOptions;
  final List<String> noteIndoorAfterOptions;
  final List<String> noteOutdoorBeforeOptions;
  final List<String> noteOutdoorAfterOptions;
  final List<String> noteOutdoorPsiBeforeOptions;
  final List<String> noteOutdoorPsiAfterOptions;

  //selected note
  final String? selectedIndoorNoteBefore;
  final String? selectedOutdoorNoteBefore;
  final String? selectedIndoorNoteAfter;
  final String? selectedOutdoorNoteAfter;
  final String? selectedOutdoorPSINoteBefore;
  final String? selectedOutdoorPSINoteAfter;

  final int currentStep;
  final ValidationViewMode currentViewMode;

  final ValidationSaveStatus saveStatus;
  final String? saveMessage;

  const ValidationDropdownLoaded({
    required this.data,
    this.selectedUnitType,
    this.capturedPhotosBefore = const [],
    this.capturedMeasurementsBefore = const [],
    required this.selectedProblemCards,
    this.capturedPhotosAfter = const [],
    this.capturedMeasurementsAfter = const [],
    this.currentStep = 0,
    this.currentViewMode = ValidationViewMode.before,
    this.outdoorSerialNumbers = const [],
    this.unitLocation = 'INDOOR',
    this.selectedOutdoorSerialNo,
    this.noteIndoorBeforeOptions = const [],
    this.noteIndoorAfterOptions = const [],
    this.noteOutdoorBeforeOptions = const [],
    this.noteOutdoorAfterOptions = const [],
    this.noteOutdoorPsiBeforeOptions = const [],
    this.noteOutdoorPsiAfterOptions = const [],
    this.selectedIndoorNoteBefore,
    this.selectedOutdoorNoteBefore,
    this.selectedIndoorNoteAfter,
    this.selectedOutdoorNoteAfter,
    this.selectedOutdoorPSINoteBefore,
    this.selectedOutdoorPSINoteAfter,
    this.saveStatus = ValidationSaveStatus.initial,
    this.saveMessage,
  });

  ValidationDropdownLoaded copyWith({
    List<ProblemSourceModel>? data,
    // Gunakan Object() sebagai penanda "tidak diubah" vs "diubah jadi null"
    // Ini adalah trik umum untuk copyWith nullable fields
    Object? selectedUnitType = const Object(),
    List<CapturedImageDetail>? capturedPhotosBefore,
    List<MeasurementEntry>? capturedMeasurementsBefore,
    List<SelectedProblemCard>? selectedProblemCards,
    List<CapturedImageDetail>? capturedPhotosAfter,
    List<MeasurementEntry>? capturedMeasurementsAfter,
    int? currentStep,
    ValidationViewMode? currentViewMode,
    List<String>? outdoorSerialNumbers,
    Object? selectedOutdoorSerialNo = const Object(),
    List<String>? noteIndoorBeforeOptions,
    List<String>? noteIndoorAfterOptions,
    List<String>? noteOutdoorBeforeOptions,
    List<String>? noteOutdoorAfterOptions,
    List<String>? noteOutdoorPsiBeforeOptions,
    List<String>? noteOutdoorPsiAfterOptions,
    Object? selectedIndoorNoteBefore = const Object(),
    Object? selectedOutdoorNoteBefore = const Object(),
    Object? selectedIndoorNoteAfter = const Object(),
    Object? selectedOutdoorNoteAfter = const Object(),
    Object? selectedOutdoorPSINoteBefore = const Object(),
    Object? selectedOutdoorPSINoteAfter = const Object(),
    ValidationSaveStatus? saveStatus,
    Object? saveMessage = const Object(), // saveMessage juga bisa null
  }) {
    // Helper untuk menangani nullable copyWith
    T _handleNullable<T>(Object? newValue, T currentValue) {
      // Jika newValue adalah penanda Object(), berarti field ini tidak diubah
      if (newValue is Object && identical(newValue, const Object())) {
        return currentValue;
      }
      // Jika newValue BUKAN penanda, gunakan newValue (bisa null atau non-null)
      return newValue as T;
    }

    return ValidationDropdownLoaded(
      data: data ?? this.data,
      selectedUnitType: _handleNullable(selectedUnitType, this.selectedUnitType),
      capturedPhotosBefore: capturedPhotosBefore ?? this.capturedPhotosBefore,
      capturedMeasurementsBefore: capturedMeasurementsBefore ?? this.capturedMeasurementsBefore,
      selectedProblemCards: selectedProblemCards ?? this.selectedProblemCards,
      capturedPhotosAfter: capturedPhotosAfter ?? this.capturedPhotosAfter,
      capturedMeasurementsAfter: capturedMeasurementsAfter ?? this.capturedMeasurementsAfter,
      currentStep: currentStep ?? this.currentStep,
      currentViewMode: currentViewMode ?? this.currentViewMode,
      outdoorSerialNumbers: outdoorSerialNumbers ?? this.outdoorSerialNumbers,
      selectedOutdoorSerialNo: _handleNullable(selectedOutdoorSerialNo, this.selectedOutdoorSerialNo),

      noteIndoorBeforeOptions: noteIndoorBeforeOptions ?? this.noteIndoorBeforeOptions,
      noteIndoorAfterOptions: noteIndoorAfterOptions ?? this.noteIndoorAfterOptions,
      noteOutdoorBeforeOptions: noteOutdoorBeforeOptions ?? this.noteOutdoorBeforeOptions,
      noteOutdoorAfterOptions: noteOutdoorAfterOptions ?? this.noteOutdoorAfterOptions,
      noteOutdoorPsiBeforeOptions: noteOutdoorPsiBeforeOptions ?? this.noteOutdoorPsiBeforeOptions,
      noteOutdoorPsiAfterOptions: noteOutdoorPsiAfterOptions ?? this.noteOutdoorPsiAfterOptions,
      selectedIndoorNoteBefore: _handleNullable(selectedIndoorNoteBefore, this.selectedIndoorNoteBefore),
      selectedOutdoorNoteBefore: _handleNullable(selectedOutdoorNoteBefore, this.selectedOutdoorNoteBefore),
      selectedIndoorNoteAfter: _handleNullable(selectedIndoorNoteAfter, this.selectedIndoorNoteAfter),
      selectedOutdoorNoteAfter: _handleNullable(selectedOutdoorNoteAfter, this.selectedOutdoorNoteAfter),
      selectedOutdoorPSINoteBefore: _handleNullable(selectedOutdoorPSINoteBefore, this.selectedOutdoorPSINoteBefore),
      selectedOutdoorPSINoteAfter: _handleNullable(selectedOutdoorPSINoteAfter, this.selectedOutdoorPSINoteAfter),


      saveStatus: saveStatus ?? this.saveStatus,
      saveMessage: _handleNullable(saveMessage, this.saveMessage),
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedUnitType,
        selectedProblemCards,
        capturedPhotosBefore,
        capturedMeasurementsBefore,
        capturedPhotosAfter,
        capturedMeasurementsAfter,
        currentStep,
        currentViewMode,
        outdoorSerialNumbers,
        selectedOutdoorSerialNo,
        noteIndoorBeforeOptions,
        noteIndoorAfterOptions,
        noteOutdoorBeforeOptions,
        noteOutdoorAfterOptions,
        noteOutdoorPsiBeforeOptions,
        noteOutdoorPsiAfterOptions,
        selectedIndoorNoteBefore,
        selectedOutdoorNoteBefore,
        selectedIndoorNoteAfter,
        selectedOutdoorNoteAfter,
        selectedOutdoorPSINoteBefore,
        selectedOutdoorPSINoteAfter,
        saveStatus,
        saveMessage,
      ];
}

class SelectedProblemCard extends Equatable {
  final String? selectedProblemId;
  final List<String> selectedSolutionIds;

  const SelectedProblemCard({
    this.selectedProblemId,
    this.selectedSolutionIds = const [],
  });

  SelectedProblemCard copyWith({
    String? selectedProblemId,
    List<String>? selectedSolutionIds,
  }) {
    return SelectedProblemCard(
      selectedProblemId: selectedProblemId ?? this.selectedProblemId,
      selectedSolutionIds: selectedSolutionIds ?? this.selectedSolutionIds,
    );
  }

  @override
  List<Object?> get props => [selectedProblemId, selectedSolutionIds];
}
