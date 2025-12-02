import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/common/captured_image_detail.dart';
import 'full_screen_image_viewer.dart';

Widget buildPhotoGrid(
    BuildContext context,
    List<CapturedImageDetail> photos, {
      required bool isLoading,
      required ValueChanged<String> onRemovePhoto,
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
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      final imageDetail = photos[index];
      final imageFile = File(imageDetail.imagePath);

      return Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImageViewer(imageDetail: imageDetail),
                ),
              );
            },
            child: Hero(
              tag: imageDetail.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  cacheWidth: 300,
                  cacheHeight: 300,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
                  },
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onRemovePhoto(imageDetail.imagePath),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ],
      );
    },
  );
}
