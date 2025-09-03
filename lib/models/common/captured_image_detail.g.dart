// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'captured_image_detail.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CapturedImageDetailAdapter extends TypeAdapter<CapturedImageDetail> {
  @override
  final int typeId = 2;

  @override
  CapturedImageDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CapturedImageDetail(
      imagePath: fields[0] as String,
      timestamp: fields[1] as DateTime,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      address: fields[4] as String,
      technicianName: fields[5] as String,
      deviceModel: fields[6] as String,
      transNo: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CapturedImageDetail obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.technicianName)
      ..writeByte(6)
      ..write(obj.deviceModel)
      ..writeByte(7)
      ..write(obj.transNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapturedImageDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
