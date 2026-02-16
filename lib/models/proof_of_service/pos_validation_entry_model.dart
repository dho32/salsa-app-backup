import 'package:hive/hive.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_entry.dart';

part 'pos_validation_entry_model.g.dart';

@HiveType(typeId: 8)
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

  @HiveField(13)
  String? noteRemark;

  @HiveField(14)
  List<CapturedImageDetail>? remarkPhotos;

  // [NEW] Field untuk Reference Line Number dari Backend
  @HiveField(15)
  String? reffLineNo;

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
    this.noteRemark,
    this.remarkPhotos,
    this.reffLineNo, // Add to constructor
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
      noteRemark: '',
      remarkPhotos: [],
      reffLineNo: '',
    );
  }

  // [NEW] Method CopyWith (Wajib untuk BLoC pattern)
  PosValidationEntryModel copyWith({
    String? transNo,
    String? serialNo,
    List<CapturedImageDetail>? photosBefore,
    List<CapturedImageDetail>? photosAfter,
    List<MeasurementEntry>? measurementsAfter,
    bool? isCompleted,
    String? note,
    String? articleNo,
    String? articleDesc,
    String? articleUnitDesc,
    int? capacity,
    String? articleType,
    String? pairedSerialNo,
    String? noteRemark,
    List<CapturedImageDetail>? remarkPhotos,
    String? reffLineNo,
  }) {
    return PosValidationEntryModel(
      transNo: transNo ?? this.transNo,
      serialNo: serialNo ?? this.serialNo,
      photosBefore: photosBefore ?? this.photosBefore,
      photosAfter: photosAfter ?? this.photosAfter,
      measurementsAfter: measurementsAfter ?? this.measurementsAfter,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      articleNo: articleNo ?? this.articleNo,
      articleDesc: articleDesc ?? this.articleDesc,
      articleUnitDesc: articleUnitDesc ?? this.articleUnitDesc,
      capacity: capacity ?? this.capacity,
      articleType: articleType ?? this.articleType,
      pairedSerialNo: pairedSerialNo ?? this.pairedSerialNo,
      noteRemark: noteRemark ?? this.noteRemark,
      remarkPhotos: remarkPhotos ?? this.remarkPhotos,
      reffLineNo: reffLineNo ?? this.reffLineNo,
    );
  }
}