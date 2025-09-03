import 'package:hive/hive.dart';

part 'confirmation_task_queue.g.dart';

@HiveType(typeId: 6)
class ConfirmationTaskModel extends HiveObject {
  @HiveField(0)
  String transNo;

  @HiveField(1)
  int retryCount;

  ConfirmationTaskModel({
    required this.transNo,
    this.retryCount = 0,
  });
}