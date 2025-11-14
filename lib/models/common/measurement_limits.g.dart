// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_limits.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeasurementLimitsAdapter extends TypeAdapter<MeasurementLimits> {
  @override
  final int typeId = 15;

  @override
  MeasurementLimits read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementLimits(
      id: fields[0] as String,
      label: fields[1] as String,
      min: fields[2] as double,
      max: fields[3] as double,
      unit: fields[4] as String,
      normalMin: fields[5] as double,
      normalMax: fields[6] as double,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementLimits obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.min)
      ..writeByte(3)
      ..write(obj.max)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.normalMin)
      ..writeByte(6)
      ..write(obj.normalMax);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementLimitsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
