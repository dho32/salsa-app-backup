
class PosHistoryDetailModel {
  final PosHistoryCustomerInfo customerInfo;
  final PosHistoryPicInfo picInfo;
  final PosHistoryTicketInfo ticketInfo;
  final List<PosHistoryUnitInfo> unitInfo;

  PosHistoryDetailModel({
    required this.customerInfo,
    required this.picInfo,
    required this.ticketInfo,
    required this.unitInfo,
  });

  factory PosHistoryDetailModel.fromJson(Map<String, dynamic> json) {
    return PosHistoryDetailModel(
      customerInfo: PosHistoryCustomerInfo.fromJson(json['customer_info'] ?? {}),
      picInfo: PosHistoryPicInfo.fromJson(json['pic_info'] ?? {}),
      ticketInfo: PosHistoryTicketInfo.fromJson(json['ticket_info'] ?? {}),
      unitInfo: (json['unit_info'] as List<dynamic>? ?? [])
          .map((item) => PosHistoryUnitInfo.fromJson(item))
          .toList(),
    );
  }
}

class PosHistoryCustomerInfo {
  final String storeName;
  final String storeAddress;
  final String branch;
  final String contact;

  PosHistoryCustomerInfo({
    required this.storeName,
    required this.storeAddress,
    required this.branch,
    required this.contact,
  });

  factory PosHistoryCustomerInfo.fromJson(Map<String, dynamic> json) {
    return PosHistoryCustomerInfo(
      storeName: json['store_name'] ?? '',
      storeAddress: json['store_address'] ?? '',
      branch: json['branch'] ?? '',
      contact: json['store_phone'] ?? '',
    );
  }
}

// Bagian: Tiket Dokumen Proof of Service
class PosHistoryTicketInfo {
  final String transNo;
  final String status;
  final String scheduleDate;
  final List<String> technicians;
  final String tempIn;
  final String tempOut;
  final String serviceTime;

  PosHistoryTicketInfo({
    required this.transNo,
    required this.status,
    required this.scheduleDate,
    required this.technicians,
    required this.tempIn,
    required this.tempOut,
    required this.serviceTime,
  });

  factory PosHistoryTicketInfo.fromJson(Map<String, dynamic> json) {
    return PosHistoryTicketInfo(
      transNo: json['trans_no'] ?? '',
      status: json['status'] ?? '',
      // --- UBAH KEY DI SINI ---
      scheduleDate: json['required_date'] ?? '', // Ganti dari 'schedule_date'
      technicians: List<String>.from(json['technicians'] ?? []),
      tempIn: json['temperature_in'] ?? '',
      tempOut: json['temperature_out'] ?? '',
      serviceTime: json['service_time'] ?? '',
    );
  }
}

// Bagian: PIC Toko
class PosHistoryPicInfo {
  final String name;
  final String phone;
  final String nik;
  final String position;
  final String imageUrl; // URL foto PIC dari server

  PosHistoryPicInfo({
    required this.name,
    required this.phone,
    required this.nik,
    required this.position,
    required this.imageUrl,
  });

  factory PosHistoryPicInfo.fromJson(Map<String, dynamic> json) {
    return PosHistoryPicInfo(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      nik: json['nik'] ?? '',
      position: json['position'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }
}

// Bagian: Informasi Unit untuk Proof of Service
class PosHistoryUnitInfo {
  final String unitName;
  final String articleDesc;
  final String serialNo;
  final List<String> photosBefore;
  final List<String> photosAfter;
  final List<PosHistoryMeasurement> measurements; // Kita bisa gunakan ulang ScHistoryMeasurement

  PosHistoryUnitInfo({
    required this.unitName,
    required this.articleDesc,
    required this.serialNo,
    required this.photosBefore,
    required this.photosAfter,
    required this.measurements,
  });

  factory PosHistoryUnitInfo.fromJson(Map<String, dynamic> json) {
    return PosHistoryUnitInfo(
      unitName: json['unit_name'] ?? '',
      articleDesc: json['article_desc'] ?? '',
      serialNo: json['serial_no'] ?? '',
      photosBefore: List<String>.from(json['photos_before'] ?? []),
      photosAfter: List<String>.from(json['photos_after'] ?? []),
      measurements: (json['measurements'] as List<dynamic>? ?? [])
          .map((item) => PosHistoryMeasurement.fromJson(item))
          .toList(),
    );
  }
}

class PosHistoryMeasurement {
  final String name; // e.g., "Suhu Sebelum"
  final String value; // e.g., "9.6 °C"
  final String imageUrl;

  PosHistoryMeasurement.fromJson(Map<String, dynamic> json)
      : name = json['name'] ?? '',
        value = json['value'] ?? '',
        imageUrl = json['image_url'] ?? '';
}