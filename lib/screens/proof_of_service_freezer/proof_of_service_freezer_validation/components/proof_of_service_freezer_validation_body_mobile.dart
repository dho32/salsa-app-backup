import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_cubit.dart';
import '../../../../blocs/proof_of_service_freezer/posf_validation/posf_validation_state.dart';
import '../../../../components/services/photo_capture_service.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
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
  static const _stepTitles = ['Kondisi Awal', 'Proses Cuci', 'Pemeriksaan Teknis'];

  final _arrivalTempController = TextEditingController();
  final _initialNoteController = TextEditingController();
  final _cleaningProductController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {
    for (final m in kPosfMeasurements) m.id: TextEditingController(),
  };

  bool _controllersReady = false;
  bool _capturingInitial = false;
  bool _capturingAfter = false;

  @override
  void dispose() {
    _arrivalTempController.dispose();
    _initialNoteController.dispose();
    _cleaningProductController.dispose();
    for (final c in _measurementControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(PosfValidationState s) {
    if (_controllersReady) return;
    _arrivalTempController.text = s.arrivalTemp;
    _initialNoteController.text = s.initialNote;
    _cleaningProductController.text = s.cleaningProduct;
    for (final m in s.measurements) {
      final c = _measurementControllers[m.measurementId];
      if (c != null) c.text = m.value == 0 ? '' : m.value.toString();
    }
    _controllersReady = true;
  }

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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${s.currentStep + 1} dari 3',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(_stepTitles[s.currentStep],
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final done = i < s.currentStep || (s.isStepValid(i));
              final active = i == s.currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
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
        return _buildStep1(s);
      case 1:
        return _buildStep2(s);
      case 2:
        return _buildStep3(s);
      default:
        return const SizedBox.shrink();
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Kondisi Awal
  // ---------------------------------------------------------------------------
  Widget _buildStep1(PosfValidationState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Suhu terbaca saat tiba',
          MeasurementInputWidget(
            controller: _arrivalTempController,
            transNo: _cubit.transNo,
            label: 'Suhu terbaca saat tiba (°C)',
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            limits: kPosfArrivalTempLimit,
            initialImage: s.arrivalTempImage,
            isSkipEnabled: false,
            onChanged: _cubit.arrivalTempChanged,
            onImageChanged: _cubit.arrivalTempImageChanged,
          ),
        ),
        _card(
          'Kondisi umum saat datang',
          _chipGroup(kPosfGeneralConditions, s.generalCondition,
              _cubit.generalConditionChanged),
        ),
        _card(
          'Ketebalan bunga es',
          _chipGroup(
              kPosfFrostThickness, s.frostThickness, _cubit.frostThicknessChanged),
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
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Proses Cuci
  // ---------------------------------------------------------------------------
  Widget _buildStep2(PosfValidationState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Checklist Proses Cuci (semua wajib)',
          Column(
            children: [
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: s.isStep2Valid,
                onChanged: (v) => _cubit.toggleAllChecklist(v ?? false),
                title: const Text('Centang semua',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              const Divider(height: 1),
              for (int i = 0; i < kPosfCleaningChecklist.length; i++)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: i < s.cleaningChecklist.length
                      ? s.cleaningChecklist[i]
                      : false,
                  onChanged: (v) => _cubit.toggleChecklist(i, v ?? false),
                  title: Text(kPosfCleaningChecklist[i],
                      style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
        _card(
          'Produk pembersih yang digunakan',
          TextField(
            controller: _cleaningProductController,
            onChanged: _cubit.cleaningProductChanged,
            decoration: _inputDecoration('Mis. sabun food-grade, dll'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Pemeriksaan Teknis
  // ---------------------------------------------------------------------------
  Widget _buildStep3(PosfValidationState s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          'Sistem Refrigerasi',
          Column(
            children: kPosfRefrigerationItems
                .map((it) => _statusChips(it, s.statusFlags[it.id]))
                .toList(),
          ),
        ),
        _card(
          'Kelistrikan',
          Column(
            children: kPosfElectricalItems
                .map((it) => _statusChips(it, s.statusFlags[it.id]))
                .toList(),
          ),
        ),
        _card(
          'Pengukuran Aktual',
          Column(
            children: [
              for (final limit in kPosfMeasurements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MeasurementInputWidget(
                    controller: _measurementControllers[limit.id]!,
                    transNo: _cubit.transNo,
                    label: limit.label,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true, signed: true),
                    limits: limit,
                    initialImage: _measurementFor(s, limit.id)?.capturedImage,
                    isSkipEnabled: true,
                    isSkipped: _measurementFor(s, limit.id)?.isSkipped ?? false,
                    onChanged: (v) => _cubit.measurementValueChanged(limit.id, v),
                    onImageChanged: (img) =>
                        _cubit.measurementImageChanged(limit.id, img),
                    onSkipChanged: (skip) =>
                        _cubit.measurementSkipChanged(limit.id, skip),
                  ),
                ),
            ],
          ),
        ),
        _card(
          'Foto Setelah Cuci',
          _buildAfterPhotoSlots(s),
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

  Widget _statusChips(PosfStatusItem item, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: kPosfStatusOptions.map((o) {
              final selected = value == o;
              final c = _statusColor(o);
              return ChoiceChip(
                label: Text(o,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : c)),
                selected: selected,
                showCheckmark: false,
                backgroundColor: c.withValues(alpha: 0.10),
                selectedColor: c,
                side: BorderSide(
                    color: c.withValues(alpha: selected ? 1 : 0.4)),
                onSelected: (_) => _cubit.statusFlagChanged(item.id, o),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OK':
        return Colors.green;
      case 'Perhatian':
        return Colors.orange;
      case 'Masalah':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ---------------------------------------------------------------------------
  // Nav buttons
  // ---------------------------------------------------------------------------
  Widget _buildNavButtons(PosfValidationState s) {
    final isLast = s.currentStep == 2;
    final canProceed = s.isStepValid(s.currentStep);
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
        photos: s.initialPhotos,
        capturing: _capturingInitial,
        onCapture: _captureInitialSlot,
        onRemove: _cubit.removeInitialPhoto,
      );

  Widget _buildAfterPhotoSlots(PosfValidationState s) => _photoSlotRow(
        photos: s.afterPhotos,
        capturing: _capturingAfter,
        onCapture: _captureAfterSlot,
        onRemove: _cubit.removeAfterPhoto,
      );

  Widget _photoSlotRow({
    required Map<String, CapturedImageDetail> photos,
    required bool capturing,
    required void Function(String slotId) onCapture,
    required void Function(String slotId) onRemove,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < kPosfPhotoSlots.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _photoSlot(
              slot: kPosfPhotoSlots[i],
              photo: photos[kPosfPhotoSlots[i].id],
              capturing: capturing,
              onCapture: () => onCapture(kPosfPhotoSlots[i].id),
              onRemove: () => onRemove(kPosfPhotoSlots[i].id),
            ),
          ),
        ],
      ],
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
      onTap: capturing ? null : onCapture,
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
