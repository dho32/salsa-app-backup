class TaskMaintenanceModel {
  final String status;
  final String message;
  final TransactionSuggestion result;

  TaskMaintenanceModel({
    required this.status,
    required this.message,
    required this.result,
  });

  factory TaskMaintenanceModel.fromJson(Map<String, dynamic> json) {
    return TaskMaintenanceModel(
      status: json['status'] as String,
      message: json['message'] as String,
      result: TransactionSuggestion.fromJson(
          json['result'] as Map<String, dynamic>),
    );
  }
}

class TransactionSuggestion {
  final String transNo;
  final String customerName;
  final String customerCode;
  final String type;
  final String status;
  final String? domainMail;

  TransactionSuggestion({
    required this.transNo,
    required this.customerName,
    required this.customerCode,
    required this.type,
    required this.status,
    this.domainMail,
  });

  factory TransactionSuggestion.fromJson(Map<String, dynamic> json) {
    return TransactionSuggestion(
      transNo: json['trans_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerCode: json['customer_code'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? '',
      domainMail: json['domain_mail'],
    );
  }
}

class POData {
  final String transNo;

  POData({required this.transNo});
}
