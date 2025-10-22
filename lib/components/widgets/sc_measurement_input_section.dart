import 'package:collection/collection.dart';
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
  final List<MeasurementEntry> measurements; // Data pengukuran (Before ATAU After)
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
      final valueText = mEntry.isSkipped ? '' :
      (mEntry.value == mEntry.value.truncateToDouble()
          ? mEntry.value.truncate().toString()
          : mEntry.value.toStringAsFixed(1)); // Sesuaikan format jika perlu

      if (_controllers.containsKey(mEntry.measurementId)) {
        // Update jika teks berbeda & tidak di-skip
        final currentController = _controllers[mEntry.measurementId]!;
        if (mounted && currentController.text != valueText) {
          currentController.text = valueText;
          // Tidak perlu setState di sini karena controller diupdate langsung
        }
      } else {
        // Buat controller baru jika belum ada
        _controllers[mEntry.measurementId] = TextEditingController(text: valueText);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }
  TextEditingController _getController(MeasurementEntry mEntry) {
    if (!_controllers.containsKey(mEntry.measurementId)) {
      // Jika controller hilang, coba inisialisasi ulang
      print("⚠️ Controller missing for ${mEntry.measurementId}, re-initializing...");
      _initializeOrUpdateControllers(widget.measurements);
      // Kembalikan controller baru jika berhasil dibuat
      if (_controllers.containsKey(mEntry.measurementId)) {
        return _controllers[mEntry.measurementId]!;
      } else {
        // Fallback jika masih gagal (seharusnya tidak terjadi)
        print("🔴 FATAL: Failed to create controller for ${mEntry.measurementId}");
        return TextEditingController(); // Kembalikan controller kosong
      }
    }
    return _controllers[mEntry.measurementId]!;
  }


  @override
  Widget build(BuildContext context) {
    // Pisahkan pengukuran indoor & outdoor
    final indoorMeasurements = widget.measurements.where((m) =>
        m.measurementId.toLowerCase().contains('temperature')
    ).toList();
    final outdoorMeasurements = widget.measurements.where((m) =>
    !m.measurementId.toLowerCase().contains('temperature')
    ).toList();

    // Ambil daftar Limits dari konstanta
    final List<MeasurementLimits> availableLimits = kMeasurementLimits.values.toList();

    // Fungsi helper untuk merender satu MeasurementInputWidget
    Widget buildMeasurementWidget(MeasurementEntry mEntry) {
      final limits = availableLimits.firstWhereOrNull((ml) => ml.id == mEntry.measurementId);
      if (limits == null) return Text("Error: Config for ${mEntry.measurementId} missing");

      final controller = _getController(mEntry);

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
          onEditingComplete: (newValue) { // Gunakan onEditingComplete
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
          isSkipped: mEntry.isSkipped,
          onSkipChanged: (isSkipped) {
            context.read<ValidationDropdownBloc>().add(
              ToggleMeasurementSkip(
                measurementId: mEntry.measurementId,
                isBefore: widget.isBefore,
                isSkipped: isSkipped,
              ),
            );
            if (isSkipped) {
              controller.clear();
              final event = widget.isBefore
                  ? UpdateMeasurementBefore(mEntry.copyWith(value: 0.0, capturedImage: null, isSkipped: true))
                  : UpdateMeasurementAfter(mEntry.copyWith(value: 0.0, capturedImage: null, isSkipped: true));
              context.read<ValidationDropdownBloc>().add(event);
            }
          },
        ),
      );
    } // Akhir buildMeasurementWidget

    // --- Struktur UI Section ---
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
        ],
        if (outdoorMeasurements.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Pengukuran Unit Outdoor (${widget.isBefore ? "Sebelum" : "Sesudah"})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          // Dropdown Serial Outdoor (HANYA tampil di step 'Sebelum')
          if (widget.isBefore) ...[
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
                      validator: (value) =>
                      value == null ? 'Serial No. Outdoor harus dipilih' : null,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...outdoorMeasurements.map(buildMeasurementWidget),
        ],
      ],
    );
  }
}