// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementEntryAdapter extends TypeAdapter<MeasurementEntry> {
  @override
  final int typeId = 3;

  @override
  MeasurementEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementEntry(
      measurementId: fields[0] as String,
      value: fields[1] as double,
      unit: fields[2] as String,
      capturedImage: fields[3] as CapturedImageDetail?,
      isSkipped: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.measurementId)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.capturedImage)
      ..writeByte(4)
      ..write(obj.isSkipped);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
