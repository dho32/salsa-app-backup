import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/models/service_call/service_call_summary_model.dart';

import '../../../components/shared_function.dart';

class ServiceCallSummaryRepository {
  Future<ServiceCallSummaryModel> fetchData({required String maintenanceBy }) async {
    final params = {
      'maintenance_by': maintenanceBy,
    };
    Uri uri = getUrl(pathUrl: 'service_call/summary', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return ServiceCallSummaryModel.fromJson(jsonData['result']);
    } else {
      throw Exception('Failed to load service_call_summary');
    }
  }
}
