import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';

part 'rro_cut_off_entry_model.g.dart';

// --- MODEL FORM ---
@HiveType(typeId: 217)
class RROCutOffFormModel extends HiveObject {
  @HiveField(0)
  final String transNo;

  @HiveField(1)
  final String picName;

  @HiveField(2)
  final String picPhone;

  @HiveField(3)
  final String picNik;

  @HiveField(4)
  final String picPosition;

  @HiveField(5)
  final String technician1;

  @HiveField(6)
  final String technician2;

  @HiveField(7)
  final String technician3;

  @override
  @HiveField(8)
  CapturedImageDetail? picImageDetail;

  RROCutOffFormModel({
    required this.transNo,
    required this.picName,
    required this.picPhone,
    required this.picNik,
    required this.picPosition,
    required this.technician1,
    required this.technician2,
    required this.technician3,
    this.picImageDetail,
  });
}

@HiveType(typeId: 218)
class RROCutOffPhotoModel {
  @HiveField(0)
  final String imagePath;

  @HiveField(1)
  final String imageFileName;

  @HiveField(2)
  final String timestamp;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final String deviceModel;

  RROCutOffPhotoModel({
    required this.imagePath,
    required this.imageFileName,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.deviceModel,
  });

  Map<String, dynamic> toJson() => {
    'image_file_name': imageFileName,
    'timestamp': timestamp,
    'latitude': latitude,
    'longitude': longitude,
    'device': deviceModel,
  };
}

// --- MODEL ENTRY UNIT ---
@HiveType(typeId: 219)
class RROCutOffEntryModel extends HiveObject {
  @HiveField(0)
  final String transNo;

  @HiveField(1)
  final String rroArticleNo;

  @HiveField(2)
  final String unitType;

  @HiveField(3)
  final int unitIndex;

  @HiveField(4)
  String? selectedSerialNumber;

  @HiveField(5)
  List<RROCutOffPhotoModel> photos;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  final int lineNo;

  RROCutOffEntryModel({
    required this.transNo,
    required this.rroArticleNo,
    required this.unitType,
    required this.unitIndex,
    required this.lineNo,
    this.selectedSerialNumber,
    this.photos = const [], // Defaultnya list kosong
    this.isCompleted = false,
  });
}