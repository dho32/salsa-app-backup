import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/measurement_input_widget.dart';
import 'package:salsa/models/common/measurement_entry.dart';

import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../constants.dart';

class GenericMeasurementInputSection extends StatefulWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final Function(MeasurementEntry) onUpdate;
  final double? indoorTemp;

  const GenericMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.onUpdate,
    required this.indoorTemp,
  });

  @override
  State<GenericMeasurementInputSection> createState() =>
      _GenericMeasurementInputSectionState();
}

class _GenericMeasurementInputSectionState extends State<GenericMeasurementInputSection> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant GenericMeasurementInputSection oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if(widget.measurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            'Pengukuran Unit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        ...widget.measurements.map((mEntry) {
          final limits = kPOSMeasurementLimits.values.firstWhere(
                (ml) => ml.id == mEntry.measurementId,
          );

          var limitsToUse = limits;
          const String indoorTempMeasurementId = 'temperature';

          if (mEntry.measurementId == indoorTempMeasurementId && widget.indoorTemp != null) {
            // Buat objek limit baru dengan menimpa nilai max
            limitsToUse = MeasurementLimits(
              id: limits.id,
              label: limits.label,
              min: limits.min,
              max: widget.indoorTemp!,
              normalMax: limits.normalMax,
              normalMin: limits.normalMin,
              unit: limits.unit,
              
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: MeasurementInputWidget(
              controller: _controllers[mEntry.measurementId]!,
              transNo: widget.transNo,
              label: limitsToUse.label,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              limits: limitsToUse,
              initialImage: mEntry.capturedImage,
              onChanged: (newValue) {
                final updatedValue = double.tryParse(newValue) ?? mEntry.value;
                widget.onUpdate(
                  MeasurementEntry(
                    measurementId: mEntry.measurementId,
                    value: updatedValue,
                    unit: mEntry.unit,
                    capturedImage: mEntry.capturedImage,
                  ),
                );
              },
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