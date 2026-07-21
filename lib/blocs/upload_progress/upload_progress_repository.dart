import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../components/shared_function.dart';

Future<void> notifyBackendSuccess(String presignedUrl) async {
  try {
    Uri uri = getUrl(pathUrl: 'upload/callback');
    await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'presigned_url': presignedUrl,
      }),
    );
    print("📡 Lapor backend sukses: $presignedUrl");
  } catch (e) {
    print("⚠️ Gagal lapor status ke backend: $e");
  }
}

Future<void> notifyBackendBatch(List<String> successfulUrls) async {
  if (successfulUrls.isEmpty) return;

  // ⛔ DINONAKTIFKAN SEMENTARA: endpoint `upload/callback_batch` (update status
  // foto sudah terupload) sering balas 504 "Endpoint request timed out" saat
  // foto banyak, karena sudah di handle di worker. Hapus baris return di bawah untuk mengaktifkan kembali.
  log("⏸️ notifyBackendBatch dinonaktifkan sementara (${successfulUrls.length} files dilewati).");
  return;

  // ignore: dead_code
  try {
    Uri uri = getUrl(pathUrl: 'upload/callback_batch');

    final body = {
      'presigned_url': successfulUrls,
      'total_files': successfulUrls.length
    };

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    log("====== REQUEST BODY FINAL ======");
    log(encoder.convert(body));

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Sukses lapor batch (${successfulUrls.length} files) ke backend.");
    } else {
      print("⚠️ Gagal lapor batch: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("❌ Error network lapor batch: $e");
  }
}