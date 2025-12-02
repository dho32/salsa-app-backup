import 'dart:io';
import 'package:flutter/material.dart';

import '../../models/common/captured_image_detail.dart';
import '../shared_function.dart';

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
    final double targetWidth =
        MediaQuery.of(context).size.width.toInt().toDouble();
    final double targetHeight =
        MediaQuery.of(context).size.height.toInt().toDouble();

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
                  : ImageHelper.safeFile(imageDetail.imagePath,
                      cacheWidth: 1080, cacheHeight: 1080)),
        ),
      ),
    );
  }
}
