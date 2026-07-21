import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/i_pic_photo_storable.dart';

part 'pos_transaction_info_model.g.dart';

@HiveType(typeId: 7)
class PosTransactionInfoModel extends HiveObject implements IPicPhotoStorable {
  @override
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
  String? technician1;

  @HiveField(6)
  String? technician2;

  @HiveField(7)
  String? temperatureIn;

  @HiveField(8)
  String? temperatureOut;

  @HiveField(9)
  String? serviceTime;

  @override
  @HiveField(10)
  CapturedImageDetail? picImageDetail;

  @HiveField(11)
  CapturedImageDetail? temperatureInImage;

  @HiveField(12)
  CapturedImageDetail? temperatureOutImage;

  @HiveField(13)
  String? finalTemperatureIn;

  @HiveField(14)
  CapturedImageDetail? finalTemperatureInImage;

  @HiveField(15)
  bool? isTempInSkipped;

  @HiveField(16)
  String? tempInNote;

  @HiveField(17)
  bool? isTempOutSkipped;

  @HiveField(18)
  String? tempOutNote;

  @HiveField(19)
  bool? isFinalTempInSkipped;

  @HiveField(20)
  String? finalTempInNote;

  @HiveField(21)
  String? technician3;

  @HiveField(22)
  String? technician1Nik;

  @HiveField(23)
  String? technician2Nik;

  @HiveField(24)
  String? technician3Nik;

  // Bukti kendala saat suhu di-skip dengan alasan ber-flag require_remark
  // (mis. "Terkendala dengan alat kerja"): keterangan tambahan + foto bukti.
  @HiveField(25)
  String? tempInSkipRemark;

  @HiveField(26)
  String? tempOutSkipRemark;

  @HiveField(27)
  String? finalTempInSkipRemark;

  @HiveField(28)
  List<CapturedImageDetail>? tempInSkipPhotos;

  @HiveField(29)
  List<CapturedImageDetail>? tempOutSkipPhotos;

  @HiveField(30)
  List<CapturedImageDetail>? finalTempInSkipPhotos;

  PosTransactionInfoModel({
    required this.transNo,
    this.picNik,
    this.picName,
    this.picPosition,
    this.picPhone,
    this.technician1,
    this.technician2,
    this.technician3,
    this.technician1Nik,
    this.technician2Nik,
    this.technician3Nik,
    this.temperatureIn,
    this.temperatureOut,
    this.serviceTime,
    this.picImageDetail,
    this.temperatureInImage,
    this.temperatureOutImage,
    this.finalTemperatureIn,      // <-- Tambahkan di constructor
    this.finalTemperatureInImage,
    this.isTempInSkipped,
    this.tempInNote,
    this.isTempOutSkipped,
    this.tempOutNote,
    this.isFinalTempInSkipped,
    this.finalTempInNote,
    this.tempInSkipRemark,
    this.tempOutSkipRemark,
    this.finalTempInSkipRemark,
    this.tempInSkipPhotos,
    this.tempOutSkipPhotos,
    this.finalTempInSkipPhotos,
  });
}