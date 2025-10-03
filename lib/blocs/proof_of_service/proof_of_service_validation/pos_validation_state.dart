import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';

abstract class PosValidationState extends Equatable {
  const PosValidationState();
  @override
  List<Object?> get props => [];
}

class PosValidationInitial extends PosValidationState {}
class PosValidationLoading extends PosValidationState {}

class PosValidationLoaded extends PosValidationState {
  final int currentStep;
  final String unitType; // 'IN', 'OUT', atau 'SET'
  final List<CapturedImageDetail> photosBefore;
  final List<CapturedImageDetail> photosAfter;
  final List<MeasurementEntry> measurementsAfter;
  final List<String> availableIndoorSerials;
  final String? pairedIndoorSerial;

  const PosValidationLoaded({
    this.currentStep = 0,
    required this.unitType,
    this.photosBefore = const [],
    this.photosAfter = const [],
    this.measurementsAfter = const [],
    this.availableIndoorSerials = const [],
    this.pairedIndoorSerial,
  });

  PosValidationLoaded copyWith({
    int? currentStep,
    String? unitType,
    List<CapturedImageDetail>? photosBefore,
    List<CapturedImageDetail>? photosAfter,
    List<MeasurementEntry>? measurementsAfter,
    List<String>? availableIndoorSerials,
    String? pairedIndoorSerial,
  }) {
    return PosValidationLoaded(
      currentStep: currentStep ?? this.currentStep,
      unitType: unitType ?? this.unitType,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      measurementsAfter: measurementsAfter ?? this.measurementsAfter,
      availableIndoorSerials: availableIndoorSerials ?? this.availableIndoorSerials,
      pairedIndoorSerial: pairedIndoorSerial ?? this.pairedIndoorSerial,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    unitType,
    photosBefore,
    photosAfter,
    measurementsAfter,
    availableIndoorSerials,
    pairedIndoorSerial,
  ];
}

class PosValidationError extends PosValidationState {
  final String message;
  const PosValidationError(this.message);
}

class PosValidationSaveFailure extends PosValidationState {
  final String message;
  final PosValidationLoaded lastState;

  const PosValidationSaveFailure(this.message, this.lastState);

  @override
  List<Object> get props => [message, lastState];
}

class PosValidationSaveSuccess extends PosValidationState {}