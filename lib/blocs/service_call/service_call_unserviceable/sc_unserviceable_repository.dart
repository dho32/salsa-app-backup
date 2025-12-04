import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/service_call/sc_unserviceable_model.dart'; // Bisa reuse model ini

// Ekstensi toJson bisa dibuat di file terpisah atau di sini
extension SCUnserviceableModelJson on SCUnserviceableModel {
  Map<String, dynamic> toJson() { // Sesuaikan payload jika endpoint SC berbeda
    return {
      'trans_no': transNo,
      'path_attachment': pathAttachment,
      'reason': reason,
      'notes': notes,
      'reported_at': reportedAt.toIso8601String(),
      'reported_by': reportedBy,
      'reported_by_id': reportedById,
      'proof_images': proofImages.map((img) {
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

class SCUnserviceableRepository {
  Future<Map<String, dynamic>> submitReport(SCUnserviceableModel report) async {
    try {
      final requestBody = report.toJson(); // Gunakan ekstensi toJson

      // Ganti dengan endpoint API Service Call Anda
      Uri uri = getUrl(pathUrl: '/service_call/closed');

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log(uri.toString());
      log("================================");


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