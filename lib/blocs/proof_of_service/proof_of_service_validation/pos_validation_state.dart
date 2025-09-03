import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';

abstract class PosValidationState extends Equatable {
  const PosValidationState();
  @override
  List<Object> get props => [];
}

class PosValidationInitial extends PosValidationState {}
class PosValidationLoading extends PosValidationState {}

class PosValidationLoaded extends PosValidationState {
  final int currentStep;
  final String unitType; // 'IN', 'OUT', atau 'SET'
  final List<CapturedImageDetail> photosBefore;
  final List<CapturedImageDetail> photosAfter;
  final List<MeasurementEntry> measurementsAfter;

  const PosValidationLoaded({
    this.currentStep = 0,
    required this.unitType,
    this.photosBefore = const [],
    this.photosAfter = const [],
    this.measurementsAfter = const [],
  });

  PosValidationLoaded copyWith({
    int? currentStep,
    String? unitType,
    List<CapturedImageDetail>? photosBefore,
    List<CapturedImageDetail>? photosAfter,
    List<MeasurementEntry>? measurementsAfter,
  }) {
    return PosValidationLoaded(
      currentStep: currentStep ?? this.currentStep,
      unitType: unitType ?? this.unitType,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      measurementsAfter: measurementsAfter ?? this.measurementsAfter,
    );
  }

  @override
  List<Object> get props => [
    currentStep,
    unitType,
    photosBefore,
    photosAfter,
    measurementsAfter,
  ];
}

class PosValidationError extends PosValidationState {
  final String message;
  const PosValidationError(this.message);
}