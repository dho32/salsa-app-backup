import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/shared_function.dart';

import '../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';

/// Repository data tugas Cuci Freezer.
///
/// [getDetail] GET `proof_of_service_freezer/detail?trans_no=...` dan mem-parse
/// `result` menjadi [ProofOfServiceFreezerDetailModel] (header + daftar freezer).
///
/// Respons backend juga menyertakan `skip_reason_options`, `complaint_options`,
/// `unused_reason_options`, `unserviceable_reasons`, `planogram_url`, dan
/// `measurements` (config pengukuran). Semuanya diparse ke `PosfWizardConfig`
/// (non-persisted); wizard jatuh ke konstanta lokal
/// (`proof_of_service_freezer_constants.dart`) hanya bila list-nya kosong —
/// mis. saat detail dibaca dari cache Hive.
class ProofOfServiceFreezerDetailRepository {
  Future<ProofOfServiceFreezerDetailModel> getDetail(String transNo) async {
    try {
      final uri = getUrl(
        pathUrl: 'proof_of_service_freezer/detail',
        params: {'trans_no': transNo},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          return ProofOfServiceFreezerDetailModel.fromJson(body['result']);
        }
        throw Exception('API returned error: ${body['message']}');
      }
      throw Exception('Failed to load detail: ${response.statusCode}');
    } catch (e) {
      // DEMO: transNo dummy tidak ada di server → pakai data mock (1 unit).
      if (kEnableDummyDemoTasks) return _mockDetail(transNo);
      rethrow;
    }
  }

  /// Data mock Cuci Freezer untuk demo (aktif bila [kEnableDummyDemoTasks]).
  /// Minimal: 1 unit freezer. Koordinat Monas (Jakarta) untuk uji geofence.
  ProofOfServiceFreezerDetailModel _mockDetail(String transNo) {
    return ProofOfServiceFreezerDetailModel(
      header: ProofOfServiceFreezerHeader(
        transNo: transNo,
        poDate: '2026-08-14',
        shipTo: 'T002',
        shipToName: 'Toko Maju Jaya (DEMO)',
        shipToAddress: 'Jl. Sudirman No. 5, Jakarta Pusat',
        shipToMail: 'toko.majujaya@example.com',
        branchCode: 'JKT',
        branchName: 'Cabang Jakarta',
        latitude: -6.2256613,
        longitude: 106.656931,
      ),
      items: [
        ProofOfServiceFreezerItem(
          serialNo: 'CF-2001',
          articleNo: 'ART-CF1',
          articleDesc: 'Freezer Chest 300L',
          unitDesc: 'Freezer Chest',
          lineNo: 1,
          isGeneric: false,
          unitIndex: 0,
        ),
      ],
    );
  }
}
