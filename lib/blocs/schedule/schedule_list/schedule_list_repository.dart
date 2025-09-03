import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/models/schedule/schedule_list_response.dart';

import '../../../components/shared_function.dart';

class ScheduleListRepository {
  // Method utama untuk mengambil daftar jadwal
  Future<ScheduleListResponse> fetchSchedules({
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

    Uri uri = getUrl(pathUrl: 'schedule/list', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ScheduleListResponse.fromJson(json['result']);
    } else {
      throw Exception('Gagal memuat jadwal. Status code: ${response.statusCode}');
    }
  }
}