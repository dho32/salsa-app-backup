import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';

part 'scf_validation_entry_model.g.dart';

/// Key Hive per-unit freezer (dipakai bloc/cubit validasi SCF):
///   - generic : `GEN_<transNo>_<unitIndex>`
///   - serial  : `serialNo.trim().toUpperCase()`
String scfEntryKey(String transNo, String serialNo, bool isGeneric, int unitIndex) {
  if (isGeneric) return 'GEN_${transNo}_$unitIndex';
  return serialNo.trim().toUpperCase();
}

// --- TYPE ID: 156 --- (data wizard per-freezer Service Call Freezer).
//
// Gabungan pola:
//   - Service Call  : measurements SEBELUM & SESUDAH + Permasalahan & Solusi
//                     + catatan/remark/foto bukti skip per grup.
//   - Cuci Freezer  : kondisi awal (suhu tiba, kondisi umum + keluhan, ketebalan
//                     bunga es, foto slot berlabel).
//
// Grup pengukuran: 'temperature' (suhu) vs listrik ('ampere' + 'volt', di-link).
@HiveType(typeId: 156)
class ScfValidationEntryModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String serialNo;

  @HiveField(2)
  bool isGeneric;

  @HiveField(3)
  int unitIndex;

  @HiveField(4)
  String articleNo;

  @HiveField(5)
  String articleDesc;

  @HiveField(6)
  String unitType;

  @HiveField(7)
  bool isCompleted;

  @HiveField(8)
  String? device;

  // --- Step Sebelum: Kondisi Awal Freezer ---
  @HiveField(9)
  double? arrivalTemp;

  @HiveField(10)
  CapturedImageDetail? arrivalTempImage;

  @HiveField(11)
  bool arrivalTempSkipped;

  @HiveField(12)
  String? arrivalTempReason;

  @HiveField(13)
  String? arrivalTempSkipRemark;

  @HiveField(14)
  List<CapturedImageDetail>? arrivalTempSkipPhotos;

  @HiveField(15)
  String? generalCondition; // Normal / Ada Keluhan / Tidak terpakai

  @HiveField(16)
  String? complaint; // jenis keluhan / alasan tidak terpakai

  @HiveField(17)
  String? conditionNote; // keterangan tambahan (wajib bila non-Normal)

  @HiveField(18)
  List<CapturedImageDetail>? conditionPhotos; // foto bukti kondisi (wajib >=1)

  @HiveField(19)
  String? frostThickness;

  @HiveField(20)
  Map<String, CapturedImageDetail> initialPhotos; // slot id -> foto awal

  @HiveField(21)
  String? initialNote;

  // --- Pengukuran ---
  @HiveField(22)
  List<MeasurementEntry> measurementsBefore;

  @HiveField(23)
  List<MeasurementEntry> measurementsAfter;

  @HiveField(24)
  Map<String, CapturedImageDetail> afterPhotos; // slot id -> foto setelah

  // --- Catatan skip (alasan terpilih) per grup, fase Sebelum & Sesudah ---
  @HiveField(25)
  String? selectedTempNoteBefore;

  @HiveField(26)
  String? selectedElecNoteBefore;

  @HiveField(27)
  String? selectedTempNoteAfter;

  @HiveField(28)
  String? selectedElecNoteAfter;

  // --- Bukti kendala skip (alasan di kScfSkipReasonsRequireRemark):
  //     keterangan tambahan (>=20 huruf) + foto bukti per grup ---
  @HiveField(29)
  String? tempSkipRemarkBefore;

  @HiveField(30)
  List<CapturedImageDetail>? tempSkipPhotosBefore;

  @HiveField(31)
  String? elecSkipRemarkBefore;

  @HiveField(32)
  List<CapturedImageDetail>? elecSkipPhotosBefore;

  @HiveField(33)
  String? tempSkipRemarkAfter;

  @HiveField(34)
  List<CapturedImageDetail>? tempSkipPhotosAfter;

  @HiveField(35)
  String? elecSkipRemarkAfter;

  @HiveField(36)
  List<CapturedImageDetail>? elecSkipPhotosAfter;

  // --- Permasalahan & Solusi (pola Service Call) ---
  @HiveField(37)
  List<ScfValidationProblem> problems;

  ScfValidationEntryModel({
    required this.transNo,
    required this.serialNo,
    this.isGeneric = false,
    this.unitIndex = 0,
    this.articleNo = '',
    this.articleDesc = '',
    this.unitType = '',
    this.isCompleted = false,
    this.device,
    this.arrivalTemp,
    this.arrivalTempImage,
    this.arrivalTempSkipped = false,
    this.arrivalTempReason,
    this.arrivalTempSkipRemark,
    this.arrivalTempSkipPhotos,
    this.generalCondition,
    this.complaint,
    this.conditionNote,
    this.conditionPhotos,
    this.frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    this.initialNote,
    List<MeasurementEntry>? measurementsBefore,
    List<MeasurementEntry>? measurementsAfter,
    Map<String, CapturedImageDetail>? afterPhotos,
    this.selectedTempNoteBefore,
    this.selectedElecNoteBefore,
    this.selectedTempNoteAfter,
    this.selectedElecNoteAfter,
    this.tempSkipRemarkBefore,
    this.tempSkipPhotosBefore,
    this.elecSkipRemarkBefore,
    this.elecSkipPhotosBefore,
    this.tempSkipRemarkAfter,
    this.tempSkipPhotosAfter,
    this.elecSkipRemarkAfter,
    this.elecSkipPhotosAfter,
    List<ScfValidationProblem>? problems,
  })  : initialPhotos = initialPhotos ?? {},
        measurementsBefore = measurementsBefore ?? [],
        measurementsAfter = measurementsAfter ?? [],
        afterPhotos = afterPhotos ?? {},
        problems = problems ?? [];

  factory ScfValidationEntryModel.empty() {
    return ScfValidationEntryModel(transNo: '', serialNo: '');
  }
}

// --- TYPE ID: 157 --- (pasangan problem + daftar solusi terpilih; mirror
// ValidationProblem Service Call).
@HiveType(typeId: 157)
class ScfValidationProblem extends HiveObject {
  @HiveField(0)
  String problemId;

  @HiveField(1)
  List<String> solutionIds;

  ScfValidationProblem({
    required this.problemId,
    required this.solutionIds,
  });
}
