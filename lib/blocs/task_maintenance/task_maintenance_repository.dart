// lib/repositories/po_repository.dart
import 'dart:convert'; // Untuk mengelola JSON
import 'dart:developer';
import 'package:http/http.dart' as http;

import '../../components/shared_function.dart';
import '../../models/task_maintenance/task_maintenance_model.dart';

class TaskMaintenanceRepository {
  Future<List<TransactionSuggestion>> searchTransactions(
      String transNo, String maintenanceBy) async {
    try {
      final params = {'trans_no': transNo, 'maintenance_by': maintenanceBy};

      Uri uri = getUrl(pathUrl: 'task_maintenance/v2', params: params);
      final response = await http.get(uri);

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
          throw Exception(
              responseBody['message'] ?? 'Gagal memperbarui data di server.');
        }
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
      rethrow;
    }
  }

  Future<List<TransactionSuggestion>> getPendingTasks(
      String maintenanceBy, String createdBy) async {
    try {
      final params = {
        'maintenance_by': maintenanceBy,
        'created_by': createdBy,
      };

      Uri uri = getUrl(pathUrl: 'task_maintenance/pending_tasks', params: params);
      print(uri);
      final response = await http.get(uri);
      print("==============");
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");


      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          final List<dynamic> results = body['result'] ?? [];
          return results
              .map((json) => TransactionSuggestion.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Gagal memuat list tugas. Code: ${response.statusCode}');
      }

      // await Future.delayed(Duration(seconds: 1)); // Simulasi delay
      // return [
      //   TransactionSuggestion(
      //       transNo: "ZOMBIE-123", // Transaksi Pura-pura
      //       customerName: "Toko Test",
      //       customerCode: "XXX",
      //       status: "NEED_UPLOAD", // Status memicu
      //       type: "SERVICE"
      //   ),
      //   TransactionSuggestion(
      //       transNo: "ZOMBIE-12453", // Transaksi Pura-pura
      //       customerName: "Toko Test45",
      //       customerCode: "XX45X",
      //       status: "NEED_UPLOAD", // Status memicu
      //       type: "CUCI"
      //   )
      // ];
    } catch (e) {
      // Return list kosong jika gagal koneksi/error, supaya user tetap bisa pakai fitur search manual
      log("Error fetching pending tasks: $e");
      return [];
    }
  }
}
