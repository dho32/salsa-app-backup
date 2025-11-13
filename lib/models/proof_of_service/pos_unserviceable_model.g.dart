// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_unserviceable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosUnserviceableModelAdapter extends TypeAdapter<PosUnserviceableModel> {
  @override
  final int typeId = 13;

  @override
  PosUnserviceableModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosUnserviceableModel(
      transNo: fields[0] as String,
      reason: fields[1] as String,
      notes: fields[2] as String?,
      proofImages: (fields[3] as List).cast<CapturedImageDetail>(),
      reportedAt: fields[4] as DateTime,
      reportedBy: fields[5] as String,
      reportedById: fields[6] as String,
      technicianName: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PosUnserviceableModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.reason)
      ..writeByte(2)
      ..write(obj.notes)
      ..writeByte(3)
      ..write(obj.proofImages)
      ..writeByte(4)
      ..write(obj.reportedAt)
      ..writeByte(5)
      ..write(obj.reportedBy)
      ..writeByte(6)
      ..write(obj.reportedById)
      ..writeByte(7)
      ..write(obj.technicianName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosUnserviceableModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
