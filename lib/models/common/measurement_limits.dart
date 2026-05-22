import 'package:hive/hive.dart';

part 'measurement_limits.g.dart';

@HiveType(typeId: 15)
class MeasurementLimits {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final double min;

  @HiveField(3)
  final double max;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final double normalMin;

  @HiveField(6)
  final double normalMax;

  const MeasurementLimits({
    required this.id,
    required this.label,
    required this.min,
    required this.max,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
  });

  // --- 5. TAMBAHKAN FACTORY FROMJSON ---
  factory MeasurementLimits.fromJson(Map<String, dynamic> json) {
    // Helper untuk parse 'num' (int atau double) dengan aman
    double _parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return MeasurementLimits(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      min: _parseDouble(json['min']),
      max: _parseDouble(json['max']),
      unit: json['unit'] as String? ?? '',
      normalMin: _parseDouble(json['normal_min']),
      normalMax: _parseDouble(json['normal_max']),
    );
  }
}
