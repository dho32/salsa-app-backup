// lib/services/image_service.dart
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Membuka kamera, mengambil foto, mengompres, dan mengembalikan path file.
  /// Mengembalikan `null` jika pengguna membatalkan.
  Future<String?> takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Kualitas awal sebelum kompresi
    );

    if (image == null) return null; // Pengguna membatalkan

    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create();
    }
    final targetPath =
        p.join(imagesDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    // Kompres file untuk ukuran yang lebih kecil
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70, // Kompresi lebih lanjut
    );

    return compressedFile?.path;
  }
}
