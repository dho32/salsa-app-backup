import 'dart:convert';
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
    Uri uri = getUrl(pathUrl: 'service_call/detail', params: params);
    final response = await http.get(uri);
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
