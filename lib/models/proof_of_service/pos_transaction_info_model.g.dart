// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_transaction_info_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PosTransactionInfoModelAdapter
    extends TypeAdapter<PosTransactionInfoModel> {
  @override
  final int typeId = 7;

  @override
  PosTransactionInfoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PosTransactionInfoModel(
      transNo: fields[0] as String,
      picNik: fields[1] as String?,
      picName: fields[2] as String?,
      picPosition: fields[3] as String?,
      picPhone: fields[4] as String?,
      technician1: fields[5] as String?,
      technician2: fields[6] as String?,
      technician3: fields[21] as String?,
      technician1Nik: fields[22] as String?,
      technician2Nik: fields[23] as String?,
      technician3Nik: fields[24] as String?,
      temperatureIn: fields[7] as String?,
      temperatureOut: fields[8] as String?,
      serviceTime: fields[9] as String?,
      picImageDetail: fields[10] as CapturedImageDetail?,
      temperatureInImage: fields[11] as CapturedImageDetail?,
      temperatureOutImage: fields[12] as CapturedImageDetail?,
      finalTemperatureIn: fields[13] as String?,
      finalTemperatureInImage: fields[14] as CapturedImageDetail?,
      isTempInSkipped: fields[15] as bool?,
      tempInNote: fields[16] as String?,
      isTempOutSkipped: fields[17] as bool?,
      tempOutNote: fields[18] as String?,
      isFinalTempInSkipped: fields[19] as bool?,
      finalTempInNote: fields[20] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PosTransactionInfoModel obj) {
    writer
      ..writeByte(25)
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
      ..write(obj.temperatureIn)
      ..writeByte(8)
      ..write(obj.temperatureOut)
      ..writeByte(9)
      ..write(obj.serviceTime)
      ..writeByte(10)
      ..write(obj.picImageDetail)
      ..writeByte(11)
      ..write(obj.temperatureInImage)
      ..writeByte(12)
      ..write(obj.temperatureOutImage)
      ..writeByte(13)
      ..write(obj.finalTemperatureIn)
      ..writeByte(14)
      ..write(obj.finalTemperatureInImage)
      ..writeByte(15)
      ..write(obj.isTempInSkipped)
      ..writeByte(16)
      ..write(obj.tempInNote)
      ..writeByte(17)
      ..write(obj.isTempOutSkipped)
      ..writeByte(18)
      ..write(obj.tempOutNote)
      ..writeByte(19)
      ..write(obj.isFinalTempInSkipped)
      ..writeByte(20)
      ..write(obj.finalTempInNote)
      ..writeByte(21)
      ..write(obj.technician3)
      ..writeByte(22)
      ..write(obj.technician1Nik)
      ..writeByte(23)
      ..write(obj.technician2Nik)
      ..writeByte(24)
      ..write(obj.technician3Nik);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosTransactionInfoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
