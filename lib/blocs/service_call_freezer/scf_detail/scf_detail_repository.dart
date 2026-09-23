import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../components/shared_function.dart';
import '../../../models/service_call_freezer/service_call_freezer_detail_model.dart';

/// Repository data tugas **Service Call Freezer** (repair freezer).
///
/// [getDetail] GET `service_call_freezer/detail?trans_no=...` dan mem-parse
/// `result` menjadi [ServiceCallFreezerDetailModel] (header toko + daftar
/// freezer + master Permasalahan & Solusi + master catatan skip).
///
/// Respons backend diharapkan menyertakan `header`, `detail` (daftar freezer),
/// `problems` (master Permasalahan & Solusi, shape sama dengan SC),
/// `note_temp_before_options`, `note_temp_after_options`,
/// `note_elec_before_options`, `note_elec_after_options`,
/// `skip_reason_options`, dan `measurements` (config limit pengukuran).
/// Semuanya diparse di [ServiceCallFreezerDetailModel.fromJson]; wizard jatuh
/// ke konstanta lokal (`service_call_freezer_constants.dart`) bila list-nya
/// kosong — mis. saat detail dibaca dari cache Hive.
class ScfDetailRepository {
  /// [vendorId] diteruskan ke `@p_vendor_id` di SP, sama seperti detail Service
  /// Call AC — sumbernya `userData['maintenance_by']`.
  Future<ServiceCallFreezerDetailModel> getDetail(String transNo,
      {String vendorId = ''}) async {
    final uri = getUrl(
      pathUrl: 'service_call_freezer/detail',
      params: {'trans_no': transNo, 'vendor_id': vendorId},
    );

    final response = await http.get(uri);

    try {
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body));
      log('====== RESPONSE BODY LENGKAP (SERVICE FREEZER) ======');
      log(prettyJson);
      log('=====================================================');
    } catch (e) {
      // Gagal decode (misal server balas HTML error) → log body mentah.
      log('RAW BODY (SERVICE FREEZER): ${response.body}');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        return ServiceCallFreezerDetailModel.fromJson(body['result']);
      }
      throw Exception('API returned error: ${body['message']}');
    }
    throw Exception('Failed to load detail: ${response.statusCode}');
  }
}
