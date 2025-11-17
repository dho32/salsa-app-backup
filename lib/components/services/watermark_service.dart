import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../shared_function.dart';

class WatermarkRequest {
  final String originalPath;
  final String targetPath;
  final String transNo;
  final DateTime timestamp;
  final String technicianName;
  final String deviceModel;
  final String? location;

  WatermarkRequest({
    required this.originalPath,
    required this.targetPath,
    required this.transNo,
    required this.timestamp,
    required this.technicianName,
    required this.deviceModel,
    this.location,
  });
}

class WatermarkService {
  static Future<String?> processImage(WatermarkRequest request) async {
    try {
      final resultPath = await compute(_addWatermarkInIsolate, request);
      return resultPath;
    } catch (e) {
      print("🔴 Gagal proses watermark: $e");
      return null;
    }
  }

  static Future<String> _addWatermarkInIsolate(WatermarkRequest req) async {
    await initializeDateFormatting('id_ID', null);

    final imageFile = File(req.originalPath);
    final imageBytes = imageFile.readAsBytesSync();

    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return req.originalPath;

    // Resize
    if (originalImage.width > 1080) {
      originalImage = img.copyResize(originalImage, width: 1080);
    }

    final String zone = getIndonesianTimezoneAbbreviation(req.timestamp);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID');
    final dateStr = "${dateFormat.format(req.timestamp)} $zone";

    final List<String> lines = [
      req.transNo,
      dateStr,
      "Difoto Oleh: ${req.technicianName}",
      "Device: ${req.deviceModel}",
      if (req.location != null && req.location!.isNotEmpty)
        req.location!,
    ];

    final font = img.arial24;
    const int lineSpacing = 15;
    final int lineHeight = font.size + lineSpacing;

    // Hitung tinggi total teks
    final int totalTextBlockHeight = lines.length * lineHeight;

    // Tentukan Padding Background (biar teks tidak mepet pinggir kotak)
    const int backgroundPaddingTop = 20;
    const int backgroundPaddingBottom = 20;

    // Hitung tinggi Background (Teks + Padding)
    final int backgroundHeight = totalTextBlockHeight + backgroundPaddingTop + backgroundPaddingBottom;

    // Posisi Y Background (Mulai dari bawah gambar dikurangi tinggi background)
    final int backgroundY = originalImage.height - backgroundHeight;

    // --- 1. GAMBAR BACKGROUND TRANSPARAN ---
    img.fillRect(
      originalImage,
      x1: 0,
      y1: backgroundY,
      x2: originalImage.width,
      y2: originalImage.height,
      color: img.ColorRgba8(0, 0, 0, 130),
    );

    // --- 2. POSISI TEKS ---
    int currentY = backgroundY + backgroundPaddingTop;
    const int x = 30;

    // Loop Menggambar Teks
    for (final line in lines) {
      final shadowColor = img.ColorRgb8(0, 0, 0);
      img.drawString(originalImage, line, font: font, x: x - 1, y: currentY, color: shadowColor);
      img.drawString(originalImage, line, font: font, x: x + 1, y: currentY, color: shadowColor);

      // Teks Utama (Putih)
      img.drawString(
        originalImage,
        line,
        font: font,
        x: x,
        y: currentY,
        color: img.ColorRgb8(255, 255, 255),
      );

      currentY += lineHeight;
    }

    final watermarkBytes = img.encodeJpg(originalImage, quality: 80);
    final newFile = File(req.targetPath);
    newFile.writeAsBytesSync(watermarkBytes);

    return req.targetPath;
  }
}