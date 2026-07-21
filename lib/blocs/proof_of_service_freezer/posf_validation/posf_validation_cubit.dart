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

/// Cubit wizard validasi 1 freezer (2 step: Sebelum & Sesudah).
/// Memuat/menyimpan [ProofOfServiceFreezerEntryModel] ke
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
        arrivalTempSkipped: e.arrivalTempSkipped,
        arrivalTempReason: e.arrivalTempReason,
        generalCondition: e.generalCondition,
        complaint: e.complaint,
        frostThickness: e.frostThickness,
        initialPhotos: Map.of(e.initialPhotos),
        initialNote: e.initialNote ?? '',
        conditionNote: e.conditionNote ?? '',
        conditionPhotos: List.of(e.conditionPhotos ?? const []),
        measurements:
            e.measurements.isNotEmpty ? List.of(e.measurements) : _freshMeasurements(),
        afterPhotos: Map.of(e.afterPhotos),
        arrivalTempSkipRemark: e.arrivalTempSkipRemark ?? '',
        arrivalTempSkipPhotos: e.arrivalTempSkipPhotos ?? const [],
        tempSkipRemark: e.tempSkipRemark ?? '',
        tempSkipPhotos: e.tempSkipPhotos ?? const [],
        elecSkipRemark: e.elecSkipRemark ?? '',
        elecSkipPhotos: e.elecSkipPhotos ?? const [],
      ));
    } else {
      emit(PosfValidationState(
        isLoaded: true,
        measurements: _freshMeasurements(),
      ));
    }
  }

  List<MeasurementEntry> _freshMeasurements() => kPosfMeasurements
      .map((l) => MeasurementEntry(
          measurementId: l.id, value: 0, unit: l.unit, isSkipped: false))
      .toList();

  // --- Navigasi step ---
  void nextStep() {
    if (state.currentStep < 1) {
      emit(state.copyWith(currentStep: state.currentStep + 1));
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1));
    }
  }

  // --- Step Sebelum ---
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

  void arrivalTempSkipChanged(bool skipped) {
    if (skipped) {
      // Tidak bisa diukur -> kosongkan nilai & foto, alasan menyusul.
      emit(state.copyWith(
        arrivalTempSkipped: true,
        arrivalTemp: '',
        clearArrivalTempImage: true,
      ));
    } else {
      emit(state.copyWith(
        arrivalTempSkipped: false,
        clearArrivalTempReason: true,
        arrivalTempSkipRemark: '',
        arrivalTempSkipPhotos: const [],
      ));
    }
    _scheduleSave();
  }

  void arrivalTempReasonChanged(String? v) {
    // Ganti alasan = reset remark + foto bukti (bukti mengikuti alasan).
    if (v == null || v.isEmpty) {
      emit(state.copyWith(
        clearArrivalTempReason: true,
        arrivalTempSkipRemark: '',
        arrivalTempSkipPhotos: const [],
      ));
    } else {
      emit(state.copyWith(
        arrivalTempReason: v,
        arrivalTempSkipRemark: '',
        arrivalTempSkipPhotos: const [],
      ));
    }
    _scheduleSave();
  }

  void arrivalTempSkipRemarkChanged(String v) {
    emit(state.copyWith(arrivalTempSkipRemark: v));
    _scheduleSave();
  }

  void addArrivalTempSkipPhoto(CapturedImageDetail img) {
    emit(state.copyWith(
        arrivalTempSkipPhotos: [...state.arrivalTempSkipPhotos, img]));
    _scheduleSave();
  }

  void removeArrivalTempSkipPhoto(String path) {
    emit(state.copyWith(
        arrivalTempSkipPhotos: state.arrivalTempSkipPhotos
            .where((p) => p.imagePath != path)
            .toList()));
    _scheduleSave();
  }

  void generalConditionChanged(String v) {
    // Tap ulang chip yang sudah terpilih = no-op (jangan hapus reason/note/foto).
    if (v == state.generalCondition) return;
    // Ganti kondisi → reset detail (reason + note + foto) karena tiap kondisi
    // punya daftar alasan sendiri.
    emit(state.copyWith(
      generalCondition: v,
      clearComplaint: true,
      conditionNote: '',
      conditionPhotos: const [],
    ));
    _scheduleSave();
  }

  // Alasan terpilih untuk kondisi non-Normal (keluhan / tidak terpakai).
  void complaintChanged(String? v) {
    if (v == null || v.isEmpty) {
      emit(state.copyWith(clearComplaint: true));
    } else {
      emit(state.copyWith(complaint: v));
    }
    _scheduleSave();
  }

  void conditionNoteChanged(String v) {
    emit(state.copyWith(conditionNote: v));
    _scheduleSave();
  }

  void addConditionPhoto(CapturedImageDetail img) {
    emit(state.copyWith(conditionPhotos: [...state.conditionPhotos, img]));
    _scheduleSave();
  }

  void removeConditionPhoto(String path) {
    emit(state.copyWith(
        conditionPhotos: state.conditionPhotos
            .where((p) => p.imagePath != path)
            .toList()));
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

  // --- Step Sesudah ---
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

  // Arus & Tegangan diukur bersama (1 alat). Skip/reason-nya saling terkait:
  // skip salah satu -> dua-duanya skip; reason cukup satu (pola installation).
  static const List<String> kPosfLinkedElectricalIds = ['ampere', 'volt'];

  List<String> linkedMeasurementIds(String id) =>
      kPosfLinkedElectricalIds.contains(id)
          ? kPosfLinkedElectricalIds
          : [id];

  // Grup bukti skip: 'temperature' -> tempSkip*, 'ampere'/'volt' -> elecSkip*.
  bool _isElecGroup(String id) => kPosfLinkedElectricalIds.contains(id);

  void measurementSkipChanged(String id, bool skipped) {
    final targets = linkedMeasurementIds(id).toSet();
    final updated = state.measurements.map((e) {
      if (!targets.contains(e.measurementId)) return e;
      return skipped
          ? e.copyWith(isSkipped: true, value: 0, clearCapturedImage: true)
          : e.copyWith(isSkipped: false, remark: ''); // unskip -> hapus alasan
    }).toList();
    // Unskip -> remark + foto bukti grup ikut di-reset.
    if (!skipped) {
      emit(state.copyWith(
        measurements: updated,
        tempSkipRemark: _isElecGroup(id) ? null : '',
        tempSkipPhotos: _isElecGroup(id) ? null : const [],
        elecSkipRemark: _isElecGroup(id) ? '' : null,
        elecSkipPhotos: _isElecGroup(id) ? const [] : null,
      ));
    } else {
      emit(state.copyWith(measurements: updated));
    }
    _scheduleSave();
  }

  // Alasan "tidak bisa diukur" (disimpan di remark). Untuk pasangan terkait
  // (Arus & Tegangan) alasan diset ke dua-duanya sekaligus.
  // Ganti alasan = reset remark + foto bukti grup (bukti mengikuti alasan).
  void measurementReasonChanged(String id, String? reason) {
    final targets = linkedMeasurementIds(id).toSet();
    final updated = state.measurements
        .map((e) =>
            targets.contains(e.measurementId) ? e.copyWith(remark: reason ?? '') : e)
        .toList();
    emit(state.copyWith(
      measurements: updated,
      tempSkipRemark: _isElecGroup(id) ? null : '',
      tempSkipPhotos: _isElecGroup(id) ? null : const [],
      elecSkipRemark: _isElecGroup(id) ? '' : null,
      elecSkipPhotos: _isElecGroup(id) ? const [] : null,
    ));
    _scheduleSave();
  }

  void measurementSkipRemarkChanged(String id, String v) {
    emit(_isElecGroup(id)
        ? state.copyWith(elecSkipRemark: v)
        : state.copyWith(tempSkipRemark: v));
    _scheduleSave();
  }

  void addMeasurementSkipPhoto(String id, CapturedImageDetail img) {
    emit(_isElecGroup(id)
        ? state.copyWith(elecSkipPhotos: [...state.elecSkipPhotos, img])
        : state.copyWith(tempSkipPhotos: [...state.tempSkipPhotos, img]));
    _scheduleSave();
  }

  void removeMeasurementSkipPhoto(String id, String path) {
    emit(_isElecGroup(id)
        ? state.copyWith(
            elecSkipPhotos: state.elecSkipPhotos
                .where((p) => p.imagePath != path)
                .toList())
        : state.copyWith(
            tempSkipPhotos: state.tempSkipPhotos
                .where((p) => p.imagePath != path)
                .toList()));
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
    entry.arrivalTempSkipped = state.arrivalTempSkipped;
    entry.arrivalTempReason = state.arrivalTempReason;
    entry.generalCondition = state.generalCondition;
    entry.complaint = state.complaint;
    entry.conditionNote = state.conditionNote;
    entry.conditionPhotos = List.of(state.conditionPhotos);

    if (state.hasUnused) {
      // "Tidak terpakai": freezer tidak dikerjakan. Jangan simpan data
      // Sebelum/Sesudah (suhu, ketebalan, foto standar, pengukuran) walaupun
      // sempat terisi lalu kondisi diganti — cegah data hantu terkirim.
      entry.arrivalTemp = null;
      entry.arrivalTempImage = null;
      entry.arrivalTempSkipped = false;
      entry.arrivalTempReason = null;
      entry.frostThickness = null;
      entry.initialPhotos = {};
      entry.initialNote = null;
      entry.measurements = [];
      entry.afterPhotos = {};
      entry.arrivalTempSkipRemark = null;
      entry.arrivalTempSkipPhotos = [];
      entry.tempSkipRemark = null;
      entry.tempSkipPhotos = [];
      entry.elecSkipRemark = null;
      entry.elecSkipPhotos = [];
    } else {
      entry.arrivalTemp = double.tryParse(state.arrivalTemp);
      entry.arrivalTempImage = state.arrivalTempImage;
      entry.arrivalTempSkipped = state.arrivalTempSkipped;
      entry.arrivalTempReason = state.arrivalTempReason;
      entry.frostThickness = state.frostThickness;
      entry.initialPhotos = Map.of(state.initialPhotos);
      entry.initialNote = state.initialNote;
      entry.measurements = List.of(state.measurements);
      entry.afterPhotos = Map.of(state.afterPhotos);
      entry.arrivalTempSkipRemark = state.arrivalTempSkipRemark;
      entry.arrivalTempSkipPhotos = List.of(state.arrivalTempSkipPhotos);
      entry.tempSkipRemark = state.tempSkipRemark;
      entry.tempSkipPhotos = List.of(state.tempSkipPhotos);
      entry.elecSkipRemark = state.elecSkipRemark;
      entry.elecSkipPhotos = List.of(state.elecSkipPhotos);
    }
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
