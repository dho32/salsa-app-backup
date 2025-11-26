import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/measurement_input_widget.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/common/measurement_limits.dart'; // <-- Import Model Baru

class GenericMeasurementInputSection extends StatelessWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final Map<String, TextEditingController> controllers;

  // --- 1. TAMBAHKAN MAP LIMIT DINAMIS ---
  final Map<String, MeasurementLimits> limitsMap;
  // --------------------------------------

  final Function(MeasurementEntry) onUpdate;
  final double? indoorTemp;
  final VoidCallback? onMaybeResetNote;

  const GenericMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.controllers,

    // --- 2. TAMBAHKAN DI CONSTRUCTOR ---
    required this.limitsMap,
    // -----------------------------------

    required this.onUpdate,
    required this.indoorTemp,
    this.onMaybeResetNote,
  });

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: const Text("Pengukuran Unit",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        ...measurements.map((mEntry) {

          // --- 3. GANTI LOGIC LOOKUP LIMIT ---
          // Dulu: kPOSMeasurementLimits...
          // Sekarang: Ambil dari limitsMap yang dipassing
          final limits = limitsMap[mEntry.measurementId];

          if (limits == null) {
            return Text("Error: Config for ${mEntry.measurementId} missing");
          }
          // -----------------------------------

          final controller = controllers[mEntry.measurementId];

          if (controller == null) {
            return const SizedBox.shrink();
          }

          var limitsToUse = limits;
          const String indoorTempMeasurementId = 'temperature';

          if (mEntry.measurementId == indoorTempMeasurementId &&
              indoorTemp != null) {
            // Logic penyesuaian limit suhu indoor (tetap dipertahankan)
            limitsToUse = MeasurementLimits(
              id: limits.id,
              label: limits.label,
              min: limits.min,
              max: indoorTemp!, // Override max dengan suhu ruangan saat ini
              normalMax: limits.normalMax,
              normalMin: limits.normalMin,
              unit: limits.unit,
            );
          }

          return Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: MeasurementInputWidget(
              controller: controller,
              transNo: transNo,
              label: limitsToUse.label,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              limits: limitsToUse,
              initialImage: mEntry.capturedImage,
              onEditingComplete: (finalValue) {
                final updatedValue =
                    double.tryParse(finalValue) ?? mEntry.value;
                onUpdate(mEntry.copyWith(value: updatedValue));
              },
              onImageChanged: (newImage) {
                onUpdate(mEntry.copyWith(capturedImage: newImage));
              },
              isSkipEnabled: true,
              isSkipped: mEntry.isSkipped ?? false,
              onSkipChanged: (isSkipped) {
                if (isSkipped) {
                  onUpdate(mEntry.copyWith(
                      isSkipped: true, value: 0.0, capturedImage: null));
                  controller.clear();
                  onMaybeResetNote?.call();
                } else {
                  onUpdate(mEntry.copyWith(isSkipped: false));
                  onMaybeResetNote?.call();
                }
              },
            ),
          );
        }),
      ],
    );
  }
}