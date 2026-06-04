import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart';

class FailedUploadsRepository {

  Future<void> resetTransactionData(String transNo) async {
    try {
      Uri uri = getUrl(pathUrl: 'failed_upload/V2');
      final params = {
        'trans_no': transNo,
        'no_pict': true,
      };

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(params),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? "Gagal mereset data server (Code: ${response.statusCode})");
      }
    } catch (e) {
      throw Exception("Gagal melakukan reset data: $e");
    }
  }
}