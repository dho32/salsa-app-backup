import 'package:hive/hive.dart';

part 'otp_tracking_model.g.dart';

@HiveType(typeId: 113)
class OtpTrackingModel extends HiveObject {
  @HiveField(0)
  final String transNo;

  @HiveField(1)
  int retryCount;

  @HiveField(2)
  DateTime? lastRequestTime;

  OtpTrackingModel({
    required this.transNo,
    this.retryCount = 0,
    this.lastRequestTime,
  });
}