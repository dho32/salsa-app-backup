import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../components/constants.dart';
import '../../components/shared_function.dart';
import '../../models/auth/maintenance_info_model.dart';
import '../../models/common/measurement_limits.dart';
import 'auth_storage.dart';

class AuthRepository {
  Future<String> login(String email, String password, String appVersion) async {
    Uri uri = getUrl(pathUrl: 'login');
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

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    String prettyJson = encoder.convert(result);
    log("====== BODY REQUEST LENGKAP ======");
    log(prettyJson);
    log("================================");

    if (response.statusCode == 200 && data['status'] == 'OK') {
      final token = result['user_token'];
      if (token == null || token.isEmpty) {
        throw Exception(result['error_message'] ?? 'Login gagal');
      }
      if (result['app_config'] != null) {
        await _saveAppConfigToHive(result['app_config']);
      }
      return token;
    } else {
      throw Exception('Login gagal');
    }
  }

  Future<void> _saveAppConfigToHive(Map<String, dynamic> configJson) async {
    try {
      final configBox = await Hive.openBox(kAppConfigBox);

      Map<String, MeasurementLimits> parseLimitsMap(dynamic map) {
        if (map == null || map is! Map) return {};
        return map.map<String, MeasurementLimits>(
          (key, value) => MapEntry(
            key as String,
            MeasurementLimits.fromJson(value as Map<String, dynamic>),
          ),
        );
      }

      // Parsing setiap 'key' dari JSON API
      final limitsTempHeader = parseLimitsMap(configJson['limits_temp_header']);
      final limitsScBefore =
          parseLimitsMap(configJson['limits_validation_unit']?['sc_before']);
      final limitsScAfter =
          parseLimitsMap(configJson['limits_validation_unit']?['sc_after']);
      final limitsPosAfter =
          parseLimitsMap(configJson['limits_validation_unit']?['pos_after']);

      // Simpan ke Hive (Gunakan 'put' agar menimpa config lama)
      await configBox.put('limits_temp_header', limitsTempHeader);
      await configBox.put('limits_sc_before', limitsScBefore);
      await configBox.put('limits_sc_after', limitsScAfter);
      await configBox.put('limits_pos_after', limitsPosAfter);

      log("Data limits_temp_header: ${limitsTempHeader.length} item");
      log("Data limits_sc_before: ${limitsScBefore.length} item");
      log("Data limits_sc_after: ${limitsScAfter.length} item");
      log("Data limits_pos_after: ${limitsPosAfter.length} item");
    } catch (e) {
      // print("🔴 GAGAL menyimpan AppConfig ke Hive: $e");
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
