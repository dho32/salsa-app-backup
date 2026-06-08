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
      generalCondition: fields[9] as String?,
      frostThickness: fields[10] as String?,
      initialPhotos: (fields[11] as Map?)?.cast<String, CapturedImageDetail>(),
      initialNote: fields[12] as String?,
      cleaningChecklist: (fields[13] as List?)?.cast<bool>(),
      cleaningProduct: fields[14] as String?,
      statusFlags: (fields[15] as Map?)?.cast<String, String>(),
      measurements: (fields[16] as List?)?.cast<MeasurementEntry>(),
      afterPhotos: (fields[17] as Map?)?.cast<String, CapturedImageDetail>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerEntryModel obj) {
    writer
      ..writeByte(18)
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
      ..writeByte(9)
      ..write(obj.generalCondition)
      ..writeByte(10)
      ..write(obj.frostThickness)
      ..writeByte(11)
      ..write(obj.initialPhotos)
      ..writeByte(12)
      ..write(obj.initialNote)
      ..writeByte(13)
      ..write(obj.cleaningChecklist)
      ..writeByte(14)
      ..write(obj.cleaningProduct)
      ..writeByte(15)
      ..write(obj.statusFlags)
      ..writeByte(16)
      ..write(obj.measurements)
      ..writeByte(17)
      ..write(obj.afterPhotos);
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
