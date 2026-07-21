import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';

part 'service_call_validation_entry_model.g.dart';

@HiveType(typeId: 0)
class ServiceCallValidationEntryModel extends HiveObject {
  @HiveField(0)
  String unitType;

  @HiveField(1)
  String serialNo;

  @HiveField(2)
  List<CapturedImageDetail> imagePathsBefore;

  @HiveField(3)
  List<MeasurementEntry> measurementsBefore;

  @HiveField(4)
  List<ValidationProblem> problems;

  @HiveField(5)
  List<CapturedImageDetail> imagePathsAfter;

  @HiveField(6)
  List<MeasurementEntry> measurementsAfter;

  @HiveField(7)
  String transNo;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  String? outdoorSerialNo;

  @HiveField(10)
  String? device;

  @HiveField(11)
  String? selectedIndoorNoteBefore;

  @HiveField(12)
  String? selectedOutdoorNoteBefore;

  @HiveField(13)
  String? selectedIndoorNoteAfter;

  @HiveField(14)
  String? selectedOutdoorNoteAfter;

  @HiveField(15)
  String? selectedOutdoorPSINoteBefore;

  @HiveField(16)
  String? selectedOutdoorPSINoteAfter;

  @HiveField(17)
  String? correctSerialNo;

  @HiveField(18)
  String? noteRemarkIndoor;

  @HiveField(19)
  String? noteRemarkOutdoor;

  @HiveField(20)
  String? noteRemarkPSI;

  @HiveField(21)
  String? noteRemark;

  @HiveField(22)
  List<CapturedImageDetail>? remarkPhotosIndoorAfter;

  @HiveField(23)
  List<CapturedImageDetail>? remarkPhotosOutdoorAfter;

  @HiveField(24)
  List<CapturedImageDetail>? remarkPhotosOutdoorPsiAfter;

  // Foto bukti kendala skip pengukuran fase SEBELUM (pola sama dengan After).
  // Teks remark fase Sebelum tersimpan di measurementsBefore[].remark.
  @HiveField(25)
  List<CapturedImageDetail>? remarkPhotosIndoorBefore;

  @HiveField(26)
  List<CapturedImageDetail>? remarkPhotosOutdoorBefore;

  @HiveField(27)
  List<CapturedImageDetail>? remarkPhotosOutdoorPsiBefore;

  ServiceCallValidationEntryModel({
    required this.unitType,
    required this.serialNo,
    required this.imagePathsBefore,
    required this.measurementsBefore,
    required this.problems,
    required this.imagePathsAfter,
    required this.measurementsAfter,
    required this.transNo,
    this.isCompleted = false,
    this.outdoorSerialNo,
    this.device,
    this.selectedIndoorNoteBefore,
    this.selectedOutdoorNoteBefore,
    this.selectedIndoorNoteAfter,
    this.selectedOutdoorNoteAfter,
    this.selectedOutdoorPSINoteBefore,
    this.selectedOutdoorPSINoteAfter,
    this.correctSerialNo,
    this.noteRemarkIndoor,
    this.noteRemarkOutdoor,
    this.noteRemarkPSI,
    this.noteRemark,
    this.remarkPhotosIndoorAfter,
    this.remarkPhotosOutdoorAfter,
    this.remarkPhotosOutdoorPsiAfter,
    this.remarkPhotosIndoorBefore,
    this.remarkPhotosOutdoorBefore,
    this.remarkPhotosOutdoorPsiBefore,
  });

  factory ServiceCallValidationEntryModel.empty() {
    return ServiceCallValidationEntryModel(
      unitType: '',
      serialNo: '',
      problems: [],
      imagePathsBefore: [],
      measurementsBefore: [],
      imagePathsAfter: [],
      measurementsAfter: [],
      transNo: '',
      isCompleted: false,
      outdoorSerialNo: '',
      device: '',
      selectedIndoorNoteBefore: null,
      selectedOutdoorNoteBefore: null,
      selectedIndoorNoteAfter: null,
      selectedOutdoorNoteAfter: null,
      selectedOutdoorPSINoteBefore: null,
      selectedOutdoorPSINoteAfter: null,
      correctSerialNo: null,
      noteRemarkIndoor: null,
      noteRemarkOutdoor: null,
      noteRemarkPSI: null,
      noteRemark: null,
      remarkPhotosIndoorAfter: [],
      remarkPhotosOutdoorAfter: [],
      remarkPhotosOutdoorPsiAfter: [],
      remarkPhotosIndoorBefore: [],
      remarkPhotosOutdoorBefore: [],
      remarkPhotosOutdoorPsiBefore: [],
    );
  }
}

@HiveType(typeId: 1)
class ValidationProblem extends HiveObject {
  @HiveField(0)
  String problemId;

  @HiveField(1)
  List<String> solutionIds;

  ValidationProblem({
    required this.problemId,
    required this.solutionIds,
  });
}
