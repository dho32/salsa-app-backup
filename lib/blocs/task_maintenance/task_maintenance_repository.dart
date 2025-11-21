// lib/repositories/po_repository.dart
import 'dart:convert'; // Untuk mengelola JSON
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:salsa/blocs/task_maintenance/task_maintenance_event.dart';

import '../../components/shared_function.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';

class TaskMaintenanceRepository {
  Future<List<TransactionSuggestion>> searchTransactions(
      String transNo, String maintenanceBy) async {
    try {
      final params = {
        'trans_no': transNo,
        'maintenance_by': maintenanceBy
      };

      Uri uri = getUrl(pathUrl: 'task_maintenance/v2', params: params);
      final response = await http.get(uri);

      print(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          final List<dynamic> results = body['result'] ?? [];
          return results
              .map((json) => TransactionSuggestion.fromJson(json))
              .toList();
        } else {
          throw Exception(body['message'] ?? 'Transaksi tidak ditemukan');
        }
      } else {
        throw Exception(
            'Gagal memuat data PO. Status Code: ${response.statusCode}');
      }
    } on http.ClientException {
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga saat mencari PO.');
    }
  }

  Future<void> updateStoreInfo({
    required String updatedBy,
    required String customerCode,
    required String email,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // 1. Tentukan Endpoint
      Uri uri = getUrl(pathUrl: 'task_maintenance/update_store_info');

      // 2. Siapkan Body Request (JSON)
      final requestBody = {
        'updated_by': updatedBy,
        'customer_code': customerCode,
        'email': email,
        'latitude': latitude.toString(), // API mungkin mengharapkan String
        'longitude': longitude.toString(), // API mungkin mengharapkan String
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log(uri.toString());
      log("================================");

      // 3. Lakukan Panggilan API (Gunakan POST atau PUT sesuai endpoint Anda)
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'}, // Penting untuk POST/PUT
        body: jsonEncode(requestBody),
      );

      // 4. Proses Respons
      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        // Periksa status dari body respons API Anda
        if (responseBody['status'] != 'OK') {
          // Jika API mengembalikan status error
          throw Exception(responseBody['message'] ?? 'Gagal memperbarui data di server.');
        }
        // Jika status 'OK', tidak perlu return apa-apa (void)
      } else {
        // Jika status code bukan 200
        throw Exception(
            'Gagal menghubungi server update. Status Code: ${response.statusCode}');
      }
    } on http.ClientException {
      // Error koneksi
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    } catch (e) {
      // Error lain (termasuk Exception dari atas)
      // Lempar ulang agar bisa ditangkap oleh UI
      rethrow;
    }
  }
}

