// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installation_detail_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallationHeaderDetailModelAdapter
    extends TypeAdapter<InstallationHeaderDetailModel> {
  @override
  final int typeId = 210;

  @override
  InstallationHeaderDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationHeaderDetailModel(
      transNo: fields[0] == null ? '' : fields[0] as String,
      roType: fields[1] == null ? '' : fields[1] as String,
      poCustNo: fields[2] == null ? '' : fields[2] as String,
      roPostedDate: fields[3] == null ? '' : fields[3] as String,
      estimatedDate: fields[4] == null ? '' : fields[4] as String,
      branchName: fields[5] == null ? '' : fields[5] as String,
      shipToName: fields[6] == null ? '' : fields[6] as String,
      shipToAddress: fields[7] == null ? '' : fields[7] as String,
      latitude: fields[8] == null ? 0.0 : fields[8] as double,
      longitude: fields[9] == null ? 0.0 : fields[9] as double,
      isPic: fields[10] == null ? true : fields[10] as bool,
      shipTo: fields[11] == null ? '' : fields[11] as String,
      shipToMail: fields[12] == null ? '' : fields[12] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationHeaderDetailModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.roType)
      ..writeByte(2)
      ..write(obj.poCustNo)
      ..writeByte(3)
      ..write(obj.roPostedDate)
      ..writeByte(4)
      ..write(obj.estimatedDate)
      ..writeByte(5)
      ..write(obj.branchName)
      ..writeByte(6)
      ..write(obj.shipToName)
      ..writeByte(7)
      ..write(obj.shipToAddress)
      ..writeByte(8)
      ..write(obj.latitude)
      ..writeByte(9)
      ..write(obj.longitude)
      ..writeByte(10)
      ..write(obj.isPic)
      ..writeByte(11)
      ..write(obj.shipTo)
      ..writeByte(12)
      ..write(obj.shipToMail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationHeaderDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationTargetUnitModelAdapter
    extends TypeAdapter<InstallationTargetUnitModel> {
  @override
  final int typeId = 211;

  @override
  InstallationTargetUnitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationTargetUnitModel(
      articleNo: fields[0] == null ? '' : fields[0] as String,
      description: fields[1] == null ? '' : fields[1] as String,
      unitType: fields[2] == null ? '' : fields[2] as String,
      unitIndex: fields[3] == null ? 0 : fields[3] as int,
      reffLineNo: fields[4] == null ? '' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationTargetUnitModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.articleNo)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.unitType)
      ..writeByte(3)
      ..write(obj.unitIndex)
      ..writeByte(4)
      ..write(obj.reffLineNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationTargetUnitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationMasterOptionModelAdapter
    extends TypeAdapter<InstallationMasterOptionModel> {
  @override
  final int typeId = 212;

  @override
  InstallationMasterOptionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationMasterOptionModel(
      id: fields[0] as String,
      name: fields[1] as String,
      uom: fields[2] == null ? 'Meter' : fields[2] as String,
      brands: (fields[3] as List).cast<InstallationBrandModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, InstallationMasterOptionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.uom)
      ..writeByte(3)
      ..write(obj.brands);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationMasterOptionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationMasterDataModelAdapter
    extends TypeAdapter<InstallationMasterDataModel> {
  @override
  final int typeId = 213;

  @override
  InstallationMasterDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationMasterDataModel(
      pipes: (fields[0] as List).cast<InstallationMasterOptionModel>(),
      cables: (fields[1] as List).cast<InstallationMasterOptionModel>(),
      brands: (fields[2] as List).cast<InstallationMasterOptionModel>(),
      drains: (fields[3] as List).cast<InstallationMasterOptionModel>(),
      ducts: (fields[4] as List).cast<InstallationMasterOptionModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, InstallationMasterDataModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.pipes)
      ..writeByte(1)
      ..write(obj.cables)
      ..writeByte(2)
      ..write(obj.brands)
      ..writeByte(3)
      ..write(obj.drains)
      ..writeByte(4)
      ..write(obj.ducts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationMasterDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationOptionItemModelAdapter
    extends TypeAdapter<InstallationOptionItemModel> {
  @override
  final int typeId = 214;

  @override
  InstallationOptionItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationOptionItemModel(
      label: fields[0] as String,
      requireRemark: fields[1] as bool,
      isSystemOnly: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationOptionItemModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.requireRemark)
      ..writeByte(2)
      ..write(obj.isSystemOnly);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationOptionItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationDetailModelAdapter
    extends TypeAdapter<InstallationDetailModel> {
  @override
  final int typeId = 215;

  @override
  InstallationDetailModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationDetailModel(
      header: fields[0] as InstallationHeaderDetailModel,
      targets: (fields[1] as List).cast<InstallationTargetUnitModel>(),
      masterMaterials: fields[2] as InstallationMasterDataModel,
      noteIndoorOptions:
          (fields[3] as List).cast<InstallationOptionItemModel>(),
      noteOutdoorOptions:
          (fields[4] as List).cast<InstallationOptionItemModel>(),
      noteOutdoorPSIOptions:
          (fields[5] as List).cast<InstallationOptionItemModel>(),
      customLimitsAfter: (fields[6] as Map?)?.cast<String, MeasurementLimits>(),
    );
  }

  @override
  void write(BinaryWriter writer, InstallationDetailModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.header)
      ..writeByte(1)
      ..write(obj.targets)
      ..writeByte(2)
      ..write(obj.masterMaterials)
      ..writeByte(3)
      ..write(obj.noteIndoorOptions)
      ..writeByte(4)
      ..write(obj.noteOutdoorOptions)
      ..writeByte(5)
      ..write(obj.noteOutdoorPSIOptions)
      ..writeByte(6)
      ..write(obj.customLimitsAfter);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationDetailModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationBrandModelAdapter
    extends TypeAdapter<InstallationBrandModel> {
  @override
  final int typeId = 216;

  @override
  InstallationBrandModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationBrandModel(
      id: fields[0] as String,
      name: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationBrandModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationBrandModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
