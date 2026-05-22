import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../../components/shared_function.dart';
import '../../components/constants.dart';
import '../../models/rro_cut_off/rro_cut_off_detail_model.dart';

class RROCutOffDetailRepository {

  Future<RROCutOffResult> fetchDetail(String transNo, String vendorId) async {
    final box = await Hive.openBox<RROCutOffResult>(kRROCutOffDetailBox);

    try {
      final params = {'trans_no': transNo, 'vendor_id': vendorId};
      Uri uri = getUrl(pathUrl: 'rro_cut_off/detail', params: params);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['status'] == 'OK') {
          final model = RROCutOffDetailResponseModel.fromJson(body);
          if (model.result != null) {
            // 🔥 Simpan ke Hive buat backup offline
            await box.put(transNo, model.result!);
            return model.result!;
          } else {
            throw Exception("Data result kosong dari server.");
          }
        } else {
          throw Exception(body['message'] ?? 'Gagal memuat detail RRO.');
        }
      } else {
        throw Exception('Gagal menghubungi server. Code: ${response.statusCode}');
      }
    } catch (e) {
      // 🔥 Kalau gagal (sinyal jelek/server down), cek di Hive!
      final localData = box.get(transNo);
      if (localData != null) {
        return localData;
      }
      throw Exception('Gagal memuat data dan tidak ada backup offline. (${e.toString()})');
    }
  }
}