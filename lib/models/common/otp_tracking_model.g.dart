// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_tracking_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OtpTrackingModelAdapter extends TypeAdapter<OtpTrackingModel> {
  @override
  final int typeId = 113;

  @override
  OtpTrackingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OtpTrackingModel(
      transNo: fields[0] as String,
      retryCount: fields[1] as int,
      lastRequestTime: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OtpTrackingModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.retryCount)
      ..writeByte(2)
      ..write(obj.lastRequestTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OtpTrackingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
