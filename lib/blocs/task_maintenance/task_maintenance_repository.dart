// lib/repositories/po_repository.dart
import 'dart:convert'; // Untuk mengelola JSON
import 'package:http/http.dart' as http;
import 'package:salsa/blocs/task_maintenance/task_maintenance_event.dart';

import '../../components/shared_function.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';

class TaskMaintenanceRepository {
  Future<List<TransactionSuggestion>> searchTransactions(
      String transNo, String maintenanceBy, MaintenanceType taskType) async {
    try {
      final params = {
        'trans_no': transNo,
        'maintenance_by': maintenanceBy,
        'task_type': taskType
            .toString()
            .split('.')
            .last,
      };

      Uri uri = getUrl(pathUrl: 'task_maintenance', params: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          final List<dynamic> results = body['result'] ?? [];
          return results.map((json) => TransactionSuggestion.fromJson(json)).toList();
        } else {
          throw Exception(body['message'] ?? 'Transaksi tidak ditemukan');
        }
      } else {
        throw Exception(
            'Gagal memuat data PO. Status Code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      // Error tak terduga lainnya
      print('Unexpected Error: $e');
      throw Exception('Terjadi kesalahan tidak terduga saat mencari PO.');
    }
  }
}
