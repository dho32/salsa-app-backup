// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scf_validation_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScfValidationEntryModelAdapter
    extends TypeAdapter<ScfValidationEntryModel> {
  @override
  final int typeId = 156;

  @override
  ScfValidationEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScfValidationEntryModel(
      transNo: fields[0] as String,
      serialNo: fields[1] as String,
      isGeneric: fields[2] as bool,
      unitIndex: fields[3] as int,
      articleNo: fields[4] as String,
      articleDesc: fields[5] as String,
      unitType: fields[6] as String,
      isCompleted: fields[7] as bool,
      device: fields[8] as String?,
      arrivalTemp: fields[9] as double?,
      arrivalTempImage: fields[10] as CapturedImageDetail?,
      arrivalTempSkipped: fields[11] as bool,
      arrivalTempReason: fields[12] as String?,
      arrivalTempSkipRemark: fields[13] as String?,
      arrivalTempSkipPhotos: (fields[14] as List?)?.cast<CapturedImageDetail>(),
      generalCondition: fields[15] as String?,
      complaint: fields[16] as String?,
      conditionNote: fields[17] as String?,
      conditionPhotos: (fields[18] as List?)?.cast<CapturedImageDetail>(),
      frostThickness: fields[19] as String?,
      initialPhotos: (fields[20] as Map?)?.cast<String, CapturedImageDetail>(),
      initialNote: fields[21] as String?,
      measurementsBefore: (fields[22] as List?)?.cast<MeasurementEntry>(),
      measurementsAfter: (fields[23] as List?)?.cast<MeasurementEntry>(),
      afterPhotos: (fields[24] as Map?)?.cast<String, CapturedImageDetail>(),
      selectedTempNoteBefore: fields[25] as String?,
      selectedElecNoteBefore: fields[26] as String?,
      selectedTempNoteAfter: fields[27] as String?,
      selectedElecNoteAfter: fields[28] as String?,
      tempSkipRemarkBefore: fields[29] as String?,
      tempSkipPhotosBefore: (fields[30] as List?)?.cast<CapturedImageDetail>(),
      elecSkipRemarkBefore: fields[31] as String?,
      elecSkipPhotosBefore: (fields[32] as List?)?.cast<CapturedImageDetail>(),
      tempSkipRemarkAfter: fields[33] as String?,
      tempSkipPhotosAfter: (fields[34] as List?)?.cast<CapturedImageDetail>(),
      elecSkipRemarkAfter: fields[35] as String?,
      elecSkipPhotosAfter: (fields[36] as List?)?.cast<CapturedImageDetail>(),
      problems: (fields[37] as List?)?.cast<ScfValidationProblem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScfValidationEntryModel obj) {
    writer
      ..writeByte(38)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.serialNo)
      ..writeByte(2)
      ..write(obj.isGeneric)
      ..writeByte(3)
      ..write(obj.unitIndex)
      ..writeByte(4)
      ..write(obj.articleNo)
      ..writeByte(5)
      ..write(obj.articleDesc)
      ..writeByte(6)
      ..write(obj.unitType)
      ..writeByte(7)
      ..write(obj.isCompleted)
      ..writeByte(8)
      ..write(obj.device)
      ..writeByte(9)
      ..write(obj.arrivalTemp)
      ..writeByte(10)
      ..write(obj.arrivalTempImage)
      ..writeByte(11)
      ..write(obj.arrivalTempSkipped)
      ..writeByte(12)
      ..write(obj.arrivalTempReason)
      ..writeByte(13)
      ..write(obj.arrivalTempSkipRemark)
      ..writeByte(14)
      ..write(obj.arrivalTempSkipPhotos)
      ..writeByte(15)
      ..write(obj.generalCondition)
      ..writeByte(16)
      ..write(obj.complaint)
      ..writeByte(17)
      ..write(obj.conditionNote)
      ..writeByte(18)
      ..write(obj.conditionPhotos)
      ..writeByte(19)
      ..write(obj.frostThickness)
      ..writeByte(20)
      ..write(obj.initialPhotos)
      ..writeByte(21)
      ..write(obj.initialNote)
      ..writeByte(22)
      ..write(obj.measurementsBefore)
      ..writeByte(23)
      ..write(obj.measurementsAfter)
      ..writeByte(24)
      ..write(obj.afterPhotos)
      ..writeByte(25)
      ..write(obj.selectedTempNoteBefore)
      ..writeByte(26)
      ..write(obj.selectedElecNoteBefore)
      ..writeByte(27)
      ..write(obj.selectedTempNoteAfter)
      ..writeByte(28)
      ..write(obj.selectedElecNoteAfter)
      ..writeByte(29)
      ..write(obj.tempSkipRemarkBefore)
      ..writeByte(30)
      ..write(obj.tempSkipPhotosBefore)
      ..writeByte(31)
      ..write(obj.elecSkipRemarkBefore)
      ..writeByte(32)
      ..write(obj.elecSkipPhotosBefore)
      ..writeByte(33)
      ..write(obj.tempSkipRemarkAfter)
      ..writeByte(34)
      ..write(obj.tempSkipPhotosAfter)
      ..writeByte(35)
      ..write(obj.elecSkipRemarkAfter)
      ..writeByte(36)
      ..write(obj.elecSkipPhotosAfter)
      ..writeByte(37)
      ..write(obj.problems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScfValidationEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScfValidationProblemAdapter extends TypeAdapter<ScfValidationProblem> {
  @override
  final int typeId = 157;

  @override
  ScfValidationProblem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScfValidationProblem(
      problemId: fields[0] as String,
      solutionIds: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScfValidationProblem obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.problemId)
      ..writeByte(1)
      ..write(obj.solutionIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScfValidationProblemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
