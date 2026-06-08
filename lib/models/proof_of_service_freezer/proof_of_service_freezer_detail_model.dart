import 'package:hive/hive.dart';

// Wajib untuk men-generate Adapter (build_runner)
part 'proof_of_service_freezer_detail_model.g.dart';

// --- TYPE ID: 150 - 152 --- (data tugas Cuci Freezer dari server, read-only/cache)
// Catatan: Hive hanya mengizinkan typeId 0-223; blok 200-an sudah penuh (RRO s/d 223).

@HiveType(typeId: 150)
class ProofOfServiceFreezerDetailModel extends HiveObject {
  @HiveField(0)
  final ProofOfServiceFreezerHeader? header;

  @HiveField(1)
  final List<ProofOfServiceFreezerItem> items;

  ProofOfServiceFreezerDetailModel({
    this.header,
    this.items = const [],
  });

  factory ProofOfServiceFreezerDetailModel.fromJson(Map<String, dynamic> json) {
    // Dukung payload {result: {...}} maupun langsung {...}
    final result = (json['result'] is Map) ? json['result'] : json;
    return ProofOfServiceFreezerDetailModel(
      header: result['header'] != null
          ? ProofOfServiceFreezerHeader.fromJson(Map<String, dynamic>.from(result['header']))
          : null,
      items: result['detail'] != null
          ? List<ProofOfServiceFreezerItem>.from(
              result['detail'].map((x) => ProofOfServiceFreezerItem.fromJson(Map<String, dynamic>.from(x))))
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'header': header?.toJson(),
        'detail': items.map((x) => x.toJson()).toList(),
      };
}

@HiveType(typeId: 151)
class ProofOfServiceFreezerHeader extends HiveObject {
  @HiveField(0)
  final String transNo;
  @HiveField(1)
  final String poDate;
  @HiveField(2)
  final String shipTo; // kode toko (dipakai OTP)
  @HiveField(3)
  final String shipToName; // nama toko
  @HiveField(4)
  final String shipToAddress;
  @HiveField(5)
  final String shipToMail; // email toko (dipakai OTP)
  @HiveField(6)
  final String branchCode;
  @HiveField(7)
  final String branchName;
  @HiveField(8)
  final double latitude;
  @HiveField(9)
  final double longitude;

  ProofOfServiceFreezerHeader({
    required this.transNo,
    this.poDate = '',
    this.shipTo = '',
    this.shipToName = '',
    this.shipToAddress = '',
    this.shipToMail = '',
    this.branchCode = '',
    this.branchName = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  factory ProofOfServiceFreezerHeader.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceFreezerHeader(
      transNo: json['trans_no'] ?? '',
      poDate: json['po_date'] ?? '',
      shipTo: json['ship_to'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? '',
      shipToMail: json['ship_to_mail'] ?? '',
      branchCode: json['branch_code'] ?? '',
      branchName: json['branch_name'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'trans_no': transNo,
        'po_date': poDate,
        'ship_to': shipTo,
        'ship_to_name': shipToName,
        'ship_to_address': shipToAddress,
        'ship_to_mail': shipToMail,
        'branch_code': branchCode,
        'branch_name': branchName,
        'latitude': latitude,
        'longitude': longitude,
      };
}

@HiveType(typeId: 152)
class ProofOfServiceFreezerItem extends HiveObject {
  @HiveField(0)
  final String serialNo;
  @HiveField(1)
  final String articleNo;
  @HiveField(2)
  final String articleDesc;
  @HiveField(3)
  final String unitDesc;
  @HiveField(4)
  final int lineNo;
  @HiveField(5)
  final bool isGeneric;
  @HiveField(6)
  final int unitIndex;

  ProofOfServiceFreezerItem({
    required this.serialNo,
    this.articleNo = '',
    this.articleDesc = '',
    this.unitDesc = '',
    this.lineNo = 0,
    this.isGeneric = false,
    this.unitIndex = 0,
  });

  factory ProofOfServiceFreezerItem.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceFreezerItem(
      serialNo: json['serial_no'] ?? '',
      articleNo: json['article_no'] ?? '',
      articleDesc: json['article_desc'] ?? '',
      unitDesc: json['unit_desc'] ?? '',
      lineNo: json['line_no'] ?? 0,
      isGeneric: json['is_generic'] ?? false,
      unitIndex: json['unit_index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'serial_no': serialNo,
        'article_no': articleNo,
        'article_desc': articleDesc,
        'unit_desc': unitDesc,
        'line_no': lineNo,
        'is_generic': isGeneric,
        'unit_index': unitIndex,
      };
}
