import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../../components/shared_function.dart';
import '../../../models/service_call/service_call_detail_model.dart';

class ServiceCallDetailRepository {
  Future<ServiceCallDetailModel> fetchServiceCallDetail(
      String transNo, String vendorId) async {
    final params = {
      'trans_no': transNo,
      'vendor_id': vendorId,
    };
    Uri uri = getUrl(pathUrl: 'service_call/detail/v2', params: params);
    final response = await http.get(uri);

    print("=================================");
    print(uri);

    try {
      // 1. Decode string JSON mentah menjadi Map/List dinamis
      final dynamic decodedBody = jsonDecode(response.body);

      // 2. Encode ulang menjadi format yang rapi (Pretty Print)
      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(decodedBody);

      log("====== RESPONSE BODY LENGKAP ======");
      log(prettyJson);
      log("================================");
    } catch (e) {
      // Jika gagal decode (misal server error HTML), print body mentah saja
      print("Gagal pretty print response: $e");
      log("RAW BODY: ${response.body}");
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        return ServiceCallDetailModel.fromJson(body['result']);
      } else {
        throw Exception('API returned error: ${body['message']}');
      }
    } else {
      throw Exception('Failed to load detail: ${response.statusCode}');
    }
  }
}
