import 'package:hive/hive.dart';

import '../common/measurement_limits.dart';
import '../common/note_option.dart';

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

  /// Config wizard dari server (skip reasons + require_remark, opsi keluhan/
  /// tidak-terpakai, range pengukuran). NON-persisted (sengaja bukan @HiveField):
  /// hanya tersedia saat model segar dari HTTP; saat dibaca dari cache Hive
  /// bernilai null → wizard fallback ke konstanta lokal.
  final PosfWizardConfig? config;

  ProofOfServiceFreezerDetailModel({
    this.header,
    this.items = const [],
    this.config,
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
      config: PosfWizardConfig.fromResultJson(Map<String, dynamic>.from(result)),
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

/// Config wizard Cuci Freezer yang dikirim server pada respons detail. Dipakai
/// wizard menggantikan konstanta lokal (`proof_of_service_freezer_constants.dart`)
/// bila tersedia; bila list-nya kosong, wizard fallback ke konstanta.
///
/// Sumber JSON (di dalam `result`):
/// - `skip_reason_options[]`  → alasan "tidak bisa diukur" + flag `require_remark`
/// - `complaint_options[]`    → opsi saat kondisi "Ada Keluhan"
/// - `unused_reason_options[]`→ opsi saat kondisi "Tidak terpakai"
/// - `measurements.limits_validation_unit.pos_after.{temperature,ampere,volt}`
///   → range pengukuran step Sesudah (ampere & volt disaring di wizard, lihat
///     `posfFilterMeasurements`)
/// - `planogram_url`         → gambar panduan susunan display produk
class PosfWizardConfig {
  final List<NoteOption> skipReasonOptions;
  final List<String> complaintOptions;
  final List<String> unusedOptions;
  final List<MeasurementLimits> measurements;

  /// URL gambar panduan planogram (S3), dari kolom ke-11 RS1 yang dipromosikan
  /// backend ke `result.planogram_url`. Kosong → wizard pakai asset bawaan
  /// `kPosfPlanogramAsset`. Karena config ini non-persisted, saat detail dibaca
  /// dari cache Hive (offline) nilainya selalu kosong dan panduan otomatis
  /// jatuh ke asset.
  final String planogramUrl;

  /// Master alasan "Freezer Tidak Bisa Diservis" (flow close), dari key
  /// `unserviceable_reasons` (pola POS). Bila list kosong, close fallback ke
  /// konstanta `kPosfClosedReasons`.
  final List<String> closedReasons;

  const PosfWizardConfig({
    this.skipReasonOptions = const [],
    this.complaintOptions = const [],
    this.unusedOptions = const [],
    this.measurements = const [],
    this.closedReasons = const [],
    this.planogramUrl = '',
  });

  bool get isEmpty =>
      skipReasonOptions.isEmpty &&
      complaintOptions.isEmpty &&
      unusedOptions.isEmpty &&
      measurements.isEmpty &&
      closedReasons.isEmpty &&
      planogramUrl.isEmpty;

  factory PosfWizardConfig.fromResultJson(Map<String, dynamic> result) {
    List<NoteOption> parseNotes(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => NoteOption.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<String> parseLabels(dynamic raw) => parseNotes(raw)
        .map((e) => e.label)
        .where((l) => l.isNotEmpty)
        .toList();

    // measurements.limits_validation_unit.pos_after.{temperature,ampere,volt}
    // Urutan sesuai wizard: Suhu, Arus, Tegangan.
    final measurements = <MeasurementLimits>[];
    final m = result['measurements'];
    if (m is Map) {
      final lvu = m['limits_validation_unit'];
      if (lvu is Map) {
        final posAfter = lvu['pos_after'];
        if (posAfter is Map) {
          for (final id in const ['temperature', 'ampere', 'volt']) {
            final item = posAfter[id];
            if (item is Map) {
              measurements.add(
                  MeasurementLimits.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }
      }
    }

    return PosfWizardConfig(
      skipReasonOptions: parseNotes(result['skip_reason_options']),
      complaintOptions: parseLabels(result['complaint_options']),
      unusedOptions: parseLabels(result['unused_reason_options']),
      measurements: measurements,
      closedReasons: parseLabels(result['unserviceable_reasons']),
      planogramUrl: (result['planogram_url'] ?? '').toString().trim(),
    );
  }
}
