// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_call_validation_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceCallValidationEntryModelAdapter
    extends TypeAdapter<ServiceCallValidationEntryModel> {
  @override
  final int typeId = 0;

  @override
  ServiceCallValidationEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceCallValidationEntryModel(
      unitType: fields[0] as String,
      serialNo: fields[1] as String,
      imagePathsBefore: (fields[2] as List).cast<CapturedImageDetail>(),
      measurementsBefore: (fields[3] as List).cast<MeasurementEntry>(),
      problems: (fields[4] as List).cast<ValidationProblem>(),
      imagePathsAfter: (fields[5] as List).cast<CapturedImageDetail>(),
      measurementsAfter: (fields[6] as List).cast<MeasurementEntry>(),
      transNo: fields[7] as String,
      isCompleted: fields[8] as bool,
      outdoorSerialNo: fields[9] as String?,
      device: fields[10] as String?,
      selectedIndoorNoteBefore: fields[11] as String?,
      selectedOutdoorNoteBefore: fields[12] as String?,
      selectedIndoorNoteAfter: fields[13] as String?,
      selectedOutdoorNoteAfter: fields[14] as String?,
      selectedOutdoorPSINoteBefore: fields[15] as String?,
      selectedOutdoorPSINoteAfter: fields[16] as String?,
      correctSerialNo: fields[17] as String?,
      noteRemarkIndoor: fields[18] as String?,
      noteRemarkOutdoor: fields[19] as String?,
      noteRemarkPSI: fields[20] as String?,
      noteRemark: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceCallValidationEntryModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.unitType)
      ..writeByte(1)
      ..write(obj.serialNo)
      ..writeByte(2)
      ..write(obj.imagePathsBefore)
      ..writeByte(3)
      ..write(obj.measurementsBefore)
      ..writeByte(4)
      ..write(obj.problems)
      ..writeByte(5)
      ..write(obj.imagePathsAfter)
      ..writeByte(6)
      ..write(obj.measurementsAfter)
      ..writeByte(7)
      ..write(obj.transNo)
      ..writeByte(8)
      ..write(obj.isCompleted)
      ..writeByte(9)
      ..write(obj.outdoorSerialNo)
      ..writeByte(10)
      ..write(obj.device)
      ..writeByte(11)
      ..write(obj.selectedIndoorNoteBefore)
      ..writeByte(12)
      ..write(obj.selectedOutdoorNoteBefore)
      ..writeByte(13)
      ..write(obj.selectedIndoorNoteAfter)
      ..writeByte(14)
      ..write(obj.selectedOutdoorNoteAfter)
      ..writeByte(15)
      ..write(obj.selectedOutdoorPSINoteBefore)
      ..writeByte(16)
      ..write(obj.selectedOutdoorPSINoteAfter)
      ..writeByte(17)
      ..write(obj.correctSerialNo)
      ..writeByte(18)
      ..write(obj.noteRemarkIndoor)
      ..writeByte(19)
      ..write(obj.noteRemarkOutdoor)
      ..writeByte(20)
      ..write(obj.noteRemarkPSI)
      ..writeByte(21)
      ..write(obj.noteRemark);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCallValidationEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ValidationProblemAdapter extends TypeAdapter<ValidationProblem> {
  @override
  final int typeId = 1;

  @override
  ValidationProblem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ValidationProblem(
      problemId: fields[0] as String,
      solutionIds: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ValidationProblem obj) {
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
      other is ValidationProblemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
