import 'package:collection/collection.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../components/constants.dart';
import '../../../models/common/captured_image_detail.dart';
import '../../../models/common/measurement_entry.dart';
import '../../../models/common/note_option.dart';
import '../../../models/service_call_freezer/scf_validation_entry_model.dart';
import '../../../models/service_call_freezer/service_call_freezer_constants.dart';
import 'scf_validation_dropdown_state.dart';

/// Cubit wizard validasi 1 freezer Service Call (2 step: Sebelum & Sesudah).
///
/// Mengelola [ScfValidationEntryModel] per unit (key via [scfEntryKey]) di
/// [kServiceCallFreezerEntryBox] — offline-first, auto-save tiap perubahan.
/// Menggabungkan pola POSF (kondisi awal freezer) dan Service Call (pengukuran
/// Sebelum/Sesudah + Permasalahan & Solusi).
class ScfValidationDropdownCubit extends Cubit<ScfValidationDropdownState> {
  final String transNo;
  final String serialNo;
  final bool isGeneric;
  final int unitIndex;
  final String articleNo;
  final String articleDesc;
  final String unitType;

  /// Config skip-reason dari server (opsional). Menentukan alasan skip yang wajib
  /// keterangan+foto (require_remark) — fallback konstanta bila kosong.
  final List<NoteOption> skipReasonOptions;

  final Box<ScfValidationEntryModel> _box;

  String get _key => scfEntryKey(transNo, serialNo, isGeneric, unitIndex);
  String get _debounceTag => 'scf-val-save-$_key';

  ScfValidationDropdownCubit({
    required this.transNo,
    required this.serialNo,
    required this.isGeneric,
    required this.unitIndex,
    required this.articleNo,
    required this.articleDesc,
    this.unitType = 'FREEZER',
    this.skipReasonOptions = const [],
  })  : _box = Hive.box<ScfValidationEntryModel>(kServiceCallFreezerEntryBox),
        super(const ScfValidationDropdownState()) {
    _load();
  }

  // Set alasan skip yang wajib keterangan+foto: dari config server (require_remark
  // per opsi) bila ada, else konstanta dummy. Konsisten dgn UI body.
  Set<String> _resolveRequireRemark() {
    if (skipReasonOptions.isNotEmpty) {
      return skipReasonOptions
          .where((o) => o.requireRemark)
          .map((o) => o.label)
          .toSet();
    }
    return kScfSkipReasonsRequireRemark;
  }

  static const List<String> _linkedElectricalIds = ['ampere', 'volt'];

  List<String> linkedMeasurementIds(String id) =>
      _linkedElectricalIds.contains(id) ? _linkedElectricalIds : [id];

  bool _isElecGroup(String id) => _linkedElectricalIds.contains(id);

  List<MeasurementEntry> _freshMeasurements() => kScfMeasurements
      .map((l) => MeasurementEntry(
          measurementId: l.id, value: 0, unit: l.unit, isSkipped: false))
      .toList();

  /// Pengukuran yang sudah dianggap terkonfirmasi "sesuai foto" saat draft
  /// dibuka kembali: punya nilai (≠0) + foto dan TIDAK di-skip. Konsisten dengan
  /// konvensi "value+foto ⇒ confirmed" (mirror seed konfirmasi POS/POSF) sehingga
  /// gerbang Lanjut/Selesai langsung terbuka tanpa input ulang. Pengukuran yang
  /// di-skip divalidasi terpisah lewat [measurementsConfirmedForStep] (yang
  /// melewati item skip), jadi cukup kumpulkan yang non-skip di sini.
  Set<String> _confirmedFrom(List<MeasurementEntry> list) => list
      .where((m) =>
          !(m.isSkipped ?? false) && m.value != 0 && m.capturedImage != null)
      .map((m) => m.measurementId)
      .toSet();

  void _load() {
    final requireRemark = _resolveRequireRemark();
    final e = _box.get(_key);
    if (e != null) {
      emit(ScfValidationDropdownState(
        isLoaded: true,
        skipReasonsRequireRemark: requireRemark,
        arrivalTemp: e.arrivalTemp?.toString() ?? '',
        arrivalTempImage: e.arrivalTempImage,
        arrivalTempSkipped: e.arrivalTempSkipped,
        arrivalTempReason: e.arrivalTempReason,
        arrivalTempSkipRemark: e.arrivalTempSkipRemark ?? '',
        arrivalTempSkipPhotos: e.arrivalTempSkipPhotos ?? const [],
        generalCondition: e.generalCondition,
        complaint: e.complaint,
        conditionNote: e.conditionNote ?? '',
        conditionPhotos: List.of(e.conditionPhotos ?? const []),
        frostThickness: e.frostThickness,
        initialPhotos: _knownSlotPhotos(e.initialPhotos),
        initialNote: e.initialNote ?? '',
        measurementsBefore: e.measurementsBefore.isNotEmpty
            ? List.of(e.measurementsBefore)
            : _freshMeasurements(),
        measurementsAfter: e.measurementsAfter.isNotEmpty
            ? List.of(e.measurementsAfter)
            : _freshMeasurements(),
        afterPhotos: _knownSlotPhotos(e.afterPhotos),
        problemCards: e.problems
            .map((p) => ScfProblemCard(
                selectedProblemId: p.problemId,
                selectedSolutionIds: List.of(p.solutionIds)))
            .toList(),
        selectedUnitType: _validUnitType(e.unitType),
        tempSkipRemarkBefore: e.tempSkipRemarkBefore ?? '',
        tempSkipPhotosBefore: e.tempSkipPhotosBefore ?? const [],
        elecSkipRemarkBefore: e.elecSkipRemarkBefore ?? '',
        elecSkipPhotosBefore: e.elecSkipPhotosBefore ?? const [],
        tempSkipRemarkAfter: e.tempSkipRemarkAfter ?? '',
        tempSkipPhotosAfter: e.tempSkipPhotosAfter ?? const [],
        elecSkipRemarkAfter: e.elecSkipRemarkAfter ?? '',
        elecSkipPhotosAfter: e.elecSkipPhotosAfter ?? const [],
        // Pulihkan status konfirmasi "sesuai foto" dari data tersimpan supaya
        // tombol Lanjut/Selesai tidak terkunci saat draft dibuka kembali.
        confirmedBefore: _confirmedFrom(e.measurementsBefore),
        confirmedAfter: _confirmedFrom(e.measurementsAfter),
      ));
    } else {
      emit(ScfValidationDropdownState(
        isLoaded: true,
        measurementsBefore: _freshMeasurements(),
        measurementsAfter: _freshMeasurements(),
        skipReasonsRequireRemark: requireRemark,
      ));
    }
  }

  /// Buang foto slot yang sudah tidak dikenal wizard (mis. kunci 'display'
  /// dari draft sebelum Display Produk dihapus). Tanpa ini, foto lama tetap
  /// ikut terkirim di payload `images_initial` / `images_after` karena
  /// serialisasi memetakan seluruh isi map, bukan hanya slot aktif.
  Map<String, CapturedImageDetail> _knownSlotPhotos(
      Map<String, CapturedImageDetail> saved) {
    final known = kScfPhotoSlots.map((s) => s.id).toSet();
    return {
      for (final entry in saved.entries)
        if (known.contains(entry.key)) entry.key: entry.value,
    };
  }

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

  void goToStep(int step) => emit(state.copyWith(currentStep: step));

  // --- Konfirmasi "angka sesuai foto" (transient) ---
  void setMeasurementConfirmed(String id, bool confirmed,
      {required bool isBefore}) {
    final set = Set<String>.from(
        isBefore ? state.confirmedBefore : state.confirmedAfter);
    final changed = confirmed ? set.add(id) : set.remove(id);
    if (!changed) return;
    emit(isBefore
        ? state.copyWith(confirmedBefore: set)
        : state.copyWith(confirmedAfter: set));
  }

  bool measurementsConfirmedForStep(int step) {
    if (step == 0) {
      // Kondisi Freezer (termasuk suhu tiba) dihapus dari wizard: konfirmasi
      // "sesuai foto" cukup untuk pengukuran awal (Suhu/Ampere/Volt).
      for (final m in state.measurementsBefore) {
        if (m.isSkipped ?? false) continue;
        if (!state.confirmedBefore.contains(m.measurementId)) return false;
      }
      return true;
    }
    if (step == 1) {
      for (final m in state.measurementsAfter) {
        if (m.isSkipped ?? false) continue;
        if (!state.confirmedAfter.contains(m.measurementId)) return false;
      }
      return true;
    }
    return true;
  }

  // --- Step Sebelum: kondisi awal ---
  void arrivalTempChanged(String v) {
    emit(state.copyWith(arrivalTemp: v));
    _scheduleSave();
  }

  void arrivalTempImageChanged(CapturedImageDetail? image) {
    emit(image == null
        ? state.copyWith(clearArrivalTempImage: true)
        : state.copyWith(arrivalTempImage: image));
    _scheduleSave();
  }

  void arrivalTempSkipChanged(bool skipped) {
    if (skipped) {
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
    if (v == state.generalCondition) return;
    emit(state.copyWith(
      generalCondition: v,
      clearComplaint: true,
      conditionNote: '',
      conditionPhotos: const [],
    ));
    _scheduleSave();
  }

  void complaintChanged(String? v) {
    emit(v == null || v.isEmpty
        ? state.copyWith(clearComplaint: true)
        : state.copyWith(complaint: v));
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

  // --- Pengukuran (before / after) ---
  List<MeasurementEntry> _listFor(bool isBefore) =>
      isBefore ? state.measurementsBefore : state.measurementsAfter;

  void _emitMeasurements(List<MeasurementEntry> list, bool isBefore) {
    emit(isBefore
        ? state.copyWith(measurementsBefore: list)
        : state.copyWith(measurementsAfter: list));
  }

  void measurementValueChanged(String id, String value,
      {required bool isBefore}) {
    final list = _listFor(isBefore)
        .map((e) => e.measurementId == id
            ? e.copyWith(value: double.tryParse(value) ?? 0)
            : e)
        .toList();
    _emitMeasurements(list, isBefore);
    _scheduleSave();
  }

  void measurementImageChanged(String id, CapturedImageDetail? image,
      {required bool isBefore}) {
    final list = _listFor(isBefore)
        .map((e) => e.measurementId == id
            ? (image == null
                ? e.copyWith(clearCapturedImage: true)
                : e.copyWith(capturedImage: image))
            : e)
        .toList();
    _emitMeasurements(list, isBefore);
    _scheduleSave();
  }

  void measurementSkipChanged(String id, bool skipped,
      {required bool isBefore}) {
    final targets = linkedMeasurementIds(id).toSet();
    final list = _listFor(isBefore).map((e) {
      if (!targets.contains(e.measurementId)) return e;
      return skipped
          ? e.copyWith(isSkipped: true, value: 0, clearCapturedImage: true)
          : e.copyWith(isSkipped: false, remark: '');
    }).toList();
    _emitMeasurements(list, isBefore);
    // Unskip -> reset remark + foto bukti grup.
    if (!skipped) _resetSkipEvidence(id, isBefore);
    _scheduleSave();
  }

  void measurementReasonChanged(String id, String? reason,
      {required bool isBefore}) {
    final targets = linkedMeasurementIds(id).toSet();
    final list = _listFor(isBefore)
        .map((e) => targets.contains(e.measurementId)
            ? e.copyWith(remark: reason ?? '')
            : e)
        .toList();
    _emitMeasurements(list, isBefore);
    _resetSkipEvidence(id, isBefore); // ganti alasan -> reset bukti
    _scheduleSave();
  }

  void _resetSkipEvidence(String id, bool isBefore) {
    if (_isElecGroup(id)) {
      emit(isBefore
          ? state.copyWith(
              elecSkipRemarkBefore: '', elecSkipPhotosBefore: const [])
          : state.copyWith(
              elecSkipRemarkAfter: '', elecSkipPhotosAfter: const []));
    } else {
      emit(isBefore
          ? state.copyWith(
              tempSkipRemarkBefore: '', tempSkipPhotosBefore: const [])
          : state.copyWith(
              tempSkipRemarkAfter: '', tempSkipPhotosAfter: const []));
    }
  }

  void measurementSkipRemarkChanged(String id, String v,
      {required bool isBefore}) {
    if (_isElecGroup(id)) {
      emit(isBefore
          ? state.copyWith(elecSkipRemarkBefore: v)
          : state.copyWith(elecSkipRemarkAfter: v));
    } else {
      emit(isBefore
          ? state.copyWith(tempSkipRemarkBefore: v)
          : state.copyWith(tempSkipRemarkAfter: v));
    }
    _scheduleSave();
  }

  void addMeasurementSkipPhoto(String id, CapturedImageDetail img,
      {required bool isBefore}) {
    final current = state.skipPhotosFor(id, isBefore: isBefore);
    final updated = [...current, img];
    _emitSkipPhotos(id, isBefore, updated);
    _scheduleSave();
  }

  void removeMeasurementSkipPhoto(String id, String path,
      {required bool isBefore}) {
    final updated = state
        .skipPhotosFor(id, isBefore: isBefore)
        .where((p) => p.imagePath != path)
        .toList();
    _emitSkipPhotos(id, isBefore, updated);
    _scheduleSave();
  }

  void _emitSkipPhotos(
      String id, bool isBefore, List<CapturedImageDetail> photos) {
    if (_isElecGroup(id)) {
      emit(isBefore
          ? state.copyWith(elecSkipPhotosBefore: photos)
          : state.copyWith(elecSkipPhotosAfter: photos));
    } else {
      emit(isBefore
          ? state.copyWith(tempSkipPhotosBefore: photos)
          : state.copyWith(tempSkipPhotosAfter: photos));
    }
  }

  // --- Foto setelah (slot) ---
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

  // --- Sumber Permasalahan (Unit Type) ---
  static const List<String> _validUnitTypes = ['UNIT', 'NON_UNIT'];

  String? _validUnitType(String? raw) =>
      raw != null && _validUnitTypes.contains(raw) ? raw : null;

  /// Ganti sumber permasalahan. Mengganti (mengosongkan) seluruh kartu
  /// Permasalahan & Solusi — mirror SC ValidationDropdownBloc._onSelectUnitType.
  void unitTypeChanged(String unitType) {
    if (unitType == state.selectedUnitType) return;
    emit(state.copyWith(selectedUnitType: unitType, problemCards: const []));
    _scheduleSave();
  }

  // --- Permasalahan & Solusi (pola SC: 1 kartu per permasalahan terpilih) ---
  /// Tambah kartu dari dialog. Tolak duplikat permasalahan
  /// (mirror SC ValidationDropdownBloc._onAddProblemCard).
  void addProblemCardFromDialog(String problemId, List<String> solutionIds) {
    if (state.problemCards.any((c) => c.selectedProblemId == problemId)) return;
    emit(state.copyWith(problemCards: [
      ...state.problemCards,
      ScfProblemCard(
          selectedProblemId: problemId,
          selectedSolutionIds: List.of(solutionIds)),
    ]));
    _scheduleSave();
  }

  /// Hapus kartu berdasarkan problemId (mirror SC._onRemoveProblemCard).
  void removeProblemCardById(String problemId) {
    final list = state.problemCards
        .where((c) => c.selectedProblemId != problemId)
        .toList();
    emit(state.copyWith(problemCards: list));
    _scheduleSave();
  }

  // --- Persistence ---
  void _scheduleSave() {
    EasyDebounce.debounce(
        _debounceTag, const Duration(milliseconds: 400), () => _save(false));
  }

  String? _groupReason(List<MeasurementEntry> list, Set<String> ids) {
    return list
        .firstWhereOrNull(
            (m) => ids.contains(m.measurementId) && (m.isSkipped ?? false))
        ?.remark;
  }

  Future<void> _save(bool completed) async {
    final entry =
        _box.get(_key) ?? ScfValidationEntryModel(transNo: transNo, serialNo: serialNo);
    entry.transNo = transNo;
    entry.serialNo = serialNo;
    entry.isGeneric = isGeneric;
    entry.unitIndex = unitIndex;
    entry.articleNo = articleNo;
    entry.articleDesc = articleDesc;
    // Persist sumber permasalahan terpilih (UNIT/NON_UNIT). Fallback ke unitType
    // konstruktor bila belum dipilih (mis. draft awal).
    entry.unitType = state.selectedUnitType ?? unitType;
    entry.generalCondition = state.generalCondition;
    entry.complaint = state.complaint;
    entry.conditionNote = state.conditionNote;
    entry.conditionPhotos = List.of(state.conditionPhotos);

    entry.problems = state.problemCards
        .where((c) =>
            c.selectedProblemId != null && c.selectedProblemId!.isNotEmpty)
        .map((c) => ScfValidationProblem(
            problemId: c.selectedProblemId!,
            solutionIds: List.of(c.selectedSolutionIds)))
        .toList();

    if (state.hasUnused) {
      // "Tidak terpakai": jangan simpan data Sebelum/Sesudah (dokumentasi saja).
      entry.arrivalTemp = null;
      entry.arrivalTempImage = null;
      entry.arrivalTempSkipped = false;
      entry.arrivalTempReason = null;
      entry.arrivalTempSkipRemark = null;
      entry.arrivalTempSkipPhotos = [];
      entry.frostThickness = null;
      entry.initialPhotos = {};
      entry.initialNote = null;
      entry.measurementsBefore = [];
      entry.measurementsAfter = [];
      entry.afterPhotos = {};
      entry.selectedTempNoteBefore = null;
      entry.selectedElecNoteBefore = null;
      entry.selectedTempNoteAfter = null;
      entry.selectedElecNoteAfter = null;
      entry.tempSkipRemarkBefore = null;
      entry.tempSkipPhotosBefore = [];
      entry.elecSkipRemarkBefore = null;
      entry.elecSkipPhotosBefore = [];
      entry.tempSkipRemarkAfter = null;
      entry.tempSkipPhotosAfter = [];
      entry.elecSkipRemarkAfter = null;
      entry.elecSkipPhotosAfter = [];
      entry.problems = [];
    } else {
      entry.arrivalTemp = double.tryParse(state.arrivalTemp);
      entry.arrivalTempImage = state.arrivalTempImage;
      entry.arrivalTempSkipped = state.arrivalTempSkipped;
      entry.arrivalTempReason = state.arrivalTempReason;
      entry.arrivalTempSkipRemark = state.arrivalTempSkipRemark;
      entry.arrivalTempSkipPhotos = List.of(state.arrivalTempSkipPhotos);
      entry.frostThickness = state.frostThickness;
      entry.initialPhotos = Map.of(state.initialPhotos);
      entry.initialNote = state.initialNote;
      entry.measurementsBefore = List.of(state.measurementsBefore);
      entry.measurementsAfter = List.of(state.measurementsAfter);
      entry.afterPhotos = Map.of(state.afterPhotos);

      const tempIds = {'temperature'};
      const elecIds = {'ampere', 'volt'};
      entry.selectedTempNoteBefore =
          _groupReason(state.measurementsBefore, tempIds);
      entry.selectedElecNoteBefore =
          _groupReason(state.measurementsBefore, elecIds);
      entry.selectedTempNoteAfter =
          _groupReason(state.measurementsAfter, tempIds);
      entry.selectedElecNoteAfter =
          _groupReason(state.measurementsAfter, elecIds);

      entry.tempSkipRemarkBefore = state.tempSkipRemarkBefore;
      entry.tempSkipPhotosBefore = List.of(state.tempSkipPhotosBefore);
      entry.elecSkipRemarkBefore = state.elecSkipRemarkBefore;
      entry.elecSkipPhotosBefore = List.of(state.elecSkipPhotosBefore);
      entry.tempSkipRemarkAfter = state.tempSkipRemarkAfter;
      entry.tempSkipPhotosAfter = List.of(state.tempSkipPhotosAfter);
      entry.elecSkipRemarkAfter = state.elecSkipRemarkAfter;
      entry.elecSkipPhotosAfter = List.of(state.elecSkipPhotosAfter);
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
    emit(state.copyWith(isSaving: true, saveStatus: ScfSaveStatus.saving));
    await _save(true);
    emit(state.copyWith(isSaving: false, saveStatus: ScfSaveStatus.successFinal));
    return true;
  }
}
