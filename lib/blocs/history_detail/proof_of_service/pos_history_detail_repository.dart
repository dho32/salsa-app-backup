// blocs/history/pos_history_detail_repository.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/history/pos_history_detail_model.dart';

class PosHistoryDetailRepository {
  /// Mengambil data detail riwayat Proof of Service dari API.
  Future<PosHistoryDetailModel> fetchPosHistoryDetail(String transNo) async {
    final params = {'trans_no': transNo};

    // Ganti dengan endpoint API detail riwayat POS Anda
    Uri uri = getUrl(pathUrl: '/history/proof_of_service/detail', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        // Ubah JSON 'result' menjadi objek Model kita
        return PosHistoryDetailModel.fromJson(body['result']);
      } else {
        throw Exception('API returned error: ${body['message']}');
      }
    } else {
      throw Exception('Failed to load history detail: ${response.statusCode}');
    }
  }
}