import 'dart:convert';
import 'dart:developer';

import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';

/// Repository submit Cuci Freezer.
///
/// NOTE(backend): endpoint submit BELUM tersedia. [submit] merakit [requestBody]
/// (header PIC + teknisi, lalu items) dan me-log-nya, lalu mengembalikan response
/// mock `{status: OK, result: {detail: []}}` sehingga alur submit selesai secara
/// lokal (tanpa file presigned -> upload di-skip otomatis).
///
/// Saat endpoint siap, ganti `return mock` di bawah menjadi:
///   final uri = getUrl(pathUrl: 'proof_of_service_freezer/submitted');
///   final res = await http.post(uri,
///       headers: {'Content-Type': 'application/json'},
///       body: jsonEncode(requestBody));
///   return jsonDecode(res.body);
/// di mana response asli berisi presigned URL di result.detail[].uploads[].
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
      'pic_posision': info?.picPosition ?? '',
      'pic_phone': info?.picPhone ?? '',
      'technician_1_name': info?.technician1 ?? '',
      'technician_2_name': info?.technician2 ?? '',
      'technician_3_name': info?.technician3 ?? '',
      'technician_1_nik': info?.technician1Nik ?? '',
      'technician_2_nik': info?.technician2Nik ?? '',
      'technician_3_nik': info?.technician3Nik ?? '',
      'pic_image_detail': info?.picImageDetail?.imagePath.split('/').last,
      'items': items,
    };

    final prettyJson = const JsonEncoder.withIndent('  ').convert(requestBody);
    log('====== BODY REQUEST LENGKAP (FREEZER) ======');
    log(prettyJson);
    log('============================================');

    await Future.delayed(const Duration(milliseconds: 400)); // simulasi network
    return {
      'status': 'OK',
      'result': {'detail': <dynamic>[]},
    };
  }

  /// Cek apakah toko ini sudah punya tiket Service Call (SC) aktif untuk
  /// freezer bermasalah. Pola POS: `checkActiveServiceCall`.
  ///
  /// NOTE(backend): endpoint BELUM tersedia. MOCK selalu mengembalikan `false`
  /// (anggap belum ada SC) sehingga dialog "buat tiket SC" selalu muncul saat
  /// ada freezer "Ada Keluhan". Saat endpoint siap, ganti dengan HTTP call ke
  /// mis. `/proof_of_service_freezer/sc_check_active?trans_no=...` dan baca
  /// `result.has_active_sc`.
  Future<bool> checkActiveServiceCall(String transNo) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simulasi network
    return false;
  }
}
