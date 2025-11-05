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
      technician2: fields[5] as String?,
      technician3: fields[6] as String?,
      picImageDetail: fields[7] as CapturedImageDetail?,
      finalTemperatureIn: fields[8] as String?,
      finalTemperatureInImage: fields[9] as CapturedImageDetail?,
      isFinalTempSkipped: fields[10] as bool?,
      finalTempNote: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionInfoModel obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.technician2)
      ..writeByte(6)
      ..write(obj.technician3)
      ..writeByte(7)
      ..write(obj.picImageDetail)
      ..writeByte(8)
      ..write(obj.finalTemperatureIn)
      ..writeByte(9)
      ..write(obj.finalTemperatureInImage)
      ..writeByte(10)
      ..write(obj.isFinalTempSkipped)
      ..writeByte(11)
      ..write(obj.finalTempNote);
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
