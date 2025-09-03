import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/common/captured_image_detail.dart';
import 'full_screen_image_viewer.dart';

Widget buildPhotoGrid(
    BuildContext context,
    List<CapturedImageDetail> photos, {
      required bool isLoading,
      required ValueChanged<String> onRemovePhoto, // Terima callback untuk aksi hapus
    }) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: photos.length + (isLoading ? 1 : 0),
    itemBuilder: (context, index) {
      if (isLoading && index == photos.length) {
        return Container( /* ... placeholder loading ... */ );
      }

      final imageDetail = photos[index];
      return Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageDetail: imageDetail)),
            ),
            child: Hero(
              tag: imageDetail.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FadeInImage(
                  placeholder: const AssetImage(
                      'assets/images/placeholder_image.jpeg'),
                  // Gambar placeholder
                  image: FileImage(File(imageDetail.imagePath)),
                  // Gambar asli
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  // Jika terjadi error saat load gambar asli
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        size: 40, color: Colors.grey);
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            // PANGGIL CALLBACK onRemovePhoto SECARA LANGSUNG
            onTap: () => onRemovePhoto(imageDetail.imagePath),
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ],
      );
    },
  );
}