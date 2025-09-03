import 'dashboard_data_model.dart';

class DashboardResponseModel {
  final String status;
  final String message;
  final DashboardDataModel? result;

  DashboardResponseModel({
    required this.status,
    required this.message,
    this.result,
  });

  factory DashboardResponseModel.fromJson(Map<String, dynamic> json) {
    return DashboardResponseModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null
          ? DashboardDataModel.fromJson(json['result'])
          : null,
    );
  }
}
