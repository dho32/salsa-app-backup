import 'package:equatable/equatable.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/proof_of_service/pos_validation_entry_model.dart';

abstract class PosValidationEvent extends Equatable {
  const PosValidationEvent();

  @override
  List<Object?> get props => [];
}

class FetchPosValidationData extends PosValidationEvent {
  final PosValidationEntryModel? initialData;
  final String unitType;
  final String articleNo;
  final String articleDesc;
  final String articleUnitDesc;
  final String transNo;
  final String serialNo;
  final List<String> allIndoorSerials;

  // 🔥 GENERIC SUPPORT
  final bool isGeneric;
  final int unitIndex;

  const FetchPosValidationData({
    this.initialData,
    required this.unitType,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.transNo,
    required this.serialNo,
    required this.allIndoorSerials,
    this.isGeneric = false, // Default false (Existing)
    this.unitIndex = 0,
  });

  @override
  List<Object?> get props => [
    transNo, serialNo, unitType,
    articleNo, articleDesc, articleUnitDesc,
    initialData, allIndoorSerials,
    isGeneric, unitIndex // 🔥
  ];
}

// 🔥 EVENT BARU: Update Input Serial (Saat user ketik/scan)
class UpdateInputSerial extends PosValidationEvent {
  final String newSerial;

  const UpdateInputSerial(this.newSerial);

  @override
  List<Object?> get props => [newSerial];
}

class ChangePosValidationStep extends PosValidationEvent {
  final int step;

  const ChangePosValidationStep(this.step);

  @override
  List<Object?> get props => [step];
}

class AddPhotoBefore extends PosValidationEvent {
  final CapturedImageDetail imageDetail;

  const AddPhotoBefore(this.imageDetail);

  @override
  List<Object?> get props => [imageDetail];
}

class RemovePhotoBefore extends PosValidationEvent {
  final String imagePath;

  const RemovePhotoBefore(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class AddPhotoAfter extends PosValidationEvent {
  final CapturedImageDetail imageDetail;

  const AddPhotoAfter(this.imageDetail);

  @override
  List<Object?> get props => [imageDetail];
}

class RemovePhotoAfter extends PosValidationEvent {
  final String imagePath;

  const RemovePhotoAfter(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class UpdateMeasurementAfter extends PosValidationEvent {
  final MeasurementEntry measurement;

  const UpdateMeasurementAfter(this.measurement);

  @override
  List<Object?> get props => [measurement];
}

class SavePosValidationData extends PosValidationEvent {
  final String transNo;
  final String serialNo;
  final bool markAsCompleted;
  final String note;
  final String articleNo;
  final String articleDesc;
  final String articleUnitDesc;
  final int capacity;
  final String articleType;
  final double? indoorTemp;

  // 🔥 GENERIC SUPPORT
  final bool isGeneric;
  final int unitIndex;

  const SavePosValidationData({
    required this.transNo,
    required this.serialNo,
    this.markAsCompleted = false,
    required this.note,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.capacity,
    required this.articleType,
    this.indoorTemp,
    this.isGeneric = false, // 🔥
    this.unitIndex = 0,     // 🔥
  });

  @override
  List<Object?> get props => [
    transNo,
    serialNo,
    markAsCompleted,
    note,
    articleNo,
    articleDesc,
    articleUnitDesc,
    capacity,
    articleType,
    indoorTemp,
    isGeneric, // 🔥
    unitIndex  // 🔥
  ];
}

class MarkAsInProgress extends PosValidationEvent {
  final String transNo;
  final String serialNo;
  final String note;
  final String articleNo;
  final String articleDesc;
  final String articleUnitDesc;
  final int capacity;
  final String articleType;

  // 🔥 GENERIC SUPPORT
  final bool isGeneric;
  final int unitIndex;

  const MarkAsInProgress({
    required this.transNo,
    required this.serialNo,
    required this.note,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.capacity,
    required this.articleType,
    this.isGeneric = false, // 🔥
    this.unitIndex = 0,     // 🔥
  });

  @override
  List<Object?> get props => [
    transNo, serialNo, note, articleNo, articleDesc,
    articleUnitDesc, capacity, articleType,
    isGeneric, unitIndex // 🔥
  ];
}

class PairOutdoorWithIndoor extends PosValidationEvent {
  final String outdoorSerialNo;
  final String? indoorSerialNo;

  const PairOutdoorWithIndoor({
    required this.outdoorSerialNo,
    required this.indoorSerialNo,
  });

  @override
  List<Object?> get props => [outdoorSerialNo, indoorSerialNo];
}

class ProceedToNextStep extends PosValidationEvent {
  const ProceedToNextStep();

  @override
  List<Object> get props => [];
}

class UpdateNoteAfter extends PosValidationEvent {
  final String note;

  const UpdateNoteAfter(this.note);

  @override
  List<Object?> get props => [note];
}

class UpdateNoteRemark extends PosValidationEvent {
  final String remark;

  const UpdateNoteRemark(this.remark);

  @override
  List<Object> get props => [remark];
}

class AddRemarkPhoto extends PosValidationEvent {
  final CapturedImageDetail imageDetail;

  const AddRemarkPhoto(this.imageDetail);

  @override
  List<Object?> get props => [imageDetail];
}

class RemoveRemarkPhoto extends PosValidationEvent {
  final String imagePath;

  const RemoveRemarkPhoto(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}