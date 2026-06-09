import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import '../proof_of_service_freezer_detail/proof_of_service_freezer_detail_bloc.dart' show freezerEntryKey;
import 'posf_validation_state.dart';

/// Cubit wizard validasi 1 freezer. Memuat/menyimpan [ProofOfServiceFreezerEntryModel] ke
/// [kProofOfServiceFreezerEntryBox] (offline-first, auto-save tiap perubahan).
class PosfValidationCubit extends Cubit<PosfValidationState> {
  final String transNo;
  final String serialNo;
  final bool isGeneric;
  final int unitIndex;
  final String articleNo;
  final String articleDesc;
  final Box<ProofOfServiceFreezerEntryModel> _box;

  String get _key => freezerEntryKey(transNo, serialNo, isGeneric, unitIndex);
  String get _debounceTag => 'posf-val-save-$_key';

  PosfValidationCubit({
    required this.transNo,
    required this.serialNo,
    required this.isGeneric,
    required this.unitIndex,
    required this.articleNo,
    required this.articleDesc,
  })  : _box = Hive.box<ProofOfServiceFreezerEntryModel>(kProofOfServiceFreezerEntryBox),
        super(const PosfValidationState()) {
    _load();
  }

  void _load() {
    final e = _box.get(_key);
    if (e != null) {
      emit(PosfValidationState(
        isLoaded: true,
        arrivalTemp: e.arrivalTemp?.toString() ?? '',
        arrivalTempImage: e.arrivalTempImage,
        generalCondition: e.generalCondition,
        frostThickness: e.frostThickness,
        initialPhotos: Map.of(e.initialPhotos),
        initialNote: e.initialNote ?? '',
        cleaningChecklist:
            e.cleaningChecklist.length == kPosfCleaningChecklist.length
                ? List.of(e.cleaningChecklist)
                : _freshChecklist(),
        cleaningProduct: e.cleaningProduct ?? '',
        statusFlags: Map.of(e.statusFlags),
        measurements:
            e.measurements.isNotEmpty ? List.of(e.measurements) : _freshMeasurements(),
        afterPhotos: Map.of(e.afterPhotos),
      ));
    } else {
      emit(PosfValidationState(
        isLoaded: true,
        cleaningChecklist: _freshChecklist(),
        measurements: _freshMeasurements(),
      ));
    }
  }

  List<bool> _freshChecklist() =>
      List<bool>.generate(kPosfCleaningChecklist.length, (_) => false);

  List<MeasurementEntry> _freshMeasurements() => kPosfMeasurements
      .map((l) => MeasurementEntry(
          measurementId: l.id, value: 0, unit: l.unit, isSkipped: false))
      .toList();

  // --- Navigasi step ---
  void nextStep() {
    if (state.currentStep < 2) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  // --- Step 1 ---
  void arrivalTempChanged(String v) {
    emit(state.copyWith(arrivalTemp: v));
    _scheduleSave();
  }

  void arrivalTempImageChanged(CapturedImageDetail? image) {
    if (image == null) {
      emit(state.copyWith(clearArrivalTempImage: true));
    } else {
      emit(state.copyWith(arrivalTempImage: image));
    }
    _scheduleSave();
  }

  void generalConditionChanged(String v) {
    emit(state.copyWith(generalCondition: v));
    _scheduleSave();
  }

  void frostThicknessChanged(String v) {
    emit(state.copyWith(frostThickness: v));
    _scheduleSave();
  }

  void initialNoteChanged(String v) {
    emit(state.copyWith(initialNote: v));
    _scheduleSave();
  }

  void setInitialPhoto(String slotId, CapturedImageDetail img) {
    final m = Map<String, CapturedImageDetail>.of(state.initialPhotos);
    m[slotId] = img;
    emit(state.copyWith(initialPhotos: m));
    _scheduleSave();
  }

  void removeInitialPhoto(String slotId) {
    final m = Map<String, CapturedImageDetail>.of(state.initialPhotos);
    m.remove(slotId);
    emit(state.copyWith(initialPhotos: m));
    _scheduleSave();
  }

  // --- Step 2 ---
  void toggleChecklist(int index, bool value) {
    if (index < 0 || index >= state.cleaningChecklist.length) return;
    final list = List<bool>.of(state.cleaningChecklist);
    list[index] = value;
    emit(state.copyWith(cleaningChecklist: list));
    _scheduleSave();
  }

  void toggleAllChecklist(bool value) {
    emit(state.copyWith(
        cleaningChecklist:
            List<bool>.generate(kPosfCleaningChecklist.length, (_) => value)));
    _scheduleSave();
  }

  void cleaningProductChanged(String v) {
    emit(state.copyWith(cleaningProduct: v));
    _scheduleSave();
  }

  // --- Step 3 ---
  void statusFlagChanged(String id, String value) {
    final m = Map<String, String>.of(state.statusFlags);
    m[id] = value;
    emit(state.copyWith(statusFlags: m));
    _scheduleSave();
  }

  void measurementValueChanged(String id, String value) {
    emit(state.copyWith(
        measurements: _updateMeasurement(
            id, (e) => e.copyWith(value: double.tryParse(value) ?? 0))));
    _scheduleSave();
  }

  void measurementImageChanged(String id, CapturedImageDetail? image) {
    emit(state.copyWith(
        measurements: _updateMeasurement(
            id,
            (e) => image == null
                ? e.copyWith(clearCapturedImage: true)
                : e.copyWith(capturedImage: image))));
    _scheduleSave();
  }

  void measurementSkipChanged(String id, bool skipped) {
    emit(state.copyWith(
        measurements: _updateMeasurement(
            id,
            (e) => skipped
                ? e.copyWith(isSkipped: true, value: 0, clearCapturedImage: true)
                : e.copyWith(isSkipped: false))));
    _scheduleSave();
  }

  void setAfterPhoto(String slotId, CapturedImageDetail img) {
    final m = Map<String, CapturedImageDetail>.of(state.afterPhotos);
    m[slotId] = img;
    emit(state.copyWith(afterPhotos: m));
    _scheduleSave();
  }

  void removeAfterPhoto(String slotId) {
    final m = Map<String, CapturedImageDetail>.of(state.afterPhotos);
    m.remove(slotId);
    emit(state.copyWith(afterPhotos: m));
    _scheduleSave();
  }

  List<MeasurementEntry> _updateMeasurement(
      String id, MeasurementEntry Function(MeasurementEntry) f) {
    return state.measurements
        .map((e) => e.measurementId == id ? f(e) : e)
        .toList();
  }

  // --- Persistence ---
  void _scheduleSave() {
    EasyDebounce.debounce(
        _debounceTag, const Duration(milliseconds: 400), () => _save(false));
  }

  Future<void> _save(bool completed) async {
    final entry = _box.get(_key) ??
        ProofOfServiceFreezerEntryModel(transNo: transNo, serialNo: serialNo);
    entry.transNo = transNo;
    entry.serialNo = serialNo;
    entry.isGeneric = isGeneric;
    entry.unitIndex = unitIndex;
    entry.articleNo = articleNo;
    entry.articleDesc = articleDesc;
    entry.arrivalTemp = double.tryParse(state.arrivalTemp);
    entry.arrivalTempImage = state.arrivalTempImage;
    entry.generalCondition = state.generalCondition;
    entry.frostThickness = state.frostThickness;
    entry.initialPhotos = Map.of(state.initialPhotos);
    entry.initialNote = state.initialNote;
    entry.cleaningChecklist = List.of(state.cleaningChecklist);
    entry.cleaningProduct = state.cleaningProduct;
    entry.statusFlags = Map.of(state.statusFlags);
    entry.measurements = List.of(state.measurements);
    entry.afterPhotos = Map.of(state.afterPhotos);
    if (completed) entry.isCompleted = true;
    await _box.put(_key, entry);
  }

  /// Simpan progress sebagai draft (dipanggil saat keluar wizard).
  Future<void> saveDraft() async {
    EasyDebounce.cancel(_debounceTag);
    await _save(false);
  }

  /// Simpan & tandai unit selesai. Return true bila valid & tersimpan.
  Future<bool> finishAndComplete() async {
    if (!state.isComplete) return false;
    EasyDebounce.cancel(_debounceTag);
    emit(state.copyWith(isSaving: true));
    await _save(true);
    return true;
  }
}
