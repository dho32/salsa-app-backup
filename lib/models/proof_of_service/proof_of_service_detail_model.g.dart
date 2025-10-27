// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proof_of_service_detail_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProofOfServiceDetailModelAdapter
    extends TypeAdapter<ProofOfServiceDetailModel> {
  @override
  final int typeId = 10;

  @override
  ProofOfServiceDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceDetailModel(
      header: fields[0] as ProofOfServiceHeader,
      detail: (fields[1] as List).cast<ProofOfServiceItemDetail>(),
      noteIndoorOptions: (fields[2] as List?)?.cast<String>(),
      noteOutdoorOptions: (fields[3] as List?)?.cast<String>(),
      unserviceableReasons: (fields[4] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceDetailModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.header)
      ..writeByte(1)
      ..write(obj.detail)
      ..writeByte(2)
      ..write(obj.noteIndoorOptions)
      ..writeByte(3)
      ..write(obj.noteOutdoorOptions)
      ..writeByte(4)
      ..write(obj.unserviceableReasons);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProofOfServiceHeaderAdapter extends TypeAdapter<ProofOfServiceHeader> {
  @override
  final int typeId = 11;

  @override
  ProofOfServiceHeader read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceHeader(
      transNo: fields[0] as String,
      poDate: fields[1] as String,
      shipToCode: fields[2] as String,
      shipToName: fields[3] as String,
      shipToAddress: fields[4] as String,
      branchCode: fields[5] as String,
      branchName: fields[6] as String,
      storeEmail: fields[7] as String,
      latitude: fields[8] as String,
      longitude: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceHeader obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.poDate)
      ..writeByte(2)
      ..write(obj.shipToCode)
      ..writeByte(3)
      ..write(obj.shipToName)
      ..writeByte(4)
      ..write(obj.shipToAddress)
      ..writeByte(5)
      ..write(obj.branchCode)
      ..writeByte(6)
      ..write(obj.branchName)
      ..writeByte(7)
      ..write(obj.storeEmail)
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
      other is ProofOfServiceHeaderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProofOfServiceItemDetailAdapter
    extends TypeAdapter<ProofOfServiceItemDetail> {
  @override
  final int typeId = 12;

  @override
  ProofOfServiceItemDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProofOfServiceItemDetail(
      articleNo: fields[0] as String,
      articleDesc: fields[1] as String,
      unitDesc: fields[2] as String,
      serialNo: fields[3] as String,
      unitType: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ProofOfServiceItemDetail obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.articleNo)
      ..writeByte(1)
      ..write(obj.articleDesc)
      ..writeByte(2)
      ..write(obj.unitDesc)
      ..writeByte(3)
      ..write(obj.serialNo)
      ..writeByte(4)
      ..write(obj.unitType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProofOfServiceItemDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
