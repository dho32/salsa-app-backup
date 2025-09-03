import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../components/shared_function.dart';

class ServiceTaskRepository{
  Future<Map<String, dynamic>> confirmUploadSuccess(String transNo) async {
    try {
      final requestBody = {'trans_no': transNo};

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      Uri uri = getUrl(pathUrl: '/task_maintenance/update');

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