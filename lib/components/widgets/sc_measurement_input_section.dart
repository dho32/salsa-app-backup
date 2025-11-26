import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/models/common/note_option.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../../../components/widgets/measurement_input_widget.dart';
import '../../../../../models/common/measurement_entry.dart';
import '../../models/common/measurement_limits.dart';

class ScMeasurementInputSection extends StatefulWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final bool isBefore;
  final Map<String, MeasurementLimits> limitsMap;

  const ScMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.isBefore,
    required this.limitsMap,
  });

  @override
  State<ScMeasurementInputSection> createState() =>
      _ScMeasurementInputSectionState();
}

class _ScMeasurementInputSectionState extends State<ScMeasurementInputSection> {
  final Map<String, TextEditingController> _controllers = {};

  // Controller untuk Remark per GRUP (Bukan per item)
  final TextEditingController _indoorRemarkController = TextEditingController();
  final TextEditingController _outdoorRemarkController = TextEditingController();
  final TextEditingController _outdoorPsiRemarkController = TextEditingController();

  final TextEditingController _indoorNoteSearchController = TextEditingController();
  final TextEditingController _outdoorNoteSearchController = TextEditingController();
  final TextEditingController _outdoorPSINoteSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeOrUpdateControllers(widget.measurements);
    _initRemarkControllers();
  }

  @override
  void didUpdateWidget(covariant ScMeasurementInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.measurements, oldWidget.measurements)) {
      _initializeOrUpdateControllers(widget.measurements);
      // Kita tidak reset remark controller di sini agar text tidak hilang saat rebuild
      setState(() {});
    }
  }

  void _initRemarkControllers() {
    // Ambil nilai awal dari salah satu item di grup masing-masing (jika ada)
    final indoorM = widget.measurements.firstWhere((m) => m.measurementId == 'temperature', orElse: () => MeasurementEntry(measurementId: '', value: 0, unit: ''));
    if (indoorM.remark != null) _indoorRemarkController.text = indoorM.remark!;

    final outdoorM = widget.measurements.firstWhere((m) => m.measurementId == 'volt', orElse: () => MeasurementEntry(measurementId: '', value: 0, unit: ''));
    if (outdoorM.remark != null) _outdoorRemarkController.text = outdoorM.remark!;

    final psiM = widget.measurements.firstWhere((m) => m.measurementId == 'psi', orElse: () => MeasurementEntry(measurementId: '', value: 0, unit: ''));
    if (psiM.remark != null) _outdoorPsiRemarkController.text = psiM.remark!;
  }

  void _initializeOrUpdateControllers(List<MeasurementEntry> measurements) {
    _disposeControllers();
    final currentIds = measurements.map((m) => m.measurementId).toSet();
    _controllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    for (var mEntry in widget.measurements) {
      final valueText = mEntry.isSkipped ?? false
          ? ''
          : (mEntry.value == mEntry.value.truncateToDouble()
          ? mEntry.value.truncate().toString()
          : mEntry.value.toStringAsFixed(2));

      if (_controllers.containsKey(mEntry.measurementId)) {
        final currentController = _controllers[mEntry.measurementId]!;
        if (mounted && currentController.text != valueText) {
          currentController.text = valueText;
        }
      } else {
        _controllers[mEntry.measurementId] =
            TextEditingController(text: valueText == "0" ? "" : valueText);
      }
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _indoorNoteSearchController.dispose();
    _outdoorNoteSearchController.dispose();
    _outdoorPSINoteSearchController.dispose();
    _indoorRemarkController.dispose();
    _outdoorRemarkController.dispose();
    _outdoorPsiRemarkController.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  TextEditingController _getController(MeasurementEntry mEntry) {
    if (!_controllers.containsKey(mEntry.measurementId)) {
      _initializeOrUpdateControllers(widget.measurements);
      if (_controllers.containsKey(mEntry.measurementId)) {
        return _controllers[mEntry.measurementId]!;
      } else {
        return TextEditingController();
      }
    }
    return _controllers[mEntry.measurementId]!;
  }

  // Helper untuk update semua remark di grup
  void _updateGroupRemark(String remark, List<MeasurementEntry> groupItems) {
    final bloc = context.read<ValidationDropdownBloc>();
    for (var item in groupItems) {
      if (item.isSkipped ?? false) {
        final event = widget.isBefore
            ? UpdateMeasurementBefore(item.copyWith(remark: remark))
            : UpdateMeasurementAfter(item.copyWith(remark: remark));
        bloc.add(event);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocState = context.watch<ValidationDropdownBloc>().state;
    if (blocState is! ValidationDropdownLoaded) {
      return const SizedBox.shrink();
    }

    const indoorIds = {'temperature'};
    const outdoorElecIds = {'volt', 'ampere'};
    const outdoorPsiIds = {'psi'};

    final indoorMeasurements = widget.measurements.where((m) => indoorIds.contains(m.measurementId)).toList();
    final outdoorElecMeasurements = widget.measurements.where((m) => outdoorElecIds.contains(m.measurementId)).toList();
    final outdoorPsiMeasurements = widget.measurements.where((m) => outdoorPsiIds.contains(m.measurementId)).toList();

    final bool isIndoorSkipped = indoorMeasurements.any((m) => m.isSkipped ?? false);
    final bool isOutdoorElecSkipped = outdoorElecMeasurements.any((m) => m.isSkipped ?? false);
    final bool isOutdoorPsiSkipped = outdoorPsiMeasurements.any((m) => m.isSkipped ?? false);

    Widget buildMeasurementWidget(MeasurementEntry mEntry) {
      final limits = widget.limitsMap[mEntry.measurementId];
      if (limits == null) return Text("Error: Config for ${mEntry.measurementId} missing");

      final controller = _getController(mEntry);

      // --- HAPUS LOGIC REMARK DARI SINI ---
      // Kita pindahkan ke bawah (di level grup)

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: MeasurementInputWidget(
          controller: controller,
          transNo: widget.transNo,
          label: limits.label,
          key: ValueKey('${widget.isBefore ? 'before' : 'after'}_${mEntry.measurementId}'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          limits: limits,
          initialImage: mEntry.capturedImage,
          onEditingComplete: (newValue) {
            final updatedValue = double.tryParse(newValue) ?? 0.0;
            final event = widget.isBefore
                ? UpdateMeasurementBefore(mEntry.copyWith(value: updatedValue))
                : UpdateMeasurementAfter(mEntry.copyWith(value: updatedValue));
            context.read<ValidationDropdownBloc>().add(event);
          },
          onImageChanged: (newImage) {
            final event = widget.isBefore
                ? UpdateMeasurementBefore(mEntry.copyWith(capturedImage: newImage))
                : UpdateMeasurementAfter(mEntry.copyWith(capturedImage: newImage));
            context.read<ValidationDropdownBloc>().add(event);
          },
          isSkipEnabled: true,
          isSkipped: mEntry.isSkipped ?? false,
          onSkipChanged: (isSkipped) {
            final bloc = context.read<ValidationDropdownBloc>();
            final measurementId = mEntry.measurementId;
            final NoteType noteType;
            if (measurementId == 'temperature') {
              noteType = NoteType.indoor;
            } else if (measurementId == 'volt' || measurementId == 'ampere') {
              noteType = NoteType.outdoor;
            } else {
              noteType = NoteType.outdoorPsi;
            }

            final updateEvent = widget.isBefore
                ? UpdateMeasurementBefore(mEntry.copyWith(isSkipped: isSkipped, value: 0.0, capturedImage: null, remark: ''))
                : UpdateMeasurementAfter(mEntry.copyWith(isSkipped: isSkipped, value: 0.0, capturedImage: null, remark: ''));
            bloc.add(updateEvent);

            if (isSkipped) {
              controller.clear();
              // Remark controller jangan di-clear di sini, karena shared per grup
            }

            // Logic Reset Note (SAMA)
            if (!isSkipped) {
              Future.microtask(() {
                if (!mounted) return;
                final currentBlocState = context.read<ValidationDropdownBloc>().state;
                if (currentBlocState is ValidationDropdownLoaded) {
                  final List<MeasurementEntry> relevantMeasurements = widget.isBefore
                      ? currentBlocState.capturedMeasurementsBefore
                      : currentBlocState.capturedMeasurementsAfter;
                  Set<String> currentGroupIds;
                  if (noteType == NoteType.indoor) currentGroupIds = indoorIds;
                  else if (noteType == NoteType.outdoor) currentGroupIds = outdoorElecIds;
                  else currentGroupIds = outdoorPsiIds;
                  final bool anyOtherSkippedInGroup = relevantMeasurements
                      .where((m) => m.measurementId != measurementId)
                      .any((m) => currentGroupIds.contains(m.measurementId) && (m.isSkipped ?? false));
                  if (!anyOtherSkippedInGroup) {
                    bloc.add(NoteChanged(null, noteType: noteType, isBefore: widget.isBefore));
                  }
                }
              });
            } else {
              bloc.add(NoteChanged(null, noteType: noteType, isBefore: widget.isBefore));
            }
          },
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (indoorMeasurements.isNotEmpty) ...[
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Pengukuran Unit Indoor (${widget.isBefore ? "Sebelum" : "Sesudah"})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          ...indoorMeasurements.map(buildMeasurementWidget),

          // --- DROPDOWN & REMARK INDOOR ---
          if (isIndoorSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore ? blocState.noteIndoorBeforeOptions : blocState.noteIndoorAfterOptions,
              selectedValue: widget.isBefore ? blocState.selectedIndoorNoteBefore : blocState.selectedIndoorNoteAfter,
              searchController: _indoorNoteSearchController,
              label: 'Alasan Skip Pengukuran Indoor',
              remarkController: _indoorRemarkController, // Pass remark controller
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                  NoteChanged(value, noteType: NoteType.indoor, isBefore: widget.isBefore),
                );
              },
              onRemarkChanged: (val) => _updateGroupRemark(val, indoorMeasurements),
            ),
        ],

        // ... (Header Outdoor SAMA) ...
        if (outdoorElecMeasurements.isNotEmpty || outdoorPsiMeasurements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(width: double.infinity, color: Colors.grey.shade200, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: Text('Pengukuran Unit Outdoor (${widget.isBefore ? "Sebelum" : "Sesudah"})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          const SizedBox(height: 16),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(builder: (context, state) { if (state is ValidationDropdownLoaded) { final bool isEnabled = state.currentStep == 0; return DropdownButtonFormField<String>(value: state.selectedOutdoorSerialNo, isExpanded: true, decoration: const InputDecoration(labelText: 'Pilih Serial No. Outdoor', border: OutlineInputBorder()), hint: const Text('Pilih Serial No. Outdoor'), items: state.outdoorSerialNumbers.map((serial) => DropdownMenuItem(value: serial, child: Text(serial))).toList(), onChanged: isEnabled ? (value) { if (value != null) context.read<ValidationDropdownBloc>().add(SelectOutdoorSerial(value)); } : null, validator: (value) => value == null ? 'Serial No. Outdoor harus dipilih' : null); } return const SizedBox.shrink(); })),
        ],

        // --- OUTDOOR ELEC (Volt/Ampere) ---
        if (outdoorElecMeasurements.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...outdoorElecMeasurements.map(buildMeasurementWidget),
          if (isOutdoorElecSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore ? blocState.noteOutdoorBeforeOptions : blocState.noteOutdoorAfterOptions,
              selectedValue: widget.isBefore ? blocState.selectedOutdoorNoteBefore : blocState.selectedOutdoorNoteAfter,
              searchController: _outdoorNoteSearchController,
              label: 'Alasan Skip (Volt/Ampere)',
              remarkController: _outdoorRemarkController,
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                    NoteChanged(value, noteType: NoteType.outdoor, isBefore: widget.isBefore));
              },
              onRemarkChanged: (val) => _updateGroupRemark(val, outdoorElecMeasurements),
            ),
        ],

        // --- OUTDOOR PSI ---
        if (outdoorPsiMeasurements.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...outdoorPsiMeasurements.map(buildMeasurementWidget),
          if (isOutdoorPsiSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore ? blocState.noteOutdoorPsiBeforeOptions : blocState.noteOutdoorPsiAfterOptions,
              selectedValue: widget.isBefore ? blocState.selectedOutdoorPSINoteBefore : blocState.selectedOutdoorPSINoteAfter,
              searchController: _outdoorPSINoteSearchController,
              label: 'Alasan Skip (Tekanan)',
              remarkController: _outdoorPsiRemarkController,
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                    NoteChanged(value, noteType: NoteType.outdoorPsi, isBefore: widget.isBefore));
              },
              onRemarkChanged: (val) => _updateGroupRemark(val, outdoorPsiMeasurements),
            ),
        ],
      ],
    );
  }

  // --- MODIFIKASI _buildNoteDropdown (MENAMBAHKAN TEXTFIELD) ---
  Widget _buildNoteDropdown({
    required BuildContext context,
    required List<NoteOption> options,
    required String? selectedValue,
    required TextEditingController searchController,
    required String label,
    required ValueChanged<String?> onChanged,
    required TextEditingController remarkController,
    required ValueChanged<String> onRemarkChanged,
  }) {
    final double maxDropdownHeight = MediaQuery.of(context).size.height * 0.4;
    final filteredOptions = options.where((opt) => !opt.isSystemOnly || opt.label == selectedValue).toList();

    // Cek apakah opsi terpilih butuh remark
    final selectedOptionObj = filteredOptions.where((opt) => opt.label == selectedValue).firstOrNull;
    final bool isReadOnlySystemValue = selectedOptionObj?.isSystemOnly ?? false;
    final bool requireRemark = selectedOptionObj?.requireRemark ?? false;

    final dropdownKey = ValueKey('note_dropdown_${label}_${selectedValue ?? 'null'}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16.0),
      child: Column(
        children: [
          DropdownButtonFormField2<String>(
            key: dropdownKey,
            value: selectedValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: '$label (*Wajib)',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              filled: true,
              fillColor: isReadOnlySystemValue ? Colors.grey.shade200 : Colors.white,
            ),
            hint: Text('Pilih Alasan', style: const TextStyle(fontSize: 14)),
            onChanged: isReadOnlySystemValue ? null : (value) {
              onChanged(value);
              FocusScope.of(context).unfocus();
              // Reset remark controller jika ganti opsi
              remarkController.clear();
              onRemarkChanged('');
            },
            items: filteredOptions.map((item) => DropdownMenuItem<String>(
              value: item.label,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text(item.label, style: const TextStyle(fontSize: 14))),
              ),
            )).toList(),
            selectedItemBuilder: (context) {
              return options.map((item) {
                return Text(item.label, style: const TextStyle(fontSize: 14, overflow: TextOverflow.ellipsis), maxLines: 1);
              }).toList();
            },
            dropdownStyleData: DropdownStyleData(
              maxHeight: maxDropdownHeight,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
            ),
            menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 14)),
            dropdownSearchData: DropdownSearchData(searchController: searchController, searchInnerWidgetHeight: 50, searchInnerWidget: Container(height: 50, padding: const EdgeInsets.all(8), child: TextFormField(expands: true, maxLines: null, controller: searchController, decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), hintText: 'Cari catatan...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))), searchMatchFn: (item, searchValue) => item.value.toString().toLowerCase().contains(searchValue.toLowerCase())),
            onMenuStateChange: (isOpen) { if (!isOpen) searchController.clear(); },
          ),

          // --- TEXT FIELD REMARK (MUNCUL DI BAWAH DROPDOWN) ---
          if (requireRemark && !widget.isBefore) // Hanya muncul jika requireRemark=true DAN di halaman After
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: TextFormField(
                controller: remarkController,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  labelText: 'Keterangan Tambahan (*Wajib)',
                  hintText: 'Jelaskan detail masalah dan solusinya (Min. 20 huruf)...',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  prefixIcon: const Icon(Icons.edit_note),
                ),
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
                maxLines: 2,
              ),
            ),
          // ----------------------------------------------------
        ],
      ),
    );
  }
}