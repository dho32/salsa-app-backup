import 'package:equatable/equatable.dart';

import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';

/// State wizard validasi 1 freezer (2 step: Sebelum & Sesudah).
/// Dipakai oleh [PosfValidationCubit].
class PosfValidationState extends Equatable {
  final int currentStep; // 0..1
  final bool isLoaded;
  final bool isSaving;

  // --- Step Sebelum: Kondisi Awal ---
  final String arrivalTemp;
  final CapturedImageDetail? arrivalTempImage;
  final bool arrivalTempSkipped; // suhu tiba "tidak bisa diukur"
  final String? arrivalTempReason; // alasan bila arrivalTempSkipped
  final String? generalCondition;
  final String? complaint; // alasan keluhan bila dimensi 'Ada Keluhan'
  final String? unusedReason; // alasan bila dimensi 'Tidak Terpakai'
  final String? frostThickness;
  final Map<String, CapturedImageDetail> initialPhotos;
  final String initialNote;

  // Detail kondisi non-Normal ('Ada Keluhan' / 'Tidak terpakai'):
  // keterangan tambahan (wajib) + foto bukti (wajib ≥1).
  final String conditionNote;
  final List<CapturedImageDetail> conditionPhotos;

  // --- Step Sesudah: Pengukuran & Foto ---
  final List<MeasurementEntry> measurements;
  final Map<String, CapturedImageDetail> afterPhotos;

  // --- Bukti kendala skip (alasan di kPosfSkipReasonsRequireRemark) ---
  final String arrivalTempSkipRemark;
  final List<CapturedImageDetail> arrivalTempSkipPhotos;
  final String tempSkipRemark;
  final List<CapturedImageDetail> tempSkipPhotos;
  final String elecSkipRemark;
  final List<CapturedImageDetail> elecSkipPhotos;

  // Alasan skip yang mewajibkan keterangan + foto bukti. Sumber: config server
  // (require_remark per opsi) bila ada, else konstanta dummy. Diisi cubit dari
  // config supaya gerbang validasi (isSkipReasonComplete) ikut API di production,
  // bukan hanya UI.
  final Set<String> skipReasonsRequireRemark;

  const PosfValidationState({
    this.currentStep = 0,
    this.isLoaded = false,
    this.isSaving = false,
    this.arrivalTemp = '',
    this.arrivalTempImage,
    this.arrivalTempSkipped = false,
    this.arrivalTempReason,
    this.generalCondition,
    this.complaint,
    this.unusedReason,
    this.frostThickness,
    this.initialPhotos = const {},
    this.initialNote = '',
    this.conditionNote = '',
    this.conditionPhotos = const [],
    this.measurements = const [],
    this.afterPhotos = const {},
    this.arrivalTempSkipRemark = '',
    this.arrivalTempSkipPhotos = const [],
    this.tempSkipRemark = '',
    this.tempSkipPhotos = const [],
    this.elecSkipRemark = '',
    this.elecSkipPhotos = const [],
    this.skipReasonsRequireRemark = kPosfSkipReasonsRequireRemark,
  });

  // Dua dimensi kondisi (dari string gabungan generalCondition).
  bool get hasComplaint => posfIsComplaint(generalCondition);
  bool get hasUnused => posfIsUnused(generalCondition);

  /// Nilai dropdown 1 (dimensi FUNGSI). Null bila belum dipilih.
  String? get functionCondition {
    final c = generalCondition;
    if (c == null || c.isEmpty) return null;
    if (posfIsUnwashable(c)) return kPosfCondUnwashable;
    return hasComplaint ? kPosfConditionComplaint : kPosfConditionNormal;
  }

  /// Nilai dropdown 2 (dimensi PEMAKAIAN). Null bila belum dipilih, atau bila
  /// tidak berlaku ("Freezer Tidak Bisa Dicuci" berdiri sendiri).
  ///
  /// Urutan cek penting: "Tidak Terpakai" memuat kata "Terpakai", jadi dimensi
  /// tidak-terpakai diuji lebih dulu. String parsial (dimensi fungsi saja,
  /// mis. "Normal") tidak memuat keduanya → null, artinya dropdown 2 memang
  /// masih kosong dan bukan diam-diam dianggap "Terpakai".
  String? get usageCondition {
    final c = generalCondition;
    if (c == null || c.isEmpty || posfIsUnwashable(c)) return null;
    if (hasUnused) return kPosfConditionUnused;
    return c.contains(kPosfConditionUsed) ? kPosfConditionUsed : null;
  }

  /// Kondisi awal sudah lengkap dipilih: kedua dropdown terisi, atau dropdown 1
  /// = "Freezer Tidak Bisa Dicuci" (yang memang tanpa dimensi pemakaian).
  /// Seluruh form di bawahnya baru ditampilkan setelah ini true.
  bool get isConditionSelected =>
      hasUnwashable || (functionCondition != null && usageCondition != null);

  /// Kondisi ke-5 yang berdiri sendiri: unit tidak bisa dikerjakan sama sekali.
  bool get hasUnwashable => posfIsUnwashable(generalCondition);

  /// Unit tidak dikerjakan ("Tidak Terpakai" atau "Tidak Bisa Dicuci"):
  /// wizard cukup 1 step (Sebelum) — tanpa suhu, ketebalan bunga es, foto
  /// standar, maupun step Sesudah.
  bool get isUnitSkipped => hasUnused || hasUnwashable;

  // Selain "Normal Terpakai" butuh detail: alasan (per dimensi) + note + foto.
  bool get needsConditionDetail => hasComplaint || hasUnused || hasUnwashable;

  bool get isConditionDetailValid {
    if (!needsConditionDetail) return true;
    // "Freezer Tidak Bisa Dicuci" mengikuti form laporan close: alasan +
    // minimal 1 foto bukti WAJIB, catatan tambahan OPSIONAL. Alasannya
    // disimpan di [unusedReason] (slot "alasan unit tidak dikerjakan").
    if (hasUnwashable) {
      return (unusedReason != null && unusedReason!.isNotEmpty) &&
          conditionPhotos.isNotEmpty;
    }
    // "Ada Keluhan" → wajib pilih alasan keluhan.
    if (hasComplaint && (complaint == null || complaint!.isEmpty)) return false;
    // "Tidak Terpakai" → wajib pilih alasan tidak terpakai.
    if (hasUnused && (unusedReason == null || unusedReason!.isEmpty)) {
      return false;
    }
    // Keterangan + foto bukti wajib untuk semua kondisi non-(Normal Terpakai).
    return conditionNote.trim().isNotEmpty && conditionPhotos.isNotEmpty;
  }

  // Alasan skip lengkap: alasan dipilih; bila alasan ber-flag require_remark
  // (dari [skipReasonsRequireRemark] = config server / konstanta dummy),
  // remark ≥ 20 huruf (tanpa spasi) + minimal 1 foto bukti (pola POS/SC).
  bool isSkipReasonComplete(
      String? reason, String remark, List<CapturedImageDetail> photos) {
    if (reason == null || reason.isEmpty) return false;
    if (!skipReasonsRequireRemark.contains(reason)) return true;
    final int charCount = remark.replaceAll(' ', '').length;
    return charCount >= 20 && photos.isNotEmpty;
  }

  // Suhu tiba valid bila: di-skip + alasan lengkap, ATAU nilai + foto terisi.
  bool get isArrivalTempValid => arrivalTempSkipped
      ? isSkipReasonComplete(
          arrivalTempReason, arrivalTempSkipRemark, arrivalTempSkipPhotos)
      : (double.tryParse(arrivalTemp) != null && arrivalTempImage != null);

  // --- Validasi per-step ---
  bool get isStepBeforeValid {
    // Kedua dimensi wajib dipilih dulu (kecuali "Tidak Bisa Dicuci").
    if (!isConditionSelected) return false;
    // "Tidak terpakai" / "Tidak Bisa Dicuci": cukup dokumentasi (reason +
    // foto, note sesuai kondisi), tanpa suhu / ketebalan / foto standar /
    // step Sesudah.
    if (isUnitSkipped) return isConditionDetailValid;
    // Normal / Ada Keluhan: alur penuh.
    return isArrivalTempValid &&
        isConditionDetailValid &&
        frostThickness != null &&
        kPosfPhotoSlots.every((s) => initialPhotos.containsKey(s.id));
  }

  // Remark & foto bukti untuk grup pengukuran (temperature / elec).
  String skipRemarkFor(String measurementId) =>
      measurementId == 'temperature' ? tempSkipRemark : elecSkipRemark;

  List<CapturedImageDetail> skipPhotosFor(String measurementId) =>
      measurementId == 'temperature' ? tempSkipPhotos : elecSkipPhotos;

  bool get isStepAfterValid {
    // Tiap pengukuran valid bila: di-skip + alasan lengkap (termasuk remark +
    // foto bukti bila alasan mewajibkan), ATAU ada foto bukti pengukuran.
    final allMeasurements = measurements.length == kPosfMeasurements.length &&
        measurements.every((m) => (m.isSkipped ?? false)
            ? isSkipReasonComplete(m.remark, skipRemarkFor(m.measurementId),
                skipPhotosFor(m.measurementId))
            : m.capturedImage != null);
    final allAfterPhotos =
        kPosfPhotoSlots.every((s) => afterPhotos.containsKey(s.id));
    return allMeasurements && allAfterPhotos;
  }

  // Unit tidak dikerjakan: selesai cukup di step Sebelum (tanpa step Sesudah).
  bool get isComplete => isUnitSkipped
      ? isStepBeforeValid
      : (isStepBeforeValid && isStepAfterValid);

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return isStepBeforeValid;
      case 1:
        return isStepAfterValid;
      default:
        return false;
    }
  }

  PosfValidationState copyWith({
    int? currentStep,
    bool? isLoaded,
    bool? isSaving,
    String? arrivalTemp,
    CapturedImageDetail? arrivalTempImage,
    bool clearArrivalTempImage = false,
    bool? arrivalTempSkipped,
    String? arrivalTempReason,
    bool clearArrivalTempReason = false,
    String? generalCondition,
    bool clearGeneralCondition = false,
    String? complaint,
    bool clearComplaint = false,
    String? unusedReason,
    bool clearUnusedReason = false,
    String? frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    String? initialNote,
    String? conditionNote,
    List<CapturedImageDetail>? conditionPhotos,
    List<MeasurementEntry>? measurements,
    Map<String, CapturedImageDetail>? afterPhotos,
    String? arrivalTempSkipRemark,
    List<CapturedImageDetail>? arrivalTempSkipPhotos,
    String? tempSkipRemark,
    List<CapturedImageDetail>? tempSkipPhotos,
    String? elecSkipRemark,
    List<CapturedImageDetail>? elecSkipPhotos,
    Set<String>? skipReasonsRequireRemark,
  }) {
    return PosfValidationState(
      currentStep: currentStep ?? this.currentStep,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      arrivalTemp: arrivalTemp ?? this.arrivalTemp,
      arrivalTempImage: clearArrivalTempImage
          ? null
          : (arrivalTempImage ?? this.arrivalTempImage),
      arrivalTempSkipped: arrivalTempSkipped ?? this.arrivalTempSkipped,
      arrivalTempReason: clearArrivalTempReason
          ? null
          : (arrivalTempReason ?? this.arrivalTempReason),
      generalCondition: clearGeneralCondition
          ? null
          : (generalCondition ?? this.generalCondition),
      complaint: clearComplaint ? null : (complaint ?? this.complaint),
      unusedReason:
          clearUnusedReason ? null : (unusedReason ?? this.unusedReason),
      frostThickness: frostThickness ?? this.frostThickness,
      initialPhotos: initialPhotos ?? this.initialPhotos,
      initialNote: initialNote ?? this.initialNote,
      conditionNote: conditionNote ?? this.conditionNote,
      conditionPhotos: conditionPhotos ?? this.conditionPhotos,
      measurements: measurements ?? this.measurements,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      arrivalTempSkipRemark:
          arrivalTempSkipRemark ?? this.arrivalTempSkipRemark,
      arrivalTempSkipPhotos:
          arrivalTempSkipPhotos ?? this.arrivalTempSkipPhotos,
      tempSkipRemark: tempSkipRemark ?? this.tempSkipRemark,
      tempSkipPhotos: tempSkipPhotos ?? this.tempSkipPhotos,
      elecSkipRemark: elecSkipRemark ?? this.elecSkipRemark,
      elecSkipPhotos: elecSkipPhotos ?? this.elecSkipPhotos,
      skipReasonsRequireRemark:
          skipReasonsRequireRemark ?? this.skipReasonsRequireRemark,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoaded,
        isSaving,
        arrivalTemp,
        arrivalTempImage,
        arrivalTempSkipped,
        arrivalTempReason,
        generalCondition,
        complaint,
        unusedReason,
        frostThickness,
        initialPhotos,
        initialNote,
        conditionNote,
        conditionPhotos,
        measurements,
        afterPhotos,
        arrivalTempSkipRemark,
        arrivalTempSkipPhotos,
        tempSkipRemark,
        tempSkipPhotos,
        elecSkipRemark,
        elecSkipPhotos,
        skipReasonsRequireRemark,
      ];
}
