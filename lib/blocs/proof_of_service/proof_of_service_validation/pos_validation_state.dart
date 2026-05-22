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
  final String? originalSerialNo;
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
  final List<CapturedImageDetail>? remarkPhotos;

  // 🔥 FIELD BARU UNTUK GENERIC UNIT
  final bool isGeneric;
  final int unitIndex;

  // 🔥 FIELD BARU UNTUK EXCLUDE QTY FLAG
  final bool excludeQty;
  final String? reffLineNo;

  const PosValidationLoaded({
    this.currentStep = 0,
    required this.unitType,
    required this.transNo,
    required this.serialNo,
    this.originalSerialNo,
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
    this.remarkPhotos = const [],
    this.isGeneric = false, // Default False (Unit Sewa)
    this.unitIndex = 0,     // Default 0
    this.excludeQty = false, // 🔥 Default False
    this.reffLineNo,
  });

  PosValidationLoaded copyWith({
    int? currentStep,
    String? unitType,
    String? transNo,
    String? serialNo,
    String? originalSerialNo,
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
    List<CapturedImageDetail>? remarkPhotos,
    bool? isGeneric,
    int? unitIndex,
    bool? excludeQty, // 🔥
    String? reffLineNo,
  }) {
    return PosValidationLoaded(
      currentStep: currentStep ?? this.currentStep,
      unitType: unitType ?? this.unitType,
      transNo: transNo ?? this.transNo,
      serialNo: serialNo ?? this.serialNo,
      originalSerialNo: originalSerialNo ?? this.originalSerialNo,
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
      remarkPhotos: remarkPhotos ?? this.remarkPhotos,
      isGeneric: isGeneric ?? this.isGeneric,
      unitIndex: unitIndex ?? this.unitIndex,
      excludeQty: excludeQty ?? this.excludeQty, // 🔥
      reffLineNo: reffLineNo ?? this.reffLineNo,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    unitType,
    transNo,
    serialNo,
    originalSerialNo,
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
    remarkPhotos,
    isGeneric,
    unitIndex,
    excludeQty, // 🔥 Tambahkan ke props agar bloc mendeteksi perubahan state
    reffLineNo,
  ];
}

class PosValidationError extends PosValidationState {
  final String message;

  const PosValidationError(this.message);

  @override
  List<Object?> get props => [message];
}

class PosValidationSaveFailure extends PosValidationState {
  final String message;
  final PosValidationLoaded lastState;

  const PosValidationSaveFailure(this.message, this.lastState);

  @override
  List<Object> get props => [message, lastState];
}

class PosValidationSaveSuccess extends PosValidationState {}