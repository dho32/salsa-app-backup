import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart'
    show SelectedProblemCard;
import '../../../../blocs/service_call_freezer/scf_validation_dropdown/scf_validation_dropdown_cubit.dart';
import '../../../../blocs/service_call_freezer/scf_validation_dropdown/scf_validation_dropdown_state.dart';
import '../../../../components/services/photo_capture_service.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/common/measurement_entry.dart';
import '../../../../models/common/measurement_limits.dart';
import '../../../../models/common/note_option.dart';
import '../../../../models/service_call/problem_source_model.dart';
import '../../../../models/service_call_freezer/service_call_freezer_constants.dart';
import '../../../service_call/service_call_validation/components/widgets/service_call_validation_widgets.dart';

class ScfValidationBodyMobile extends StatefulWidget {
  final String serialNo;
  final String articleDesc;
  final String storeName;
  final List<ProblemSourceModel> problems;

  /// Config skip-reason dari server (detail) — menentukan opsi & require_remark.
  final List<NoteOption> skipReasonOptions;

  /// Override batas pengukuran dari server (`measurements.limits_validation_unit`),
  /// per measurement id, untuk step Sebelum & Sesudah. Kosong → pakai konstanta
  /// lokal [kScfMeasurements]. Set pengukuran (suhu/ampere/volt) tetap dari
  /// konstanta; yang di-override hanya batas/label/unit-nya — pola sama POS & SC.
  final Map<String, MeasurementLimits> customLimitsBefore;
  final Map<String, MeasurementLimits> customLimitsAfter;

  const ScfValidationBodyMobile({
    super.key,
    required this.serialNo,
    required this.articleDesc,
    this.storeName = '',
    this.problems = const [],
    this.skipReasonOptions = const [],
    this.customLimitsBefore = const {},
    this.customLimitsAfter = const {},
  });

  @override
  State<ScfValidationBodyMobile> createState() =>
      _ScfValidationBodyMobileState();
}

class _ScfValidationBodyMobileState extends State<ScfValidationBodyMobile> {
  static const _stepTitles = ['Sebelum', 'Sesudah'];
  static const _stepCount = 2;

  final _initialNoteController = TextEditingController();
  final _tempSkipRemarkBeforeController = TextEditingController();
  final _elecSkipRemarkBeforeController = TextEditingController();
  final _tempSkipRemarkAfterController = TextEditingController();
  final _elecSkipRemarkAfterController = TextEditingController();

  // Controller pengukuran per fase (prefix 'b_' Sebelum, 'a_' Sesudah).
  final Map<String, TextEditingController> _measurementControllers = {
    for (final m in kScfMeasurements) 'b_${m.id}': TextEditingController(),
    for (final m in kScfMeasurements) 'a_${m.id}': TextEditingController(),
  };

  bool _controllersReady = false;
  bool _capturingInitial = false;
  bool _capturingAfter = false;
  String? _capturingSkipGroup;

  ScfValidationDropdownCubit get _cubit =>
      context.read<ScfValidationDropdownCubit>();

  // Opsi alasan skip: label dari config server bila ada, else konstanta dummy.
  List<String> get _skipReasons {
    final cfg = widget.skipReasonOptions;
    return cfg.isNotEmpty ? cfg.map((o) => o.label).toList() : kScfSkipReasons;
  }

  // require_remark per alasan: dari config server bila ada, else konstanta dummy.
  // Konsisten dengan set di state (isSkipReasonComplete).
  bool _skipReasonRequiresRemark(String reason) {
    final cfg = widget.skipReasonOptions;
    if (cfg.isNotEmpty) {
      for (final o in cfg) {
        if (o.label == reason) return o.requireRemark;
      }
      return false;
    }
    return kScfSkipReasonsRequireRemark.contains(reason);
  }

  // Batas pengukuran efektif untuk satu step: override server menimpa konstanta
  // lokal per measurement id. Urutan & jumlah pengukuran selalu mengikuti
  // kScfMeasurements, jadi key controller dan gating tetap konsisten.
  List<MeasurementLimits> _limitsFor({required bool isBefore}) {
    final overrides =
        isBefore ? widget.customLimitsBefore : widget.customLimitsAfter;
    if (overrides.isEmpty) return kScfMeasurements;
    return kScfMeasurements.map((l) => overrides[l.id] ?? l).toList();
  }

  @override
  void dispose() {
    _initialNoteController.dispose();
    _tempSkipRemarkBeforeController.dispose();
    _elecSkipRemarkBeforeController.dispose();
    _tempSkipRemarkAfterController.dispose();
    _elecSkipRemarkAfterController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(ScfValidationDropdownState s) {
    if (_controllersReady) return;
    _initialNoteController.text = s.initialNote;
    _tempSkipRemarkBeforeController.text = s.tempSkipRemarkBefore;
    _elecSkipRemarkBeforeController.text = s.elecSkipRemarkBefore;
    _tempSkipRemarkAfterController.text = s.tempSkipRemarkAfter;
    _elecSkipRemarkAfterController.text = s.elecSkipRemarkAfter;
    for (final m in s.measurementsBefore) {
      _measurementControllers['b_${m.measurementId}']?.text =
          m.value == 0 ? '' : m.value.toString();
    }
    for (final m in s.measurementsAfter) {
      _measurementControllers['a_${m.measurementId}']?.text =
          m.value == 0 ? '' : m.value.toString();
    }
    _controllersReady = true;
  }

  int _effectiveStepCount(ScfValidationDropdownState s) =>
      s.hasUnused ? 1 : _stepCount;

  Future<void> _onExit() async {
    final cubit = _cubit;
    if (cubit.state.isComplete) {
      await cubit.saveDraft();
      if (mounted) Navigator.pop(context);
      return;
    }
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari validasi?'),
        content: const Text(
            'Progres akan disimpan sebagai draft dan bisa dilanjutkan nanti.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar')),
        ],
      ),
    );
    if (keluar == true) {
      await cubit.saveDraft();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScfValidationDropdownCubit, ScfValidationDropdownState>(
      listener: (context, state) {
        if (state.isLoaded) _initControllers(state);
      },
      builder: (context, state) {
        if (!state.isLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        // Seed controller pengukuran dari draft juga di sini (bukan hanya lewat
        // listener): cubit memuat draft secara sinkron di konstruktor sehingga
        // state 'isLoaded' sudah aktif sebelum listener ter-subscribe — listener
        // tak pernah menyala untuk state awal, jadi tanpa ini nilai pengukuran
        // Sebelum/Sesudah tidak terisi ulang saat wizard dibuka kembali.
        _initControllers(state);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _onExit();
          },
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bg_app.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back), onPressed: _onExit),
                title:
                    Text(widget.articleDesc, style: const TextStyle(fontSize: 16)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(16),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                        widget.serialNo.isEmpty ? 'Generic' : widget.serialNo,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white70)),
                  ),
                ),
              ),
              body: Column(
                children: [
                  _buildStepHeader(state),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: _buildStepContent(state),
                    ),
                  ),
                  _buildNavButtons(state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Header progress
  // ---------------------------------------------------------------------------
  Widget _buildStepHeader(ScfValidationDropdownState s) {
    final int stepCount = _effectiveStepCount(s);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${s.currentStep + 1} dari $stepCount',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_stepTitles[s.currentStep],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(stepCount, (i) {
              final done = i < s.currentStep || s.isStepValid(i);
              final active = i == s.currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < stepCount - 1 ? 6 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).primaryColor
                        : (done ? Colors.green : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ScfValidationDropdownState s) {
    switch (s.currentStep) {
      case 0:
        return _buildStepBefore(s);
      case 1:
        return _buildStepAfter(s);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Step Sebelum
  // ---------------------------------------------------------------------------
  Widget _buildStepBefore(ScfValidationDropdownState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Foto Kondisi Awal', _buildInitialPhotoSlots(s)),
        _card(
          'Pengukuran Awal (Sebelum)',
          _buildMeasurementSection(s, isBefore: true),
        ),
        _card(
          'Catatan kondisi awal (opsional)',
          TextField(
            controller: _initialNoteController,
            maxLines: 3,
            onChanged: _cubit.initialNoteChanged,
            decoration: _inputDecoration('Keluhan dari pihak outlet, dll.'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step Sesudah
  // ---------------------------------------------------------------------------
  Widget _buildStepAfter(ScfValidationDropdownState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card('Foto Setelah Perbaikan', _buildAfterPhotoSlots(s)),
        _card(
          'Pengukuran Aktual (Sesudah)',
          _buildMeasurementSection(s, isBefore: false),
        ),
        _card('Permasalahan & Solusi', _buildProblemSection(s)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Pengukuran (before / after)
  // ---------------------------------------------------------------------------
  Widget _buildMeasurementSection(ScfValidationDropdownState s,
      {required bool isBefore}) {
    final list = isBefore ? s.measurementsBefore : s.measurementsAfter;
    final prefix = isBefore ? 'b_' : 'a_';
    return Column(
      children: [
        for (final limit in _limitsFor(isBefore: isBefore))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              children: [
                MeasurementInputWidget(
                  controller: _measurementControllers['$prefix${limit.id}']!,
                  transNo: _cubit.transNo,
                  storeName: widget.storeName,
                  label: limit.label,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  limits: limit,
                  initialImage: _measurementFor(list, limit.id)?.capturedImage,
                  isSkipEnabled: true,
                  isSkipped: _measurementFor(list, limit.id)?.isSkipped ?? false,
                  onChanged: (v) => _cubit.measurementValueChanged(limit.id, v,
                      isBefore: isBefore),
                  onEditingComplete: (v) => _cubit
                      .measurementValueChanged(limit.id, v, isBefore: isBefore),
                  onImageChanged: (img) => _cubit
                      .measurementImageChanged(limit.id, img, isBefore: isBefore),
                  enableConfirmDialog: true,
                  onConfirmedChanged: (c) => _cubit
                      .setMeasurementConfirmed(limit.id, c, isBefore: isBefore),
                  onSkipChanged: (skip) {
                    if (skip) {
                      for (final mid in _cubit.linkedMeasurementIds(limit.id)) {
                        _measurementControllers['$prefix$mid']?.clear();
                        _cubit.setMeasurementConfirmed(mid, false,
                            isBefore: isBefore);
                      }
                    }
                    _cubit.measurementSkipChanged(limit.id, skip,
                        isBefore: isBefore);
                  },
                ),
                if ((_measurementFor(list, limit.id)?.isSkipped ?? false) &&
                    limit.id != 'ampere')
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _buildSkipReasonSection(
                      reason: _measurementFor(list, limit.id)?.remark,
                      onReasonChanged: (r) {
                        _skipRemarkController(limit.id, isBefore).clear();
                        _cubit.measurementReasonChanged(limit.id, r,
                            isBefore: isBefore);
                      },
                      remarkController:
                          _skipRemarkController(limit.id, isBefore),
                      onRemarkChanged: (v) => _cubit.measurementSkipRemarkChanged(
                          limit.id, v,
                          isBefore: isBefore),
                      photos: s.skipPhotosFor(limit.id, isBefore: isBefore),
                      photoGroup:
                          '${isBefore ? 'b' : 'a'}_${limit.id == 'temperature' ? 'temp' : 'elec'}',
                      photoLabel: limit.id == 'temperature'
                          ? 'Bukti Kendala Suhu'
                          : 'Bukti Kendala Arus & Tegangan',
                      onPhotoCaptured: (img) => _cubit.addMeasurementSkipPhoto(
                          limit.id, img,
                          isBefore: isBefore),
                      onPhotoRemoved: (path) => _cubit
                          .removeMeasurementSkipPhoto(limit.id, path,
                              isBefore: isBefore),
                      label: limit.id == 'volt'
                          ? 'Alasan tidak bisa diukur (Arus & Tegangan)'
                          : 'Alasan tidak bisa diukur',
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  TextEditingController _skipRemarkController(String id, bool isBefore) {
    final isElec = id != 'temperature';
    if (isBefore) {
      return isElec
          ? _elecSkipRemarkBeforeController
          : _tempSkipRemarkBeforeController;
    }
    return isElec
        ? _elecSkipRemarkAfterController
        : _tempSkipRemarkAfterController;
  }

  MeasurementEntry? _measurementFor(List<MeasurementEntry> list, String id) {
    for (final m in list) {
      if (m.measurementId == id) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Permasalahan & Solusi
  // ---------------------------------------------------------------------------
  //
  // Faithful copy of the SC AC flow. UI reuses SC's shared widgets
  // (buildUnitTypeSelector / showDialogAddProblem / buildProblemCard) so the
  // look & behavior are identical; only the driving state changes (cubit).
  Widget _buildProblemSection(ScfValidationDropdownState s) {
    final problemsForType = _problemsForSelectedType(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selektor sumber permasalahan (UNIT / NON_UNIT) — ganti tipe akan
        // mengosongkan seluruh kartu (mirror SC).
        buildUnitTypeSelector(
          context: context,
          groupValue: s.selectedUnitType,
          onChanged: (value) {
            if (value != null) _cubit.unitTypeChanged(value);
          },
        ),
        const SizedBox(height: 4),
        // Kartu permasalahan tersimpan (swipe-to-dismiss + dialog konfirmasi,
        // chip solusi read-only) — identik SC.
        for (final card in s.problemCards)
          _buildScProblemCard(card, problemsForType),
        // Tombol tambah — label & style identik SC.
        _buildButtonAddProblem(s, problemsForType),
      ],
    );
  }

  List<Problem> _problemsForSelectedType(ScfValidationDropdownState s) {
    return widget.problems
        .firstWhere(
          (e) => e.unitType == s.selectedUnitType,
          orElse: () => ProblemSourceModel(unitType: '', problems: []),
        )
        .problems;
  }

  Widget _buildScProblemCard(
      ScfProblemCard card, List<Problem> problemsForType) {
    final selectedProblem = problemsForType
        .firstWhereOrNull((p) => p.causeId == card.selectedProblemId);
    final selectedSolutions = selectedProblem?.solutions
            .where((sol) => card.selectedSolutionIds.contains(sol.solutionId))
            .toList() ??
        <Solution>[];
    return buildProblemCard(
      context: context,
      card: SelectedProblemCard(
        selectedProblemId: card.selectedProblemId,
        selectedSolutionIds: card.selectedSolutionIds,
      ),
      selectedProblem: selectedProblem,
      selectedSolutions: selectedSolutions,
      onRemove: () {
        if (card.selectedProblemId != null) {
          _cubit.removeProblemCardById(card.selectedProblemId!);
        }
      },
    );
  }

  Widget _buildButtonAddProblem(
      ScfValidationDropdownState s, List<Problem> problemsForType) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Permasalahan & Solusi'),
        onPressed: () => _handleAddProblem(s, problemsForType),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
        ),
      ),
    );
  }

  // Modal AlertDialog SC: dropdown permasalahan (difilter tipe unit) + picker
  // solusi berbasis chip, guard duplikat, wajib ≥1 solusi (semua di dalam
  // showDialogAddProblem yang dipakai ulang dari SC).
  void _handleAddProblem(
      ScfValidationDropdownState s, List<Problem> problemsForType) {
    final existingProblemIds = s.problemCards
        .map((c) => c.selectedProblemId)
        .whereType<String>()
        .toList();
    showDialogAddProblem(
      context: context,
      problems: problemsForType,
      existingProblemIds: existingProblemIds,
      onAdd: (problemId, solutionIds) =>
          _cubit.addProblemCardFromDialog(problemId, solutionIds),
    );
  }

  // ---------------------------------------------------------------------------
  // Skip reason section (dropdown + remark + evidence photos)
  // ---------------------------------------------------------------------------
  Widget _buildSkipReasonDropdown(
      String? selected, ValueChanged<String?> onChanged,
      {String label = 'Alasan tidak bisa diukur'}) {
    final value = _skipReasons.contains(selected) ? selected : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(label),
      hint: const Text('Pilih alasan', style: TextStyle(fontSize: 14)),
      items: _skipReasons
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSkipReasonSection({
    required String? reason,
    required ValueChanged<String?> onReasonChanged,
    required TextEditingController remarkController,
    required ValueChanged<String> onRemarkChanged,
    required List<CapturedImageDetail> photos,
    required String photoGroup,
    required String photoLabel,
    required ValueChanged<CapturedImageDetail> onPhotoCaptured,
    required ValueChanged<String> onPhotoRemoved,
    String label = 'Alasan tidak bisa diukur',
  }) {
    final bool requireRemark =
        reason != null && _skipReasonRequiresRemark(reason);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkipReasonDropdown(reason, onReasonChanged, label: label),
        if (requireRemark) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: remarkController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration('Keterangan Tambahan (*Wajib)').copyWith(
              hintText: 'Jelaskan detail kendala (Min. 20 huruf)...',
              prefixIcon: const Icon(Icons.edit_note, size: 25),
            ),
            maxLines: 2,
            onChanged: onRemarkChanged,
            validator: (value) {
              final text = value ?? '';
              if (text.trim().isEmpty) return 'Wajib diisi';
              final int charCount = text.replaceAll(' ', '').length;
              if (charCount < 20) {
                return 'Kurang ${20 - charCount} huruf lagi (tanpa spasi)';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          RemarkPhotoPicker(
            photos: photos,
            isLoading: _capturingSkipGroup == photoGroup,
            isReadOnly: false,
            onAddTap: () => _captureSkipEvidencePhoto(
              group: photoGroup,
              photoLabel: photoLabel,
              currentCount: photos.length,
              onCaptured: onPhotoCaptured,
            ),
            onRemoveTap: onPhotoRemoved,
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Photo capture
  // ---------------------------------------------------------------------------
  Future<void> _captureSkipEvidencePhoto({
    required String group,
    required String photoLabel,
    required int currentCount,
    required ValueChanged<CapturedImageDetail> onCaptured,
  }) async {
    if (currentCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maksimal hanya bisa upload 5 foto bukti.')));
      return;
    }
    setState(() => _capturingSkipGroup = group);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: photoLabel, storeName: widget.storeName);
      if (img != null) onCaptured(img);
    } finally {
      if (mounted) setState(() => _capturingSkipGroup = null);
    }
  }

  String _slotLabel(String slotId) {
    for (final s in kScfPhotoSlots) {
      if (s.id == slotId) return s.label;
    }
    return slotId;
  }

  Future<void> _captureInitialSlot(String slotId) async {
    setState(() => _capturingInitial = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: '${_slotLabel(slotId)} - Before',
          storeName: widget.storeName);
      if (img != null) _cubit.setInitialPhoto(slotId, img);
    } finally {
      if (mounted) setState(() => _capturingInitial = false);
    }
  }

  Future<void> _captureAfterSlot(String slotId) async {
    setState(() => _capturingAfter = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: '${_slotLabel(slotId)} - After',
          storeName: widget.storeName);
      if (img != null) _cubit.setAfterPhoto(slotId, img);
    } finally {
      if (mounted) setState(() => _capturingAfter = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Nav buttons
  // ---------------------------------------------------------------------------
  Widget _buildNavButtons(ScfValidationDropdownState s) {
    final isLast = s.currentStep == _effectiveStepCount(s) - 1;
    final canProceed = s.isStepValid(s.currentStep) &&
        _cubit.measurementsConfirmedForStep(s.currentStep);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      // SafeArea bawah: cegah tombol tertutup navigation bar / gesture bar
      // pada HP yang punya area sistem di bawah layar.
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (s.currentStep > 0) ...[
              SizedBox(
                height: 48,
                width: 52,
                child: ElevatedButton(
                  onPressed: _cubit.prevStep,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  // Tetap bisa ditekan walau belum lengkap: alih-alih diam,
                  // tekan memunculkan toast yang menyebut data wajib yang
                  // belum diisi.
                  onPressed: canProceed
                      ? (isLast ? _onFinish : _cubit.nextStep)
                      : () => _showMissingToast(s),
                  style: ElevatedButton.styleFrom(
                    // Saat belum lengkap tampil seperti nonaktif (abu-abu)
                    // namun tetap menerima tap untuk menampilkan alasan.
                    backgroundColor: canProceed ? null : Colors.grey.shade300,
                    foregroundColor: canProceed ? null : Colors.grey.shade600,
                    elevation: canProceed ? null : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLast ? 'Selesai' : 'Lanjut'),
                      if (!isLast) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilkan toast berisi data wajib pertama yang belum lengkap pada step ini.
  void _showMissingToast(ScfValidationDropdownState s) {
    final msg = _missingReason(s, s.currentStep) ??
        'Lengkapi semua data wajib terlebih dahulu.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 2),
      ));
  }

  // Alasan pertama step belum boleh lanjut (null bila sebenarnya sudah lengkap).
  // Mengikuti urutan gerbang di [ScfValidationDropdownState] + konfirmasi
  // "sesuai foto" (measurementsConfirmedForStep).
  String? _missingReason(ScfValidationDropdownState s, int step) {
    final bool isBefore = step == 0;
    if (step == 0) {
      if (!kScfInitialPhotoSlots.every((p) => s.initialPhotos.containsKey(p.id))) {
        return 'Lengkapi semua Foto Kondisi Awal.';
      }
    } else if (step == 1) {
      if (!kScfAfterPhotoSlots.every((p) => s.afterPhotos.containsKey(p.id))) {
        return 'Lengkapi semua Foto Setelah Perbaikan.';
      }
    } else {
      return null;
    }

    final list = isBefore ? s.measurementsBefore : s.measurementsAfter;
    for (final limit in _limitsFor(isBefore: isBefore)) {
      final m = _measurementFor(list, limit.id);
      if (m == null || (!(m.isSkipped ?? false) && m.capturedImage == null)) {
        return 'Ambil foto pengukuran ${limit.label}.';
      }
      if ((m.isSkipped ?? false) &&
          !s.isSkipReasonComplete(m.remark,
              s.skipRemarkFor(limit.id, isBefore: isBefore),
              s.skipPhotosFor(limit.id, isBefore: isBefore))) {
        return 'Lengkapi alasan & bukti pengukuran ${limit.label}.';
      }
    }

    // Step Sesudah: wajib minimal 1 Permasalahan & Solusi lengkap.
    if (step == 1 && !s.hasCompleteProblem) {
      return 'Tambahkan minimal 1 Permasalahan & Solusi.';
    }

    // Gate konfirmasi "sesuai foto" untuk pengukuran non-skip.
    final confirmed = isBefore ? s.confirmedBefore : s.confirmedAfter;
    for (final m in list) {
      if (m.isSkipped ?? false) continue;
      if (!confirmed.contains(m.measurementId)) {
        return 'Konfirmasi ${_labelFor(m.measurementId, isBefore: isBefore)} "sesuai foto".';
      }
    }
    return null;
  }

  String _labelFor(String id, {required bool isBefore}) {
    for (final m in _limitsFor(isBefore: isBefore)) {
      if (m.id == id) return m.label;
    }
    return id;
  }

  Future<void> _onFinish() async {
    final ok = await _cubit.finishAndComplete();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lengkapi semua data wajib terlebih dahulu.')));
    }
  }

  // ---------------------------------------------------------------------------
  // Photo slots UI
  // ---------------------------------------------------------------------------
  Widget _buildInitialPhotoSlots(ScfValidationDropdownState s) => _photoSlotRow(
        slots: kScfInitialPhotoSlots,
        photos: s.initialPhotos,
        capturing: _capturingInitial,
        onCapture: _captureInitialSlot,
        onRemove: _cubit.removeInitialPhoto,
      );

  Widget _buildAfterPhotoSlots(ScfValidationDropdownState s) => _photoSlotRow(
        slots: kScfAfterPhotoSlots,
        photos: s.afterPhotos,
        capturing: _capturingAfter,
        onCapture: _captureAfterSlot,
        onRemove: _cubit.removeAfterPhoto,
      );

  Widget _photoSlotRow({
    required List<ScfPhotoSlot> slots,
    required Map<String, CapturedImageDetail> photos,
    required bool capturing,
    required void Function(String slotId) onCapture,
    required void Function(String slotId) onRemove,
  }) {
    const double spacing = 10;
    const int perRow = 3;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double itemWidth =
            (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final slot in slots)
              SizedBox(
                width: itemWidth,
                child: _photoSlot(
                  slot: slot,
                  photo: photos[slot.id],
                  capturing: capturing,
                  onCapture: () => onCapture(slot.id),
                  onRemove: () => onRemove(slot.id),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _photoSlot({
    required ScfPhotoSlot slot,
    required CapturedImageDetail? photo,
    required bool capturing,
    required VoidCallback onCapture,
    required VoidCallback onRemove,
  }) {
    final filled = photo != null;
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: capturing
          ? null
          : (filled
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenImageViewer(imageDetail: photo),
                    ),
                  )
              : onCapture),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? primary : Colors.grey.shade300,
              width: filled ? 1.5 : 1,
            ),
            image: filled
                ? DecorationImage(
                    image: FileImage(File(photo.imagePath)), fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!filled)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: Colors.grey.shade600,
                        size: slot.hint == null ? 26 : 22),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(slot.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ),
                    // Keterangan objek yang wajib terlihat (mis. Ruang Mesin =
                    // Kipas & Kompressor).
                    if (slot.hint != null)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 2, left: 3, right: 3),
                        child: Text(slot.hint!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: primary)),
                      ),
                  ],
                ),
              if (filled) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(slot.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white)),
                        if (slot.hint != null)
                          Text(slot.hint!,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 9, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
                const Positioned(
                  top: 3,
                  left: 3,
                  child: Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
              if (capturing && !filled)
                const Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Small UI helpers
  // ---------------------------------------------------------------------------
  Widget _card(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }
}
