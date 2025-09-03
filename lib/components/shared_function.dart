import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salsa/components/constants.dart';

/// Fungsi untuk mendapatkan tanggal dalam format yang lebih mudah dibaca
String getFormattedIndonesianDate(
    [DateTime? date, String pattern = 'EEEE, d MMM yyyy']) {
  final formatter = DateFormat(pattern, 'id_ID');
  return formatter.format(date ?? DateTime.now());
}

/// Fungsi untuk menghasilkan warna acak
Color generateRandomColor() {
  final random = Random();
  return Color.fromARGB(
    255,
    random.nextInt(256),
    random.nextInt(256),
    random.nextInt(256),
  );
}

class JwtHelper {
  /// Decode JWT token dan kembalikan payload sebagai Map
  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return json.decode(payload);
    } catch (e) {
      return null;
    }
  }

  /// Ambil nilai dari key tertentu dalam payload
  static String? getValue(String token, String key) {
    final payload = decode(token);
    return payload != null && payload.containsKey(key)
        ? payload[key].toString()
        : null;
  }
}

Uri getUrl({required String pathUrl, Map<String, dynamic>? params}) {
  String newPath = kPath + pathUrl;
  Uri uri = Uri.https(kBaseUrl, newPath, params);
  return uri;
}

String normalizePhoneNumber(String input) {
  String cleaned = input.replaceAll(' ', '').replaceAll('-', '');

  if (cleaned.startsWith('+62')) {
    cleaned = '0${cleaned.substring(3)}';
  } else if (cleaned.startsWith('62')) {
    cleaned = '0${cleaned.substring(2)}';
  } else if (!cleaned.startsWith('0')) {
    cleaned = '0$cleaned';
  }

  return cleaned;
}

String maskNumberCustom(String number) {
  String normalizeNumber = normalizePhoneNumber(number);
  int length = normalizeNumber.length;

  if (length <= 4) return normalizeNumber;

  int maskCount = (length ~/ 2) + 1;
  int prefixLength = ((length - maskCount) / 2).floor();
  int suffixLength = length - maskCount - prefixLength;

  String prefix = normalizeNumber.substring(0, prefixLength);
  String suffix = normalizeNumber.substring(length - suffixLength);
  String stars = '*' * maskCount;

  return '$prefix$stars$suffix';
}

class ChipBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  ChipBarDelegate(this.child);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 52;

  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}

String getIndonesianTimezoneAbbreviation(DateTime dateTime) {
  final offsetHours = dateTime.timeZoneOffset.inHours;
  if (offsetHours == 7) return 'WIB';
  if (offsetHours == 8) return 'WITA';
  if (offsetHours == 9) return 'WIT';
  return dateTime.timeZoneName; // Fallback
}

Future<String> getPublicIpAddress() async {
  try {
    final response = await http.get(Uri.parse('https://api.ipify.org'));
    if (response.statusCode == 200) {
      return response.body;
    }
    // Jika gagal, kembalikan string default
    return 'IP Tidak Ditemukan';
  } catch (e) {
    // Jika ada error koneksi
    return 'IP Tidak Ditemukan';
  }
}

String getHiveKeyForTransaction(String transNo) {
  return transNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

