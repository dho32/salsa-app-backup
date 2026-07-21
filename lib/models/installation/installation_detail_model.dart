import 'package:hive/hive.dart';

import '../common/measurement_limits.dart';

part 'installation_detail_model.g.dart';

// --- TYPE ID: 210 - 219 ---

@HiveType(typeId: 210)
class InstallationHeaderDetailModel {
  @HiveField(0, defaultValue: '')
  final String transNo;
  @HiveField(1, defaultValue: '')
  final String roType;
  @HiveField(2, defaultValue: '')
  final String poCustNo;
  @HiveField(3, defaultValue: '')
  final String roPostedDate;
  @HiveField(4, defaultValue: '')
  final String estimatedDate;
  @HiveField(5, defaultValue: '')
  final String branchName;
  @HiveField(6, defaultValue: '')
  final String shipToName;
  @HiveField(7, defaultValue: '')
  final String shipToAddress;
  @HiveField(8, defaultValue: 0.0)
  final double latitude;
  @HiveField(9, defaultValue: 0.0)
  final double longitude;

  // --- PIC & OTP (mirror RRO Cut Off) ---
  @HiveField(10, defaultValue: true)
  final bool isPic;
  @HiveField(11, defaultValue: '')
  final String shipTo;
  @HiveField(12, defaultValue: '')
  final String shipToMail;

  InstallationHeaderDetailModel({
    required this.transNo,
    required this.roType,
    required this.poCustNo,
    required this.roPostedDate,
    required this.estimatedDate,
    required this.branchName,
    required this.shipToName,
    required this.shipToAddress,
    required this.latitude,
    required this.longitude,
    this.isPic = true,
    this.shipTo = '',
    this.shipToMail = '',
  });

  factory InstallationHeaderDetailModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return InstallationHeaderDetailModel(
      transNo: json['trans_no'] ?? '',
      roType: json['ro_type'] ?? '',
      poCustNo: json['po_cust_no'] ?? '',
      roPostedDate: json['ro_posted_date'] ?? '',
      estimatedDate: json['estimated_installation_date'] ?? '',
      branchName: json['branch_name'] ?? '',
      shipToName: json['ship_to_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      isPic: json['is_pic'] ?? true,
      shipTo: json['ship_to'] ?? '',
      shipToMail: json['ship_to_mail'] ?? '',
    );
  }
}

@HiveType(typeId: 211)
class InstallationTargetUnitModel {
  @HiveField(0, defaultValue: '')
  final String articleNo;
  @HiveField(1, defaultValue: '')
  final String description;
  @HiveField(2, defaultValue: '')
  final String unitType;
  @HiveField(3, defaultValue: 0)
  final int unitIndex;
  @HiveField(4, defaultValue: '')
  final String reffLineNo;

  InstallationTargetUnitModel({
    required this.articleNo,
    required this.description,
    required this.unitType,
    required this.unitIndex,
    required this.reffLineNo,
  });

  factory InstallationTargetUnitModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    return InstallationTargetUnitModel(
      articleNo: json['article_no'] ?? '',
      description: json['article_name_unit'] ?? '',
      unitType: json['unit_type'] ?? '',
      unitIndex: parseInt(json['unit_index']),
      // [FIX] Ubah key dari 'reff_line_no' menjadi 'line_no' sesuai API
      reffLineNo: (json['line_no'] ?? json['reff_line_no'])?.toString() ?? '',
    );
  }
}

@HiveType(typeId: 212)
class InstallationMasterOptionModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2, defaultValue: 'Meter')
  final String uom;
  @HiveField(3)
  final List<InstallationBrandModel> brands;

  InstallationMasterOptionModel({
    required this.id,
    required this.name,
    this.uom = 'Meter',
    this.brands = const [],
  });

  factory InstallationMasterOptionModel.fromJson(Map<String, dynamic> json) =>
      InstallationMasterOptionModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        uom: json['uom'] ?? 'Meter',
        brands: (json['brands'] as List?)
                ?.map((e) => InstallationBrandModel.fromJson(e))
                .toList() ??
            [],
      );
}

@HiveType(typeId: 213)
class InstallationMasterDataModel {
  @HiveField(0)
  final List<InstallationMasterOptionModel> pipes;
  @HiveField(1)
  final List<InstallationMasterOptionModel> cables;
  @HiveField(2)
  final List<InstallationMasterOptionModel> brands;

  @HiveField(3)
  final List<InstallationMasterOptionModel> drains;
  @HiveField(4)
  final List<InstallationMasterOptionModel> ducts;

  InstallationMasterDataModel({
    this.pipes = const [],
    this.cables = const [],
    this.brands = const [],
    this.drains = const [],
    this.ducts = const [],
  });

  factory InstallationMasterDataModel.fromJson(Map<String, dynamic> json) {
    List<InstallationMasterOptionModel> parse(List? l) => (l ?? [])
        .map((e) => InstallationMasterOptionModel.fromJson(e))
        .toList();

    return InstallationMasterDataModel(
        pipes: parse(json['pipes']),
        cables: parse(json['cables']),
        brands: parse(json['brands']),
        drains: parse(json['drains']),
        ducts: parse(json['ducts']));
  }
}

@HiveType(typeId: 214)
class InstallationOptionItemModel {
  @HiveField(0)
  final String label;
  @HiveField(1)
  final bool requireRemark;
  @HiveField(2)
  final bool isSystemOnly;

  InstallationOptionItemModel(
      {required this.label,
      required this.requireRemark,
      required this.isSystemOnly});

  factory InstallationOptionItemModel.fromJson(Map<String, dynamic> json) =>
      InstallationOptionItemModel(
          label: json['label'] ?? '',
          requireRemark: json['require_remark'] ?? false,
          isSystemOnly: json['is_system_only'] ?? false);
}

@HiveType(typeId: 215)
class InstallationDetailModel {
  @HiveField(0)
  final InstallationHeaderDetailModel header;
  @HiveField(1)
  final List<InstallationTargetUnitModel> targets;
  @HiveField(2)
  final InstallationMasterDataModel masterMaterials;
  @HiveField(3)
  final List<InstallationOptionItemModel> noteIndoorOptions;
  @HiveField(4)
  final List<InstallationOptionItemModel> noteOutdoorOptions;
  @HiveField(5)
  final List<InstallationOptionItemModel> noteOutdoorPSIOptions;
  @HiveField(6)
  final Map<String, MeasurementLimits>? customLimitsAfter;

  InstallationDetailModel({
    required this.header,
    required this.targets,
    required this.masterMaterials,
    required this.noteIndoorOptions,
    required this.noteOutdoorOptions,
    required this.noteOutdoorPSIOptions,
    this.customLimitsAfter,
  });

  factory InstallationDetailModel.fromJson(Map<String, dynamic> json) {
    final data = json['result'] ?? json;

    List<InstallationOptionItemModel> parseOpt(List? l) =>
        (l ?? []).map((e) => InstallationOptionItemModel.fromJson(e)).toList();

    Map<String, MeasurementLimits> parsedLimitsAfter = {};

    if (data['measurements'] != null && data['measurements']['limits_validation_unit'] != null) {
      final limitsData = data['measurements']['limits_validation_unit'];

      if (limitsData['sc_after'] != null && limitsData['sc_after'] is Map) {
        (limitsData['sc_after'] as Map).forEach((key, value) {
          if (value != null && value is Map) {
            parsedLimitsAfter[key.toString()] =
                MeasurementLimits.fromJson(Map<String, dynamic>.from(value));
          }
        });
      }
    }
    // ---------------------------------------------------

    return InstallationDetailModel(
      header: InstallationHeaderDetailModel.fromJson(data['header'] ?? {}),
      targets: (data['detail'] as List? ?? [])
          .map((e) => InstallationTargetUnitModel.fromJson(e))
          .toList(),
      masterMaterials:
      InstallationMasterDataModel.fromJson(data['master_materials'] ?? {}),
      noteIndoorOptions: parseOpt(data['note_indoor_options']),
      noteOutdoorOptions: parseOpt(data['note_outdoor_options']),
      noteOutdoorPSIOptions: parseOpt(data['note_outdoor_psi_options']),
      customLimitsAfter: parsedLimitsAfter, // Inject hasil parse
    );
  }
}

@HiveType(typeId: 216)
class InstallationBrandModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  InstallationBrandModel({required this.id, required this.name});

  factory InstallationBrandModel.fromJson(Map<String, dynamic> json) =>
      InstallationBrandModel(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
      );
}
