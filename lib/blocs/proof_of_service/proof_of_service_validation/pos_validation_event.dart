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
  const FetchPosValidationData({this.initialData, required this.unitType});
}

class ChangePosValidationStep extends PosValidationEvent {
  final int step;
  const ChangePosValidationStep(this.step);
}

class AddPhotoBefore extends PosValidationEvent {
  final CapturedImageDetail imageDetail;
  const AddPhotoBefore(this.imageDetail);
}

class RemovePhotoBefore extends PosValidationEvent {
  final String imagePath;
  const RemovePhotoBefore(this.imagePath);
}

class AddPhotoAfter extends PosValidationEvent {
  final CapturedImageDetail imageDetail;
  const AddPhotoAfter(this.imageDetail);
}

class RemovePhotoAfter extends PosValidationEvent {
  final String imagePath;
  const RemovePhotoAfter(this.imagePath);
}

class UpdateMeasurementAfter extends PosValidationEvent {
  final MeasurementEntry measurement;
  const UpdateMeasurementAfter(this.measurement);
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
    indoorTemp // <-- TAMBAHKAN DI PROPS
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

  const MarkAsInProgress({
    required this.transNo,
    required this.serialNo,
    required this.note,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.capacity,
    required this.articleType,
  });
}