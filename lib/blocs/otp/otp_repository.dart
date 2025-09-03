import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart';

class OtpRepository {
  Future<Map<String, dynamic>?> sendOtp(String shipTo, String isFirst) async {
    final params = {'ship_to': shipTo, 'is_first': isFirst};
    Uri uri = getUrl(pathUrl: 'otp/request', params: params);
    final response = await http.get(uri);

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);
    if (json['status'] != 'OK') return null;

    final result = json['result'];
    return {
      'otp': result['otp'].toString().trim(),
      'expired_date': DateTime.parse(result['expired_date']).toLocal(),
      'retry_count': int.parse(result['retry_count'].toString()),
    };
  }
}
