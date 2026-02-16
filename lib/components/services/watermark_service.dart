import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// ===============================
/// WATERMARK REQUEST
/// ===============================
class WatermarkRequest {
  final String originalPath;
  final String targetPath;
  final String transNo;
  final String formattedDate;
  final String technicianName;
  final String deviceModel;
  final String? location;

  WatermarkRequest({
    required this.originalPath,
    required this.targetPath,
    required this.transNo,
    required this.formattedDate,
    required this.technicianName,
    required this.deviceModel,
    this.location,
  });
}

/// ===============================
/// WATERMARK SERVICE
/// ===============================
class WatermarkService {
  static Future<String?> processImage(WatermarkRequest request) async {
    try {
      return await compute(_addWatermarkInIsolate, request);
    } catch (e) {
      debugPrint('🔴 Gagal proses watermark: $e');
      return null;
    }
  }

  /// ===============================
  /// ISOLATE FUNCTION (PURE & RAM SAFE)
  /// ===============================
  static Future<String> _addWatermarkInIsolate(
      WatermarkRequest req) async {
    final imageFile = File(req.originalPath);
    final bytes = await imageFile.readAsBytes();

    img.Image? image = img.decodeJpg(bytes);
    if (image == null) return req.originalPath;

    // ===============================
    // WATERMARK CONTENT
    // ===============================
    final lines = [
      req.transNo,
      req.formattedDate,
      'Difoto Oleh: ${req.technicianName}',
      'Device: ${req.deviceModel}',
      if (req.location?.isNotEmpty == true) req.location!,
    ];

    final font = img.arial24;
    const padding = 20;
    const x = 30;
    final lineHeight = font.size + 15;
    final bgHeight = lines.length * lineHeight + padding * 2;
    final bgY = image.height - bgHeight;

    // Background transparan
    img.fillRect(
      image,
      x1: 0,
      y1: bgY,
      x2: image.width,
      y2: image.height,
      color: img.ColorRgba8(0, 0, 0, 130),
    );

    // Draw text
    int y = bgY + padding;
    for (final line in lines) {
      img.drawString(
        image,
        line,
        font: font,
        x: x,
        y: y,
        color: img.ColorRgb8(255, 255, 255),
      );
      y += lineHeight;
    }

    // Encode hasil
    final outBytes = img.encodeJpg(image, quality: 70);
    final outFile = File(req.targetPath);
    await outFile.writeAsBytes(outBytes);

    // 🧹 HAPUS FILE KAMERA ASLI (ANTI OOM)
    try {
      await imageFile.delete();
    } catch (_) {}

    return req.targetPath;
  }
}
