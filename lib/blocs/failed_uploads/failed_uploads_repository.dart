import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart'; // Pastikan import getUrl benar

class FailedUploadsRepository {

  // Fungsi RESET ZOMBIE (Hit ke Server)
  Future<void> resetTransactionData(String transNo) async {
    try {
      log("🔵 [ZOMBIE] Requesting RESET for: $transNo");

      // 1. Setup Endpoint (Sesuaikan path backend Akang)
      // Contoh: 'task_maintenance/reset_evidence_status'
      Uri uri = getUrl(pathUrl: 'failed_upload');

      // 2. Setup Body Request
      final params = {
        'trans_no': transNo,
        // Tambahkan parameter lain jika backend butuh (misal updated_by)
        // 'updated_by': 'username_akang'
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(params);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log(uri.toString());
      log("================================");

      // 3. Eksekusi Request
      // Gunakan token header jika diperlukan (biasanya ada helpernya)
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer $token', // Jangan lupa token jika butuh
        },
        body: jsonEncode(params),
      );

      log("🔵 [ZOMBIE] Response Code: ${response.statusCode}");
      log("🔵 [ZOMBIE] Response Body: ${response.body}");

      // 4. Cek Hasil
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sukses! Tidak perlu return apa-apa, yang penting gak error.
        log("✅ [ZOMBIE] Reset Success!");
      } else {
        // Gagal
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? "Gagal mereset data server (Code: ${response.statusCode})");
      }

    } catch (e) {
      log("❌ [ZOMBIE] Error resetting data: $e");
      throw Exception("Gagal melakukan reset data: $e");
    }
  }
}