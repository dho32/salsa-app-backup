import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart';

class OtpRepository {
  Future<void> sendOtp(
      String transNo, String shipTo, String isFirst) async {
    final params = {
      'trans_no': transNo,
      'ship_to': shipTo,
      'is_first': isFirst
    };
    Uri uri = getUrl(pathUrl: 'otp/request', params: params);

    print(uri);

    try {
      await http.get(uri).timeout(const Duration(seconds: 30));
    } catch (e) {
      print("⚠️ Request OTP Background Error (Ignored): $e");
    }
  }

  Future<bool> validateOtp(String transNo, String shipTo, String otpCode) async {
    final body = {
      "trans_no": transNo,
      "ship_to": shipTo,
      "otp_code": otpCode,
    };

    Uri uri = getUrl(pathUrl: 'otp/validate');

    print(uri);

    try {
      print("masuk hit");
      final response = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body)
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final status = json['status']?.toString().toUpperCase() ?? '';
        final message = json['message']?.toString().toUpperCase() ?? '';

        print(status);
        print(message);
        return status == 'OK' && message == 'SUCCESS';
      }
      return false;
    } catch (e) {
      throw Exception("Gagal validasi ke server: $e");
    }
  }
}
