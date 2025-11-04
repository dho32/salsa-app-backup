import 'package:salsa/models/service_call/problem_source_model.dart';

class ServiceCallDetailModel {
  final ServiceCallHeader header;
  final List<ServiceCallUnitDetail> detail;
  final List<OutdoorUnit> outdoor;
  final List<ProblemSourceModel> problems;
  final List<String> unserviceableReasons;
  final List<String> noteIndoorBeforeOptions;
  final List<String> noteIndoorAfterOptions;
  final List<String> noteOutdoorBeforeOptions;
  final List<String> noteOutdoorAfterOptions;
  final List<String> noteOutdoorPsiBeforeOptions;
  final List<String> noteOutdoorPsiAfterOptions;

  ServiceCallDetailModel({
    required this.header,
    required this.detail,
    required this.outdoor,
    required this.problems,
    required this.unserviceableReasons,
    required this.noteIndoorBeforeOptions,
    required this.noteIndoorAfterOptions,
    required this.noteOutdoorBeforeOptions,
    required this.noteOutdoorAfterOptions,
    required this.noteOutdoorPsiBeforeOptions,
    required this.noteOutdoorPsiAfterOptions,
  });

  factory ServiceCallDetailModel.fromJson(Map<String, dynamic> json) {
    var outdoorList = json['outdoor'] as List<dynamic>? ?? [];
    var problemList = json['problems'] as List<dynamic>? ?? [];

    return ServiceCallDetailModel(
      header: ServiceCallHeader.fromJson(json['header']),
      detail: (json['detail'] as List<dynamic>)
          .map((item) => ServiceCallUnitDetail.fromJson(item))
          .toList(),
      outdoor: outdoorList.map((item) => OutdoorUnit.fromJson(item)).toList(),
      problems: problemList.map((item) => ProblemSourceModel.fromJson(item)).toList(),
      unserviceableReasons: List<String>.from(json['unserviceable_reasons'] ?? []),
      noteIndoorBeforeOptions: List<String>.from(json['note_indoor_before_options'] ?? []),
      noteIndoorAfterOptions: List<String>.from(json['note_indoor_after_options'] ?? []),
      noteOutdoorBeforeOptions: List<String>.from(json['note_outdoor_before_options'] ?? []),
      noteOutdoorAfterOptions: List<String>.from(json['note_outdoor_after_options'] ?? []),
      noteOutdoorPsiBeforeOptions: List<String>.from(json['note_outdoor_psi_before_options'] ?? []),
      noteOutdoorPsiAfterOptions: List<String>.from(json['note_outdoor_psi_after_options'] ?? []),
    );
  }
}

class ServiceCallHeader {
  final String branchId;
  final String branchName;
  final String storeId;
  final String storeName;
  final String storeAddress;
  final String storeEmail;
  final String storeLat;
  final String storeLong;
  final String contactName;
  final String contactPhone;
  final String transNo;
  final String pathAttachment;
  final String postedDate;
  final String complaintCategory;
  final String complaintSubject;
  final String technicianName1;
  final String technicianName2;
  final String technicianName3;
  final String closedDate;
  final String status;

  ServiceCallHeader({
    required this.branchId,
    required this.branchName,
    required this.storeId,
    required this.storeName,
    required this.storeAddress,
    required this.storeEmail,
    required this.storeLat,
    required this.storeLong,
    required this.contactName,
    required this.contactPhone,
    required this.transNo,
    required this.pathAttachment,
    required this.postedDate,
    required this.complaintCategory,
    required this.complaintSubject,
    required this.technicianName1,
    required this.technicianName2,
    required this.technicianName3,
    required this.closedDate,
    required this.status,
  });

  factory ServiceCallHeader.fromJson(Map<String, dynamic> json) {
    return ServiceCallHeader(
      branchId: json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      storeId: json['store_id'] ?? '',
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      storeEmail: json['store_email'] ?? '',
      storeLat: json['latitude'] ?? '0.0',
      storeLong: json['longitude'] ?? '0.0',
      contactName: json['contact_name'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      transNo: json['trans_no'] ?? '',
      pathAttachment: json['path_attachment'] ?? '',
      postedDate: json['posted_date'] ?? '',
      complaintCategory: json['complaint_category'] ?? '',
      complaintSubject: json['complaint_subject'] ?? '',
      technicianName1: json['technician_name_1'] ?? '',
      technicianName2: json['technician_name_2'] ?? '',
      technicianName3: json['technician_name_3'] ?? '',
      closedDate: json['closed_date'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class ServiceCallUnitDetail {
  final String articleNameUnit;
  final String serialNo;
  final String complaintDetails;
  final String assetAge;
  final String rentDate;
  final String leasesEndingDate;
  final String lineNo;
  final String imageFile;

  ServiceCallUnitDetail({
    required this.articleNameUnit,
    required this.serialNo,
    required this.complaintDetails,
    required this.assetAge,
    required this.rentDate,
    required this.leasesEndingDate,
    required this.lineNo,
    required this.imageFile,
  });

  factory ServiceCallUnitDetail.fromJson(Map<String, dynamic> json) {
    return ServiceCallUnitDetail(
      articleNameUnit: json['article_name_unit'] ?? '',
      serialNo: json['serial_no'] ?? '',
      complaintDetails: json['complaint_details'] ?? '',
      assetAge: json['rental_period'] ?? '',
      rentDate: json['rent_date'] ?? '',
      leasesEndingDate: json['leases_ending_date'] ?? '',
      lineNo: json['line_no'] ?? '',
      imageFile: json['image_file'] ?? '',
    );
  }
}

class OutdoorUnit {
  final String serialNo;

  OutdoorUnit({required this.serialNo});

  factory OutdoorUnit.fromJson(Map<String, dynamic> json) {
    return OutdoorUnit(
      serialNo: json['serial_no'] ?? '',
    );
  }
}
