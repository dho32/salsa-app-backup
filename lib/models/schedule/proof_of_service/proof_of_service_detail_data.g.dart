// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_service_detail_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofOfServiceDetailDataAdapter
    extends TypeAdapter<ProofOfServiceDetailData> {
  @override
  final int typeId = 4;

  @override
  ProofOfServiceDetailData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceDetailData(
      note: fields[0] as String,
      imagePaths: (fields[1] as List).cast<String>(),
      volt: fields[2] as String,
      ampere: fields[3] as String,
      psi: fields[4] as String,
      temperature: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceDetailData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.note)
      ..writeByte(1)
      ..write(obj.imagePaths)
      ..writeByte(2)
      ..write(obj.volt)
      ..writeByte(3)
      ..write(obj.ampere)
      ..writeByte(4)
      ..write(obj.psi)
      ..writeByte(5)
      ..write(obj.temperature);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceDetailDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
