// lib/blocs/service_call/validation_dropdown/validation_dropdown_state.dart
import 'package:equatable/equatable.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/common/measurement_limits.dart';
import '../../../models/common/note_option.dart';
import '../../../models/service_call/problem_source_model.dart';

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

enum NoteType {
  indoor,
  outdoor,
  outdoorPsi,
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
  final String transNo;
  final String serialNo;
  final List<ProblemSourceModel> data;
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
  final List<NoteOption> noteIndoorBeforeOptions;
  final List<NoteOption> noteIndoorAfterOptions;
  final List<NoteOption> noteOutdoorBeforeOptions;
  final List<NoteOption> noteOutdoorAfterOptions;
  final List<NoteOption> noteOutdoorPsiBeforeOptions;
  final List<NoteOption> noteOutdoorPsiAfterOptions;

  //selected note
  final String? selectedIndoorNoteBefore;
  final String? selectedOutdoorNoteBefore;
  final String? selectedIndoorNoteAfter;
  final String? selectedOutdoorNoteAfter;
  final String? selectedOutdoorPSINoteBefore;
  final String? selectedOutdoorPSINoteAfter;

  final Map<NoteType, List<CapturedImageDetail>> remarkPhotosBefore;
  final Map<NoteType, List<CapturedImageDetail>> remarkPhotosAfter;

  final Map<String, MeasurementLimits> limitsScBefore;
  final Map<String, MeasurementLimits> limitsScAfter;

  final int currentStep;
  final ValidationViewMode currentViewMode;

  final ValidationSaveStatus saveStatus;
  final String? saveMessage;

  final String? correctSerialNo;

  const ValidationDropdownLoaded({
    required this.transNo,
    required this.serialNo,
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
    required this.limitsScBefore,
    required this.limitsScAfter,
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
    this.remarkPhotosBefore = const {},
    this.remarkPhotosAfter = const {},
    this.saveStatus = ValidationSaveStatus.initial,
    this.saveMessage,
    this.correctSerialNo,
  });

  ValidationDropdownLoaded copyWith({
    String? transNo,
    String? serialNo,
    List<ProblemSourceModel>? data,
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
    List<NoteOption>? noteIndoorBeforeOptions,
    List<NoteOption>? noteIndoorAfterOptions,
    List<NoteOption>? noteOutdoorBeforeOptions,
    List<NoteOption>? noteOutdoorAfterOptions,
    List<NoteOption>? noteOutdoorPsiBeforeOptions,
    List<NoteOption>? noteOutdoorPsiAfterOptions,
    Object? selectedIndoorNoteBefore = const Object(),
    Object? selectedOutdoorNoteBefore = const Object(),
    Object? selectedIndoorNoteAfter = const Object(),
    Object? selectedOutdoorNoteAfter = const Object(),
    Object? selectedOutdoorPSINoteBefore = const Object(),
    Object? selectedOutdoorPSINoteAfter = const Object(),
    Map<NoteType, List<CapturedImageDetail>>? remarkPhotosBefore,
    Map<NoteType, List<CapturedImageDetail>>? remarkPhotosAfter,
    ValidationSaveStatus? saveStatus,
    Object? saveMessage = const Object(),
    Map<String, MeasurementLimits>? limitsScBefore,
    Map<String, MeasurementLimits>? limitsScAfter,
    Object? correctSerialNo = const Object(),
  }) {
    // Helper untuk menangani nullable copyWith
    T handleNullable<T>(Object? newValue, T currentValue) {
      // Jika newValue adalah penanda Object(), berarti field ini tidak diubah
      if (newValue is Object && identical(newValue, const Object())) {
        return currentValue;
      }
      // Jika newValue BUKAN penanda, gunakan newValue (bisa null atau non-null)
      return newValue as T;
    }

    return ValidationDropdownLoaded(
      transNo: transNo ?? this.transNo,
      serialNo: serialNo ?? this.serialNo,
      data: data ?? this.data,
      selectedUnitType: handleNullable(selectedUnitType, this.selectedUnitType),
      capturedPhotosBefore: capturedPhotosBefore ?? this.capturedPhotosBefore,
      capturedMeasurementsBefore:
          capturedMeasurementsBefore ?? this.capturedMeasurementsBefore,
      selectedProblemCards: selectedProblemCards ?? this.selectedProblemCards,
      capturedPhotosAfter: capturedPhotosAfter ?? this.capturedPhotosAfter,
      capturedMeasurementsAfter:
          capturedMeasurementsAfter ?? this.capturedMeasurementsAfter,
      currentStep: currentStep ?? this.currentStep,
      currentViewMode: currentViewMode ?? this.currentViewMode,
      outdoorSerialNumbers: outdoorSerialNumbers ?? this.outdoorSerialNumbers,
      selectedOutdoorSerialNo:
          handleNullable(selectedOutdoorSerialNo, this.selectedOutdoorSerialNo),
      limitsScBefore: limitsScBefore ?? this.limitsScBefore,
      limitsScAfter: limitsScAfter ?? this.limitsScAfter,
      noteIndoorBeforeOptions:
          noteIndoorBeforeOptions ?? this.noteIndoorBeforeOptions,
      noteIndoorAfterOptions:
          noteIndoorAfterOptions ?? this.noteIndoorAfterOptions,
      noteOutdoorBeforeOptions:
          noteOutdoorBeforeOptions ?? this.noteOutdoorBeforeOptions,
      noteOutdoorAfterOptions:
          noteOutdoorAfterOptions ?? this.noteOutdoorAfterOptions,
      noteOutdoorPsiBeforeOptions:
          noteOutdoorPsiBeforeOptions ?? this.noteOutdoorPsiBeforeOptions,
      noteOutdoorPsiAfterOptions:
          noteOutdoorPsiAfterOptions ?? this.noteOutdoorPsiAfterOptions,
      selectedIndoorNoteBefore: handleNullable(
          selectedIndoorNoteBefore, this.selectedIndoorNoteBefore),
      selectedOutdoorNoteBefore: handleNullable(
          selectedOutdoorNoteBefore, this.selectedOutdoorNoteBefore),
      selectedIndoorNoteAfter:
          handleNullable(selectedIndoorNoteAfter, this.selectedIndoorNoteAfter),
      selectedOutdoorNoteAfter: handleNullable(
          selectedOutdoorNoteAfter, this.selectedOutdoorNoteAfter),
      selectedOutdoorPSINoteBefore: handleNullable(
          selectedOutdoorPSINoteBefore, this.selectedOutdoorPSINoteBefore),
      selectedOutdoorPSINoteAfter: handleNullable(
          selectedOutdoorPSINoteAfter, this.selectedOutdoorPSINoteAfter),
      remarkPhotosBefore: remarkPhotosBefore ?? this.remarkPhotosBefore,
      remarkPhotosAfter: remarkPhotosAfter ?? this.remarkPhotosAfter,
      saveStatus: saveStatus ?? this.saveStatus,
      saveMessage: handleNullable(saveMessage, this.saveMessage),
      correctSerialNo: handleNullable(correctSerialNo, this.correctSerialNo),
    );
  }

  @override
  List<Object?> get props => [
        transNo,
        serialNo,
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
        remarkPhotosBefore,
        remarkPhotosAfter,
        limitsScBefore,
        limitsScAfter,
        saveStatus,
        saveMessage,
        correctSerialNo,
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
