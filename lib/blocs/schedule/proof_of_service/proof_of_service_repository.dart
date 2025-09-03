import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/blocs/schedule/proof_of_service/proof_of_service_bloc.dart';
import '../../../components/shared_function.dart';
import '../../../models/schedule/proof_of_service/proof_of_service_response.dart';

class ProofOfServiceRepository {
  /// Mengambil semua data awal untuk form berdasarkan nomor transaksi
  Future<POSLoaded> fetchPOSDetail(String transNo) async {
    final params = {
      'trans_no': transNo
    };

    Uri uri = getUrl(pathUrl: 'schedule/proof_of_service', params: params);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'OK') {
        final result = body['result'];

        // Parsing semua bagian dari JSON menjadi objek Dart
        final headerData = POSHeaderData.fromJson(result['header']);
        final measurementsData = POSMeasurementData.fromJson(result['measurements']);
        final List<dynamic> unitListJson = result['unit_list'];
        final unitList = unitListJson.map((json) => POSUnitItem.fromJson(json)).toList();

        // Kembalikan state Loaded yang sudah lengkap dengan data
        return POSLoaded(
          headerData: headerData,
          measurements: measurementsData,
          unitList: unitList,
        );
      } else {
        throw Exception('API Error: ${body['message']}');
      }
    } else {
      throw Exception('Gagal memuat detail POS. Status code: ${response.statusCode}');
    }
  }

// TODO: Buat juga method untuk mengirim (POST) data form yang sudah diisi
// Future<void> submitPOSData(String transNo, POSLoaded state) async { ... }
}