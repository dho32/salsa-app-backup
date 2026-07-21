// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_service_freezer_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofOfServiceFreezerEntryModelAdapter
    extends TypeAdapter<ProofOfServiceFreezerEntryModel> {
  @override
  final int typeId = 154;

  @override
  ProofOfServiceFreezerEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceFreezerEntryModel(
      transNo: fields[0] as String,
      serialNo: fields[1] as String,
      isGeneric: fields[2] as bool,
      unitIndex: fields[3] as int,
      articleNo: fields[4] as String,
      articleDesc: fields[5] as String,
      isCompleted: fields[6] as bool,
      arrivalTemp: fields[7] as double?,
      arrivalTempImage: fields[8] as CapturedImageDetail?,
      arrivalTempSkipped: fields[19] as bool,
      arrivalTempReason: fields[20] as String?,
      generalCondition: fields[9] as String?,
      frostThickness: fields[10] as String?,
      initialPhotos: (fields[11] as Map?)?.cast<String, CapturedImageDetail>(),
      initialNote: fields[12] as String?,
      complaint: fields[18] as String?,
      conditionNote: fields[27] as String?,
      conditionPhotos: (fields[28] as List?)?.cast<CapturedImageDetail>(),
      measurements: (fields[16] as List?)?.cast<MeasurementEntry>(),
      afterPhotos: (fields[17] as Map?)?.cast<String, CapturedImageDetail>(),
      arrivalTempSkipRemark: fields[21] as String?,
      arrivalTempSkipPhotos: (fields[22] as List?)?.cast<CapturedImageDetail>(),
      tempSkipRemark: fields[23] as String?,
      tempSkipPhotos: (fields[24] as List?)?.cast<CapturedImageDetail>(),
      elecSkipRemark: fields[25] as String?,
      elecSkipPhotos: (fields[26] as List?)?.cast<CapturedImageDetail>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerEntryModel obj) {
    writer
      ..writeByte(26)
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
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.arrivalTemp)
      ..writeByte(8)
      ..write(obj.arrivalTempImage)
      ..writeByte(19)
      ..write(obj.arrivalTempSkipped)
      ..writeByte(20)
      ..write(obj.arrivalTempReason)
      ..writeByte(9)
      ..write(obj.generalCondition)
      ..writeByte(10)
      ..write(obj.frostThickness)
      ..writeByte(11)
      ..write(obj.initialPhotos)
      ..writeByte(12)
      ..write(obj.initialNote)
      ..writeByte(18)
      ..write(obj.complaint)
      ..writeByte(27)
      ..write(obj.conditionNote)
      ..writeByte(28)
      ..write(obj.conditionPhotos)
      ..writeByte(16)
      ..write(obj.measurements)
      ..writeByte(17)
      ..write(obj.afterPhotos)
      ..writeByte(21)
      ..write(obj.arrivalTempSkipRemark)
      ..writeByte(22)
      ..write(obj.arrivalTempSkipPhotos)
      ..writeByte(23)
      ..write(obj.tempSkipRemark)
      ..writeByte(24)
      ..write(obj.tempSkipPhotos)
      ..writeByte(25)
      ..write(obj.elecSkipRemark)
      ..writeByte(26)
      ..write(obj.elecSkipPhotos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceFreezerEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
