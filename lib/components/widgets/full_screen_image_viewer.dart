// lib/screens/common/image_viewer/full_screen_image_viewer.dart
import 'dart:io'; // Untuk Image.file
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk DateFormat
import 'package:salsa/models/common/captured_image_detail.dart';

import '../shared_function.dart'; // Import model CapturedImageDetail

class FullScreenImageViewer extends StatelessWidget {
  final CapturedImageDetail imageDetail;
  final bool
      isNetworkImage; // True jika gambar dari URL, false jika dari path lokal

  const FullScreenImageViewer({
    super.key,
    required this.imageDetail,
    this.isNetworkImage = false, // Defaultnya gambar lokal
  });

  @override
  Widget build(BuildContext context) {
    String zone = getIndonesianTimezoneAbbreviation(imageDetail.timestamp);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context), // Kembali saat diketuk
        child: Center(
          child: Hero(
            tag: imageDetail.imagePath,
            // Menggunakan imagePath sebagai Hero tag
            child: InteractiveViewer(
              // Memungkinkan pinch-to-zoom
              child: isNetworkImage
                  ? Image.network(
                      imageDetail.imagePath,
                      fit: BoxFit.contain, // Sesuaikan fit
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 100),
                    )
                  : Image.file(
                      File(imageDetail.imagePath),
                      fit: BoxFit.contain, // Sesuaikan fit
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 100),
                    ),
            ),
          ),
        ),
      ),
      // Overlay informasi di bagian bawah atau atas layar
      bottomNavigationBar: Container(
        color: Colors.black12,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Penting agar tidak memenuhi tinggi
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(imageDetail.transNo,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('dd MMMM yyyy, HH:mm:ss ')
                    .format(imageDetail.timestamp) + zone,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
              Text(
                'Difoto Oleh: ${imageDetail.technicianName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,),
              ),
              Text(
                'Device: ${imageDetail.deviceModel}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,),
              ),
              // const SizedBox(height: 4),
              // Text(
              //   'Lat: ${imageDetail.latitude.toStringAsFixed(6)}, Long: ${imageDetail.longitude.toStringAsFixed(6)}',
              //   style: const TextStyle(color: Colors.white, fontSize: 14),
              // ),
              // Text(
              //   imageDetail.address,
              //   style: const TextStyle(color: Colors.white, fontSize: 14),
              // ),
              // Jika Anda punya data tambahan seperti keterangan foto, bisa ditambahkan di sini
            ],
          ),
        ),
      ),
    );
  }
}
