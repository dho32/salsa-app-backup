import 'dart:io';
import 'package:flutter/material.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

class FullScreenImageViewer extends StatelessWidget {
  final CapturedImageDetail imageDetail;
  final bool isNetworkImage;

  const FullScreenImageViewer({
    super.key,
    required this.imageDetail,
    this.isNetworkImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Hero(
          tag: imageDetail.imagePath,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: isNetworkImage
                ? Image.network(
              imageDetail.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 100),
            )
                : Image.file(
              File(imageDetail.imagePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 100),
            ),
          ),
        ),
      ),
    );
  }
}