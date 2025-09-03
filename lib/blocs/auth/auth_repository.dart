import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart';
import '../../models/auth/maintenance_info_model.dart';
import 'auth_storage.dart';

class AuthRepository {
  Future<String> login(String email, String password) async {
    Uri uri = getUrl(pathUrl: '/login');
    var map = <String, dynamic>{};
    map['user'] = email;
    map['password'] = password;

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(map),
    );

    final data = jsonDecode(response.body);
    final result = data['result'];

    if (response.statusCode == 200 && data['status'] == 'OK') {
      final token = result['user_token'];
      if (token == null || token.isEmpty) {
        throw Exception(result['error_message'] ?? 'Login gagal');
      }
      return token; // Langsung kembalikan token
    } else {
      throw Exception('Login gagal');
    }
  }

  Future<void> saveUserSession(String token, {MaintenanceInfo? selectedMaintenance}) async {
    await AuthStorage.saveToken(token);
    final payload = JwtHelper.decode(token);
    if (payload == null) throw Exception("Token tidak valid");

    // Tentukan maintenance_by dan maintenance_by_name
    final maintenanceBy = selectedMaintenance?.maintenanceBy ?? payload['maintenance'][0]['maintenance_by'];
    final maintenanceByName = selectedMaintenance?.maintenanceByName ?? payload['maintenance'][0]['maintenance_by_name'];

    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown Device';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}"; // mis: "Samsung SM-A525F"
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceModel = iosInfo.utsname.machine; // mis: "iPhone13,2"
    }

    await AuthStorage.saveUser(
      userId: payload['user_id'],
      name: payload['user_name'],
      email: payload['email'],
      maintenanceBy: maintenanceBy, // Gunakan nilai yang sudah ditentukan
      maintenanceByName: maintenanceByName, // Gunakan nilai yang sudah ditentukan
      role: payload['role_code'],
      team: payload['team'],
      deviceModel: deviceModel,
    );
  }

  Future<String?> getToken() async {
    return await AuthStorage.getToken();
  }

  Future<void> deleteToken() async {
    await AuthStorage.clearAll();
  }

  Future<bool> hasToken() async {
    return (await getToken()) != null;
  }

  Future<void> recordLogin(String token, String vendorId) async {
    try {
      // Ambil data dari token untuk dikirim
      final payload = JwtHelper.decode(token);
      if (payload == null) return;

      final deviceInfo = DeviceInfoPlugin();
      String deviceModel = 'Unknown Device';
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      }

      final requestBody = {
        'user_id': payload['user_id'],
        'user_name': payload['user_name'],
        'vendor_id': vendorId,
        'device': deviceModel,
        'login_time': DateTime.now().toIso8601String(),
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      Uri uri = getUrl(pathUrl: '/login/log');
      http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      print("Gagal mencatat log login: $e");
    }
  }

  Future<void> recordLogout() async {
    try {
      final token = await AuthStorage.getToken();
      final userData = await AuthStorage.getUser();
      final deviceModel = userData['device_model'] ?? '';
      final userId = userData['user_id'];
      if (userId == null) return;

      final requestBody = {
        'user_id': userId,
        'device': deviceModel,
        'logout_time': DateTime.now().toIso8601String(),
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      Uri uri = getUrl(pathUrl: '/logout/log');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      print("Gagal mencatat log logout: $e");
    }
  }
}
