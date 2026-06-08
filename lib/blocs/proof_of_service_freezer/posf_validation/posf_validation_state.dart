import 'package:equatable/equatable.dart';

import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';

/// State wizard validasi 1 freezer (3 step). Dipakai oleh [PosfValidationCubit].
class PosfValidationState extends Equatable {
  final int currentStep; // 0..2
  final bool isLoaded;
  final bool isSaving;

  // --- Step 1: Kondisi Awal ---
  final String arrivalTemp;
  final CapturedImageDetail? arrivalTempImage;
  final String? generalCondition;
  final String? frostThickness;
  final Map<String, CapturedImageDetail> initialPhotos;
  final String initialNote;

  // --- Step 2: Proses Cuci ---
  final List<bool> cleaningChecklist;
  final String cleaningProduct;

  // --- Step 3: Pemeriksaan Teknis ---
  final Map<String, String> statusFlags;
  final List<MeasurementEntry> measurements;
  final Map<String, CapturedImageDetail> afterPhotos;

  const PosfValidationState({
    this.currentStep = 0,
    this.isLoaded = false,
    this.isSaving = false,
    this.arrivalTemp = '',
    this.arrivalTempImage,
    this.generalCondition,
    this.frostThickness,
    this.initialPhotos = const {},
    this.initialNote = '',
    this.cleaningChecklist = const [],
    this.cleaningProduct = '',
    this.statusFlags = const {},
    this.measurements = const [],
    this.afterPhotos = const {},
  });

  // --- Validasi per-step ---
  bool get isStep1Valid =>
      double.tryParse(arrivalTemp) != null &&
      arrivalTempImage != null &&
      generalCondition != null &&
      frostThickness != null &&
      kPosfPhotoSlots.every((s) => initialPhotos.containsKey(s.id));

  bool get isStep2Valid =>
      cleaningChecklist.length == kPosfCleaningChecklist.length &&
      cleaningChecklist.every((c) => c);

  bool get isStep3Valid {
    final allFlags = kPosfAllStatusItems
        .every((it) => (statusFlags[it.id] ?? '').isNotEmpty);
    final allMeasurements = measurements.length == kPosfMeasurements.length &&
        measurements.every(
            (m) => (m.isSkipped ?? false) || m.capturedImage != null);
    final allAfterPhotos =
        kPosfPhotoSlots.every((s) => afterPhotos.containsKey(s.id));
    return allFlags && allMeasurements && allAfterPhotos;
  }

  bool get isComplete => isStep1Valid && isStep2Valid && isStep3Valid;

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return isStep1Valid;
      case 1:
        return isStep2Valid;
      case 2:
        return isStep3Valid;
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
    String? generalCondition,
    String? frostThickness,
    Map<String, CapturedImageDetail>? initialPhotos,
    String? initialNote,
    List<bool>? cleaningChecklist,
    String? cleaningProduct,
    Map<String, String>? statusFlags,
    List<MeasurementEntry>? measurements,
    Map<String, CapturedImageDetail>? afterPhotos,
  }) {
    return PosfValidationState(
      currentStep: currentStep ?? this.currentStep,
      isLoaded: isLoaded ?? this.isLoaded,
      isSaving: isSaving ?? this.isSaving,
      arrivalTemp: arrivalTemp ?? this.arrivalTemp,
      arrivalTempImage: clearArrivalTempImage
          ? null
          : (arrivalTempImage ?? this.arrivalTempImage),
      generalCondition: generalCondition ?? this.generalCondition,
      frostThickness: frostThickness ?? this.frostThickness,
      initialPhotos: initialPhotos ?? this.initialPhotos,
      initialNote: initialNote ?? this.initialNote,
      cleaningChecklist: cleaningChecklist ?? this.cleaningChecklist,
      cleaningProduct: cleaningProduct ?? this.cleaningProduct,
      statusFlags: statusFlags ?? this.statusFlags,
      measurements: measurements ?? this.measurements,
      afterPhotos: afterPhotos ?? this.afterPhotos,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        isLoaded,
        isSaving,
        arrivalTemp,
        arrivalTempImage,
        generalCondition,
        frostThickness,
        initialPhotos,
        initialNote,
        cleaningChecklist,
        cleaningProduct,
        statusFlags,
        measurements,
        afterPhotos,
      ];
}
