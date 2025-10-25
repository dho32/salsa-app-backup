import 'package:hive/hive.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';

part 'pos_validation_entry_model.g.dart';

@HiveType(typeId: 8) // Pastikan typeId ini unik
class PosValidationEntryModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String serialNo;

  @HiveField(2)
  List<CapturedImageDetail> photosBefore;

  @HiveField(3)
  List<CapturedImageDetail> photosAfter;

  @HiveField(4)
  List<MeasurementEntry> measurementsAfter;

  @HiveField(5)
  bool? isCompleted;

  @HiveField(6)
  String? note;

  @HiveField(7)
  String? articleNo;

  @HiveField(8)
  String? articleDesc;

  @HiveField(9)
  String? articleUnitDesc;

  @HiveField(10)
  int? capacity;

  @HiveField(11)
  String? articleType;

  @HiveField(12)
  String? pairedSerialNo;

  PosValidationEntryModel({
    required this.transNo,
    required this.serialNo,
    required this.photosBefore,
    required this.photosAfter,
    required this.measurementsAfter,
    this.isCompleted = false,
    required this.note,
    required this.articleNo,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.capacity,
    required this.articleType,
    this.pairedSerialNo,
  });

  factory PosValidationEntryModel.empty() {
    return PosValidationEntryModel(
      transNo: '',
      serialNo: '',
      photosBefore: [],
      photosAfter: [],
      measurementsAfter: [],
      isCompleted: false,
      note: '',
      articleNo: '',
      articleDesc: '',
      articleUnitDesc: '',
      capacity: null,
      articleType: '',
      pairedSerialNo: '',
    );
  }
}
