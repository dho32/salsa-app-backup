// lib/screens/service_call/service_call_validation/components/widgets/measurement_input_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../../../components/widgets/measurement_input_widget.dart';
import '../../../../../models/common/measurement_entry.dart';
import '../../../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart'; // Import MeasurementLimits

class MeasurementInputSection extends StatefulWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final List<MeasurementLimits> availableMeasurements;
  final Function(MeasurementEntry) onUpdate;

  const MeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.availableMeasurements,
    required this.onUpdate,
  });

  @override
  State<MeasurementInputSection> createState() =>
      _MeasurementInputSectionState();
}

class _MeasurementInputSectionState extends State<MeasurementInputSection> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant MeasurementInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.measurements != oldWidget.measurements) {
      _disposeControllers();
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    for (var mEntry in widget.measurements) {
      final valueText = mEntry.value == mEntry.value.truncateToDouble()
          ? mEntry.value.truncate().toString()
          : mEntry.value.toStringAsFixed(1);
      _controllers[mEntry.measurementId] = TextEditingController(text: valueText);
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  TextEditingController _getController(MeasurementEntry mEntry) {
    return _controllers[mEntry.measurementId]!;
  }

  @override
  Widget build(BuildContext context) {
    final indoorMeasurements = widget.measurements.where((m) {
      return m.measurementId.toLowerCase().contains('temperature');
    }).toList();

    final outdoorMeasurements = widget.measurements.where((m) {
      // Ambil semua sisa nya yang BUKAN suhu.
      return !m.measurementId.toLowerCase().contains('temperature');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Pengukuran Unit Indoor', // Judul baru
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...indoorMeasurements.map((mEntry) {
          // Logika untuk membuat MeasurementInputWidget tetap SAMA PERSIS
          final limits = widget.availableMeasurements.firstWhere(
            (ml) => ml.id == mEntry.measurementId,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MeasurementInputWidget(
              controller: _getController(mEntry),
              transNo: widget.transNo,
              label: limits.label,
              key: ValueKey('indoor_${mEntry.measurementId}'),
              // Beri key unik
              keyboardType: const TextInputType.numberWithOptions(
                // MODIFIKASI: Pastikan TextInputType ini konsisten
                decimal: true,
              ),
              limits: limits,
              onChanged: (newValue) {
                final updatedValue = double.tryParse(newValue) ?? mEntry.value;
                widget.onUpdate(
                  MeasurementEntry(
                    measurementId: mEntry.measurementId,
                    value: updatedValue,
                    unit: mEntry.unit,
                    capturedImage:
                        mEntry.capturedImage, // Pastikan foto juga diteruskan
                  ),
                );
              },
              initialImage: mEntry.capturedImage,
              // BARU: Teruskan foto awal
              onImageChanged: (newImage) {
                // BARU: Tangani perubahan foto
                widget.onUpdate(MeasurementEntry(
                  measurementId: mEntry.measurementId,
                  value: mEntry.value, // Pertahankan nilai pengukuran
                  unit: mEntry.unit,
                  capturedImage: newImage,
                ));
              },
            ),
          );
        }),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Pengukuran Unit Outdoor', // Judul baru
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
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
              return const SizedBox
                  .shrink(); // Tampilkan kosong jika state lain
            },
          ),
        ),
        const SizedBox(height: 8),
        ...outdoorMeasurements.map((mEntry) {
          // Logika untuk membuat MeasurementInputWidget juga SAMA PERSIS
          final limits = widget.availableMeasurements.firstWhere(
            (ml) => ml.id == mEntry.measurementId,
            orElse: () => MeasurementLimits(
              id: mEntry.measurementId,
              label: mEntry.measurementId,
              unit: '',
              min: 0,
              max: 100,
              normalMin: 0,
              normalMax: 100,
            ),
          );

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MeasurementInputWidget(
              controller: _getController(mEntry),
              transNo: widget.transNo,
              label: limits.label,
              key: ValueKey('outdoor_${mEntry.measurementId}'),
              // Beri key unik
              keyboardType: const TextInputType.numberWithOptions(
                // MODIFIKASI: Pastikan TextInputType ini konsisten
                decimal: true,
                signed: true,
              ),
              limits: limits,
              onChanged: (newValue) {
                final updatedValue = double.tryParse(newValue) ?? mEntry.value;
                widget.onUpdate(
                  MeasurementEntry(
                    measurementId: mEntry.measurementId,
                    value: updatedValue,
                    unit: mEntry.unit,
                    capturedImage:
                        mEntry.capturedImage, // Pastikan foto juga diteruskan
                  ),
                );
              },
              initialImage: mEntry.capturedImage,
              onImageChanged: (newImage) {
                widget.onUpdate(MeasurementEntry(
                  measurementId: mEntry.measurementId,
                  value: mEntry.value,
                  unit: mEntry.unit,
                  capturedImage: newImage,
                ));
              },
            ),
          );
        }),
      ],
    );
  }
}
