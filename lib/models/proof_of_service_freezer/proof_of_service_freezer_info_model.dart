import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/i_pic_photo_storable.dart';

part 'proof_of_service_freezer_info_model.g.dart';

// --- TYPE ID: 153 --- (info level-transaksi: PIC toko + teknisi bertugas)
// Pola sama dengan PosTransactionInfoModel, tanpa field suhu (suhu freezer
// dicatat per-unit di wizard, bukan di level transaksi).
// Implements IPicPhotoStorable supaya box-nya bisa dipakai LocationValidationBloc
// (foto lokasi/PIC saat OTP) — sama seperti PosTransactionInfoModel.
@HiveType(typeId: 153)
class ProofOfServiceFreezerInfoModel extends HiveObject implements IPicPhotoStorable {
  @override
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String? picName;

  @HiveField(2)
  String? picNik;

  @HiveField(3)
  String? picPosition;

  @HiveField(4)
  String? picPhone;

  @override
  @HiveField(5)
  CapturedImageDetail? picImageDetail;

  @HiveField(6)
  String? technician1;

  @HiveField(7)
  String? technician2;

  @HiveField(8)
  String? technician3;

  @HiveField(9)
  String? technician1Nik;

  @HiveField(10)
  String? technician2Nik;

  @HiveField(11)
  String? technician3Nik;

  ProofOfServiceFreezerInfoModel({
    required this.transNo,
    this.picName,
    this.picNik,
    this.picPosition,
    this.picPhone,
    this.picImageDetail,
    this.technician1,
    this.technician2,
    this.technician3,
    this.technician1Nik,
    this.technician2Nik,
    this.technician3Nik,
  });
}
