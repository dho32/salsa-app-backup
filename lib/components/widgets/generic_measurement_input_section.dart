import 'package:flutter/material.dart';
import 'package:salsa/components/widgets/measurement_input_widget.dart';
import 'package:salsa/models/common/measurement_entry.dart';
import 'package:salsa/models/common/measurement_limits.dart';

class GenericMeasurementInputSection extends StatefulWidget {
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
  State<GenericMeasurementInputSection> createState() =>
      _GenericMeasurementInputSectionState();
}

class _GenericMeasurementInputSectionState
    extends State<GenericMeasurementInputSection> {
  final Map<String, MeasurementEntry> _localCache = {};

  @override
  void didUpdateWidget(covariant GenericMeasurementInputSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (var m in widget.measurements) {
      _localCache[m.measurementId] = m;
    }
  }

  // Fungsi helper buat ngirim data ke Parent dengan aman
  void _safeUpdate(MeasurementEntry updatedEntry) {
    _localCache[updatedEntry.measurementId] =
        updatedEntry;
    widget.onUpdate(updatedEntry);
  }

  // Fungsi helper buat dapetin data paling baru saat ini
  MeasurementEntry _getLatestEntry(MeasurementEntry mEntry) {
    return _localCache[mEntry.measurementId] ?? mEntry;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measurements.isEmpty) return const SizedBox.shrink();

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
        ...widget.measurements.map(_buildMeasurementItem),
      ],
    );
  }

  Widget _buildMeasurementItem(MeasurementEntry mEntry) {
    final limits = widget.limitsMap[mEntry.measurementId];
    final controller = widget.controllers[mEntry.measurementId];

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

    if (mEntry.measurementId == 'temperature' && widget.indoorTemp != null) {
      limitsToUse = MeasurementLimits(
        id: limits.id,
        label: limits.label,
        min: limits.min,
        max: widget.indoorTemp!,
        normalMin: limits.normalMin,
        normalMax: limits.normalMax,
        unit: limits.unit,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: MeasurementInputWidget(
        controller: controller,
        transNo: widget.transNo,
        label: limitsToUse.label,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        limits: limitsToUse,
        initialImage: _getLatestEntry(mEntry).capturedImage,
        onEditingComplete: (finalValue) {
          final parsedValue = double.tryParse(finalValue);
          final latest = _getLatestEntry(mEntry);
          _safeUpdate(
            latest.copyWith(
              value: parsedValue ?? latest.value,
            ),
          );
        },
        onImageChanged: (newImage) {
          final latest = _getLatestEntry(mEntry);
          _safeUpdate(latest.copyWith(capturedImage: newImage));
        },
        isSkipEnabled: true,
        isSkipped: _getLatestEntry(mEntry).isSkipped ?? false,
        onSkipChanged: (isSkipped) {
          final latest = _getLatestEntry(mEntry);
          if (isSkipped) {
            controller.clear();
            _safeUpdate(
              latest.copyWith(
                isSkipped: true,
                value: 0.0,
                capturedImage: null,
              ),
            );
          } else {
            _safeUpdate(latest.copyWith(isSkipped: false));
          }
          widget.onMaybeResetNote?.call();
        },
      ),
    );
  }
}
