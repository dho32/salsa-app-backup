import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';

part 'proof_of_service_freezer_entry_model.g.dart';

// --- TYPE ID: 154 --- (data wizard per-freezer; pola PosValidationEntryModel)
//
// Wizard 2 step:
//   - Sebelum : kondisi awal (suhu tiba, kondisi umum + keluhan, ketebalan
//               bunga es, foto kondisi awal, catatan).
//   - Sesudah : pengukuran aktual + foto setelah cuci.
//
// Key Hive per-unit (lihat cubit/bloc validasi):
//   - generic : GEN_<transNo>_<unitIndex>
//   - serial  : serialNo.trim().toUpperCase()
@HiveType(typeId: 154)
class ProofOfServiceFreezerEntryModel extends HiveObject {
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
  bool isCompleted;

  // --- Step Sebelum: Kondisi Awal ---
  @HiveField(7)
  double? arrivalTemp; // suhu terbaca saat tiba (°C)

  @HiveField(8)
  CapturedImageDetail? arrivalTempImage; // foto pembacaan suhu tiba (watermark)

  @HiveField(19)
  bool arrivalTempSkipped; // true bila suhu tiba "tidak bisa diukur"

  @HiveField(20)
  String? arrivalTempReason; // alasan bila arrivalTempSkipped

  @HiveField(9)
  String? generalCondition; // Normal / Ada Keluhan / Tidak Beroperasi

  @HiveField(10)
  String? frostThickness; // Tipis <1cm / Sedang 1-3cm / Tebal >3cm

  @HiveField(11)
  Map<String, CapturedImageDetail> initialPhotos; // slot id (front/inside/condenser) -> foto

  @HiveField(12)
  String? initialNote;

  // Alasan terpilih untuk kondisi non-Normal: jenis keluhan (Ada Keluhan) atau
  // alasan tidak terpakai (Tidak terpakai). Dipakai ulang lintas kedua kondisi.
  @HiveField(18)
  String? complaint;

  // Keterangan tambahan (wajib) untuk kondisi "Ada Keluhan" / "Tidak terpakai".
  // CATATAN: indeks 27/28 (BUKAN 13/14) — field 13/14 pernah dipakai tipe lain
  // pada adapter typeId 154 versi lama; reuse akan merusak draft lama.
  @HiveField(27)
  String? conditionNote;

  // Foto bukti kondisi (wajib ≥1) untuk "Ada Keluhan" / "Tidak terpakai".
  @HiveField(28)
  List<CapturedImageDetail>? conditionPhotos;

  // --- Step Sesudah: Pengukuran & Foto ---
  @HiveField(16)
  List<MeasurementEntry> measurements; // arus kompresor (A), tegangan (V), suhu pull-down (°C)

  @HiveField(17)
  Map<String, CapturedImageDetail> afterPhotos; // slot id -> foto setelah cuci

  // --- Bukti kendala skip (alasan di kPosfSkipReasonsRequireRemark):
  //     keterangan tambahan + foto bukti per grup pengukuran ---
  @HiveField(21)
  String? arrivalTempSkipRemark;

  @HiveField(22)
  List<CapturedImageDetail>? arrivalTempSkipPhotos;

  @HiveField(23)
  String? tempSkipRemark; // grup suhu pull-down ('temperature')

  @HiveField(24)
  List<CapturedImageDetail>? tempSkipPhotos;

  @HiveField(25)
  String? elecSkipRemark; // grup Arus & Tegangan ('ampere' + 'volt')

  @HiveField(26)
  List<CapturedImageDetail>? elecSkipPhotos;

  ProofOfServiceFreezerEntryModel({
    required this.transNo,
    required this.serialNo,
    this.isGeneric = false,
    this.unitIndex = 0,
    this.articleNo = '',
    this.articleDesc = '',
    this.isCompleted = false,
    this.arrivalTemp,
    this.arrivalTempImage,
    this.arrivalTempSkipped = false,
    this.arrivalTempReason,
    this.generalCondition,
    this.frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    this.initialNote,
    this.complaint,
    this.conditionNote,
    this.conditionPhotos,
    List<MeasurementEntry>? measurements,
    Map<String, CapturedImageDetail>? afterPhotos,
    this.arrivalTempSkipRemark,
    this.arrivalTempSkipPhotos,
    this.tempSkipRemark,
    this.tempSkipPhotos,
    this.elecSkipRemark,
    this.elecSkipPhotos,
  })  : initialPhotos = initialPhotos ?? {},
        measurements = measurements ?? [],
        afterPhotos = afterPhotos ?? {};
}
