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

  final int currentStep;
  final ValidationViewMode currentViewMode;

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
  });

  ValidationDropdownLoaded copyWith({
    List<ProblemSourceModel>? data,
    String? selectedUnitType,
    List<CapturedImageDetail>? capturedPhotosBefore,
    List<MeasurementEntry>? capturedMeasurementsBefore,
    List<SelectedProblemCard>? selectedProblemCards,
    List<CapturedImageDetail>? capturedPhotosAfter,
    List<MeasurementEntry>? capturedMeasurementsAfter,
    int? currentStep,
    ValidationViewMode? currentViewMode,
    List<String>? outdoorSerialNumbers,
    String? selectedOutdoorSerialNo,
  }) {
    return ValidationDropdownLoaded(
      data: data ?? this.data,
      selectedUnitType: selectedUnitType ?? this.selectedUnitType,
      capturedPhotosBefore: capturedPhotosBefore ?? this.capturedPhotosBefore,
      capturedMeasurementsBefore: capturedMeasurementsBefore ?? this.capturedMeasurementsBefore,
      selectedProblemCards: selectedProblemCards ?? this.selectedProblemCards,
      capturedPhotosAfter: capturedPhotosAfter ?? this.capturedPhotosAfter,
      capturedMeasurementsAfter: capturedMeasurementsAfter ?? this.capturedMeasurementsAfter,
      currentStep: currentStep ?? this.currentStep,
      currentViewMode: currentViewMode ?? this.currentViewMode,
      outdoorSerialNumbers: outdoorSerialNumbers ?? this.outdoorSerialNumbers,
      selectedOutdoorSerialNo:
      selectedOutdoorSerialNo ?? this.selectedOutdoorSerialNo,
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