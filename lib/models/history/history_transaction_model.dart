class HistoryTransactionModel {
  final String transNo;
  final String transactionType; // "Service Call" atau "Proof of Service"
  final String status; // "Selesai" atau "In Progress"
  final String storeName;
  final String picName;
  final String serviceDate;
  final int totalUnits;

  HistoryTransactionModel({
    required this.transNo,
    required this.transactionType,
    required this.status,
    required this.storeName,
    required this.picName,
    required this.serviceDate,
    required this.totalUnits,
  });

  factory HistoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return HistoryTransactionModel(
      transNo: json['trans_no'] ?? '',
      transactionType: json['transaction_type'] ?? '',
      status: json['status'] ?? '',
      storeName: json['store_name'] ?? '',
      picName: json['pic_name'] ?? '',
      serviceDate: json['service_date'] ?? '',
      totalUnits: json['total_units'] ?? 0,
    );
  }
}