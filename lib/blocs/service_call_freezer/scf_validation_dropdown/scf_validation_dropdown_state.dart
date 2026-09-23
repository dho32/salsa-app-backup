import 'package:equatable/equatable.dart';

import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/service_call_freezer/service_call_freezer_constants.dart';

enum ScfSaveStatus { initial, saving, successDraft, successFinal, error }

/// Kartu pilihan Permasalahan & Solusi (pola SelectedProblemCard SC).
class ScfProblemCard extends Equatable {
  final String? selectedProblemId;
  final List<String> selectedSolutionIds;

  const ScfProblemCard({
    this.selectedProblemId,
    this.selectedSolutionIds = const [],
  });

  ScfProblemCard copyWith({
    String? selectedProblemId,
    List<String>? selectedSolutionIds,
  }) {
    return ScfProblemCard(
      selectedProblemId: selectedProblemId ?? this.selectedProblemId,
      selectedSolutionIds: selectedSolutionIds ?? this.selectedSolutionIds,
    );
  }

  @override
  List<Object?> get props => [selectedProblemId, selectedSolutionIds];
}

/// State wizard validasi 1 freezer (2 step: Sebelum & Sesudah).
/// Dipakai oleh [ScfValidationDropdownCubit].
class ScfValidationDropdownState extends Equatable {
  final int currentStep; // 0..1
  final bool isLoaded;
  final bool isSaving;
  final ScfSaveStatus saveStatus;

  // --- Step Sebelum: Kondisi Awal ---
  final String arrivalTemp;
  final CapturedImageDetail? arrivalTempImage;
  final bool arrivalTempSkipped;
  final String? arrivalTempReason;
  final String arrivalTempSkipRemark;
  final List<CapturedImageDetail> arrivalTempSkipPhotos;
  final String? generalCondition; // Normal / Ada Keluhan / Tidak terpakai
  final String? complaint;
  final String conditionNote;
  final List<CapturedImageDetail> conditionPhotos;
  final String? frostThickness;
  final Map<String, CapturedImageDetail> initialPhotos;
  final String initialNote;

  // --- Pengukuran Sebelum & Sesudah ---
  final List<MeasurementEntry> measurementsBefore;
  final List<MeasurementEntry> measurementsAfter;

  // --- Step Sesudah: foto setelah + Permasalahan & Solusi ---
  final Map<String, CapturedImageDetail> afterPhotos;
  final List<ScfProblemCard> problemCards;

  // Sumber Permasalahan terpilih (UNIT / NON_UNIT). Mengganti seluruh kartu
  // saat berubah (pola SC ValidationDropdownBloc.selectedUnitType).
  final String? selectedUnitType;

  // --- Bukti kendala skip per grup (temp / elec) × fase (before / after) ---
  final String tempSkipRemarkBefore;
  final List<CapturedImageDetail> tempSkipPhotosBefore;
  final String elecSkipRemarkBefore;
  final List<CapturedImageDetail> elecSkipPhotosBefore;
  final String tempSkipRemarkAfter;
  final List<CapturedImageDetail> tempSkipPhotosAfter;
  final String elecSkipRemarkAfter;
  final List<CapturedImageDetail> elecSkipPhotosAfter;

  // Pengukuran yang sudah dikonfirmasi "sesuai foto" per fase (transient).
  final Set<String> confirmedBefore;
  final Set<String> confirmedAfter;

  // Alasan skip yang mewajibkan keterangan + foto bukti. Sumber: config server
  // (require_remark per opsi) bila ada, else konstanta dummy. Diisi cubit dari
  // config supaya gerbang validasi (isSkipReasonComplete) ikut API di production,
  // bukan hanya UI.
  final Set<String> skipReasonsRequireRemark;

  const ScfValidationDropdownState({
    this.currentStep = 0,
    this.isLoaded = false,
    this.isSaving = false,
    this.saveStatus = ScfSaveStatus.initial,
    this.arrivalTemp = '',
    this.arrivalTempImage,
    this.arrivalTempSkipped = false,
    this.arrivalTempReason,
    this.arrivalTempSkipRemark = '',
    this.arrivalTempSkipPhotos = const [],
    this.generalCondition,
    this.complaint,
    this.conditionNote = '',
    this.conditionPhotos = const [],
    this.frostThickness,
    this.initialPhotos = const {},
    this.initialNote = '',
    this.measurementsBefore = const [],
    this.measurementsAfter = const [],
    this.afterPhotos = const {},
    this.problemCards = const [],
    this.selectedUnitType,
    this.tempSkipRemarkBefore = '',
    this.tempSkipPhotosBefore = const [],
    this.elecSkipRemarkBefore = '',
    this.elecSkipPhotosBefore = const [],
    this.tempSkipRemarkAfter = '',
    this.tempSkipPhotosAfter = const [],
    this.elecSkipRemarkAfter = '',
    this.elecSkipPhotosAfter = const [],
    this.confirmedBefore = const {},
    this.confirmedAfter = const {},
    this.skipReasonsRequireRemark = kScfSkipReasonsRequireRemark,
  });

  bool get hasComplaint => generalCondition == kScfConditionComplaint;
  bool get hasUnused => generalCondition == kScfConditionUnused;
  bool get needsConditionDetail => hasComplaint || hasUnused;

  bool get isConditionDetailValid {
    if (!needsConditionDetail) return true;
    return complaint != null &&
        complaint!.isNotEmpty &&
        conditionNote.trim().isNotEmpty &&
        conditionPhotos.isNotEmpty;
  }

  /// Alasan skip lengkap: alasan dipilih; bila alasan ber-flag require_remark
  /// (dari [skipReasonsRequireRemark] = config server / konstanta dummy),
  /// remark ≥ 20 huruf (tanpa spasi) + minimal 1 foto bukti (pola POS/SC).
  bool isSkipReasonComplete(
      String? reason, String remark, List<CapturedImageDetail> photos) {
    if (reason == null || reason.isEmpty) return false;
    if (!skipReasonsRequireRemark.contains(reason)) return true;
    final int charCount = remark.replaceAll(' ', '').length;
    return charCount >= 20 && photos.isNotEmpty;
  }

  bool get isArrivalTempValid => arrivalTempSkipped
      ? isSkipReasonComplete(
          arrivalTempReason, arrivalTempSkipRemark, arrivalTempSkipPhotos)
      : (double.tryParse(arrivalTemp) != null && arrivalTempImage != null);

  bool _isElec(String id) => kScfLinkedElectricalIds.contains(id);

  String skipRemarkFor(String id, {required bool isBefore}) {
    if (_isElec(id)) return isBefore ? elecSkipRemarkBefore : elecSkipRemarkAfter;
    return isBefore ? tempSkipRemarkBefore : tempSkipRemarkAfter;
  }

  List<CapturedImageDetail> skipPhotosFor(String id, {required bool isBefore}) {
    if (_isElec(id)) return isBefore ? elecSkipPhotosBefore : elecSkipPhotosAfter;
    return isBefore ? tempSkipPhotosBefore : tempSkipPhotosAfter;
  }

  bool _measurementsValid(List<MeasurementEntry> list, {required bool isBefore}) {
    if (list.length != kScfMeasurements.length) return false;
    return list.every((m) => (m.isSkipped ?? false)
        ? isSkipReasonComplete(m.remark, skipRemarkFor(m.measurementId, isBefore: isBefore),
            skipPhotosFor(m.measurementId, isBefore: isBefore))
        : m.capturedImage != null);
  }

  // Minimal satu kartu problem lengkap (problem + minimal 1 solusi).
  bool get hasCompleteProblem => problemCards.any((c) =>
      c.selectedProblemId != null &&
      c.selectedProblemId!.isNotEmpty &&
      c.selectedSolutionIds.isNotEmpty);

  // --- Validasi per-step ---
  // Kondisi Freezer (suhu tiba, kondisi umum, keluhan, catatan, ketebalan bunga
  // es) sudah dihapus dari wizard: Step Sebelum lengkap cukup dengan foto unit
  // awal + pengukuran awal (Suhu/Ampere/Volt) yang terisi/skip lengkap.
  bool get isStepBeforeValid {
    return kScfInitialPhotoSlots.every((s) => initialPhotos.containsKey(s.id)) &&
        _measurementsValid(measurementsBefore, isBefore: true);
  }

  bool get isStepAfterValid {
    final allAfterPhotos =
        kScfAfterPhotoSlots.every((s) => afterPhotos.containsKey(s.id));
    return _measurementsValid(measurementsAfter, isBefore: false) &&
        allAfterPhotos &&
        hasCompleteProblem;
  }

  // "Tidak terpakai": selesai cukup di step Sebelum.
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

  ScfValidationDropdownState copyWith({
    int? currentStep,
    bool? isLoaded,
    bool? isSaving,
    ScfSaveStatus? saveStatus,
    String? arrivalTemp,
    CapturedImageDetail? arrivalTempImage,
    bool clearArrivalTempImage = false,
    bool? arrivalTempSkipped,
    String? arrivalTempReason,
    bool clearArrivalTempReason = false,
    String? arrivalTempSkipRemark,
    List<CapturedImageDetail>? arrivalTempSkipPhotos,
    String? generalCondition,
    String? complaint,
    bool clearComplaint = false,
    String? conditionNote,
    List<CapturedImageDetail>? conditionPhotos,
    String? frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    String? initialNote,
    List<MeasurementEntry>? measurementsBefore,
    List<MeasurementEntry>? measurementsAfter,
    Map<String, CapturedImageDetail>? afterPhotos,
    List<ScfProblemCard>? problemCards,
    String? selectedUnitType,
    String? tempSkipRemarkBefore,
    List<CapturedImageDetail>? tempSkipPhotosBefore,
    String? elecSkipRemarkBefore,
    List<CapturedImageDetail>? elecSkipPhotosBefore,
    String? tempSkipRemarkAfter,
    List<CapturedImageDetail>? tempSkipPhotosAfter,
    String? elecSkipRemarkAfter,
    List<CapturedImageDetail>? elecSkipPhotosAfter,
    Set<String>? confirmedBefore,
    Set<String>? confirmedAfter,
    Set<String>? skipReasonsRequireRemark,
  }) {
    return ScfValidationDropdownState(
      currentStep: currentStep ?? this.currentStep,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      saveStatus: saveStatus ?? this.saveStatus,
      arrivalTemp: arrivalTemp ?? this.arrivalTemp,
      arrivalTempImage: clearArrivalTempImage
          ? null
          : (arrivalTempImage ?? this.arrivalTempImage),
      arrivalTempSkipped: arrivalTempSkipped ?? this.arrivalTempSkipped,
      arrivalTempReason: clearArrivalTempReason
          ? null
          : (arrivalTempReason ?? this.arrivalTempReason),
      arrivalTempSkipRemark:
          arrivalTempSkipRemark ?? this.arrivalTempSkipRemark,
      arrivalTempSkipPhotos:
          arrivalTempSkipPhotos ?? this.arrivalTempSkipPhotos,
      generalCondition: generalCondition ?? this.generalCondition,
      complaint: clearComplaint ? null : (complaint ?? this.complaint),
      conditionNote: conditionNote ?? this.conditionNote,
      conditionPhotos: conditionPhotos ?? this.conditionPhotos,
      frostThickness: frostThickness ?? this.frostThickness,
      initialPhotos: initialPhotos ?? this.initialPhotos,
      initialNote: initialNote ?? this.initialNote,
      measurementsBefore: measurementsBefore ?? this.measurementsBefore,
      measurementsAfter: measurementsAfter ?? this.measurementsAfter,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      problemCards: problemCards ?? this.problemCards,
      selectedUnitType: selectedUnitType ?? this.selectedUnitType,
      tempSkipRemarkBefore: tempSkipRemarkBefore ?? this.tempSkipRemarkBefore,
      tempSkipPhotosBefore: tempSkipPhotosBefore ?? this.tempSkipPhotosBefore,
      elecSkipRemarkBefore: elecSkipRemarkBefore ?? this.elecSkipRemarkBefore,
      elecSkipPhotosBefore: elecSkipPhotosBefore ?? this.elecSkipPhotosBefore,
      tempSkipRemarkAfter: tempSkipRemarkAfter ?? this.tempSkipRemarkAfter,
      tempSkipPhotosAfter: tempSkipPhotosAfter ?? this.tempSkipPhotosAfter,
      elecSkipRemarkAfter: elecSkipRemarkAfter ?? this.elecSkipRemarkAfter,
      elecSkipPhotosAfter: elecSkipPhotosAfter ?? this.elecSkipPhotosAfter,
      confirmedBefore: confirmedBefore ?? this.confirmedBefore,
      confirmedAfter: confirmedAfter ?? this.confirmedAfter,
      skipReasonsRequireRemark:
          skipReasonsRequireRemark ?? this.skipReasonsRequireRemark,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoaded,
        isSaving,
        saveStatus,
        arrivalTemp,
        arrivalTempImage,
        arrivalTempSkipped,
        arrivalTempReason,
        arrivalTempSkipRemark,
        arrivalTempSkipPhotos,
        generalCondition,
        complaint,
        conditionNote,
        conditionPhotos,
        frostThickness,
        initialPhotos,
        initialNote,
        measurementsBefore,
        measurementsAfter,
        afterPhotos,
        problemCards,
        selectedUnitType,
        tempSkipRemarkBefore,
        tempSkipPhotosBefore,
        elecSkipRemarkBefore,
        elecSkipPhotosBefore,
        tempSkipRemarkAfter,
        tempSkipPhotosAfter,
        elecSkipRemarkAfter,
        elecSkipPhotosAfter,
        confirmedBefore,
        confirmedAfter,
        skipReasonsRequireRemark,
      ];
}
