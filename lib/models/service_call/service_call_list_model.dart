class ServiceCallListModel {
  final String transNo;
  final String postedDate;
  final String ageComplaint;
  final String ahoNo;
  final String complaintSubject;
  final String shipTo;
  final String shipToName;
  final String technicianName;
  final String closedDate;
  final String branchId;
  final String branchName;

  ServiceCallListModel({
    required this.transNo,
    required this.postedDate,
    required this.ageComplaint,
    required this.ahoNo,
    required this.complaintSubject,
    required this.shipTo,
    required this.shipToName,
    required this.technicianName,
    required this.closedDate,
    required this.branchId,
    required this.branchName,
  });

  factory ServiceCallListModel.fromJson(Map<String, dynamic> json) {
    return ServiceCallListModel(
      transNo: json['trans_no'],
      postedDate: json['posted_date'],
      ageComplaint: json['age_complaint'],
      ahoNo: json['aho_no'],
      complaintSubject: json['complaint_subject'],
      shipTo: json['ship_to'],
      shipToName: json['ship_to_name'],
      technicianName: json['technician_name'],
      closedDate: json['closed_date'],
      branchId: json['branch_id'],
      branchName: json['branch_name'],
    );
  }
}
