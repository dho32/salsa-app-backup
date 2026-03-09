import 'package:hive/hive.dart';

part 'installation_model.g.dart';

// --- TYPE ID: 200 - 209 ---

@HiveType(typeId: 200)
class InstallationPhotoModel {
  @HiveField(0)
  final String imagePath;
  @HiveField(1)
  final String imageFileName;
  @HiveField(2)
  final String timestamp;
  @HiveField(3)
  final double latitude;
  @HiveField(4)
  final double longitude;
  @HiveField(5)
  final String deviceModel;

  InstallationPhotoModel({
    required this.imagePath,
    required this.imageFileName,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.deviceModel,
  });

  factory InstallationPhotoModel.fromJson(Map<String, dynamic> json) {
    return InstallationPhotoModel(
      imagePath: json['image_path'] ?? '',
      imageFileName: json['image_file_name'] ?? '',
      timestamp: json['timestamp'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      deviceModel: json['device'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'image_path': imagePath,
        'image_file_name': imageFileName,
        'timestamp': timestamp,
        'latitude': latitude,
        'longitude': longitude,
        'device': deviceModel,
      };
}

@HiveType(typeId: 201)
class InstallationMeasurementModel {
  @HiveField(0)
  final String measurementId;
  @HiveField(1)
  final double? value;
  @HiveField(2)
  final String unit;
  @HiveField(3)
  final InstallationPhotoModel? photo;
  @HiveField(4)
  final bool isSkipped;
  @HiveField(5)
  final String? note;

  InstallationMeasurementModel({
    required this.measurementId,
    this.value,
    required this.unit,
    this.photo,
    this.isSkipped = false,
    this.note,
  });

  factory InstallationMeasurementModel.fromJson(Map<String, dynamic> json) {
    return InstallationMeasurementModel(
      measurementId: json['measurement_id'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      photo: json['photo'] != null
          ? InstallationPhotoModel.fromJson(json['photo'])
          : null,
      isSkipped: json['is_skipped'] ?? false,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'measurement_id': measurementId,
        'value': value,
        'unit': unit,
        'photo': photo?.toJson(),
        'is_skipped': isSkipped,
        'note': note,
      };
}

@HiveType(typeId: 202)
class InstallationMaterialItemModel {
  @HiveField(0)
  final String articleId;
  @HiveField(1)
  final String articleName;
  @HiveField(2)
  final String brandId;
  @HiveField(3)
  final String brandName;
  @HiveField(4)
  final double length;
  @HiveField(5)
  final String usageType;

  InstallationMaterialItemModel({
    required this.articleId,
    required this.articleName,
    required this.brandId,
    required this.brandName,
    required this.length,
    required this.usageType,
  });

  factory InstallationMaterialItemModel.fromJson(Map<String, dynamic> json) {
    return InstallationMaterialItemModel(
      articleId: json['article_id'] ?? '',
      articleName: json['article_name'] ?? '',
      brandId: json['brand_id'] ?? '',
      brandName: json['brand_name'] ?? '',
      length: (json['length'] ?? 0).toDouble(),
      usageType: json['usage_type'] ?? 'UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() => {
        'article_id': articleId,
        'article_name': articleName,
        'brand_id': brandId,
        'brand_name': brandName,
        'length': length,
        'usage_type': usageType,
      };
}

@HiveType(typeId: 203)
class InstallationMaterialsModel {
  @HiveField(0)
  final List<InstallationMaterialItemModel> pipes;
  @HiveField(1)
  final List<InstallationMaterialItemModel> cables;
  @HiveField(2)
  final String mountingType;
  @HiveField(3)
  final bool hasJasaPerapihan;

  InstallationMaterialsModel({
    this.pipes = const [],
    this.cables = const [],
    this.mountingType = 'NONE',
    this.hasJasaPerapihan = false,
  });

  factory InstallationMaterialsModel.fromJson(Map<String, dynamic> json) {
    return InstallationMaterialsModel(
      pipes: (json['pipes'] as List?)
              ?.map((e) => InstallationMaterialItemModel.fromJson(e))
              .toList() ??
          [],
      cables: (json['cables'] as List?)
              ?.map((e) => InstallationMaterialItemModel.fromJson(e))
              .toList() ??
          [],
      mountingType: json['mounting_type'] ?? 'NONE',
      hasJasaPerapihan: json['has_jasa_perapihan'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'pipes': pipes.map((e) => e.toJson()).toList(),
        'cables': cables.map((e) => e.toJson()).toList(),
        'mounting_type': mountingType,
        'has_jasa_perapihan': hasJasaPerapihan,
      };
}

@HiveType(typeId: 204)
class InstallationUnitModel {
  @HiveField(0)
  final String serialNo;
  @HiveField(1)
  final String articleNo;
  @HiveField(2)
  final String articleDesc;
  @HiveField(3)
  final String articleType;

  // Note Utama (Dropdown) - Untuk Indoor & Outdoor (Fisik)
  @HiveField(4)
  final String? note;

  @HiveField(5)
  final List<InstallationMeasurementModel> measurements;
  @HiveField(6)
  final InstallationMaterialsModel materials;
  @HiveField(7)
  final String? pairedSerialNo;
  @HiveField(8)
  final int unitIndex;
  @HiveField(9)
  final String? status;
  @HiveField(10, defaultValue: 'NONE')
  final String materialStatus;
  @HiveField(11)
  final String reffLineNo;

  // --- [NEW FIELDS FOR BACKEND V2] ---

  // 1. Remark Manual (Shared Indoor/Outdoor Fisik)
  @HiveField(12, defaultValue: '')
  final String remark;

  // 2. Remark Photos (Shared Indoor/Outdoor Fisik)
  @HiveField(13, defaultValue: [])
  final List<InstallationPhotoModel> remarkPhotos;

  // 3. Note PSI (Dropdown Khusus Outdoor PSI)
  @HiveField(14, defaultValue: '')
  final String notePsi;

  // 4. Remark PSI (Manual Khusus Outdoor PSI)
  @HiveField(15, defaultValue: '')
  final String remarkPsi;

  // 5. Remark Photos PSI (Khusus Outdoor PSI)
  @HiveField(16, defaultValue: [])
  final List<InstallationPhotoModel> remarkPhotosPsi;

  InstallationUnitModel({
    required this.serialNo,
    required this.articleNo,
    required this.articleDesc,
    required this.articleType,
    this.note,
    this.measurements = const [],
    required this.materials,
    this.pairedSerialNo,
    required this.unitIndex,
    this.status,
    this.materialStatus = 'NONE',
    this.reffLineNo = '',
    // Defaults for New Fields
    this.remark = '',
    this.remarkPhotos = const [],
    this.notePsi = '',
    this.remarkPsi = '',
    this.remarkPhotosPsi = const [],
  });

  InstallationUnitModel copyWith({
    String? serialNo,
    String? articleNo,
    String? articleDesc,
    String? articleType,
    String? note,
    List<InstallationMeasurementModel>? measurements,
    InstallationMaterialsModel? materials,
    String? pairedSerialNo,
    int? unitIndex,
    String? status,
    String? materialStatus,
    String? reffLineNo,
    // Params for New Fields
    String? remark,
    List<InstallationPhotoModel>? remarkPhotos,
    String? notePsi,
    String? remarkPsi,
    List<InstallationPhotoModel>? remarkPhotosPsi,
  }) {
    return InstallationUnitModel(
      serialNo: serialNo ?? this.serialNo,
      articleNo: articleNo ?? this.articleNo,
      articleDesc: articleDesc ?? this.articleDesc,
      articleType: articleType ?? this.articleType,
      note: note ?? this.note,
      measurements: measurements ?? this.measurements,
      materials: materials ?? this.materials,
      pairedSerialNo: pairedSerialNo ?? this.pairedSerialNo,
      unitIndex: unitIndex ?? this.unitIndex,
      status: status ?? this.status,
      materialStatus: materialStatus ?? this.materialStatus,
      reffLineNo: reffLineNo ?? this.reffLineNo,
      // Copy Logic for New Fields
      remark: remark ?? this.remark,
      remarkPhotos: remarkPhotos ?? this.remarkPhotos,
      notePsi: notePsi ?? this.notePsi,
      remarkPsi: remarkPsi ?? this.remarkPsi,
      remarkPhotosPsi: remarkPhotosPsi ?? this.remarkPhotosPsi,
    );
  }

  factory InstallationUnitModel.fromJson(Map<String, dynamic> json) {
    return InstallationUnitModel(
      serialNo: json['serial_no'] ?? '',
      articleNo: json['article_no'] ?? '',
      articleDesc: json['article_desc'] ?? '',
      articleType: json['article_type'] ?? '',
      note: json['note'],
      measurements: (json['measurements'] as List?)
              ?.map((e) => InstallationMeasurementModel.fromJson(e))
              .toList() ??
          [],
      materials: json['materials'] != null
          ? InstallationMaterialsModel.fromJson(json['materials'])
          : InstallationMaterialsModel(),
      pairedSerialNo: json['paired_serial_no'],
      unitIndex: json['unit_index'] ?? 0,
      status: json['status'],
      materialStatus: json['material_status'] ?? 'NONE',
      reffLineNo: json['reff_line_no'] ?? '',

      // JSON Parsing for New Fields (Optional, mostly for backup)
      remark: json['remark'] ?? '',
      remarkPhotos: (json['remark_photos'] as List?)
              ?.map((e) => InstallationPhotoModel.fromJson(e))
              .toList() ??
          [],
      notePsi: json['note_psi'] ?? '',
      remarkPsi: json['remark_psi'] ?? '',
      remarkPhotosPsi: (json['remark_photos_psi'] as List?)
              ?.map((e) => InstallationPhotoModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'serial_no': serialNo,
        'article_no': articleNo,
        'article_desc': articleDesc,
        'article_type': articleType,
        'note': note,
        'measurements': measurements.map((e) => e.toJson()).toList(),
        'materials': materials.toJson(),
        'paired_serial_no': pairedSerialNo,
        'unit_index': unitIndex,
        'status': status,
        'material_status': materialStatus,
        'reff_line_no': reffLineNo,
        // To JSON for New Fields
        'remark': remark,
        'remark_photos': remarkPhotos.map((e) => e.toJson()).toList(),
        'note_psi': notePsi,
        'remark_psi': remarkPsi,
        'remark_photos_psi': remarkPhotosPsi.map((e) => e.toJson()).toList(),
      };
}

@HiveType(typeId: 205)
class InstallationEntryModel {
  @HiveField(0)
  final String transNo;
  @HiveField(1)
  final String vendorId;
  @HiveField(2)
  final String vendorName;
  @HiveField(3)
  final String technicianId;
  @HiveField(4)
  final String technician1Name;
  @HiveField(5)
  final String technician2Name;
  @HiveField(6)
  final String technician3Name;
  @HiveField(7)
  final DateTime? startDate;
  @HiveField(8)
  final String? finalNote;
  @HiveField(9)
  final List<InstallationPhotoModel> finalPhotos;
  @HiveField(10)
  final List<InstallationUnitModel> units;
  @HiveField(11)
  final List<MaterialEvidenceModel> materialEvidences;
  @HiveField(12)
  final bool hasTransport;
  @HiveField(13)
  final InstallationPhotoModel? storeFrontPhoto;

  // [FITUR BARU] Transport
  @HiveField(14)
  final double? transportDistance;
  @HiveField(15)
  final InstallationPhotoModel? transportEvidencePhoto;

  InstallationEntryModel({
    required this.transNo,
    required this.vendorId,
    required this.vendorName,
    required this.technicianId,
    required this.technician1Name,
    this.technician2Name = '',
    this.technician3Name = '',
    this.startDate,
    this.finalNote,
    this.finalPhotos = const [],
    this.units = const [],
    this.materialEvidences = const [],
    this.hasTransport = false,
    this.storeFrontPhoto,
    this.transportDistance = 0,
    this.transportEvidencePhoto,
  });

  InstallationEntryModel copyWith({
    String? transNo,
    String? vendorId,
    String? vendorName,
    String? technicianId,
    String? technician1Name,
    String? technician2Name,
    String? technician3Name,
    DateTime? startDate,
    String? finalNote,
    List<InstallationPhotoModel>? finalPhotos,
    List<InstallationUnitModel>? units,
    List<MaterialEvidenceModel>? materialEvidences,
    bool? hasTransport,
    InstallationPhotoModel? storeFrontPhoto,
    bool clearStoreFrontPhoto = false,
    double? transportDistance,
    InstallationPhotoModel? transportEvidencePhoto,
    bool clearTransportPhoto = false,
  }) {
    return InstallationEntryModel(
        transNo: transNo ?? this.transNo,
        vendorId: vendorId ?? this.vendorId,
        vendorName: vendorName ?? this.vendorName,
        technicianId: technicianId ?? this.technicianId,
        technician1Name: technician1Name ?? this.technician1Name,
        technician2Name: technician2Name ?? this.technician2Name,
        technician3Name: technician3Name ?? this.technician3Name,
        startDate: startDate ?? this.startDate,
        finalNote: finalNote ?? this.finalNote,
        finalPhotos: finalPhotos ?? this.finalPhotos,
        units: units ?? this.units,
        materialEvidences: materialEvidences ?? this.materialEvidences,
        hasTransport: hasTransport ?? this.hasTransport,
        storeFrontPhoto: clearStoreFrontPhoto
            ? null
            : (storeFrontPhoto ?? this.storeFrontPhoto),
        transportDistance: transportDistance ?? this.transportDistance,
        transportEvidencePhoto: clearTransportPhoto
            ? null
            : (transportEvidencePhoto ?? this.transportEvidencePhoto));
  }
}

@HiveType(typeId: 206)
class MaterialEvidenceModel {
  @HiveField(0)
  final String key;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String photoPath;

  MaterialEvidenceModel({
    required this.key,
    required this.title,
    required this.photoPath,
  });
}
