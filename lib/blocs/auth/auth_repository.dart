import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../../components/shared_function.dart';
import '../../models/auth/maintenance_info_model.dart';
import 'auth_storage.dart';

class AuthRepository {
  Future<String> login(String email, String password, String appVersion) async {
    Uri uri = getUrl(pathUrl: '/login');
    var map = <String, dynamic>{};
    map['user'] = email;
    map['password'] = password;
    map['version'] = appVersion;

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
      return token;
    } else {
      throw Exception('Login gagal');
    }
  }

  Future<void> saveUserSession(String token,
      {MaintenanceInfo? selectedMaintenance}) async {
    await AuthStorage.saveToken(token);
    final payload = JwtHelper.decode(token);
    if (payload == null) throw Exception("Token tidak valid");

    final MaintenanceInfo activeMaintenance;
    if (selectedMaintenance != null) {
      activeMaintenance = selectedMaintenance;
    } else {
      activeMaintenance = MaintenanceInfo.fromJson(payload['maintenance'][0]);
    }

    final String maintenanceType = activeMaintenance.maintenanceType;
    final String maintenanceBy = activeMaintenance.maintenanceBy;
    final String maintenanceByName = activeMaintenance.maintenanceByName;

    final deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown Device';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceModel = "${androidInfo.manufacturer} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceModel = iosInfo.utsname.machine;
    }

    await AuthStorage.saveUser(
      userId: payload['user_id'],
      name: payload['user_name'],
      email: payload['email'],
      maintenanceBy: maintenanceBy,
      maintenanceByName: maintenanceByName,
      role: payload['role_code'],
      team: payload['team'],
      deviceModel: deviceModel,
      maintenanceType: maintenanceType,
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

  Future<void> recordLogin(
      String token, String vendorId, String appVersion) async {
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
        'app_version': appVersion,
      };

      JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      String prettyJson = encoder.convert(requestBody);
      log("====== BODY REQUEST LENGKAP ======");
      log(prettyJson);
      log("================================");

      Uri uri = getUrl(pathUrl: '/login/log');
      http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      print("Gagal mencatat log logout: $e");
    }
  }

  // auth_repository.dart

  Future<Map<String, String>> getAppConfig() async {
    Uri uri = getUrl(pathUrl: '/version');

    try {
      final response = await http.get(uri);
      final decodedResponse = json.decode(response.body);

      if (response.statusCode == 200 && decodedResponse['status'] == 'OK') {
        final result = decodedResponse['result'];
        return {
          'requiredVersion': result['min_app_version'],
          'updateUrl': Platform.isAndroid
              ? result['update_url_android']
              : result['update_url_ios'],
        };
      } else {
        throw Exception('Gagal memuat konfigurasi aplikasi');
      }
    } catch (e) {
      throw Exception(
          'Tidak dapat terhubung ke server untuk memeriksa pembaruan.');
    }
  }
}
