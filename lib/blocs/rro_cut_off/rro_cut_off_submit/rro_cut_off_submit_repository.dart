import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../components/shared_function.dart';

class RROCutOffSubmitRepository {
  Future<Map<String, dynamic>> submitPayloadRRO(
      Map<String, dynamic> payload) async {
    // Print Log untuk cek data
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    log("====== REQUEST BODY FINAL RRO CUT OFF ======");
    log(encoder.convert(payload));

    Uri uri = getUrl(pathUrl: 'rro_cut_off/submitted');

    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Submit Failed: ${response.statusCode} - ${response.body}");
    }
  }
}
