import 'package:hive/hive.dart';

import '../common/captured_image_detail.dart';
import '../common/measurement_entry.dart';

part 'service_call_validation_entry_model.g.dart';

@HiveType(typeId: 0)
class ServiceCallValidationEntryModel extends HiveObject {
  @HiveField(0)
  String unitType;

  @HiveField(1)
  String serialNo;

  @HiveField(2)
  List<CapturedImageDetail> imagePathsBefore;

  @HiveField(3)
  List<MeasurementEntry> measurementsBefore;

  @HiveField(4)
  List<ValidationProblem> problems;

  @HiveField(5)
  List<CapturedImageDetail> imagePathsAfter;

  @HiveField(6)
  List<MeasurementEntry> measurementsAfter;

  @HiveField(7)
  String transNo;

  @HiveField(8)
  bool isCompleted;

  @HiveField(9)
  String? outdoorSerialNo;

  @HiveField(10)
  String? device;

  ServiceCallValidationEntryModel({
    required this.unitType,
    required this.serialNo,
    required this.imagePathsBefore,
    required this.measurementsBefore,
    required this.problems,
    required this.imagePathsAfter,
    required this.measurementsAfter,
    required this.transNo,
    this.isCompleted = false,
    this.outdoorSerialNo,
    this.device,
  });

  factory ServiceCallValidationEntryModel.empty() {
    return ServiceCallValidationEntryModel(
      unitType: '',
      serialNo: '',
      problems: [],
      imagePathsBefore: [], // MODIFIKASI: Inisialisasi
      measurementsBefore: [], // MODIFIKASI: Inisialisasi
      imagePathsAfter: [], // MODIFIKASI: Inisialisasi
      measurementsAfter: [], // MODIFIKASI: Inisialisasi
      transNo: '',
      isCompleted: false,
      outdoorSerialNo: '',
      device: '',
    );
  }
}

@HiveType(typeId: 1)
class ValidationProblem extends HiveObject {
  @HiveField(0)
  String problemId;

  @HiveField(1)
  List<String> solutionIds;

  ValidationProblem({
    required this.problemId,
    required this.solutionIds,
  });
}
