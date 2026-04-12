import 'package:hive/hive.dart';
import '../common/note_option.dart';
import '../common/measurement_limits.dart'; // <-- JANGAN LUPA IMPORT INI KANG!

part 'proof_of_service_detail_model.g.dart';

@HiveType(typeId: 10)
class ProofOfServiceDetailModel {
  @HiveField(0)
  final ProofOfServiceHeader header;

  @HiveField(1)
  final List<ProofOfServiceItemDetail> detail;

  @HiveField(5)
  final List<NoteOption>? noteIndoorOptions;

  @HiveField(6)
  final List<NoteOption>? noteOutdoorOptions;

  @HiveField(7)
  final List<NoteOption>? unserviceableReasons;

  // --- [TAMBAHAN: WADAH LIMIT DINAMIS POS] ---
  @HiveField(8)
  final Map<String, MeasurementLimits>? customLimitsAfter;

  ProofOfServiceDetailModel({
    required this.header,
    required this.detail,
    this.noteIndoorOptions,
    this.noteOutdoorOptions,
    this.unserviceableReasons,
    this.customLimitsAfter, // <-- Tambahan
  });

  factory ProofOfServiceDetailModel.fromJson(Map<String, dynamic> json) {
    List<NoteOption> parseNotes(dynamic list) {
      if (list == null || list is! List) return [];
      return list.map((item) {
        if (item is Map) {
          return NoteOption.fromJson(Map<String, dynamic>.from(item));
        } else if (item is String) {
          return NoteOption.fromJson({'label': item});
        }
        return NoteOption(label: item.toString());
      }).toList();
    }

    // --- [TAMBAHAN: PARSING LIMIT DINAMIS DARI API] ---
    Map<String, MeasurementLimits> parsedLimitsAfter = {};

    if (json['measurements'] != null && json['measurements']['limits_validation_unit'] != null) {
      final limitsData = json['measurements']['limits_validation_unit'];

      // Ambil pos_after
      if (limitsData['pos_after'] != null && limitsData['pos_after'] is Map) {
        (limitsData['pos_after'] as Map).forEach((key, value) {
          if (value != null && value is Map) {
            parsedLimitsAfter[key.toString()] =
                MeasurementLimits.fromJson(Map<String, dynamic>.from(value));
          }
        });
      }
    }
    // ---------------------------------------------------

    return ProofOfServiceDetailModel(
      header: ProofOfServiceHeader.fromJson(json['header'] ?? {}),
      detail: (json['detail'] as List<dynamic>? ?? [])
          .map((item) => ProofOfServiceItemDetail.fromJson(item))
          .toList(),
      noteIndoorOptions: parseNotes(json['note_indoor_options']),
      noteOutdoorOptions: parseNotes(json['note_outdoor_options']),
      unserviceableReasons: parseNotes(json['unserviceable_reasons']),
      customLimitsAfter: parsedLimitsAfter, // <-- Inject ke Sini
    );
  }
}

@HiveType(typeId: 11)
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

@HiveType(typeId: 12)
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
  @HiveField(5)
  final String reffLineNo;

  // 🔥 NEW FIELDS FOR GENERIC UNIT 🔥
  @HiveField(6)
  final bool isGeneric;

  @HiveField(7)
  final int unitIndex;

  ProofOfServiceItemDetail({
    required this.articleNo,
    required this.articleDesc,
    required this.unitDesc,
    required this.serialNo,
    required this.unitType,
    required this.reffLineNo,
    this.isGeneric = false,
    this.unitIndex = 0,
  });

  factory ProofOfServiceItemDetail.fromJson(Map<String, dynamic> json) {
    return ProofOfServiceItemDetail(
      articleNo: json['article_no'] ?? '',
      articleDesc: json['description'] ?? '',
      unitDesc: json['article_name_unit'] ?? '',
      serialNo: json['serial_no'] ?? '',
      unitType: json['unit_type'] ?? '',
      reffLineNo: json['reff_line_no']?.toString() ?? '',

      // 🔥 Parsing Logic 🔥
      // Mengantisipasi format boolean (true/false) atau integer (1/0)
      isGeneric: json['is_generic'] == true || json['is_generic'] == 1 || json['is_generic'] == '1',
      unitIndex: int.tryParse(json['unit_index']?.toString() ?? '0') ?? 0,
    );
  }
}