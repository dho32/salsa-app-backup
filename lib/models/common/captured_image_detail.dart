import 'package:hive/hive.dart';
part 'captured_image_detail.g.dart';

@HiveType(typeId: 2) // Pastikan ID ini unik secara global di aplikasi Anda
class CapturedImageDetail extends HiveObject {
  @HiveField(0)
  String imagePath; // Path lokal file
  @HiveField(1)
  DateTime timestamp;
  @HiveField(2)
  double latitude;
  @HiveField(3)
  double longitude;
  @HiveField(4)
  String address;
  @HiveField(5)
  String technicianName;
  @HiveField(6)
  String deviceModel;
  @HiveField(7)
  String transNo;

  CapturedImageDetail({
    required this.imagePath,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.technicianName,
    required this.deviceModel,
    required this.transNo,
  });
}