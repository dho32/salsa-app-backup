import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salsa/models/service_call/service_call_validation_entry_model_ext.dart';
import 'dart:developer';
import '../../../components/shared_function.dart';
import '../../../models/service_call/transaction_info_model.dart';

class ServiceCallSubmittedRepository {
  Future<Map<String, dynamic>> submitValidation(
    String transNo,
    String createdBy,
    String createdByName,
    String createdByIp,
    String pathAttachment,
    List<Map<String, dynamic>> payload,
    TransactionInfoModel? transactionInfo,
    String? ahoNumber,
  ) async {
    try {
      final requestBody = {
        'trans_no': transNo,
        'aho_number': ahoNumber,
        'temperature_in_after':
            double.tryParse(transactionInfo?.finalTemperatureIn ?? '0') ?? 0,
        'temperature_in_note': transactionInfo?.isFinalTempSkipped ?? false ? transactionInfo?.finalTempNote ?? '' : '',
        'created_by': createdBy,
        'created_by_name': createdByName,
        'created_by_ip': createdByIp,
        'path_attachment': pathAttachment,
        'pic_nik': transactionInfo?.picNik ?? '',
        'pic_name': transactionInfo?.picName ?? '',
        'pic_position': transactionInfo?.picPosition ?? '',
        'pic_phone': transactionInfo?.picPhone ?? '',
        'technician_1_name': transactionInfo?.technician1 ?? '',
        'technician_2_name': transactionInfo?.technician2 ?? '',
        'technician_3_name': transactionInfo?.technician3 ?? '',
        'pic_image_detail': transactionInfo?.picImageDetail?.toJson(),
        'temp_in_image_detail_after':
            transactionInfo?.finalTemperatureInImage?.toJson(),
        'items': payload,
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      Uri uri = getUrl(pathUrl: '/service_call/validation/submitted');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final body = jsonDecode(response.body);

      return body; // ✅ kirim seluruh response ke UI
    } catch (e) {
      return {
        'status': 'ERROR',
        'message': e.toString(),
      };
    }
  }
}
