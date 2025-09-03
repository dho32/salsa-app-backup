import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';

class PosSubmittedRepository {
  Future<Map<String, dynamic>> submitPosValidation({
    required String transNo,
    required String createdBy,
    required String createdByName,
    required String createdByIp,
    required PosTransactionInfoModel? transactionInfo,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final requestBody = {
        'trans_no': transNo,
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_by_ip': createdByIp,
        'pic_nik': transactionInfo?.picNik ?? '',
        'pic_name': transactionInfo?.picName ?? '',
        'pic_posision': transactionInfo?.picPosition ?? '',
        'pic_phone': transactionInfo?.picPhone ?? '',
        'technician_2_name': transactionInfo?.technician2 ?? '',
        'technician_3_name': transactionInfo?.technician3 ?? '',
        'temperature_in': double.tryParse(transactionInfo?.temperatureIn ?? '0') ?? 0,
        'temperature_out': double.tryParse(transactionInfo?.temperatureOut ?? '0') ?? 0,
        'service_time': transactionInfo?.serviceTime ?? '',
        'pic_image_detail': transactionInfo?.picImageDetail?.toJson(),
        'temp_in_image_detail': transactionInfo?.temperatureInImage?.toJson(),
        'temp_out_image_detail': transactionInfo?.temperatureOutImage?.toJson(),
        'items': items,
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      // Ganti dengan endpoint API Proof of Service Anda
      Uri uri = getUrl(pathUrl: '/proof_of_service/submitted');

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
// Anda bisa menambahkan method confirmUploadSuccess di sini juga
}