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
  final String? complaint; // reason terpilih bila 'Ada Keluhan' / 'Tidak terpakai'
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
  });

  bool get hasComplaint => generalCondition == kPosfConditionComplaint;
  bool get hasUnused => generalCondition == kPosfConditionUnused;

  // Kondisi non-Normal butuh detail: reason + note + foto.
  bool get needsConditionDetail => hasComplaint || hasUnused;

  bool get isConditionDetailValid {
    if (!needsConditionDetail) return true;
    return complaint != null &&
        complaint!.isNotEmpty &&
        conditionNote.trim().isNotEmpty &&
        conditionPhotos.isNotEmpty;
  }

  // Alasan skip lengkap: alasan dipilih; bila alasan ber-flag require_remark,
  // remark ≥ 20 huruf (tanpa spasi) + minimal 1 foto bukti (pola POS/SC).
  static bool isSkipReasonComplete(
      String? reason, String remark, List<CapturedImageDetail> photos) {
    if (reason == null || reason.isEmpty) return false;
    if (!kPosfSkipReasonsRequireRemark.contains(reason)) return true;
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
    if (generalCondition == null) return false;
    // "Tidak terpakai": cukup dokumentasi (reason + note + foto), tanpa
    // suhu / ketebalan / foto standar / step Sesudah.
    if (hasUnused) return isConditionDetailValid;
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

  // "Tidak terpakai": selesai cukup di step Sebelum (tanpa step Sesudah).
  bool get isComplete =>
      hasUnused ? isStepBeforeValid : (isStepBeforeValid && isStepAfterValid);

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
    String? complaint,
    bool clearComplaint = false,
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
      generalCondition: generalCondition ?? this.generalCondition,
      complaint: clearComplaint ? null : (complaint ?? this.complaint),
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
      ];
}
