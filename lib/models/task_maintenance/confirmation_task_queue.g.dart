// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirmation_task_queue.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfirmationTaskModelAdapter extends TypeAdapter<ConfirmationTaskModel> {
  @override
  final int typeId = 6;

  @override
  ConfirmationTaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConfirmationTaskModel(
      transNo: fields[0] as String,
      retryCount: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConfirmationTaskModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfirmationTaskModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
