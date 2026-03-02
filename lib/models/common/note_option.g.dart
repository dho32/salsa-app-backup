// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_option.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NoteOptionAdapter extends TypeAdapter<NoteOption> {
  @override
  final int typeId = 102;

  @override
  NoteOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteOption(
      label: fields[0] as String,
      requireRemark: fields[1] as bool,
      isSystemOnly: fields[2] as bool,
      excludeQty: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NoteOption obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.requireRemark)
      ..writeByte(2)
      ..write(obj.isSystemOnly)
      ..writeByte(3)
      ..write(obj.excludeQty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
