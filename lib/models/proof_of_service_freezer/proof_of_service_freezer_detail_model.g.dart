// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_service_freezer_detail_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofOfServiceFreezerDetailModelAdapter
    extends TypeAdapter<ProofOfServiceFreezerDetailModel> {
  @override
  final int typeId = 150;

  @override
  ProofOfServiceFreezerDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceFreezerDetailModel(
      header: fields[0] as ProofOfServiceFreezerHeader?,
      items: (fields[1] as List).cast<ProofOfServiceFreezerItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerDetailModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.header)
      ..writeByte(1)
      ..write(obj.items);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceFreezerDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProofOfServiceFreezerHeaderAdapter
    extends TypeAdapter<ProofOfServiceFreezerHeader> {
  @override
  final int typeId = 151;

  @override
  ProofOfServiceFreezerHeader read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceFreezerHeader(
      transNo: fields[0] as String,
      poDate: fields[1] as String,
      shipTo: fields[2] as String,
      shipToName: fields[3] as String,
      shipToAddress: fields[4] as String,
      shipToMail: fields[5] as String,
      branchCode: fields[6] as String,
      branchName: fields[7] as String,
      latitude: fields[8] as double,
      longitude: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerHeader obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.poDate)
      ..writeByte(2)
      ..write(obj.shipTo)
      ..writeByte(3)
      ..write(obj.shipToName)
      ..writeByte(4)
      ..write(obj.shipToAddress)
      ..writeByte(5)
      ..write(obj.shipToMail)
      ..writeByte(6)
      ..write(obj.branchCode)
      ..writeByte(7)
      ..write(obj.branchName)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceFreezerHeaderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProofOfServiceFreezerItemAdapter
    extends TypeAdapter<ProofOfServiceFreezerItem> {
  @override
  final int typeId = 152;

  @override
  ProofOfServiceFreezerItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceFreezerItem(
      serialNo: fields[0] as String,
      articleNo: fields[1] as String,
      articleDesc: fields[2] as String,
      unitDesc: fields[3] as String,
      lineNo: fields[4] as int,
      isGeneric: fields[5] as bool,
      unitIndex: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceFreezerItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.serialNo)
      ..writeByte(1)
      ..write(obj.articleNo)
      ..writeByte(2)
      ..write(obj.articleDesc)
      ..writeByte(3)
      ..write(obj.unitDesc)
      ..writeByte(4)
      ..write(obj.lineNo)
      ..writeByte(5)
      ..write(obj.isGeneric)
      ..writeByte(6)
      ..write(obj.unitIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceFreezerItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
