// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstallationPhotoModelAdapter
    extends TypeAdapter<InstallationPhotoModel> {
  @override
  final int typeId = 200;

  @override
  InstallationPhotoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationPhotoModel(
      imagePath: fields[0] as String,
      imageFileName: fields[1] as String,
      timestamp: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      deviceModel: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationPhotoModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.imageFileName)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.deviceModel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationPhotoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationMeasurementModelAdapter
    extends TypeAdapter<InstallationMeasurementModel> {
  @override
  final int typeId = 201;

  @override
  InstallationMeasurementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationMeasurementModel(
      measurementId: fields[0] as String,
      value: fields[1] as double?,
      unit: fields[2] as String,
      photo: fields[3] as InstallationPhotoModel?,
      isSkipped: fields[4] as bool,
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationMeasurementModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.measurementId)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.photo)
      ..writeByte(4)
      ..write(obj.isSkipped)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationMeasurementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationMaterialItemModelAdapter
    extends TypeAdapter<InstallationMaterialItemModel> {
  @override
  final int typeId = 202;

  @override
  InstallationMaterialItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationMaterialItemModel(
      articleId: fields[0] as String,
      articleName: fields[1] as String,
      brandId: fields[2] as String,
      brandName: fields[3] as String,
      length: fields[4] as double,
      usageType: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationMaterialItemModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.articleId)
      ..writeByte(1)
      ..write(obj.articleName)
      ..writeByte(2)
      ..write(obj.brandId)
      ..writeByte(3)
      ..write(obj.brandName)
      ..writeByte(4)
      ..write(obj.length)
      ..writeByte(5)
      ..write(obj.usageType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationMaterialItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationMaterialsModelAdapter
    extends TypeAdapter<InstallationMaterialsModel> {
  @override
  final int typeId = 203;

  @override
  InstallationMaterialsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationMaterialsModel(
      pipes: (fields[0] as List).cast<InstallationMaterialItemModel>(),
      cables: (fields[1] as List).cast<InstallationMaterialItemModel>(),
      mountingType: fields[2] as String,
      hasJasaPerapihan: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationMaterialsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.pipes)
      ..writeByte(1)
      ..write(obj.cables)
      ..writeByte(2)
      ..write(obj.mountingType)
      ..writeByte(3)
      ..write(obj.hasJasaPerapihan);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationMaterialsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationUnitModelAdapter extends TypeAdapter<InstallationUnitModel> {
  @override
  final int typeId = 204;

  @override
  InstallationUnitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationUnitModel(
      serialNo: fields[0] as String,
      articleNo: fields[1] as String,
      articleDesc: fields[2] as String,
      articleType: fields[3] as String,
      note: fields[4] as String?,
      measurements: (fields[5] as List).cast<InstallationMeasurementModel>(),
      materials: fields[6] as InstallationMaterialsModel,
      pairedSerialNo: fields[7] as String?,
      unitIndex: fields[8] as int,
      status: fields[9] as String?,
      materialStatus: fields[10] == null ? 'NONE' : fields[10] as String,
      reffLineNo: fields[11] as String,
      remark: fields[12] == null ? '' : fields[12] as String,
      remarkPhotos: fields[13] == null
          ? []
          : (fields[13] as List).cast<InstallationPhotoModel>(),
      notePsi: fields[14] == null ? '' : fields[14] as String,
      remarkPsi: fields[15] == null ? '' : fields[15] as String,
      remarkPhotosPsi: fields[16] == null
          ? []
          : (fields[16] as List).cast<InstallationPhotoModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, InstallationUnitModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.serialNo)
      ..writeByte(1)
      ..write(obj.articleNo)
      ..writeByte(2)
      ..write(obj.articleDesc)
      ..writeByte(3)
      ..write(obj.articleType)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.measurements)
      ..writeByte(6)
      ..write(obj.materials)
      ..writeByte(7)
      ..write(obj.pairedSerialNo)
      ..writeByte(8)
      ..write(obj.unitIndex)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.materialStatus)
      ..writeByte(11)
      ..write(obj.reffLineNo)
      ..writeByte(12)
      ..write(obj.remark)
      ..writeByte(13)
      ..write(obj.remarkPhotos)
      ..writeByte(14)
      ..write(obj.notePsi)
      ..writeByte(15)
      ..write(obj.remarkPsi)
      ..writeByte(16)
      ..write(obj.remarkPhotosPsi);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationUnitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class InstallationEntryModelAdapter
    extends TypeAdapter<InstallationEntryModel> {
  @override
  final int typeId = 205;

  @override
  InstallationEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InstallationEntryModel(
      transNo: fields[0] as String,
      vendorId: fields[1] as String,
      vendorName: fields[2] as String,
      technicianId: fields[3] as String,
      technician1Name: fields[4] as String,
      technician2Name: fields[5] as String,
      technician3Name: fields[6] as String,
      startDate: fields[7] as DateTime?,
      finalNote: fields[8] as String?,
      finalPhotos: (fields[9] as List).cast<InstallationPhotoModel>(),
      units: (fields[10] as List).cast<InstallationUnitModel>(),
      materialEvidences: (fields[11] as List).cast<MaterialEvidenceModel>(),
      hasTransport: fields[12] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, InstallationEntryModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.vendorId)
      ..writeByte(2)
      ..write(obj.vendorName)
      ..writeByte(3)
      ..write(obj.technicianId)
      ..writeByte(4)
      ..write(obj.technician1Name)
      ..writeByte(5)
      ..write(obj.technician2Name)
      ..writeByte(6)
      ..write(obj.technician3Name)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.finalNote)
      ..writeByte(9)
      ..write(obj.finalPhotos)
      ..writeByte(10)
      ..write(obj.units)
      ..writeByte(11)
      ..write(obj.materialEvidences)
      ..writeByte(12)
      ..write(obj.hasTransport);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstallationEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MaterialEvidenceModelAdapter extends TypeAdapter<MaterialEvidenceModel> {
  @override
  final int typeId = 206;

  @override
  MaterialEvidenceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaterialEvidenceModel(
      key: fields[0] as String,
      title: fields[1] as String,
      photoPath: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MaterialEvidenceModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.photoPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialEvidenceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
