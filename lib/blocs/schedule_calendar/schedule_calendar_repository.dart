import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salsa/blocs/schedule_calendar/schedule_calendar_bloc.dart';

class ScheduleCalendarRepository {
  // TODO: Ganti dengan base URL API Anda yang sebenarnya
  final String _baseUrl = "https://dummyjson.com/c/5845-a634-4c34-872e";

  /// Mengambil data ringkasan untuk semua marker di kalender
  Future<Map<DateTime, CalendarDayData>> fetchAllSchedules() async {
    // TODO: Ganti dengan endpoint Anda
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        final List<dynamic> scheduleListJson = body['result'];
        return {
          for (var jsonItem in scheduleListJson)
            DateTime.utc(
              DateTime.parse(jsonItem['date']).year,
              DateTime.parse(jsonItem['date']).month,
              DateTime.parse(jsonItem['date']).day,
            ): CalendarDayData.fromJson(jsonItem)
        };
      } else {
        throw Exception('API Error: ${body['message']}');
      }
    } else {
      throw Exception('Gagal memuat data jadwal.');
    }
  }

  /// Mengambil daftar detail jadwal untuk tanggal yang dipilih
  Future<List<POService>> fetchPoDetailsForDay(DateTime day) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(day);
    // TODO: Ganti dengan endpoint Anda
    final response = await http.get(Uri.parse('https://dummyjson.com/c/3408-2ce0-4676-9b8f'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        final List<dynamic> poListJson = body['result'];
        // Ubah List<JSON> menjadi List<POService>
        return poListJson.map((json) => POService.fromJson(json)).toList();
      } else {
        throw Exception('API Error: ${body['message']}');
      }
    } else {
      throw Exception('Gagal memuat detail jadwal. Status code: ${response.statusCode}');
    }
  }
}