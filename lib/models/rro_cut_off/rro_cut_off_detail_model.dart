import 'package:hive/hive.dart';

// Wajib ditambahkan untuk men-generate file Adapter (build_runner)
part 'rro_cut_off_detail_model.g.dart';

// --- TYPE ID: 220 - 223 ---

class RROCutOffDetailResponseModel {
  final String? status;
  final String? message;
  final RROCutOffResult? result;

  RROCutOffDetailResponseModel({
    this.status,
    this.message,
    this.result,
  });

  factory RROCutOffDetailResponseModel.fromJson(Map<String, dynamic> json) {
    return RROCutOffDetailResponseModel(
      status: json['status'],
      message: json['message'],
      result: json['result'] != null ? RROCutOffResult.fromJson(json['result']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result?.toJson(),
    };
  }
}

// 👇 MULAI DARI SINI YANG DISIMPAN KE HIVE 👇

@HiveType(typeId: 220)
class RROCutOffResult extends HiveObject {
  @HiveField(0)
  final RROCutOffHeader? header;

  @HiveField(1)
  final List<RROCutOffDetailItem> detail;

  @HiveField(2)
  final List<RROCutOffSerialNumber> serialNumber;

  RROCutOffResult({
    this.header,
    this.detail = const [],
    this.serialNumber = const [],
  });

  factory RROCutOffResult.fromJson(Map<String, dynamic> json) {
    return RROCutOffResult(
      header: json['header'] != null ? RROCutOffHeader.fromJson(json['header']) : null,
      detail: json['detail'] != null
          ? List<RROCutOffDetailItem>.from(json['detail'].map((x) => RROCutOffDetailItem.fromJson(x)))
          : [],
      serialNumber: json['serial_number'] != null
          ? List<RROCutOffSerialNumber>.from(json['serial_number'].map((x) => RROCutOffSerialNumber.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header?.toJson(),
      'detail': detail.map((x) => x.toJson()).toList(),
      'serial_number': serialNumber.map((x) => x.toJson()).toList(),
    };
  }
}

@HiveType(typeId: 221)
class RROCutOffHeader extends HiveObject {
  @HiveField(0)
  final String transNo;

  @HiveField(1)
  final String rroType;

  @HiveField(2)
  final String poCustNo;

  @HiveField(3)
  final String estimatedRroCutOffDate;

  @HiveField(4)
  final String branchName;

  @HiveField(5)
  final String shipTo;

  @HiveField(6)
  final String shipToName;

  @HiveField(7)
  final String shipToAddress;

  @HiveField(8)
  final String shipToMail;

  @HiveField(9)
  final double latitude;

  @HiveField(10)
  final double longitude;

  @HiveField(11)
  final bool isPic;

  RROCutOffHeader({
    required this.transNo,
    required this.rroType,
    required this.poCustNo,
    required this.estimatedRroCutOffDate,
    required this.branchName,
    required this.shipTo,
    required this.shipToName,
    required this.shipToAddress,
    required this.shipToMail,
    required this.latitude,
    required this.longitude,
    required this.isPic,
  });

  factory RROCutOffHeader.fromJson(Map<String, dynamic> json) {
    return RROCutOffHeader(
      transNo: json['trans_no'] ?? '',
      rroType: json['rro_type'] ?? '',
      poCustNo: json['po_cust_no'] ?? '',
      estimatedRroCutOffDate: json['estimated_rro_cut_off_date'] ?? '',
      branchName: json['branch_name'] ?? '',
      shipTo: json['ship_to'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? '',
      shipToMail: json['ship_to_mail'] ?? '',
      latitude: (json['latitude'] != null) ? double.tryParse(json['latitude'].toString()) ?? 0.0 : 0.0,
      longitude: (json['longitude'] != null) ? double.tryParse(json['longitude'].toString()) ?? 0.0 : 0.0,
      isPic: json['is_pic'] ?? true
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trans_no': transNo,
      'rro_type': rroType,
      'po_cust_no': poCustNo,
      'estimated_rro_cut_off_date': estimatedRroCutOffDate,
      'branch_name': branchName,
      'ship_to': shipTo,
      'ship_to_name': shipToName,
      'ship_to_address': shipToAddress,
      'ship_to_mail': shipToMail,
      'latitude': latitude,
      'longitude': longitude,
      'is_pic': isPic,
    };
  }
}

@HiveType(typeId: 222)
class RROCutOffDetailItem extends HiveObject {
  @HiveField(0)
  final String rroArticleNo;

  @HiveField(1)
  final String articleNameUnit;

  @HiveField(2)
  final String unitType; // "IN" atau "OUT"

  @HiveField(3)
  final int unitIndex;

  @HiveField(4)
  final int lineNo;

  RROCutOffDetailItem({
    required this.rroArticleNo,
    required this.articleNameUnit,
    required this.unitType,
    required this.unitIndex,
    required this.lineNo,
  });

  factory RROCutOffDetailItem.fromJson(Map<String, dynamic> json) {
    return RROCutOffDetailItem(
      rroArticleNo: json['rro_article_no'] ?? '',
      articleNameUnit: json['article_name_unit'] ?? '',
      unitType: json['unit_type'] ?? '',
      unitIndex: json['unit_index'] ?? 0,
      lineNo: json['line_no'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rro_article_no': rroArticleNo,
      'article_name_unit': articleNameUnit,
      'unit_type': unitType,
      'unit_index': unitIndex,
      'line_no': lineNo,
    };
  }
}

@HiveType(typeId: 223)
class RROCutOffSerialNumber extends HiveObject {
  @HiveField(0)
  final String rroArticleNo;

  @HiveField(1)
  final String unitType;

  @HiveField(2)
  final String serialNo;

  RROCutOffSerialNumber({
    required this.rroArticleNo,
    required this.unitType,
    required this.serialNo,
  });

  factory RROCutOffSerialNumber.fromJson(Map<String, dynamic> json) {
    return RROCutOffSerialNumber(
      rroArticleNo: json['rro_article_no'] ?? '',
      unitType: json['unit_type'] ?? '',
      serialNo: json['serial_no'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rro_article_no': rroArticleNo,
      'unit_type': unitType,
      'serial_no': serialNo,
    };
  }
}