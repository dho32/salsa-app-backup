import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';

part 'transaction_info_model.g.dart';

@HiveType(typeId: 5) // Pastikan typeId ini unik
class TransactionInfoModel extends HiveObject {
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
  CapturedImageDetail? picImageDetail;

  @HiveField(8)
  String? finalTemperatureIn;

  @HiveField(9)
  CapturedImageDetail? finalTemperatureInImage;

  TransactionInfoModel({
    required this.transNo,
    this.picNik,
    this.picName,
    this.picPosition,
    this.picPhone,
    this.technician2,
    this.technician3,
    this.picImageDetail,
    this.finalTemperatureIn,
    this.finalTemperatureInImage,
  });
}