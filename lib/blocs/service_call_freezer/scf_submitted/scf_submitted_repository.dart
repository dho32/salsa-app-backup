import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../components/shared_function.dart';
// Ekstensi CapturedImageDetail.toJson() (nama file + timestamp + lat/long +
// device) — foto PIC dikirim lengkap, bukan hanya nama file (pola POSF & SC).
import '../../../models/service_call/service_call_validation_entry_model_ext.dart';
import '../../../models/service_call_freezer/scf_info_model.dart';

/// Repository submit **Service Call Freezer**.
///
/// SCF TIDAK punya endpoint submit sendiri — ia memakai endpoint Service Call
/// `/service_call/validation/submitted/v4` apa adanya, karena header, TVP, dan
/// tabel tujuannya sama. Karena itu `items[]` harus berbentuk `ItemDetail` milik
/// SC (lihat `ScfValidationEntryModelJson.toJson()` untuk pemetaannya).
///
/// Field khusus AC yang tidak dimiliki freezer (`temperature_in_*`,
/// `temp_in_image_detail_after`) sengaja TIDAK dikirim: Go mengisinya dengan
/// zero-value dan setiap pemakaiannya di backend dijaga `ImageFileName != ""`,
/// jadi tidak ada baris/presigned URL kosong yang terbentuk.
///
/// Response berisi presigned URL di `result.detail[].uploads[]` (dicocokkan by
/// filename saat upload S3).
class ScfSubmittedRepository {
  Future<Map<String, dynamic>> submit({
    required String transNo,
    required String createdBy,
    required String createdByName,
    required String createdByIp,
    required String pathAttachment,
    required ScfInfoModel? info,
    required List<Map<String, dynamic>> items,
    String? ahoNumber,
  }) async {
    // Header level-transaksi (PIC + teknisi). Teknisi 1/2/3 + NIK dikirim di
    // header, empty string bila tidak ada (kontrak NIK teknisi).
    final requestBody = {
      'trans_no': transNo,
      'aho_number': ahoNumber ?? '',
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_by_ip': createdByIp,
      // Ikut jadi segmen S3 key di backend (.../service_call/<path>/<trans_no>/...).
      'path_attachment': pathAttachment,
      'pic_nik': info?.picNik ?? '',
      'pic_name': info?.picName ?? '',
      'pic_position': info?.picPosition ?? '',
      'pic_phone': info?.picPhone ?? '',
      'technician_1_name': info?.technician1 ?? '',
      'technician_2_name': info?.technician2 ?? '',
      'technician_3_name': info?.technician3 ?? '',
      'technician_1_nik': info?.technician1Nik ?? '',
      'technician_2_nik': info?.technician2Nik ?? '',
      'technician_3_nik': info?.technician3Nik ?? '',
      'pic_image_detail': info?.picImageDetail?.toJson(),
      'items': items,
    };

    try {
      final prettyJson = const JsonEncoder.withIndent('  ').convert(requestBody);
      log('====== BODY REQUEST LENGKAP (SERVICE FREEZER) ======');
      log(prettyJson);
      log('====================================================');

      final uri = getUrl(pathUrl: '/service_call/validation/submitted/v4');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }
}
