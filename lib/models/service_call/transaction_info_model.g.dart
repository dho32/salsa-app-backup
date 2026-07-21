// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_info_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionInfoModelAdapter extends TypeAdapter<TransactionInfoModel> {
  @override
  final int typeId = 5;

  @override
  TransactionInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionInfoModel(
      transNo: fields[0] as String,
      picNik: fields[1] as String?,
      picName: fields[2] as String?,
      picPosition: fields[3] as String?,
      picPhone: fields[4] as String?,
      technician1: fields[5] as String?,
      technician2: fields[6] as String?,
      technician3: fields[12] as String?,
      technician1Nik: fields[13] as String?,
      technician2Nik: fields[14] as String?,
      technician3Nik: fields[15] as String?,
      picImageDetail: fields[7] as CapturedImageDetail?,
      finalTemperatureIn: fields[8] as String?,
      finalTemperatureInImage: fields[9] as CapturedImageDetail?,
      isFinalTempSkipped: fields[10] as bool?,
      finalTempNote: fields[11] as String?,
      finalTempSkipRemark: fields[16] as String?,
      finalTempSkipPhotos: (fields[17] as List?)?.cast<CapturedImageDetail>(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionInfoModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.transNo)
      ..writeByte(1)
      ..write(obj.picNik)
      ..writeByte(2)
      ..write(obj.picName)
      ..writeByte(3)
      ..write(obj.picPosition)
      ..writeByte(4)
      ..write(obj.picPhone)
      ..writeByte(5)
      ..write(obj.technician1)
      ..writeByte(6)
      ..write(obj.technician2)
      ..writeByte(7)
      ..write(obj.picImageDetail)
      ..writeByte(8)
      ..write(obj.finalTemperatureIn)
      ..writeByte(9)
      ..write(obj.finalTemperatureInImage)
      ..writeByte(10)
      ..write(obj.isFinalTempSkipped)
      ..writeByte(11)
      ..write(obj.finalTempNote)
      ..writeByte(12)
      ..write(obj.technician3)
      ..writeByte(13)
      ..write(obj.technician1Nik)
      ..writeByte(14)
      ..write(obj.technician2Nik)
      ..writeByte(15)
      ..write(obj.technician3Nik)
      ..writeByte(16)
      ..write(obj.finalTempSkipRemark)
      ..writeByte(17)
      ..write(obj.finalTempSkipPhotos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
