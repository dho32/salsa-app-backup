// lib/models/pos_unserviceable_model.dart

import 'package:hive/hive.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

part 'pos_unserviceable_model.g.dart';

@HiveType(typeId: 13) // Pastikan typeId ini unik
class PosUnserviceableModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String reason;

  @HiveField(2)
  String? notes;

  @HiveField(3)
  List<CapturedImageDetail> proofImages;

  @HiveField(4)
  DateTime reportedAt;

  @HiveField(5)
  String reportedBy;

  @HiveField(6)
  String reportedById;

  @HiveField(7)
  String technicianName;

  PosUnserviceableModel({
    required this.transNo,
    required this.reason,
    this.notes,
    required this.proofImages,
    required this.reportedAt,
    required this.reportedBy,
    required this.reportedById,
    required this.technicianName,
  });
}