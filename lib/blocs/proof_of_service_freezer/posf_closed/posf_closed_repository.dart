import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';

/// Repository laporan "Freezer Tidak Bisa Diservis" (close).
///
/// POST `proof_of_service_freezer/closed` dengan payload:
/// `{trans_no, reason, notes, reported_by, reported_by_id, proof_images[]}`
/// di mana `proof_images` = daftar nama file (filename only). Response asli
/// mengembalikan presigned URL foto bukti di `result.detail[].uploads[]`.
class PosfClosedRepository {
  Future<Map<String, dynamic>> submitClosed({
    required String transNo,
    required String reason,
    required String notes,
    required String reportedBy,
    required String reportedById,
    required List<String> proofImageFileNames,
  }) async {
    final requestBody = {
      'trans_no': transNo,
      'reason': reason,
      'notes': notes,
      'reported_by': reportedBy,
      'reported_by_id': reportedById,
      'proof_images': proofImageFileNames,
    };

    try {
      final prettyJson = const JsonEncoder.withIndent('  ').convert(requestBody);
      log('====== BODY REQUEST CLOSE (FREEZER) ======');
      log(prettyJson);
      log('==========================================');

      final uri = getUrl(pathUrl: 'proof_of_service_freezer/closed');
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
