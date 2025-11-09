import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:salsa/components/constants.dart';

import '../models/common/captured_image_detail.dart';

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
  Widget build(BuildContext context, double shrinkOffset,
      bool overlapsContent) =>
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
  return transNo.toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
}

class LocationHelper {
  static Future<bool> validateLocation({
    required CapturedImageDetail pic,
    required double tokoLat,
    required double tokoLng,
    double maxDistance = kDistance,
  }) async {
    final distance = Geolocator.distanceBetween(
      tokoLat,
      tokoLng,
      pic.latitude,
      pic.longitude,
    );

    return distance <= maxDistance;
  }

  /// Hitung jarak (meter) antara toko dan foto
  static Future<double> calculateDistance({
    required CapturedImageDetail pic,
    required double tokoLat,
    required double tokoLng,
  }) async {
    return Geolocator.distanceBetween(
      tokoLat,
      tokoLng,
      pic.latitude,
      pic.longitude,
    );
  }
}

class NumericRangeFormatter extends TextInputFormatter {
  final double max;

  NumericRangeFormatter({required this.max});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue,
      TextEditingValue newValue,) {
    // Jika field dikosongkan, izinkan.
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Coba ubah teks baru menjadi angka.
    final double? value = double.tryParse(newValue.text);

    // Jika teks bukan angka yang valid (misal: "12."), biarkan apa adanya untuk sementara.
    // FilteringTextInputFormatter yang sudah ada akan menanganinya.
    if (value == null) {
      return newValue;
    }

    // INTI LOGIKA: Jika angka yang baru diketik lebih besar dari batas maksimal...
    if (value > max) {
      // ...JANGAN terima perubahan, kembalikan nilai yang lama.
      return oldValue;
    }

    // Jika valid, terima perubahan.
    return newValue;
  }
}

class DashedRect extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final Radius radius;
  final Widget child;

  const DashedRect({
    super.key,
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashWidth = 6.0,
    this.radius = const Radius.circular(0),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: color,
        strokeWidth: strokeWidth,
        gap: gap,
        dashWidth: dashWidth,
        radius: radius,
      ),
      child: child,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final Radius radius;

  _DashedRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashWidth = 6.0,
    this.radius = const Radius.circular(0),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final dashedPath = Path();
    final shapePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          radius,
        ),
      );

    for (final metric in shapePath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += (dashWidth + gap);
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

