/// File: models/proof_of_service/proof_of_service_detail_model.dart

import 'package:hive/hive.dart';

// Tambahkan baris 'part' ini. Nama file harus sesuai.
part 'proof_of_service_detail_model.g.dart';

@HiveType(typeId: 10) // <-- Tambahkan anotasi HiveType dengan ID unik
class ProofOfServiceDetailModel {
  @HiveField(0) // <-- Tambahkan anotasi HiveField untuk setiap properti
  final ProofOfServiceHeader header;

  @HiveField(1)
  final List<ProofOfServiceItemDetail> detail;

  @HiveField(2)
  final List<String>? noteIndoorOptions;

  @HiveField(3)
  final List<String>? noteOutdoorOptions;

  @HiveField(4)
  final List<String>? unserviceableReasons;

  ProofOfServiceDetailModel({
    required this.header,
    required this.detail,
    this.noteIndoorOptions,
    this.noteOutdoorOptions,
    this.unserviceableReasons,
  });

  // Biarkan factory fromJson tetap ada untuk parsing data dari API
  factory ProofOfServiceDetailModel.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceDetailModel(
      header: ProofOfServiceHeader.fromJson(json['header'] ?? {}),
      detail: (json['detail'] as List<dynamic>? ?? [])
          .map((item) => ProofOfServiceItemDetail.fromJson(item))
          .toList(),
      noteIndoorOptions: List<String>.from(json['note_indoor_options'] ?? []),
      noteOutdoorOptions: List<String>.from(json['note_outdoor_options'] ?? []),
      unserviceableReasons: List<String>.from(json['unserviceable_reasons'] ?? []),
    );
  }
}

@HiveType(typeId: 11) // <-- ID unik lainnya
class ProofOfServiceHeader {
  @HiveField(0)
  final String transNo;
  @HiveField(1)
  final String poDate;
  @HiveField(2)
  final String shipToCode;
  @HiveField(3)
  final String shipToName;
  @HiveField(4)
  final String shipToAddress;
  @HiveField(5)
  final String branchCode;
  @HiveField(6)
  final String branchName;
  @HiveField(7)
  final String storeEmail;
  @HiveField(8)
  final String latitude;
  @HiveField(9)
  final String longitude;

  ProofOfServiceHeader({
    required this.transNo,
    required this.poDate,
    required this.shipToCode,
    required this.shipToName,
    required this.shipToAddress,
    required this.branchCode,
    required this.branchName,
    required this.storeEmail,
    required this.latitude,
    required this.longitude,
  });

  factory ProofOfServiceHeader.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceHeader(
      transNo: json['trans_no'] ?? '',
      poDate: json['po_date'] ?? '',
      shipToCode: json['ship_to_code'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? '',
      branchCode: json['branch_code'] ?? '',
      branchName: json['branch_name'] ?? '',
      storeEmail: json['store_email'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
    );
  }
}

@HiveType(typeId: 12) // <-- ID unik lainnya
class ProofOfServiceItemDetail {
  @HiveField(0)
  final String articleNo;
  @HiveField(1)
  final String articleDesc;
  @HiveField(2)
  final String unitDesc;
  @HiveField(3)
  final String serialNo;
  @HiveField(4)
  final String unitType;

  ProofOfServiceItemDetail({
    required this.articleNo,
    required this.articleDesc,
    required this.unitDesc,
    required this.serialNo,
    required this.unitType,
  });

  factory ProofOfServiceItemDetail.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceItemDetail(
      articleNo: json['article_no'] ?? '',
      articleDesc: json['description'] ?? '',
      unitDesc: json['article_name_unit'] ?? '',
      serialNo: json['serial_no'] ?? '',
      unitType: json['unit_type'] ?? '',
    );
  }
}