import 'dart:io';
import 'package:flutter/material.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

class RemarkPhotoPicker extends StatelessWidget {
  final List<CapturedImageDetail> photos;
  final VoidCallback onAddTap;
  final Function(String path) onRemoveTap;
  final bool isReadOnly;
  final bool isLoading;

  const RemarkPhotoPicker({
    super.key,
    required this.photos,
    required this.onAddTap,
    required this.onRemoveTap,
    this.isReadOnly = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Foto Pendukung (Wajib)",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              // Tombol Tambah (Muncul jika belum read-only & slot masih ada)
              if (!isReadOnly && photos.length < 5)
                InkWell(
                  onTap: isLoading ? null : onAddTap,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: isLoading
                        ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Row(
                      children: [
                        Icon(Icons.camera_alt,
                            size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text("Tambah Foto",
                            style: TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Area List Foto
        if (photos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                "Belum ada foto dilampirkan.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            ),
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: photos.map((photo) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(photo.imagePath),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Tombol Hapus (Silang Merah)
                  if (!isReadOnly)
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => onRemoveTap(photo.imagePath),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(blurRadius: 2, color: Colors.black26)
                            ],
                          ),
                          child: const Icon(Icons.close,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
      ],
    );
  }
}