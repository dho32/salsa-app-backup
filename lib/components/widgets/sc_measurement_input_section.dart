import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../../../components/constants.dart'; // Untuk kMeasurementLimits
import '../../../../../components/widgets/measurement_input_widget.dart';
import '../../../../../models/common/measurement_entry.dart';
import '../../../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';

class ScMeasurementInputSection extends StatefulWidget {
  final String transNo;
  final List<MeasurementEntry>
      measurements; // Data pengukuran (Before ATAU After)
  final bool isBefore; // Flag penanda

  const ScMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.isBefore,
  });

  @override
  State<ScMeasurementInputSection> createState() =>
      _ScMeasurementInputSectionState();
}

class _ScMeasurementInputSectionState extends State<ScMeasurementInputSection> {
  final Map<String, TextEditingController> _controllers = {};
  final TextEditingController _indoorNoteSearchController =
      TextEditingController();
  final TextEditingController _outdoorNoteSearchController =
      TextEditingController();
  final TextEditingController _outdoorPSINoteSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeOrUpdateControllers(widget.measurements);
  }

  @override
  void didUpdateWidget(covariant ScMeasurementInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika list measurements (instance-nya) berubah, proses ulang controllers
    if (!identical(widget.measurements, oldWidget.measurements)) {
      _initializeOrUpdateControllers(widget.measurements);
      // Panggil setState DI SINI untuk memastikan rebuild UI parent
      setState(() {});
    }
  }

  void _initializeOrUpdateControllers(List<MeasurementEntry> measurements) {
    _disposeControllers();
    final currentIds = widget.measurements.map((m) => m.measurementId).toSet();
    // Hapus controller lama
    _controllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    // Buat/Update controller
    for (var mEntry in widget.measurements) {
      final valueText = mEntry.isSkipped ?? false
          ? ''
          : (mEntry.value == mEntry.value.truncateToDouble()
              ? mEntry.value.truncate().toString()
              : mEntry.value.toStringAsFixed(2)); // Sesuaikan format jika perlu

      if (_controllers.containsKey(mEntry.measurementId)) {
        // Update jika teks berbeda & tidak di-skip
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
      // Jika controller hilang, coba inisialisasi ulang
      print(
          "⚠️ Controller missing for ${mEntry.measurementId}, re-initializing...");
      _initializeOrUpdateControllers(widget.measurements);
      // Kembalikan controller baru jika berhasil dibuat
      if (_controllers.containsKey(mEntry.measurementId)) {
        return _controllers[mEntry.measurementId]!;
      } else {
        // Fallback jika masih gagal (seharusnya tidak terjadi)
        print(
            "🔴 FATAL: Failed to create controller for ${mEntry.measurementId}");
        return TextEditingController(); // Kembalikan controller kosong
      }
    }
    return _controllers[mEntry.measurementId]!;
  }

  @override
  Widget build(BuildContext context) {
    final blocState = context.watch<ValidationDropdownBloc>().state;
    if (blocState is! ValidationDropdownLoaded) {
      return const SizedBox.shrink(); // Jangan render jika state belum siap
    }

    const indoorIds = {'temperature'};
    const outdoorElecIds = {'volt', 'ampere'}; // Volt & Ampere
    const outdoorPsiIds = {'psi'};

    // Pisahkan pengukuran indoor & outdoor
    final indoorMeasurements = widget.measurements
        .where((m) => indoorIds.contains(m.measurementId))
        .toList();
    final outdoorElecMeasurements = widget.measurements
        .where((m) => outdoorElecIds.contains(m.measurementId))
        .toList();
    final outdoorPsiMeasurements = widget.measurements
        .where((m) => outdoorPsiIds.contains(m.measurementId))
        .toList();

    final bool isIndoorSkipped =
        indoorMeasurements.any((m) => m.isSkipped ?? false);
    final bool isOutdoorElecSkipped =
        outdoorElecMeasurements.any((m) => m.isSkipped ?? false);
    final bool isOutdoorPsiSkipped =
        outdoorPsiMeasurements.any((m) => m.isSkipped ?? false);

    // Ambil daftar Limits dari konstanta
    final List<MeasurementLimits> availableLimits =
        kMeasurementLimits.values.toList();

    // Fungsi helper untuk merender satu MeasurementInputWidget
    Widget buildMeasurementWidget(MeasurementEntry mEntry) {
      final limits = availableLimits
          .firstWhereOrNull((ml) => ml.id == mEntry.measurementId);
      if (limits == null) {
        return Text("Error: Config for ${mEntry.measurementId} missing");
      }

      final controller = _getController(mEntry);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
        child: MeasurementInputWidget(
          controller: controller,
          transNo: widget.transNo,
          label: limits.label,
          key: ValueKey(
              '${widget.isBefore ? 'before' : 'after'}_${mEntry.measurementId}'),
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
                ? UpdateMeasurementBefore(
                    mEntry.copyWith(capturedImage: newImage))
                : UpdateMeasurementAfter(
                    mEntry.copyWith(capturedImage: newImage));
            context.read<ValidationDropdownBloc>().add(event);
          },
          isSkipEnabled: true,
          isSkipped: mEntry.isSkipped ?? false,

          // --- ✅ PERBAIKAN UTAMA DI SINI ✅ ---
          onSkipChanged: (isSkipped) {
            final bloc = context.read<ValidationDropdownBloc>();
            final measurementId = mEntry.measurementId;

            // 1. Tentukan NoteType yang benar
            final NoteType noteType;
            if (measurementId == 'temperature') {
              noteType = NoteType.indoor;
            } else if (measurementId == 'volt' || measurementId == 'ampere') {
              noteType = NoteType.outdoor;
            } else {
              noteType = NoteType.outdoorPsi;
            }

            // 2. Kirim event update measurement (tidak berubah)
            final updateEvent = widget.isBefore
                ? UpdateMeasurementBefore(mEntry.copyWith(
                    isSkipped: isSkipped,
                    value: 0.0,
                    capturedImage: null,
                  ))
                : UpdateMeasurementAfter(mEntry.copyWith(
                    isSkipped: isSkipped,
                    value: 0.0,
                    capturedImage: null,
                  ));
            bloc.add(updateEvent);

            // 3. Update controller LOKAL (tidak berubah)
            if (isSkipped) {
              controller.clear();
            }

            // 4. Logika reset note (unskip)
            if (!isSkipped) {
              Future.microtask(() {
                if (!mounted) return;
                final currentBlocState =
                    context.read<ValidationDropdownBloc>().state;
                if (currentBlocState is ValidationDropdownLoaded) {
                  final List<MeasurementEntry> relevantMeasurements =
                      widget.isBefore
                          ? currentBlocState.capturedMeasurementsBefore
                          : currentBlocState.capturedMeasurementsAfter;

                  // Tentukan grup ID yang relevan
                  const indoorIds = {'temperature'};
                  const outdoorElecIds = {'volt', 'ampere'};
                  const outdoorPsiIds = {'psi'};
                  Set<String> currentGroupIds;
                  if (noteType == NoteType.indoor) {
                    currentGroupIds = indoorIds;
                  } else if (noteType == NoteType.outdoor) {
                    currentGroupIds = outdoorElecIds;
                  } else {
                    currentGroupIds = outdoorPsiIds;
                  }

                  // Cek apakah ada measurement LAIN di grup yg SAMA yg MASIH di-skip
                  final bool anyOtherSkippedInGroup = relevantMeasurements
                      .where((m) => m.measurementId != measurementId)
                      .any((m) =>
                          currentGroupIds.contains(m.measurementId) &&
                          (m.isSkipped ?? false));

                  // Jika TIDAK ADA yg lain di-skip, trigger reset note
                  if (!anyOtherSkippedInGroup) {
                    bloc.add(NoteChanged(null,
                        noteType: noteType, // <-- Kirim noteType yang benar
                        isBefore: widget.isBefore));
                  }
                }
              });
            } else {
              // 5. Reset note (skip)
              bloc.add(NoteChanged(null,
                  noteType: noteType, // <-- Kirim noteType yang benar
                  isBefore: widget.isBefore));
            }
          },
          // --- AKHIR PERBAIKAN ---
        ),
      );
    }

    // --- Struktur UI Section ---
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (indoorMeasurements.isNotEmpty) ...[
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
                'Pengukuran Unit Indoor (${widget.isBefore ? "Sebelum" : "Sesudah"})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 8),
          ...indoorMeasurements.map(buildMeasurementWidget),
          if (isIndoorSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore
                  ? blocState.noteIndoorBeforeOptions
                  : blocState.noteIndoorAfterOptions,
              selectedValue: widget.isBefore
                  ? blocState.selectedIndoorNoteBefore
                  : blocState.selectedIndoorNoteAfter,
              searchController: _indoorNoteSearchController,
              label: 'Alasan Skip Pengukuran Indoor',
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                      NoteChanged(value,
                          noteType: NoteType.indoor, isBefore: widget.isBefore),
                    );
              },
            ),
        ],
        if (outdoorElecMeasurements.isNotEmpty ||
            outdoorPsiMeasurements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
                'Pengukuran Unit Outdoor (${widget.isBefore ? "Sebelum" : "Sesudah"})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          // Dropdown Serial Outdoor (HANYA tampil di step 'Sebelum')
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
              builder: (context, state) {
                if (state is ValidationDropdownLoaded) {
                  final bool isEnabled = state.currentStep == 0;
                  return DropdownButtonFormField<String>(
                    value: state.selectedOutdoorSerialNo,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Serial No. Outdoor',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Pilih Serial No. Outdoor'),
                    items: state.outdoorSerialNumbers
                        .map((serial) => DropdownMenuItem(
                              value: serial,
                              child: Text(serial),
                            ))
                        .toList(),
                    onChanged: isEnabled
                        ? (value) {
                            if (value != null) {
                              context
                                  .read<ValidationDropdownBloc>()
                                  .add(SelectOutdoorSerial(value));
                            }
                          }
                        : null,
                    validator: (value) => value == null
                        ? 'Serial No. Outdoor harus dipilih'
                        : null,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
        if (outdoorElecMeasurements.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...outdoorElecMeasurements.map(buildMeasurementWidget),
          if (isOutdoorElecSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore
                  ? blocState.noteOutdoorBeforeOptions
                  : blocState.noteOutdoorAfterOptions,
              selectedValue: widget.isBefore
                  ? blocState.selectedOutdoorNoteBefore
                  : blocState.selectedOutdoorNoteAfter,
              searchController: _outdoorNoteSearchController,
              label: 'Alasan Skip (Volt/Ampere)',
              // Label baru
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                      NoteChanged(value,
                          noteType: NoteType.outdoor,
                          isBefore: widget.isBefore),
                    );
              },
            ),
        ],
        if (outdoorPsiMeasurements.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...outdoorPsiMeasurements.map(buildMeasurementWidget),
          if (isOutdoorPsiSkipped)
            _buildNoteDropdown(
              context: context,
              options: widget.isBefore
                  ? blocState.noteOutdoorPsiBeforeOptions
                  : blocState.noteOutdoorPsiAfterOptions,
              selectedValue: widget.isBefore
                  ? blocState.selectedOutdoorPSINoteBefore
                  : blocState.selectedOutdoorPSINoteAfter,
              searchController: _outdoorPSINoteSearchController,
              // Controller baru
              label: 'Alasan Skip (Tekanan)',
              // Label baru
              onChanged: (value) {
                context.read<ValidationDropdownBloc>().add(
                      NoteChanged(value,
                          noteType: NoteType.outdoorPsi,
                          isBefore: widget.isBefore),
                    );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildNoteDropdown({
    required BuildContext context,
    required List<String> options,
    required String? selectedValue,
    required TextEditingController searchController,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    final double maxDropdownHeight = MediaQuery.of(context).size.height * 0.4;
    final dropdownKey =
        ValueKey('note_dropdown_${label}_${selectedValue ?? 'null'}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16.0),
      child: DropdownButtonFormField2<String>(
        key: dropdownKey,
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '$label (*Wajib)',
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        hint: Text('Pilih Alasan', style: const TextStyle(fontSize: 14)),
        items: options
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(item, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return options.map((item) {
            return Text(
              item,
              style: const TextStyle(
                  fontSize: 14, overflow: TextOverflow.ellipsis),
              maxLines: 1,
            );
          }).toList();
        },
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxDropdownHeight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 14),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'Cari alasan...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) => item.value
              .toString()
              .toLowerCase()
              .contains(searchValue.toLowerCase()),
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) searchController.clear();
        },
      ),
    );
  }
}
