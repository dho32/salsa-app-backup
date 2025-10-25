// generic_measurement_input_section.dart - Versi FINAL

import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/measurement_input_widget.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import '../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../constants.dart';

// DIUBAH: Menjadi StatelessWidget karena tidak lagi mengelola state internal.
class GenericMeasurementInputSection extends StatelessWidget {
  final String transNo;
  final List<MeasurementEntry> measurements;
  final Map<String, TextEditingController> controllers; // DITAMBAHKAN: Menerima controller dari induk
  final Function(MeasurementEntry) onUpdate;
  final double? indoorTemp;

  const   GenericMeasurementInputSection({
    super.key,
    required this.transNo,
    required this.measurements,
    required this.controllers, // DITAMBAHKAN: Wajib diisi oleh induk
    required this.onUpdate,
    required this.indoorTemp,
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
              style:
              TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        ...measurements.map((mEntry) {
          final limits = kPOSMeasurementLimits.values.firstWhere(
                (ml) => ml.id == mEntry.measurementId,
          );

          // Mengambil controller yang sesuai dari map yang diberikan oleh induk
          final controller = controllers[mEntry.measurementId];

          // Jika karena suatu alasan controller tidak ditemukan, jangan render widgetnya
          if (controller == null) {
            return const SizedBox.shrink();
          }

          var limitsToUse = limits;
          const String indoorTempMeasurementId = 'temperature';

          if (mEntry.measurementId == indoorTempMeasurementId && indoorTemp != null) {
            limitsToUse = MeasurementLimits(
              id: limits.id, label: limits.label, min: limits.min,
              max: indoorTemp!, normalMax: limits.normalMax,
              normalMin: limits.normalMin, unit: limits.unit,
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: MeasurementInputWidget(
              controller: controller, // DIUBAH: Menggunakan controller dari induk
              transNo: transNo,
              label: limitsToUse.label,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              limits: limitsToUse,
              initialImage: mEntry.capturedImage,
              onEditingComplete: (finalValue) {
                final updatedValue = double.tryParse(finalValue) ?? mEntry.value;
                onUpdate(mEntry.copyWith(value: updatedValue));
              },
              onImageChanged: (newImage) {
                onUpdate(mEntry.copyWith(capturedImage: newImage));
              },
              isSkipEnabled: true,
              isSkipped: mEntry.isSkipped ?? false,
              onSkipChanged: (isSkipped) {
                if (isSkipped) {
                  onUpdate(mEntry.copyWith(isSkipped: true));
                  controller.clear();
                } else {
                  onUpdate(mEntry.copyWith(isSkipped: false));
                }
              },
            ),
          );
        }),
      ],
    );
  }
}