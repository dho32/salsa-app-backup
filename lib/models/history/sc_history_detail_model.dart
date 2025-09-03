// models/history/sc_history_detail_model.dart

class ScHistoryDetailModel {
  final ScHistoryCustomerInfo customerInfo;
  final ScHistoryPicInfo picInfo;
  final ScHistoryTicketInfo ticketInfo;
  final List<ScHistoryUnitInfo> unitInfo;

  ScHistoryDetailModel({
    required this.customerInfo,
    required this.picInfo,
    required this.ticketInfo,
    required this.unitInfo,
  });

  factory ScHistoryDetailModel.fromJson(Map<String, dynamic> json) {
    return ScHistoryDetailModel(
      customerInfo: ScHistoryCustomerInfo.fromJson(json['customer_info'] ?? {}),
      picInfo: ScHistoryPicInfo.fromJson(json['pic_info'] ?? {}),
      ticketInfo: ScHistoryTicketInfo.fromJson(json['ticket_info'] ?? {}),
      unitInfo: (json['unit_info'] as List<dynamic>? ?? [])
          .map((item) => ScHistoryUnitInfo.fromJson(item))
          .toList(),
    );
  }
}

// Bagian: Informasi Customer
class ScHistoryCustomerInfo {
  final String storeName;
  final String storeAddress;
  final String branch;
  final String contact;

  ScHistoryCustomerInfo({
    required this.storeName,
    required this.storeAddress,
    required this.branch,
    required this.contact,
  });

  factory ScHistoryCustomerInfo.fromJson(Map<String, dynamic> json) {
    return ScHistoryCustomerInfo(
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      branch: json['branch'] ?? '',
      contact: json['contact'] ?? '',
    );
  }
}

// Bagian: PIC Toko
class ScHistoryPicInfo {
  final String name;
  final String phone;
  final String nik;
  final String position;
  final String imageUrl; // URL foto PIC dari server

  ScHistoryPicInfo({
    required this.name,
    required this.phone,
    required this.nik,
    required this.position,
    required this.imageUrl,
  });

  factory ScHistoryPicInfo.fromJson(Map<String, dynamic> json) {
    return ScHistoryPicInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      nik: json['nik'] ?? '',
      position: json['position'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

// Bagian: Tiket Service Call
class ScHistoryTicketInfo {
  final String transNo;
  final String status;
  final String complaintDate;
  final String category;
  final String complaint;
  final String serviceDate;
  final List<String> technicians;

  ScHistoryTicketInfo({
    required this.transNo,
    required this.status,
    required this.complaintDate,
    required this.category,
    required this.complaint,
    required this.serviceDate,
    required this.technicians,
  });

  factory ScHistoryTicketInfo.fromJson(Map<String, dynamic> json) {
    return ScHistoryTicketInfo(
      transNo: json['trans_no'] ?? '',
      status: json['status'] ?? '',
      complaintDate: json['complaint_date'] ?? '',
      category: json['category'] ?? '',
      complaint: json['complaint'] ?? '',
      serviceDate: json['service_date'] ?? '',
      technicians: List<String>.from(json['technicians'] ?? []),
    );
  }
}

// Bagian: Informasi Unit (Struktur data di dalam ExpansionTile)
class ScHistoryUnitInfo {
  final String unitName;
  final String serialNo;
  final String complaint;
  final String imgUrl;
  final List<String> photosBefore; // List of image URLs
  final List<String> photosAfter; // List of image URLs
  final List<ScHistoryMeasurement> measurementsBefore;
  final List<ScHistoryMeasurement> measurementsAfter;
  final List<ScHistoryProblem> problems;
  final String outdoorSerialNo;

  ScHistoryUnitInfo({
    required this.unitName,
    required this.serialNo,
    required this.complaint,
    required this.imgUrl,
    required this.photosBefore,
    required this.photosAfter,
    required this.measurementsBefore,
    required this.measurementsAfter,
    required this.problems,
    required this.outdoorSerialNo,
  });

  // --- IMPLEMENTASI LENGKAP DARI fromJson ---
  factory ScHistoryUnitInfo.fromJson(Map<String, dynamic> json) {
    return ScHistoryUnitInfo(
      unitName: json['unit_name'] ?? '',
      serialNo: json['serial_no'] ?? '',
      complaint: json['complaint'] ?? '',
      imgUrl: json['image_url'] ?? '',
      photosBefore: List<String>.from(json['photos_before'] ?? []),
      photosAfter: List<String>.from(json['photos_after'] ?? []),
      measurementsBefore: (json['measurements_before'] as List<dynamic>? ?? [])
          .map((item) => ScHistoryMeasurement.fromJson(item))
          .toList(),
      measurementsAfter: (json['measurements_after'] as List<dynamic>? ?? [])
          .map((item) => ScHistoryMeasurement.fromJson(item))
          .toList(),
      problems: (json['problems'] as List<dynamic>? ?? [])
          .map((item) => ScHistoryProblem.fromJson(item))
          .toList(),
      outdoorSerialNo: json['outdoor_serial_no'] ?? '',
    );
  }
}

// Sub-model untuk Pengukuran
class ScHistoryMeasurement {
  final String name; // e.g., "Suhu Sebelum"
  final String value; // e.g., "9.6 °C"
  final String imageUrl;

  ScHistoryMeasurement.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        value = json['value'] ?? '',
        imageUrl = json['image_url'] ?? '';
}

// Sub-model untuk Permasalahan
class ScHistoryProblem {
  final String problemName;
  final List<String> solutions;

  ScHistoryProblem.fromJson(Map<String, dynamic> json)
      : problemName = json['problem_name'] ?? '',
        solutions = List<String>.from(json['solutions'] ?? []);
}