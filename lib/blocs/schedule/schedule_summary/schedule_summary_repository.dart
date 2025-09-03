import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/blocs/schedule/schedule_summary/schedule_summary_bloc.dart';

import '../../../components/shared_function.dart';


class ScheduleSummaryRepository {
  /// Mengambil semua data untuk halaman Schedule Summary
  Future<ScheduleSummaryLoaded> fetchSummaryData({required String maintenanceBy }) async {
    final params = {
      'maintenance_by': maintenanceBy,
    };
    Uri uri = getUrl(pathUrl: 'schedule/summary', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        final result = body['result'];
        final stats = result['stats'];

        // Parsing daftar pekerjaan prioritas
        final List<dynamic> priorityJobsJson = result['priority_jobs'];
        final List<PriorityJob> priorityJobs =
        priorityJobsJson.map((json) => PriorityJob.fromJson(json)).toList();

        // Parsing data grafik bulanan
        final List<dynamic> chartDataJson = result['monthly_chart_data'];
        final List<MonthlyJobChartData> chartData =
        chartDataJson.map((json) => MonthlyJobChartData.fromJson(json)).toList();

        // Kembalikan objek state yang sudah lengkap dan siap pakai
        return ScheduleSummaryLoaded(
          jobsDoneCount: stats['jobs_done'],
          jobsScheduledCount: stats['jobs_scheduled'],
          jobsOverdueCount: stats['jobs_overdue'],
          jobsTodayCount: stats['jobs_today'],
          priorityJobs: priorityJobs,
          monthlyChartData: chartData,
        );
      } else {
        throw Exception('API Error: ${body['message']}');
      }
    } else {
      throw Exception('Gagal memuat summary. Status code: ${response.statusCode}');
    }
  }
}