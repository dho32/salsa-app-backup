import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../../components/constants.dart';
import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_cubit.dart';
import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_state.dart';
import '../../../../components/services/photo_capture_service.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/planogram_guide_button.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/common/measurement_entry.dart';
import '../../../../models/common/measurement_limits.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';

class ProofOfServiceFreezerValidationBodyMobile extends StatefulWidget {
  final String serialNo;
  final String articleDesc;

  /// Config wizard dari server (opsional). Null/kosong → fallback konstanta.
  final PosfWizardConfig? config;

  const ProofOfServiceFreezerValidationBodyMobile({
    super.key,
    required this.serialNo,
    required this.articleDesc,
    this.config,
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
      if (s.isUnitSkipped) return true; // unit tak dikerjakan, tanpa pengukuran
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

  // Nama toko (shipToName) untuk watermark foto — dibaca sekali dari box detail.
  String _storeName = '';

  @override
  void initState() {
    super.initState();
    _storeName = _loadStoreName();
  }

  // Baca shipToName + shipTo dari box detail (read-only) via transNo cubit;
  // watermark tampil "Toko : <nama> (<kode>)". Fallback ''.
  String _loadStoreName() {
    try {
      if (Hive.isBoxOpen(kProofOfServiceFreezerDetailBox)) {
        final hdr = Hive.box<ProofOfServiceFreezerDetailModel>(
                kProofOfServiceFreezerDetailBox)
            .get(_cubit.transNo.trim().toUpperCase())
            ?.header;
        return storeTag(hdr?.shipToName, hdr?.shipTo);
      }
    } catch (_) {}
    return '';
  }

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

  // Jumlah step efektif: unit yang tidak dikerjakan ("Tidak terpakai" /
  // "Freezer Tidak Bisa Dicuci") cukup 1 step (Sebelum).
  int _effectiveStepCount(PosfValidationState s) =>
      s.isUnitSkipped ? 1 : _stepCount;

  PosfValidationCubit get _cubit => context.read<PosfValidationCubit>();

  // --- Config wizard dari server (fallback ke konstanta bila null/kosong) ---
  // Disaring [posfFilterMeasurements] supaya Arus & Tegangan tetap hilang
  // walaupun backend masih mengirim range-nya di config.
  List<MeasurementLimits> get _measurements {
    final cfg = widget.config?.measurements;
    final src = (cfg != null && cfg.isNotEmpty) ? cfg : kPosfMeasurements;
    final filtered = posfFilterMeasurements(src);
    return filtered.isNotEmpty ? filtered : kPosfMeasurements;
  }

  List<String> get _skipReasons {
    final cfg = widget.config?.skipReasonOptions;
    return (cfg != null && cfg.isNotEmpty)
        ? cfg.map((e) => e.label).toList()
        : kPosfSkipReasons;
  }

  bool _skipReasonRequiresRemark(String reason) {
    final cfg = widget.config?.skipReasonOptions;
    if (cfg != null && cfg.isNotEmpty) {
      for (final o in cfg) {
        if (o.label == reason) return o.requireRemark;
      }
      return false; // alasan tak ada di master server → tidak wajib remark
    }
    return kPosfSkipReasonsRequireRemark.contains(reason);
  }

  List<String> _conditionOptions(bool unused) {
    final cfg =
        unused ? widget.config?.unusedOptions : widget.config?.complaintOptions;
    return (cfg != null && cfg.isNotEmpty)
        ? cfg
        : (unused ? kPosfUnusedOptions : kPosfComplaintOptions);
  }

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
        // Seed controller dari draft juga di sini (bukan hanya lewat listener):
        // cubit memuat draft secara sinkron di konstruktor sehingga state
        // 'isLoaded' sudah aktif sebelum listener ter-subscribe — listener tak
        // pernah menyala untuk state awal, jadi tanpa ini nilai suhu (Sebelum)
        // & pengukuran (Sesudah) tidak terisi ulang saat wizard dibuka kembali.
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
    // "Tidak terpakai" / "Freezer Tidak Bisa Dicuci": cukup dokumentasi
    // kondisi (alasan + foto, note sesuai kondisi), sisanya (suhu, ketebalan,
    // foto standar, catatan, step Sesudah) disembunyikan.
    final bool unused = s.isUnitSkipped;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Kondisi Freezer (selalu tampil) ---
        _card(
          'Kondisi Freezer saat teknisi tiba di toko',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown 1 — dimensi fungsi.
              _buildFunctionConditionDropdown(s),
              // Dropdown 2 — dimensi pemakaian. Baru muncul setelah dropdown 1
              // diisi, dan TIDAK berlaku untuk "Freezer Tidak Bisa Dicuci"
              // (kondisi berdiri sendiri; usage_condition dikirim kosong).
              if (s.functionCondition != null && !s.hasUnwashable) ...[
                const SizedBox(height: 12),
                _buildUsageConditionDropdown(s),
              ],
              // Detail wajib saat "Ada Keluhan" / "Tidak Terpakai" / "Tidak
              // Bisa Dicuci": alasan + keterangan tambahan + foto bukti. Baru
              // dibuka setelah kondisi lengkap dipilih.
              if (s.isConditionSelected && s.needsConditionDetail) ...[
                const SizedBox(height: 12),
                // "Ada Keluhan" → dropdown jenis keluhan.
                if (s.hasComplaint) ...[
                  _buildComplaintDropdown(s),
                  const SizedBox(height: 12),
                ],
                // "Tidak Terpakai" → dropdown alasan tidak terpakai (bisa
                // muncul bersamaan dengan keluhan pada "Ada Keluhan Tidak
                // Terpakai").
                if (s.hasUnused) ...[
                  _buildUnusedReasonDropdown(s),
                  const SizedBox(height: 12),
                ],
                // "Freezer Tidak Bisa Dicuci" → dropdown alasan close.
                if (s.hasUnwashable) ...[
                  _buildUnwashableReasonDropdown(s),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _conditionNoteController,
                  maxLines: 3,
                  onChanged: _cubit.conditionNoteChanged,
                  // Mengikuti form laporan close: catatan tambahan OPSIONAL
                  // untuk "Tidak Bisa Dicuci", wajib untuk kondisi lain.
                  decoration: _inputDecoration(s.hasUnwashable
                      ? 'Catatan Tambahan (Opsional)'
                      : 'Keterangan tambahan (*Wajib)'),
                ),
                const SizedBox(height: 12),
                if (s.hasUnwashable)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('Foto Bukti (*Wajib, maks. 3 foto)',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
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
        // Sisa form step Sebelum baru terbuka setelah kedua dimensi kondisi
        // dipilih.
        if (s.isConditionSelected && !unused) ...[
          MeasurementInputWidget(
            controller: _arrivalTempController,
            transNo: _cubit.transNo,
            storeName: _storeName,
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
            _dropdown(
              label: 'Ketebalan bunga es (*Wajib)',
              hint: 'Pilih ketebalan',
              value: s.frostThickness,
              options: kPosfFrostThickness,
              onChanged: (v) {
                if (v != null) _cubit.frostThicknessChanged(v);
              },
            ),
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
    // "Tidak Bisa Dicuci" mengikuti form laporan close: maksimal 3 foto.
    final int maxPhotos =
        _cubit.state.hasUnwashable ? kPosfUnwashableMaxPhotos : 5;
    if (_cubit.state.conditionPhotos.length >= maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maksimal $maxPhotos foto.')));
      return;
    }
    setState(() => _capturingCondition = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: 'Kondisi Freezer - ${_cubit.state.generalCondition ?? ''}',
          storeName: _storeName);
      if (img != null) _cubit.addConditionPhoto(img);
    } finally {
      if (mounted) setState(() => _capturingCondition = false);
    }
  }

  // Dropdown alasan "tidak bisa diukur" (metode sama seperti POS).
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
          photoLabel: photoLabel, storeName: _storeName);
      if (img != null) onCaptured(img);
    } finally {
      if (mounted) setState(() => _capturingSkipGroup = null);
    }
  }

  /// Dropdown 1 — dimensi FUNGSI (Normal / Ada Keluhan / Freezer Tidak Bisa
  /// Dicuci). Mengganti nilainya mereset detail kondisi di cubit, jadi
  /// controller keterangan ikut dikosongkan di sini.
  Widget _buildFunctionConditionDropdown(PosfValidationState s) {
    return _dropdown(
      label: 'Kondisi fungsi Freezer (*Wajib)',
      hint: 'Pilih kondisi fungsi',
      value: s.functionCondition,
      options: kPosfFunctionConditions,
      onChanged: (v) {
        _conditionNoteController.clear();
        _cubit.functionConditionChanged(v);
      },
    );
  }

  /// Dropdown 2 — dimensi PEMAKAIAN (Terpakai / Tidak Terpakai).
  Widget _buildUsageConditionDropdown(PosfValidationState s) {
    return _dropdown(
      label: 'Kondisi pemakaian Freezer (*Wajib)',
      hint: 'Pilih kondisi pemakaian',
      value: s.usageCondition,
      options: kPosfUsageConditions,
      onChanged: (v) {
        _conditionNoteController.clear();
        _cubit.usageConditionChanged(v);
      },
    );
  }

  // Dropdown jenis keluhan (dimensi "Ada Keluhan").
  Widget _buildComplaintDropdown(PosfValidationState s) {
    final options = _conditionOptions(false);
    final value = options.contains(s.complaint) ? s.complaint : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration('Pilih keluhan'),
      hint: const Text('Pilih keluhan', style: TextStyle(fontSize: 14)),
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

  // Dropdown alasan tidak terpakai (dimensi "Tidak Terpakai").
  Widget _buildUnusedReasonDropdown(PosfValidationState s) {
    final options = _conditionOptions(true);
    final value = options.contains(s.unusedReason) ? s.unusedReason : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration('Pilih alasan tidak terpakai'),
      hint: const Text('Pilih alasan tidak terpakai',
          style: TextStyle(fontSize: 14)),
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: _cubit.unusedReasonChanged,
    );
  }

  /// Dropdown "Alasan Tidak Bisa Dicuci" — kondisi "Freezer Tidak Bisa Dicuci".
  /// Master alasan sama dengan halaman laporan close: dari server
  /// (`config.closedReasons`) bila ada, fallback [kPosfClosedReasons].
  /// Nilainya disimpan di slot yang sama dengan alasan tidak terpakai
  /// (`unusedReason`) sehingga tidak perlu HiveField baru.
  Widget _buildUnwashableReasonDropdown(PosfValidationState s) {
    final serverReasons = widget.config?.closedReasons ?? const <String>[];
    final options =
        serverReasons.isNotEmpty ? serverReasons : kPosfClosedReasons;
    final value = options.contains(s.unusedReason) ? s.unusedReason : null;
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _inputDecoration('Alasan Tidak Bisa Dicuci (*Wajib)'),
      hint: const Text('Pilih alasan', style: TextStyle(fontSize: 14)),
      items: options
          .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: _cubit.unusedReasonChanged,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Panduan susunan display produk — dibuka full-screen (bisa
              // di-zoom) sebelum teknisi menata & memfoto Display Produk.
              PlanogramGuideButton(url: widget.config?.planogramUrl),
              const SizedBox(height: 12),
              _buildAfterPhotoSlots(s),
            ],
          ),
        ),
        _card(
          'Pengukuran Aktual',
          Column(
            children: [
              for (final limit in _measurements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    children: [
                      MeasurementInputWidget(
                        controller: _measurementControllers[limit.id]!,
                        transNo: _cubit.transNo,
                        storeName: _storeName,
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
  void _showMissingToast(PosfValidationState s) {
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
  // Mengikuti urutan gerbang di [PosfValidationState] + konfirmasi "sesuai foto".
  String? _missingReason(PosfValidationState s, int step) {
    if (step == 0) {
      if (s.functionCondition == null) {
        return 'Kondisi fungsi freezer wajib dipilih.';
      }
      // "Freezer Tidak Bisa Dicuci" tidak punya dimensi pemakaian.
      if (!s.hasUnwashable && s.usageCondition == null) {
        return 'Kondisi pemakaian freezer wajib dipilih.';
      }
      // "Freezer Tidak Bisa Dicuci" mengikuti form laporan close: alasan +
      // foto bukti wajib, catatan tambahan opsional.
      if (s.hasUnwashable) {
        if (s.unusedReason == null || s.unusedReason!.isEmpty) {
          return 'Pilih alasan tidak bisa dicuci terlebih dahulu.';
        }
        if (s.conditionPhotos.isEmpty) {
          return 'Ambil minimal 1 foto bukti.';
        }
        return null;
      }
      if (s.needsConditionDetail) {
        if (s.hasComplaint && (s.complaint == null || s.complaint!.isEmpty)) {
          return 'Pilih jenis keluhan terlebih dahulu.';
        }
        if (s.hasUnused &&
            (s.unusedReason == null || s.unusedReason!.isEmpty)) {
          return 'Pilih alasan tidak terpakai terlebih dahulu.';
        }
        if (s.conditionNote.trim().isEmpty) {
          return 'Keterangan tambahan kondisi wajib diisi.';
        }
        if (s.conditionPhotos.isEmpty) {
          return 'Ambil minimal 1 foto bukti kondisi.';
        }
      }
      if (s.hasUnused) return null; // "Tidak terpakai" cukup sampai sini.
      if (!s.isArrivalTempValid) {
        return s.arrivalTempSkipped
            ? 'Lengkapi alasan & bukti suhu sebelum pembersihan.'
            : 'Isi suhu sebelum pembersihan beserta fotonya.';
      }
      if (s.frostThickness == null) {
        return 'Pilih ketebalan bunga es.';
      }
      if (!kPosfPhotoSlots.every((p) => s.initialPhotos.containsKey(p.id))) {
        return 'Lengkapi semua Foto Kondisi Awal.';
      }
      if (!s.arrivalTempSkipped && !_confirmedIds.contains('arrival_temp')) {
        return 'Konfirmasi suhu sebelum pembersihan "sesuai foto".';
      }
      return null;
    }
    if (step == 1) {
      if (!kPosfPhotoSlots.every((p) => s.afterPhotos.containsKey(p.id))) {
        return 'Lengkapi semua Foto Setelah Cuci.';
      }
      for (final limit in _measurements) {
        final m = _measurementFor(s, limit.id);
        if (m == null || (!(m.isSkipped ?? false) && m.capturedImage == null)) {
          return 'Ambil foto pengukuran ${limit.label}.';
        }
        if ((m.isSkipped ?? false) &&
            !s.isSkipReasonComplete(m.remark, s.skipRemarkFor(limit.id),
                s.skipPhotosFor(limit.id))) {
          return 'Lengkapi alasan & bukti pengukuran ${limit.label}.';
        }
      }
      for (final m in s.measurements) {
        if (m.isSkipped ?? false) continue;
        if (!_confirmedIds.contains(m.measurementId)) {
          return 'Konfirmasi ${_labelFor(m.measurementId)} "sesuai foto".';
        }
      }
      return null;
    }
    return null;
  }

  String _labelFor(String id) {
    for (final m in _measurements) {
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
          photoLabel: '${_slotLabel(slotId)} - Before', storeName: _storeName);
      if (img != null) _cubit.setInitialPhoto(slotId, img);
    } finally {
      if (mounted) setState(() => _capturingInitial = false);
    }
  }

  Future<void> _captureAfterSlot(String slotId) async {
    setState(() => _capturingAfter = true);
    try {
      final img = await captureWatermarkedPhoto(_cubit.transNo,
          photoLabel: '${_slotLabel(slotId)} - After', storeName: _storeName);
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
                        padding: const EdgeInsets.only(top: 2, left: 3, right: 3),
                        child: Text(slot.hint!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor)),
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

  /// Dropdown pilihan tunggal — bentuk seragam untuk seluruh pilihan di step
  /// Sebelum (kondisi fungsi, kondisi pemakaian, ketebalan bunga es).
  /// [value] yang tidak ada di [options] ditampilkan sebagai belum terpilih —
  /// melindungi draft lama yang menyimpan nilai di luar daftar sekarang.
  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: options.contains(value) ? value : null,
      isExpanded: true,
      decoration: _inputDecoration(label),
      hint: Text(hint, style: const TextStyle(fontSize: 14)),
      items: options
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
