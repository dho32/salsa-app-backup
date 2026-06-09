// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_service_freezer_info_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofOfServiceFreezerInfoModelAdapter
    extends TypeAdapter<ProofOfServiceFreezerInfoModel> {
  @override
  final int typeId = 153;

  @override
  ProofOfServiceFreezerInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceFreezerInfoModel(
      transNo: fields[0] as String,
      picName: fields[1] as String?,
      picNik: fields[2] as String?,
      picPosition: fields[3] as String?,
      picPhone: fields[4] as String?,
      picImageDetail: fields[5] as CapturedImageDetail?,
      technician1: fields[6] as String?,
      technician2: fields[7] as String?,
      technician3: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerInfoModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.picName)
      ..writeByte(2)
      ..write(obj.picNik)
      ..writeByte(3)
      ..write(obj.picPosition)
      ..writeByte(4)
      ..write(obj.picPhone)
      ..writeByte(5)
      ..write(obj.picImageDetail)
      ..writeByte(6)
      ..write(obj.technician1)
      ..writeByte(7)
      ..write(obj.technician2)
      ..writeByte(8)
      ..write(obj.technician3);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceFreezerInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
