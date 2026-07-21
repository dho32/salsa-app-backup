import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_cubit.dart';
import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_state.dart';
import '../../../../components/services/photo_capture_service.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/common/measurement_entry.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';

class ProofOfServiceFreezerValidationBodyMobile extends StatefulWidget {
  final String serialNo;
  final String articleDesc;

  const ProofOfServiceFreezerValidationBodyMobile({
    super.key,
    required this.serialNo,
    required this.articleDesc,
  });

  @override
  State<ProofOfServiceFreezerValidationBodyMobile> createState() =>
      _ProofOfServiceFreezerValidationBodyMobileState();
}

class _ProofOfServiceFreezerValidationBodyMobileState
    extends State<ProofOfServiceFreezerValidationBodyMobile> {
  static const _stepTitles = ['Sebelum', 'Sesudah'];
  static const _stepCount = 2;

  final _arrivalTempController = TextEditingController();
  final _initialNoteController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {
    for (final m in kPosfMeasurements) m.id: TextEditingController(),
  };
  // Remark bukti kendala skip per grup.
  final _arrivalSkipRemarkController = TextEditingController();
  final _tempSkipRemarkController = TextEditingController();
  final _elecSkipRemarkController = TextEditingController();
  // Keterangan tambahan kondisi (Ada Keluhan / Tidak terpakai).
  final _conditionNoteController = TextEditingController();

  bool _controllersReady = false;
  bool _capturingInitial = false;
  bool _capturingAfter = false;
  bool _capturingCondition = false;

  // Pengukuran yang sudah dikonfirmasi "sesuai foto" (id: 'arrival_temp',
  // 'temperature', 'ampere', 'volt'). Tombol Lanjut/Selesai dikunci sampai
  // semua pengukuran non-skip pada step aktif terkonfirmasi.
  final Set<String> _confirmedIds = {};

  void _setConfirmed(String id, bool confirmed) {
    final changed =
        confirmed ? _confirmedIds.add(id) : _confirmedIds.remove(id);
    if (changed && mounted) setState(() {});
  }

  // Semua pengukuran non-skip pada step ini sudah dikonfirmasi?
  bool _measurementsConfirmedForStep(PosfValidationState s, int step) {
    if (step == 0) {
      if (s.hasUnused) return true; // tidak ada pengukuran
      return s.arrivalTempSkipped || _confirmedIds.contains('arrival_temp');
    }
    if (step == 1) {
      for (final m in s.measurements) {
        if (m.isSkipped ?? false) continue;
        if (!_confirmedIds.contains(m.measurementId)) return false;
      }
      return true;
    }
    return true;
  }
  // Grup foto bukti skip yang sedang mengambil foto
  // ('arrival' / 'temperature' / 'elec'), null bila tidak ada.
  String? _capturingSkipGroup;

  @override
  void dispose() {
    _arrivalTempController.dispose();
    _initialNoteController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    _arrivalSkipRemarkController.dispose();
    _tempSkipRemarkController.dispose();
    _elecSkipRemarkController.dispose();
    _conditionNoteController.dispose();
    super.dispose();
  }

  void _initControllers(PosfValidationState s) {
    if (_controllersReady) return;
    _arrivalTempController.text = s.arrivalTemp;
    _initialNoteController.text = s.initialNote;
    for (final m in s.measurements) {
      final c = _measurementControllers[m.measurementId];
      if (c != null) c.text = m.value == 0 ? '' : m.value.toString();
    }
    _arrivalSkipRemarkController.text = s.arrivalTempSkipRemark;
    _tempSkipRemarkController.text = s.tempSkipRemark;
    _elecSkipRemarkController.text = s.elecSkipRemark;
    _conditionNoteController.text = s.conditionNote;
    _controllersReady = true;
  }

  // Jumlah step efektif: "Tidak terpakai" cukup 1 step (Sebelum).
  int _effectiveStepCount(PosfValidationState s) => s.hasUnused ? 1 : _stepCount;

  PosfValidationCubit get _cubit => context.read<PosfValidationCubit>();

  Future<void> _onExit() async {
    final cubit = _cubit;
    final isComplete = cubit.state.isComplete;
    if (isComplete) {
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
    return BlocConsumer<PosfValidationCubit, PosfValidationState>(
      listener: (context, state) {
        if (state.isLoaded) _initControllers(state);
      },
      builder: (context, state) {
        if (!state.isLoaded) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
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
                title: Text(widget.articleDesc,
                    style: const TextStyle(fontSize: 16)),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(16),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(widget.serialNo,
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
  Widget _buildStepHeader(PosfValidationState s) {
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
              final done = i < s.currentStep || (s.isStepValid(i));
              final active = i == s.currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < stepCount - 1 ? 6 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).primaryColor
                        : (done
                            ? Colors.green
                            : Colors.grey.shade300),
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

  Widget _buildStepContent(PosfValidationState s) {
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
  // Step Sebelum — Kondisi Awal
  // ---------------------------------------------------------------------------
  Widget _buildStepBefore(PosfValidationState s) {
    // "Tidak terpakai": cukup dokumentasi kondisi (alasan + note + foto),
    // sisanya (suhu, ketebalan, foto standar, catatan, step Sesudah) disembunyikan.
    final bool unused = s.hasUnused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Kondisi fungsi Freezer (selalu tampil) ---
        _card(
          'Kondisi fungsi Freezer saat teknisi tiba di toko',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chipGroup(kPosfGeneralConditions, s.generalCondition, (v) {
                // Ganti kondisi = reset detail; kosongkan juga controller note.
                _conditionNoteController.clear();
                _cubit.generalConditionChanged(v);
              }),
              // Detail wajib saat "Ada Keluhan" / "Tidak terpakai":
              // alasan + keterangan tambahan + foto bukti.
              if (s.needsConditionDetail) ...[
                const SizedBox(height: 12),
                _buildConditionReasonDropdown(s),
                const SizedBox(height: 12),
                TextField(
                  controller: _conditionNoteController,
                  maxLines: 3,
                  onChanged: _cubit.conditionNoteChanged,
                  decoration:
                      _inputDecoration('Keterangan tambahan (*Wajib)'),
                ),
                const SizedBox(height: 12),
                RemarkPhotoPicker(
                  photos: s.conditionPhotos,
                  isLoading: _capturingCondition,
                  isReadOnly: false,
                  onAddTap: _captureConditionPhoto,
                  onRemoveTap: _cubit.removeConditionPhoto,
                ),
              ],
            ],
          ),
        ),
        if (!unused) ...[
          MeasurementInputWidget(
            controller: _arrivalTempController,
            transNo: _cubit.transNo,
            label: 'Suhu sebelum pembersihan (°C)',
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            limits: kPosfArrivalTempLimit,
            initialImage: s.arrivalTempImage,
            isSkipEnabled: true,
            isSkipped: s.arrivalTempSkipped,
            // onChanged = sinkron live ke state (draft aman walau belum blur);
            // onEditingComplete = commit setelah dialog konfirmasi "sesuai foto".
            onChanged: _cubit.arrivalTempChanged,
            onEditingComplete: _cubit.arrivalTempChanged,
            onImageChanged: _cubit.arrivalTempImageChanged,
            enableConfirmDialog: true,
            onConfirmedChanged: (c) => _setConfirmed('arrival_temp', c),
            onSkipChanged: (skip) {
              if (skip) {
                _arrivalTempController.clear();
                _setConfirmed('arrival_temp', false);
              }
              _cubit.arrivalTempSkipChanged(skip);
            },
          ),
          // Alasan bila suhu tidak bisa diukur (+ remark & foto bukti
          // bila alasan mewajibkan).
          if (s.arrivalTempSkipped)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: _buildSkipReasonSection(
                reason: s.arrivalTempReason,
                onReasonChanged: (r) {
                  _arrivalSkipRemarkController.clear();
                  _cubit.arrivalTempReasonChanged(r);
                },
                remarkController: _arrivalSkipRemarkController,
                onRemarkChanged: _cubit.arrivalTempSkipRemarkChanged,
                photos: s.arrivalTempSkipPhotos,
                photoGroup: 'arrival',
                photoLabel: 'Bukti Kendala Suhu Sebelum Pembersihan',
                onPhotoCaptured: _cubit.addArrivalTempSkipPhoto,
                onPhotoRemoved: _cubit.removeArrivalTempSkipPhoto,
              ),
            ),
          const SizedBox(height: 12),
          _card(
            'Ketebalan bunga es',
            _chipGroup(kPosfFrostThickness, s.frostThickness,
                _cubit.frostThicknessChanged),
          ),
          _card(
            'Foto Kondisi Awal',
            _buildInitialPhotoSlots(s),
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
      ],
    );
  }

  Future<void> _captureConditionPhoto() async {
    if (_cubit.state.conditionPhotos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maksimal 5 foto.')));
      return;
    }
    setState(() => _capturingCondition = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: 'Kondisi Freezer - ${_cubit.state.generalCondition ?? ''}');
      if (img != null) _cubit.addConditionPhoto(img);
    } finally {
      if (mounted) setState(() => _capturingCondition = false);
    }
  }

  // Dropdown alasan "tidak bisa diukur" (metode sama seperti POS).
  Widget _buildSkipReasonDropdown(
      String? selected, ValueChanged<String?> onChanged,
      {String label = 'Alasan tidak bisa diukur'}) {
    final value = kPosfSkipReasons.contains(selected) ? selected : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(label),
      hint: const Text('Pilih alasan', style: TextStyle(fontSize: 14)),
      items: kPosfSkipReasons
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

  /// Dropdown alasan skip + (bila alasan ada di [kPosfSkipReasonsRequireRemark])
  /// keterangan tambahan min. 20 huruf + foto bukti kendala — pola POS/SC.
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
        reason != null && kPosfSkipReasonsRequireRemark.contains(reason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSkipReasonDropdown(reason, onReasonChanged, label: label),
        if (requireRemark) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: remarkController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: _inputDecoration('Keterangan Tambahan (*Wajib)')
                .copyWith(
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
          photoLabel: photoLabel);
      if (img != null) onCaptured(img);
    } finally {
      if (mounted) setState(() => _capturingSkipGroup = null);
    }
  }

  // Dropdown alasan kondisi: opsi keluhan (Ada Keluhan) atau opsi tidak
  // terpakai (Tidak terpakai), tergantung kondisi terpilih.
  Widget _buildConditionReasonDropdown(PosfValidationState s) {
    final bool unused = s.hasUnused;
    final options = unused ? kPosfUnusedOptions : kPosfComplaintOptions;
    final hint = unused ? 'Pilih alasan' : 'Pilih keluhan';
    final value = options.contains(s.complaint) ? s.complaint : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration(hint),
      hint: Text(hint, style: const TextStyle(fontSize: 14)),
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: _cubit.complaintChanged,
    );
  }

  // ---------------------------------------------------------------------------
  // Step Sesudah — Pengukuran Aktual & Foto Setelah Cuci
  // ---------------------------------------------------------------------------
  Widget _buildStepAfter(PosfValidationState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Foto Setelah Cuci',
          _buildAfterPhotoSlots(s),
        ),
        _card(
          'Pengukuran Aktual',
          Column(
            children: [
              for (final limit in kPosfMeasurements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      MeasurementInputWidget(
                        controller: _measurementControllers[limit.id]!,
                        transNo: _cubit.transNo,
                        label: limit.label,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        limits: limit,
                        initialImage:
                            _measurementFor(s, limit.id)?.capturedImage,
                        isSkipEnabled: true,
                        isSkipped:
                            _measurementFor(s, limit.id)?.isSkipped ?? false,
                        // onChanged = sinkron live ke state (draft aman walau
                        // belum blur); onEditingComplete = commit setelah
                        // dialog konfirmasi "angka sesuai foto".
                        onChanged: (v) =>
                            _cubit.measurementValueChanged(limit.id, v),
                        onEditingComplete: (v) =>
                            _cubit.measurementValueChanged(limit.id, v),
                        onImageChanged: (img) =>
                            _cubit.measurementImageChanged(limit.id, img),
                        enableConfirmDialog: true,
                        onConfirmedChanged: (c) =>
                            _setConfirmed(limit.id, c),
                        onSkipChanged: (skip) {
                          // Skip -> kosongkan controller semua pengukuran terkait
                          // (Arus & Tegangan diukur bersama).
                          if (skip) {
                            for (final mid
                                in _cubit.linkedMeasurementIds(limit.id)) {
                              _measurementControllers[mid]?.clear();
                              _setConfirmed(mid, false);
                            }
                          }
                          _cubit.measurementSkipChanged(limit.id, skip);
                        },
                      ),
                      // Alasan bila pengukuran ini tidak bisa diukur (+ remark
                      // & foto bukti bila alasan mewajibkan). Untuk pasangan
                      // Arus & Tegangan, seksi cukup satu (dirender di bawah
                      // Tegangan / 'volt').
                      if ((_measurementFor(s, limit.id)?.isSkipped ?? false) &&
                          limit.id != 'ampere')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _buildSkipReasonSection(
                            reason: _measurementFor(s, limit.id)?.remark,
                            onReasonChanged: (r) {
                              (limit.id == 'temperature'
                                      ? _tempSkipRemarkController
                                      : _elecSkipRemarkController)
                                  .clear();
                              _cubit.measurementReasonChanged(limit.id, r);
                            },
                            remarkController: limit.id == 'temperature'
                                ? _tempSkipRemarkController
                                : _elecSkipRemarkController,
                            onRemarkChanged: (v) => _cubit
                                .measurementSkipRemarkChanged(limit.id, v),
                            photos: s.skipPhotosFor(limit.id),
                            photoGroup: limit.id == 'temperature'
                                ? 'temperature'
                                : 'elec',
                            photoLabel: limit.id == 'temperature'
                                ? 'Bukti Kendala Suhu Pull-down'
                                : 'Bukti Kendala Arus & Tegangan',
                            onPhotoCaptured: (img) => _cubit
                                .addMeasurementSkipPhoto(limit.id, img),
                            onPhotoRemoved: (path) => _cubit
                                .removeMeasurementSkipPhoto(limit.id, path),
                            label: limit.id == 'volt'
                                ? 'Alasan tidak bisa diukur (Arus & Tegangan)'
                                : 'Alasan tidak bisa diukur',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  MeasurementEntry? _measurementFor(PosfValidationState s, String id) {
    for (final m in s.measurements) {
      if (m.measurementId == id) return m;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Nav buttons
  // ---------------------------------------------------------------------------
  Widget _buildNavButtons(PosfValidationState s) {
    // "Tidak terpakai" → step Before adalah step terakhir (langsung Selesai).
    final isLast = s.currentStep == _effectiveStepCount(s) - 1;
    // Selain valid, semua pengukuran non-skip di step ini wajib dikonfirmasi
    // "sesuai foto" dulu (cegah balapan dengan tombol Lanjut/Selesai).
    final canProceed = s.isStepValid(s.currentStep) &&
        _measurementsConfirmedForStep(s, s.currentStep);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
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
                onPressed:
                    canProceed ? (isLast ? _onFinish : _cubit.nextStep) : null,
                style: ElevatedButton.styleFrom(
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
    );
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
  // Photo capture
  // ---------------------------------------------------------------------------
  String _slotLabel(String slotId) {
    for (final s in kPosfPhotoSlots) {
      if (s.id == slotId) return s.label;
    }
    return slotId;
  }

  Future<void> _captureInitialSlot(String slotId) async {
    setState(() => _capturingInitial = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: '${_slotLabel(slotId)} - Before');
      if (img != null) _cubit.setInitialPhoto(slotId, img);
    } finally {
      if (mounted) setState(() => _capturingInitial = false);
    }
  }

  Future<void> _captureAfterSlot(String slotId) async {
    setState(() => _capturingAfter = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: '${_slotLabel(slotId)} - After');
      if (img != null) _cubit.setAfterPhoto(slotId, img);
    } finally {
      if (mounted) setState(() => _capturingAfter = false);
    }
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

  Widget _buildInitialPhotoSlots(PosfValidationState s) => _photoSlotRow(
        slots: kPosfInitialPhotoSlots, // Display Produk paling atas
        photos: s.initialPhotos,
        capturing: _capturingInitial,
        onCapture: _captureInitialSlot,
        onRemove: _cubit.removeInitialPhoto,
      );

  Widget _buildAfterPhotoSlots(PosfValidationState s) => _photoSlotRow(
        slots: kPosfAfterPhotoSlots, // Display Produk paling akhir
        photos: s.afterPhotos,
        capturing: _capturingAfter,
        onCapture: _captureAfterSlot,
        onRemove: _cubit.removeAfterPhoto,
      );

  Widget _photoSlotRow({
    required List<PosfPhotoSlot> slots,
    required Map<String, CapturedImageDetail> photos,
    required bool capturing,
    required void Function(String slotId) onCapture,
    required void Function(String slotId) onRemove,
  }) {
    const double spacing = 10;
    const int perRow = 3;
    // Wrap 3 per baris agar slot ke-4 (Display Produk) turun ke baris berikutnya
    // dengan ukuran seragam, tidak menyempit dalam satu baris.
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
    required PosfPhotoSlot slot,
    required CapturedImageDetail? photo,
    required bool capturing,
    required VoidCallback onCapture,
    required VoidCallback onRemove,
  }) {
    final filled = photo != null;
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      // Terisi -> tap untuk preview full-screen; kosong -> tap untuk ambil foto.
      onTap: capturing
          ? null
          : (filled
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullScreenImageViewer(imageDetail: photo),
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
                        color: Colors.grey.shade600, size: 26),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(slot.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
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
                    child: Text(slot.label,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                ),
                const Positioned(
                  top: 3,
                  left: 3,
                  child:
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
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

  Widget _chipGroup(
      List<String> options, String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: options
          .map((o) => ChoiceChip(
                label: Text(o, style: const TextStyle(fontSize: 13)),
                selected: selected == o,
                onSelected: (_) => onSelect(o),
              ))
          .toList(),
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
