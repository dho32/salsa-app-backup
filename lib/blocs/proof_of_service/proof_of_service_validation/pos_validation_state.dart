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
  final String transNo;
  final String serialNo;
  final String articleNo;
  final String articleDesc;
  final String articleUnitDesc;
  final List<CapturedImageDetail> photosBefore;
  final List<CapturedImageDetail> photosAfter;
  final List<MeasurementEntry> measurementsAfter;
  final List<String> availableIndoorSerials;
  final String? pairedIndoorSerial;
  final String? note;
  final String? noteRemark;

  const PosValidationLoaded({
    this.currentStep = 0,
    required this.unitType,
    required this.transNo,
    required this.serialNo,
    this.articleNo = '',
    this.articleDesc = '',
    this.articleUnitDesc = '',
    this.photosBefore = const [],
    this.photosAfter = const [],
    this.measurementsAfter = const [],
    this.availableIndoorSerials = const [],
    this.pairedIndoorSerial,
    this.note,
    this.noteRemark,
  });

  PosValidationLoaded copyWith({
    int? currentStep,
    String? unitType,
    String? transNo,
    String? serialNo,
    String? articleNo,
    String? articleDesc,
    String? articleUnitDesc,
    List<CapturedImageDetail>? photosBefore,
    List<CapturedImageDetail>? photosAfter,
    List<MeasurementEntry>? measurementsAfter,
    List<String>? availableIndoorSerials,
    String? pairedIndoorSerial,
    String? note,
    String? noteRemark,
  }) {
    return PosValidationLoaded(
      currentStep: currentStep ?? this.currentStep,
      unitType: unitType ?? this.unitType,
      transNo: transNo ?? this.transNo,
      serialNo: serialNo ?? this.serialNo,
      articleNo: articleNo ?? this.articleNo,
      articleDesc: articleDesc ?? this.articleDesc,
      articleUnitDesc: articleUnitDesc ?? this.articleUnitDesc,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      measurementsAfter: measurementsAfter ?? this.measurementsAfter,
      availableIndoorSerials:
          availableIndoorSerials ?? this.availableIndoorSerials,
      pairedIndoorSerial: pairedIndoorSerial ?? this.pairedIndoorSerial,
      note: note ?? this.note,
      noteRemark: noteRemark ?? this.noteRemark,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        unitType,
        transNo,
        serialNo,
        articleNo,
        articleDesc,
        articleUnitDesc,
        photosBefore,
        photosAfter,
        measurementsAfter,
        availableIndoorSerials,
        pairedIndoorSerial,
        note,
        noteRemark,
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
