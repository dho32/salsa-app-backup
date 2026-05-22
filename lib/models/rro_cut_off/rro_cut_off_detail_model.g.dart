// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rro_cut_off_detail_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RROCutOffResultAdapter extends TypeAdapter<RROCutOffResult> {
  @override
  final int typeId = 220;

  @override
  RROCutOffResult read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffResult(
      header: fields[0] as RROCutOffHeader?,
      detail: (fields[1] as List).cast<RROCutOffDetailItem>(),
      serialNumber: (fields[2] as List).cast<RROCutOffSerialNumber>(),
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffResult obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.header)
      ..writeByte(1)
      ..write(obj.detail)
      ..writeByte(2)
      ..write(obj.serialNumber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffResultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RROCutOffHeaderAdapter extends TypeAdapter<RROCutOffHeader> {
  @override
  final int typeId = 221;

  @override
  RROCutOffHeader read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffHeader(
      transNo: fields[0] as String,
      rroType: fields[1] as String,
      poCustNo: fields[2] as String,
      estimatedRroCutOffDate: fields[3] as String,
      branchName: fields[4] as String,
      shipTo: fields[5] as String,
      shipToName: fields[6] as String,
      shipToAddress: fields[7] as String,
      shipToMail: fields[8] as String,
      latitude: fields[9] as double,
      longitude: fields[10] as double,
      isPic: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffHeader obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.rroType)
      ..writeByte(2)
      ..write(obj.poCustNo)
      ..writeByte(3)
      ..write(obj.estimatedRroCutOffDate)
      ..writeByte(4)
      ..write(obj.branchName)
      ..writeByte(5)
      ..write(obj.shipTo)
      ..writeByte(6)
      ..write(obj.shipToName)
      ..writeByte(7)
      ..write(obj.shipToAddress)
      ..writeByte(8)
      ..write(obj.shipToMail)
      ..writeByte(9)
      ..write(obj.latitude)
      ..writeByte(10)
      ..write(obj.longitude)
      ..writeByte(11)
      ..write(obj.isPic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffHeaderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RROCutOffDetailItemAdapter extends TypeAdapter<RROCutOffDetailItem> {
  @override
  final int typeId = 222;

  @override
  RROCutOffDetailItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffDetailItem(
      rroArticleNo: fields[0] as String,
      articleNameUnit: fields[1] as String,
      unitType: fields[2] as String,
      unitIndex: fields[3] as int,
      lineNo: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffDetailItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.rroArticleNo)
      ..writeByte(1)
      ..write(obj.articleNameUnit)
      ..writeByte(2)
      ..write(obj.unitType)
      ..writeByte(3)
      ..write(obj.unitIndex)
      ..writeByte(4)
      ..write(obj.lineNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffDetailItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RROCutOffSerialNumberAdapter extends TypeAdapter<RROCutOffSerialNumber> {
  @override
  final int typeId = 223;

  @override
  RROCutOffSerialNumber read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffSerialNumber(
      rroArticleNo: fields[0] as String,
      unitType: fields[1] as String,
      serialNo: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffSerialNumber obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.rroArticleNo)
      ..writeByte(1)
      ..write(obj.unitType)
      ..writeByte(2)
      ..write(obj.serialNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffSerialNumberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
