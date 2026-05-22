// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rro_cut_off_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RROCutOffFormModelAdapter extends TypeAdapter<RROCutOffFormModel> {
  @override
  final int typeId = 217;

  @override
  RROCutOffFormModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffFormModel(
      transNo: fields[0] as String,
      picName: fields[1] as String,
      picPhone: fields[2] as String,
      picNik: fields[3] as String,
      picPosition: fields[4] as String,
      technician1: fields[5] as String,
      technician2: fields[6] as String,
      technician3: fields[7] as String,
      picImageDetail: fields[8] as CapturedImageDetail?,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffFormModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.picName)
      ..writeByte(2)
      ..write(obj.picPhone)
      ..writeByte(3)
      ..write(obj.picNik)
      ..writeByte(4)
      ..write(obj.picPosition)
      ..writeByte(5)
      ..write(obj.technician1)
      ..writeByte(6)
      ..write(obj.technician2)
      ..writeByte(7)
      ..write(obj.technician3)
      ..writeByte(8)
      ..write(obj.picImageDetail);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffFormModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RROCutOffPhotoModelAdapter extends TypeAdapter<RROCutOffPhotoModel> {
  @override
  final int typeId = 218;

  @override
  RROCutOffPhotoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffPhotoModel(
      imagePath: fields[0] as String,
      imageFileName: fields[1] as String,
      timestamp: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      deviceModel: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffPhotoModel obj) {
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
      other is RROCutOffPhotoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RROCutOffEntryModelAdapter extends TypeAdapter<RROCutOffEntryModel> {
  @override
  final int typeId = 219;

  @override
  RROCutOffEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RROCutOffEntryModel(
      transNo: fields[0] as String,
      rroArticleNo: fields[1] as String,
      unitType: fields[2] as String,
      unitIndex: fields[3] as int,
      lineNo: fields[7] as int,
      selectedSerialNumber: fields[4] as String?,
      photos: (fields[5] as List).cast<RROCutOffPhotoModel>(),
      isCompleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RROCutOffEntryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.rroArticleNo)
      ..writeByte(2)
      ..write(obj.unitType)
      ..writeByte(3)
      ..write(obj.unitIndex)
      ..writeByte(4)
      ..write(obj.selectedSerialNumber)
      ..writeByte(5)
      ..write(obj.photos)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.lineNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RROCutOffEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
