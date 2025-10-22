// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sc_unserviceable_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SCUnserviceableModelAdapter extends TypeAdapter<SCUnserviceableModel> {
  @override
  final int typeId = 14;

  @override
  SCUnserviceableModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SCUnserviceableModel(
      transNo: fields[0] as String,
      pathAttachment: fields[1] as String,
      reason: fields[2] as String,
      notes: fields[3] as String?,
      proofImages: (fields[4] as List).cast<CapturedImageDetail>(),
      reportedAt: fields[5] as DateTime,
      reportedBy: fields[6] as String,
      reportedById: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SCUnserviceableModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.pathAttachment)
      ..writeByte(2)
      ..write(obj.reason)
      ..writeByte(3)
      ..write(obj.notes)
      ..writeByte(4)
      ..write(obj.proofImages)
      ..writeByte(5)
      ..write(obj.reportedAt)
      ..writeByte(6)
      ..write(obj.reportedBy)
      ..writeByte(7)
      ..write(obj.reportedById);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SCUnserviceableModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
