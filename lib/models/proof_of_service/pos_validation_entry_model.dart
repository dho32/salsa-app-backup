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

  @HiveField(15)
  String? reffLineNo;

  // 🔥 FIELD BARU KHUSUS GENERIC UNIT 🔥
  @HiveField(16)
  bool? isGeneric;

  @HiveField(17)
  int? unitIndex;

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
    this.reffLineNo,
    this.isGeneric = false, // Default false
    this.unitIndex = 0,     // Default 0
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
      isGeneric: false,
      unitIndex: 0,
    );
  }

  // Method CopyWith Updated
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
    bool? isGeneric, // 🔥
    int? unitIndex,  // 🔥
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
      isGeneric: isGeneric ?? this.isGeneric, // 🔥
      unitIndex: unitIndex ?? this.unitIndex, // 🔥
    );
  }

  // Method toJson (diperlukan untuk submit data ke API)
  Map<String, dynamic> toJson() {
    return {
      'trans_no': transNo,
      'serial_no': serialNo,
      'article_no': articleNo,
      'description': articleDesc,
      'article_name_unit': articleUnitDesc,
      'unit_type': articleType,
      'reff_line_no': reffLineNo,
      'paired_serial_no': pairedSerialNo,
      'is_completed': isCompleted,
      'note': note,
      'note_remark': noteRemark,
      // Mapping detail foto & measurement biasanya di-handle terpisah di BLoC submit
      // tapi struktur dasar item ada di sini.
    };
  }
}