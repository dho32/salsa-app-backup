import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';

import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
// Ekstensi CapturedImageDetail.toJson() (nama file + timestamp + lat/long +
// device) — foto PIC dikirim lengkap, bukan hanya nama file.
import '../../../models/service_call/service_call_validation_entry_model_ext.dart';

/// Repository submit Cuci Freezer.
///
/// Merakit [requestBody] (header PIC + teknisi, lalu items) dan POST ke
/// `proof_of_service_freezer/submitted`. Response asli berisi presigned URL di
/// `result.detail[].uploads[]` (dicocokkan berdasarkan filename saat upload S3).
class PosfSubmittedRepository {
  Future<Map<String, dynamic>> submit({
    required String transNo,
    required String createdBy,
    required String createdByName,
    required String createdByIp,
    required ProofOfServiceFreezerInfoModel? info,
    required List<Map<String, dynamic>> items,
  }) async {
    // Header level-transaksi (PIC + teknisi). Pola POS — teknisi 1/2/3 dikirim
    // bersama NIK-nya (technician_*_nik) di header, empty string bila tidak ada.
    final requestBody = {
      'trans_no': transNo,
      'created_by': createdBy,
      'created_by_name': createdByName,
      'created_by_ip': createdByIp,
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
      log('====== BODY REQUEST LENGKAP (FREEZER) ======');
      log(prettyJson);
      log('============================================');

      final uri = getUrl(pathUrl: 'proof_of_service_freezer/submitted');
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

  /// Cek apakah toko ini sudah punya tiket Service Call (SC) aktif untuk
  /// freezer bermasalah. Pola POS: `checkActiveServiceCall`.
  ///
  /// GET `proof_of_service_freezer/sc_check_active?trans_no=...` lalu baca
  /// `result.has_active_sc`. Bila gagal/koneksi error, anggap `false` (belum
  /// ada SC) sehingga dialog "buat tiket SC" tetap muncul saat ada keluhan.
  Future<bool> checkActiveServiceCall(String transNo) async {
    try {
      final uri = getUrl(
        pathUrl: 'proof_of_service_freezer/sc_check_active',
        params: {'trans_no': transNo},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK' && body['result'] != null) {
          final result = body['result'] as Map<String, dynamic>;
          return result['has_active_sc'] ?? false;
        }
      }
      return false;
    } catch (e) {
      log('Error checking active SC (freezer): $e');
      return false;
    }
  }
}
