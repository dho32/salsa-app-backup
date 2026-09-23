import '../common/measurement_limits.dart';
import '../common/note_option.dart';
import '../service_call/problem_source_model.dart';

/// Data tugas **Service Call Freezer** dari server (read-only). Model plain
/// (bukan Hive-typed) — di-cache sebagai JSON di box detail, mirror pola detail
/// Service Call. Gabungan: header toko + daftar unit freezer + master
/// Permasalahan & Solusi (ProblemSourceModel, dipakai ulang dari SC) + master
/// catatan skip + limit pengukuran dinamis.
class ServiceCallFreezerDetailModel {
  final ScfHeader header;
  final List<ScfFreezerUnit> units;
  final List<ProblemSourceModel> problems;
  final List<NoteOption> noteTempBeforeOptions;
  final List<NoteOption> noteTempAfterOptions;
  final List<NoteOption> noteElecBeforeOptions;
  final List<NoteOption> noteElecAfterOptions;
  final List<NoteOption> skipReasonOptions; // untuk suhu tiba / kondisi awal

  // Limit dinamis (fallback ke kScfMeasurements bila kosong).
  final Map<String, MeasurementLimits> customLimitsBefore;
  final Map<String, MeasurementLimits> customLimitsAfter;

  ServiceCallFreezerDetailModel({
    required this.header,
    this.units = const [],
    this.problems = const [],
    this.noteTempBeforeOptions = const [],
    this.noteTempAfterOptions = const [],
    this.noteElecBeforeOptions = const [],
    this.noteElecAfterOptions = const [],
    this.skipReasonOptions = const [],
    this.customLimitsBefore = const {},
    this.customLimitsAfter = const {},
  });

  factory ServiceCallFreezerDetailModel.fromJson(Map<String, dynamic> json) {
    final result = (json['result'] is Map) ? json['result'] : json;

    List<NoteOption> parseNotes(dynamic list) {
      if (list is! List) return const [];
      return list.map((item) {
        if (item is Map) {
          return NoteOption.fromJson(Map<String, dynamic>.from(item));
        }
        return NoteOption(label: item.toString());
      }).toList();
    }

    Map<String, MeasurementLimits> parseLimits(dynamic node) {
      final out = <String, MeasurementLimits>{};
      if (node is Map) {
        node.forEach((key, value) {
          if (value is Map) {
            out[key.toString()] =
                MeasurementLimits.fromJson(Map<String, dynamic>.from(value));
          }
        });
      }
      return out;
    }

    Map<String, MeasurementLimits> before = {};
    Map<String, MeasurementLimits> after = {};
    final measurements = result['measurements'];
    if (measurements is Map && measurements['limits_validation_unit'] is Map) {
      final lvu = measurements['limits_validation_unit'] as Map;
      // Backend menormalkan subgroup 'scf_before'/'scf_after' jadi
      // 'sc_before'/'sc_after' supaya bisa memakai ulang helper app-config milik
      // Service Call AC, jadi yang benar-benar terkirim adalah nama SC. Nama
      // freezer tetap dibaca lebih dulu kalau suatu saat backend mengirimnya.
      before = parseLimits(lvu['scf_before'] ?? lvu['sc_before']);
      after = parseLimits(lvu['scf_after'] ?? lvu['sc_after']);
    }

    return ServiceCallFreezerDetailModel(
      header: ScfHeader.fromJson(
          Map<String, dynamic>.from(result['header'] ?? const {})),
      units: (result['detail'] as List<dynamic>? ?? [])
          .map((e) => ScfFreezerUnit.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      problems: (result['problems'] as List<dynamic>? ?? [])
          .map((e) => ProblemSourceModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      // Endpoint detail freezer memakai ulang bentuk response Service Call AC,
      // jadi nama key yang benar-benar terkirim adalah nama SC. Pemetaannya
      // mengikuti kesepakatan submit: grup suhu -> indoor, kelistrikan -> outdoor.
      noteTempBeforeOptions: parseNotes(result['note_temp_before_options'] ??
          result['note_indoor_before_options']),
      noteTempAfterOptions: parseNotes(
          result['note_temp_after_options'] ?? result['note_indoor_after_options']),
      noteElecBeforeOptions: parseNotes(result['note_elec_before_options'] ??
          result['note_outdoor_before_options']),
      noteElecAfterOptions: parseNotes(result['note_elec_after_options'] ??
          result['note_outdoor_after_options']),
      // Alasan "tidak bisa diukur". Backend mengirimnya sebagai
      // `unserviceable_reasons` (grid RS7 milik SC), bukan `skip_reason_options`.
      // Tanpa fallback ini daftar alasan jatuh ke konstanta dummy lokal yang
      // MEWAJIBKAN keterangan + foto bukti untuk kelima alasan.
      skipReasonOptions: parseNotes(
          result['skip_reason_options'] ?? result['unserviceable_reasons']),
      customLimitsBefore: before,
      customLimitsAfter: after,
    );
  }

  Map<String, dynamic> toJson() => {
        'header': header.toJson(),
        'detail': units.map((u) => u.toJson()).toList(),
      };
}

class ScfHeader {
  final String transNo;
  final String shipTo; // kode toko (dipakai OTP)
  final String shipToName;
  final String shipToAddress;
  final String shipToMail; // email toko (dipakai OTP)
  final String branchCode;
  final String branchName;
  final String contactName;
  final String contactPhone;
  final String complaintCategory;
  final String complaintSubject;
  final String postedDate;
  final String status;
  final double latitude;
  final double longitude;

  /// Segmen folder lampiran dari server. Backend merakitnya jadi S3 key saat
  /// submit (`.../service_call/<path_attachment>/<trans_no>/...`), jadi harus
  /// diteruskan apa adanya ke payload submit.
  final String pathAttachment;

  ScfHeader({
    required this.transNo,
    this.shipTo = '',
    this.shipToName = '',
    this.shipToAddress = '',
    this.shipToMail = '',
    this.branchCode = '',
    this.branchName = '',
    this.contactName = '',
    this.contactPhone = '',
    this.complaintCategory = '',
    this.complaintSubject = '',
    this.postedDate = '',
    this.status = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.pathAttachment = '',
  });

  factory ScfHeader.fromJson(Map<String, dynamic> json) {
    return ScfHeader(
      transNo: json['trans_no'] ?? '',
      shipTo: json['ship_to'] ?? json['store_id'] ?? '',
      shipToName: json['ship_to_name'] ?? json['store_name'] ?? '',
      shipToAddress: json['ship_to_address'] ?? json['store_address'] ?? '',
      shipToMail: json['ship_to_mail'] ?? json['store_email'] ?? '',
      branchCode: json['branch_code'] ?? json['branch_id'] ?? '',
      branchName: json['branch_name'] ?? '',
      contactName: json['contact_name'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      complaintCategory: json['complaint_category'] ?? '',
      complaintSubject: json['complaint_subject'] ?? '',
      postedDate: json['posted_date'] ?? '',
      status: json['status'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      pathAttachment: json['path_attachment'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'trans_no': transNo,
        'ship_to': shipTo,
        'ship_to_name': shipToName,
        'ship_to_address': shipToAddress,
        'ship_to_mail': shipToMail,
        'branch_code': branchCode,
        'branch_name': branchName,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'complaint_category': complaintCategory,
        'complaint_subject': complaintSubject,
        'posted_date': postedDate,
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'path_attachment': pathAttachment,
      };
}

class ScfFreezerUnit {
  final String serialNo;
  final String articleNo;
  final String articleDesc;
  final String unitDesc;
  final String complaintDetails;
  final int lineNo;
  final bool isGeneric;
  final int unitIndex;

  ScfFreezerUnit({
    required this.serialNo,
    this.articleNo = '',
    this.articleDesc = '',
    this.unitDesc = '',
    this.complaintDetails = '',
    this.lineNo = 0,
    this.isGeneric = false,
    this.unitIndex = 0,
  });

  factory ScfFreezerUnit.fromJson(Map<String, dynamic> json) {
    // Grid detail unit memakai bentuk Service Call AC, yang hanya punya satu
    // kolom nama unit: `article_name_unit`. Dipakai sebagai fallback untuk
    // deskripsi & tipe unit supaya judul unit di wizard tidak kosong.
    final String articleNameUnit = json['article_name_unit'] ?? '';
    return ScfFreezerUnit(
      serialNo: json['serial_no'] ?? '',
      articleNo: json['article_no'] ?? '',
      articleDesc: json['article_desc'] ?? articleNameUnit,
      unitDesc: json['unit_desc'] ?? articleNameUnit,
      complaintDetails: json['complaint_details'] ?? '',
      lineNo: json['line_no'] is int
          ? json['line_no']
          : int.tryParse(json['line_no']?.toString() ?? '') ?? 0,
      isGeneric: json['is_generic'] ?? false,
      unitIndex: json['unit_index'] is int
          ? json['unit_index']
          : int.tryParse(json['unit_index']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'serial_no': serialNo,
        'article_no': articleNo,
        'article_desc': articleDesc,
        'unit_desc': unitDesc,
        'complaint_details': complaintDetails,
        'line_no': lineNo,
        'is_generic': isGeneric,
        'unit_index': unitIndex,
      };
}
