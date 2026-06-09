import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';

part 'proof_of_service_freezer_entry_model.g.dart';

// --- TYPE ID: 154 --- (data wizard per-freezer; pola PosValidationEntryModel)
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

  // --- Step 1: Kondisi Awal ---
  @HiveField(7)
  double? arrivalTemp; // suhu terbaca saat tiba (°C)

  @HiveField(8)
  CapturedImageDetail? arrivalTempImage; // foto pembacaan suhu tiba (watermark)

  @HiveField(9)
  String? generalCondition; // Normal / Ada Keluhan / Tidak Beroperasi

  @HiveField(10)
  String? frostThickness; // Tipis <1cm / Sedang 1-3cm / Tebal >3cm

  @HiveField(11)
  Map<String, CapturedImageDetail> initialPhotos; // slot id (front/inside/condenser) -> foto

  @HiveField(12)
  String? initialNote;

  // --- Step 2: Proses Cuci ---
  @HiveField(13)
  List<bool> cleaningChecklist; // index sesuai daftar item checklist (7 item)

  @HiveField(14)
  String? cleaningProduct; // produk pembersih yang digunakan

  // --- Step 3: Pemeriksaan Teknis ---
  @HiveField(15)
  Map<String, String> statusFlags; // id item -> OK / Perhatian / Masalah

  @HiveField(16)
  List<MeasurementEntry> measurements; // arus kompresor (A), tegangan (V), suhu pull-down (°C)

  @HiveField(17)
  Map<String, CapturedImageDetail> afterPhotos; // slot id -> foto setelah cuci

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
    this.generalCondition,
    this.frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    this.initialNote,
    List<bool>? cleaningChecklist,
    this.cleaningProduct,
    Map<String, String>? statusFlags,
    List<MeasurementEntry>? measurements,
    Map<String, CapturedImageDetail>? afterPhotos,
  })  : initialPhotos = initialPhotos ?? {},
        cleaningChecklist =
            cleaningChecklist ?? List<bool>.generate(7, (_) => false),
        statusFlags = statusFlags ?? {},
        measurements = measurements ?? [],
        afterPhotos = afterPhotos ?? {};
}
