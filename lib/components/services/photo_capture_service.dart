import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../blocs/auth/auth_storage.dart';
import '../../models/common/captured_image_detail.dart';
import '../shared_function.dart';
import 'watermark_service.dart';

/// Ambil foto dari kamera, beri watermark (transNo, tanggal, teknisi, device),
/// lalu kembalikan [CapturedImageDetail]. Return null jika dibatalkan/gagal.
///
/// Pola identik dengan `MeasurementInputWidget._takePhoto` supaya konsisten di
/// seluruh app. Modul Cuci Freezer reuse ini untuk foto kondisi awal (Step 1)
/// dan foto setelah cuci (Step 3).
Future<CapturedImageDetail?> captureWatermarkedPhoto(String transNo) async {
  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 1080,
    maxHeight: 1920,
    imageQuality: 80,
  );
  if (image == null) return null;

  final userData = await AuthStorage.getUser();
  final technicianName = userData['name'] ?? 'Unknown';
  final deviceModel = userData['device_model'] ?? 'Unknown Device';
  final timestamp = DateTime.now();

  final zone = getIndonesianTimezoneAbbreviation(timestamp);
  final formattedDate =
      '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
  if (!await imagesDir.exists()) {
    await imagesDir.create();
  }
  final targetPath =
      p.join(imagesDir.path, 'WM_${timestamp.millisecondsSinceEpoch}.jpg');

  final request = WatermarkRequest(
    originalPath: image.path,
    targetPath: targetPath,
    transNo: transNo,
    formattedDate: formattedDate,
    technicianName: technicianName,
    deviceModel: deviceModel,
  );

  final String? finalImagePath = await WatermarkService.processImage(request);
  if (finalImagePath == null) return null;

  return CapturedImageDetail(
    imagePath: finalImagePath,
    timestamp: timestamp,
    latitude: 0,
    longitude: 0,
    address: '',
    technicianName: technicianName,
    deviceModel: deviceModel,
    transNo: transNo,
  );
}
