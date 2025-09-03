import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/models/service_call/service_call_list_response.dart';

import '../../../components/shared_function.dart';

class ServiceCallListRepository {
  Future<ServiceCallListResponse> fetchServiceCalls({
    required int page,
    String status = '',
    String keyword = '',
    String maintenanceBy = '',
  }) async {
    final params = {
      'maintenance_by': maintenanceBy,
      'status': status,
      if (keyword.isNotEmpty)'keyword': keyword,
      'page': page.toString()
    };
    Uri uri = getUrl(pathUrl: 'service_call/list', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ServiceCallListResponse.fromJson(json['result']);
    } else {
      throw Exception('Failed to fetch data');
    }
  }
}
