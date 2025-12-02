import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/measurement_input_widget.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/common/measurement_limits.dart';

class GenericMeasurementInputSection extends StatelessWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final Map<String, TextEditingController> controllers;
  final Map<String, MeasurementLimits> limitsMap;
  final Function(MeasurementEntry) onUpdate;
  final double? indoorTemp;
  final VoidCallback? onMaybeResetNote;

  const GenericMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.controllers,
    required this.limitsMap,
    required this.onUpdate,
    required this.indoorTemp,
    this.onMaybeResetNote,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text(
            "Pengukuran Unit",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        ...measurements.map(_buildMeasurementItem),
      ],
    );
  }

  Widget _buildMeasurementItem(MeasurementEntry mEntry) {
    final limits = limitsMap[mEntry.measurementId];
    final controller = controllers[mEntry.measurementId];

    if (limits == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text("⚠️ Config missing for: ${mEntry.measurementId}"),
      );
    }

    if (controller == null) {
      return const SizedBox.shrink();
    }

    MeasurementLimits limitsToUse = limits;

    if (mEntry.measurementId == 'temperature' && indoorTemp != null) {
      limitsToUse = MeasurementLimits(
        id: limits.id,
        label: limits.label,
        min: limits.min,
        max: indoorTemp!,
        normalMin: limits.normalMin,
        normalMax: limits.normalMax,
        unit: limits.unit,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: MeasurementInputWidget(
        controller: controller,
        transNo: transNo,
        label: limitsToUse.label,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        limits: limitsToUse,
        initialImage: mEntry.capturedImage,
        onEditingComplete: (finalValue) {
          final parsedValue = double.tryParse(finalValue);
          onUpdate(
            mEntry.copyWith(
              value: parsedValue ?? mEntry.value,
            ),
          );
        },
        onImageChanged: (newImage) {
          onUpdate(mEntry.copyWith(capturedImage: newImage));
        },
        isSkipEnabled: true,
        isSkipped: mEntry.isSkipped ?? false,
        onSkipChanged: (isSkipped) {
          if (isSkipped) {
            controller.clear();
            onUpdate(
              mEntry.copyWith(
                isSkipped: true,
                value: 0.0,
                capturedImage: null,
              ),
            );
          } else {
            onUpdate(mEntry.copyWith(isSkipped: false));
          }
          onMaybeResetNote?.call();
        },
      ),
    );
  }
}
