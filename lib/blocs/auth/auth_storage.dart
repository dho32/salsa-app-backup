import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthStorage {
  static const _tokenKey = 'user_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _maintenanceType = 'maintenance_type';
  static const _maintenanceBy = 'maintenance_by';
  static const _maintenanceByName = 'maintenance_by_name';
  static const _userRole = 'role';
  static const _userTeam = 'team';
  static const _deviceModelKey = 'device_model';

  static final _secureStorage = FlutterSecureStorage();

  /// Save token securely
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Read token
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// validation token
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Delete token (logout)
  static Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Check if token is expired
  static Future<bool> isTokenExpired() async {
    final token = await getToken();
    if (token == null) return true;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];

      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp < now;
    } catch (_) {
      return true;
    }
  }

  /// Save user info (non-sensitive)
  static Future<void> saveUser({
    required String userId,
    required String name,
    required String email,
    required String maintenanceType,
    required maintenanceBy,
    required maintenanceByName,
    required role,
    required team,
    required String deviceModel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_maintenanceType, maintenanceType);
    await prefs.setString(_maintenanceBy, maintenanceBy);
    await prefs.setString(_maintenanceByName, maintenanceByName);
    await prefs.setString(_userRole, role);
    await prefs.setString(_userTeam, team);
    await prefs.setString(_deviceModelKey, deviceModel);
  }

  /// Get user info
  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString(_userIdKey),
      'name': prefs.getString(_userNameKey),
      'email': prefs.getString(_userEmailKey),
      'maintenance_type': prefs.getString(_maintenanceType),
      'maintenance_by': prefs.getString(_maintenanceBy),
      'maintenance_by_name': prefs.getString(_maintenanceByName),
      'role': prefs.getString(_userRole),
      'team': prefs.getString(_userTeam),
      'device_model': prefs.getString(_deviceModelKey),
    };
  }

  /// Clear all stored info
  static Future<void> clearAll() async {
    await clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_maintenanceType);
    await prefs.remove(_maintenanceBy);
    await prefs.remove(_maintenanceByName);
    await prefs.remove(_userRole);
    await prefs.remove(_userTeam);
    await prefs.remove(_deviceModelKey);
  }
}
