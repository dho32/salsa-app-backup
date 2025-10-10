import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salsa/components/shared_function.dart';

import '../../../models/proof_of_service/pos_unserviceable_model.dart';

extension PosUnserviceableModelJson on PosUnserviceableModel {
  Map<String, dynamic> toJson() {
    return {
      'trans_no': transNo,
      'reason': reason,
      'notes': notes,
      'reported_at': reportedAt.toIso8601String(),
      'reported_by': reportedBy,
      'reported_by_id': reportedById,
      'proof_images': proofImages.map((img) {
        // 2. Ubah struktur objek yang di-return di sini
        return {
          'image_file_name': img.imagePath.split('/').last,
          'timestamp': DateFormat('yyyy-MM-dd HH:mm:ss').format(img.timestamp),
          'latitude': img.latitude,
          'longitude': img.longitude,
          'device': img.deviceModel,
        };
      }).toList(),
    };
  }
}

class PosUnserviceableRepository {
  Future<Map<String, dynamic>> submitReport(
      PosUnserviceableModel report) async {
    try {
      final requestBody = report.toJson();

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      // Ganti dengan endpoint API Anda yang sebenarnya
      Uri uri = getUrl(pathUrl: '/proof_of_service/closed');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'ERROR', 'message': e.toString()};
    }
  }
}