import 'dart:convert';
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