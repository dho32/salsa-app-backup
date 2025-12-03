// lib/models/common/measurement_entry.dart
import 'package:hive/hive.dart';
import 'captured_image_detail.dart';

part 'measurement_entry.g.dart';

@HiveType(typeId: 3)
class MeasurementEntry extends HiveObject {
  @HiveField(0)
  String measurementId; // Misal: "Tegangan", "Arus", "Suhu"
  @HiveField(1)
  double value;
  @HiveField(2)
  String unit; // Misal: "V", "A", "°C"
  @HiveField(3)
  CapturedImageDetail? capturedImage; // Path foto terkait, bisa null
  @HiveField(4)
  bool? isSkipped;
  @HiveField(5)
  final String? remark;

  MeasurementEntry({
    required this.measurementId,
    required this.value,
    required this.unit,
    this.capturedImage,
    this.isSkipped = false,
    this.remark,
  });

  MeasurementEntry copyWith({
    String? measurementId,
    double? value,
    String? unit,
    CapturedImageDetail? capturedImage,
    bool? isSkipped,
    String? remark,
  }) {
    return MeasurementEntry(
      measurementId: measurementId ?? this.measurementId,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      capturedImage: capturedImage ?? this.capturedImage,
      isSkipped: isSkipped ?? this.isSkipped,
      remark: remark ?? this.remark,
    );
  }

  List<Object?> get props => [
    measurementId,
    value,
    unit,
    capturedImage,
    isSkipped,
    remark,
  ];

}