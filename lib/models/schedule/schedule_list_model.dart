class ScheduleListItemModel {
  final String transNo;
  final String type;
  final String shipTo;
  final String shipToName;
  final String branchId;
  final String branchName;
  final DateTime scheduleDate;
  final String scheduleStatus; // late, today, scheduled, done

  const ScheduleListItemModel({
    required this.transNo,
    required this.type,
    required this.shipTo,
    required this.shipToName,
    required this.branchId,
    required this.branchName,
    required this.scheduleDate,
    required this.scheduleStatus,
  });

  factory ScheduleListItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleListItemModel(
      transNo: json['trans_no'] ?? 'N/A',
      type: json['type'] ?? '',
      shipTo: json['ship_to'] ?? '',
      shipToName: json['ship_to_name'] ?? 'No Name',
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      scheduleDate: DateTime.parse(json['schedule_date']),
      scheduleStatus: json['schedule_status'] ?? '',
    );
  }
}
