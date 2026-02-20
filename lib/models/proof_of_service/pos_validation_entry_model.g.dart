// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_validation_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosValidationEntryModelAdapter
    extends TypeAdapter<PosValidationEntryModel> {
  @override
  final int typeId = 8;

  @override
  PosValidationEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosValidationEntryModel(
      transNo: fields[0] as String,
      serialNo: fields[1] as String,
      photosBefore: (fields[2] as List).cast<CapturedImageDetail>(),
      photosAfter: (fields[3] as List).cast<CapturedImageDetail>(),
      measurementsAfter: (fields[4] as List).cast<MeasurementEntry>(),
      isCompleted: fields[5] as bool?,
      note: fields[6] as String?,
      articleNo: fields[7] as String?,
      articleDesc: fields[8] as String?,
      articleUnitDesc: fields[9] as String?,
      capacity: fields[10] as int?,
      articleType: fields[11] as String?,
      pairedSerialNo: fields[12] as String?,
      noteRemark: fields[13] as String?,
      remarkPhotos: (fields[14] as List?)?.cast<CapturedImageDetail>(),
      reffLineNo: fields[15] as String?,
      isGeneric: fields[16] as bool?,
      unitIndex: fields[17] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PosValidationEntryModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.serialNo)
      ..writeByte(2)
      ..write(obj.photosBefore)
      ..writeByte(3)
      ..write(obj.photosAfter)
      ..writeByte(4)
      ..write(obj.measurementsAfter)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.articleNo)
      ..writeByte(8)
      ..write(obj.articleDesc)
      ..writeByte(9)
      ..write(obj.articleUnitDesc)
      ..writeByte(10)
      ..write(obj.capacity)
      ..writeByte(11)
      ..write(obj.articleType)
      ..writeByte(12)
      ..write(obj.pairedSerialNo)
      ..writeByte(13)
      ..write(obj.noteRemark)
      ..writeByte(14)
      ..write(obj.remarkPhotos)
      ..writeByte(15)
      ..write(obj.reffLineNo)
      ..writeByte(16)
      ..write(obj.isGeneric)
      ..writeByte(17)
      ..write(obj.unitIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosValidationEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
