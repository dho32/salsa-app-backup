import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';

/// Repository submit Cuci Freezer.
///
/// NOTE(backend): endpoint submit BELUM tersedia. [submit] mengembalikan
/// response mock `{status: OK, result: {detail: []}}` sehingga alur submit
/// selesai secara lokal (tanpa file presigned -> upload di-skip otomatis).
///
/// Saat endpoint siap, ganti isi [submit] menjadi:
///   final uri = getUrl(pathUrl: 'proof_of_service_freezer/submitted');
///   final res = await http.post(uri, headers: {...}, body: jsonEncode(payload));
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
    await Future.delayed(const Duration(milliseconds: 400)); // simulasi network
    return {
      'status': 'OK',
      'result': {'detail': <dynamic>[]},
    };
  }
}
