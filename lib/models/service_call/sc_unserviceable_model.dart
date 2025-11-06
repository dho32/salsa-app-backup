// lib/models/pos_unserviceable_model.dart

import 'package:hive/hive.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

part 'sc_unserviceable_model.g.dart';

@HiveType(typeId: 14)
class SCUnserviceableModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  String pathAttachment;

  @HiveField(2)
  String reason;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  List<CapturedImageDetail> proofImages;

  @HiveField(5)
  DateTime reportedAt;

  @HiveField(6)
  String reportedBy;

  @HiveField(7)
  String reportedById;

  SCUnserviceableModel({
    required this.transNo,
    required this.pathAttachment,
    required this.reason,
    this.notes,
    required this.proofImages,
    required this.reportedAt,
    required this.reportedBy,
    required this.reportedById,
  });
}