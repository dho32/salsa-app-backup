import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';

part 'pos_transaction_info_model.g.dart';

@HiveType(typeId: 7)
class PosTransactionInfoModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String? picNik;

  @HiveField(2)
  String? picName;

  @HiveField(3)
  String? picPosition;

  @HiveField(4)
  String? picPhone;

  @HiveField(5)
  String? technician2;

  @HiveField(6)
  String? technician3;

  @HiveField(7)
  String? temperatureIn;

  @HiveField(8)
  String? temperatureOut;

  @HiveField(9)
  String? serviceTime;

  @HiveField(10)
  CapturedImageDetail? picImageDetail;

  @HiveField(11)
  CapturedImageDetail? temperatureInImage;

  @HiveField(12)
  CapturedImageDetail? temperatureOutImage;

  PosTransactionInfoModel({
    required this.transNo,
    this.picNik,
    this.picName,
    this.picPosition,
    this.picPhone,
    this.technician2,
    this.technician3,
    this.temperatureIn,
    this.temperatureOut,
    this.serviceTime,
    this.picImageDetail,
    this.temperatureInImage,
    this.temperatureOutImage,
  });
}