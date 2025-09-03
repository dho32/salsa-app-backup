
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

class ProofOfServiceDetailRepository {
  /// Mengambil data detail Proof of Service dari API.
  Future<ProofOfServiceDetailModel> fetchProofOfServiceDetail(String transNo) async {
    // Siapkan parameter untuk API call
    final params = {'trans_no': transNo};

    // Ganti 'proof_of_service/detail' dengan endpoint API Anda yang sebenarnya
    Uri uri = getUrl(pathUrl: 'proof_of_service/detail', params: params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Periksa status dari respons API
      if (body['status'] == 'OK') {
        // Jika berhasil, ubah JSON 'result' menjadi objek Model kita
        return ProofOfServiceDetailModel.fromJson(body['result']);
      } else {
        // Jika API mengembalikan status error
        throw Exception('API returned error: ${body['message']}');
      }
    } else {
      // Jika terjadi error koneksi (bukan status 200)
      throw Exception('Failed to load detail: ${response.statusCode}');
    }
  }
}