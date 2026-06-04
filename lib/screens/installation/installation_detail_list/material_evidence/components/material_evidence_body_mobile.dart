import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Bloc & Models Imports
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/blocs/installation/installation_state.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/models/common/captured_image_detail.dart';

// Services & Components Imports
import 'package:salsa/components/services/watermark_service.dart';
import 'package:salsa/components/widgets/full_screen_image_viewer.dart';

import '../../../../../components/shared_function.dart';

// --- INTERNAL HELPER MODEL ---
class _EvidenceItem {
  final String key;
  final String label;
  final String subLabel;
  final String type;

  _EvidenceItem({
    required this.key,
    required this.label,
    required this.subLabel,
    required this.type,
  });
}

class MaterialEvidenceBodyMobile extends StatefulWidget {
  final String transNo;

  const MaterialEvidenceBodyMobile({super.key, required this.transNo});

  @override
  State<MaterialEvidenceBodyMobile> createState() =>
      _MaterialEvidenceBodyMobileState();
}

class _MaterialEvidenceBodyMobileState
    extends State<MaterialEvidenceBodyMobile> {
  final Map<String, bool> _processingItems = {};

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstallationBloc, InstallationState>(
      listener: (context, state) {},
      builder: (context, state) {
        final draft = state.draftEntry;
        if (draft == null)
          return const Center(child: CircularProgressIndicator());

        // --- 1. GENERATE UNIQUE LIST ---
        final Map<String, _EvidenceItem> uniqueItems = {};

        for (var unit in draft.units) {
          // A. PIPA (kecuali Pipa Drain)
          for (var p in unit.materials.pipes) {
            if (p.brandId.isNotEmpty && p.usageType != 'PIPA_DRAIN') {
              final key = "${p.articleId}_${p.brandId}";
              if (!uniqueItems.containsKey(key)) {
                uniqueItems[key] = _EvidenceItem(
                  key: key,
                  label: p.articleName,
                  subLabel: "Brand: ${p.brandName}",
                  type: "PIPA",
                );
              }
            }
          }
          // B. KABEL (kecuali Kabel Duct)
          for (var c in unit.materials.cables) {
            if (c.brandId.isNotEmpty && c.usageType != 'KABEL_DUCT') {
              final key = "${c.articleId}_${c.brandId}";
              if (!uniqueItems.containsKey(key)) {
                uniqueItems[key] = _EvidenceItem(
                  key: key,
                  label: c.articleName,
                  subLabel: "Brand: ${c.brandName}",
                  type: "KABEL",
                );
              }
            }
          }
        }

        if (uniqueItems.isEmpty) return _buildEmptyState();

        // --- 2. SORTING DESCENDING (Z-A) ---
        final allItems = uniqueItems.values.toList();

        final pipes = allItems.where((i) => i.type == "PIPA").toList();
        final cables = allItems.where((i) => i.type == "KABEL").toList();

        // [UPDATE] Sort by Label DESCENDING (b.label compareTo a.label)
        pipes.sort((a, b) => b.label.compareTo(a.label));
        cables.sort((a, b) => b.label.compareTo(a.label));

        // Gabung kembali (Pipa tetap grup atas, Kabel bawah)
        // Kalau mau grupnya juga dibalik (Kabel atas, Pipa bawah), tinggal tukar posisi variable di bawah
        final sortedItems = [...pipes, ...cables];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];

            MaterialEvidenceModel? existing;
            try {
              existing =
                  draft.materialEvidences.firstWhere((e) => e.key == item.key);
            } catch (_) {}

            return _buildPhotoCard(context, item, existing);
          },
        );
      },
    );
  }

  Widget _buildPhotoCard(BuildContext context, _EvidenceItem itemData,
      MaterialEvidenceModel? savedData) {
    String photoPath = savedData?.photoPath ?? '';
    bool hasImage = photoPath.isNotEmpty && File(photoPath).existsSync();
    bool isLoading = _processingItems[itemData.key] ?? false;

    bool isPipe = itemData.type == 'PIPA';
    Color typeColor = isPipe ? Colors.blue : Colors.orange;
    IconData typeIcon =
        isPipe ? Icons.water_drop_outlined : Icons.electrical_services;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: hasImage
                  ? Colors.green.withOpacity(0.5)
                  : Colors.grey.shade300,
              width: 1)),
      child: InkWell(
        onTap: isLoading
            ? null
            : () => hasImage
                ? _showPreviewDialog(context, itemData, photoPath)
                : _takePhoto(itemData),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ICON
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),

              // INFO TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(itemData.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(itemData.subLabel, style: TextStyle(fontSize: 12)),
                    if (isLoading)
                      const Text("Memproses...",
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontStyle: FontStyle.italic))
                    else if (hasImage)
                      const Text("Terfoto ✅",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                  ],
                ),
              ),

              // THUMBNAIL / BUTTON
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      hasImage ? null : Border.all(color: Colors.grey.shade300),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                Image.file(File(photoPath), fit: BoxFit.cover))
                        : const Icon(Icons.camera_alt,
                            color: Colors.grey, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIC FOTO ---
  Future<void> _takePhoto(_EvidenceItem item) async {
    setState(() => _processingItems[item.key] = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85);

      if (image != null) {
        final user = await AuthStorage.getUser();
        final directory = await getApplicationDocumentsDirectory();

        final String fileName =
            'WM_EVID_${item.key}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String targetPath = p.join(directory.path, fileName);
        final String techName = user['name'] ?? 'Teknisi';

        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        final req = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: techName,
          deviceModel: 'Mobile App',
          location: '',
        );

        final String? resultPath = await WatermarkService.processImage(req);

        if (resultPath != null) {
          if (mounted) {
            // [FIXED] Langsung kirim parameter String, tanpa MaterialEvidenceModel
            context.read<InstallationBloc>().add(SaveMaterialEvidence(
                key: item.key, title: item.label, path: resultPath));
          }
          try {
            await File(image.path).delete();
          } catch (_) {}
        } else {
          _showError("Gagal memproses watermark foto.");
        }
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
      _showError("Terjadi kesalahan saat mengambil foto.");
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(item.key));
      }
    }
  }

  // --- PREVIEW DIALOG ---
  void _showPreviewDialog(
      BuildContext context, _EvidenceItem itemData, String photoPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text(itemData.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  final imgDetail = CapturedImageDetail(
                      imagePath: photoPath,
                      timestamp: DateTime.now(),
                      technicianName: '',
                      deviceModel: '',
                      transNo: widget.transNo,
                      latitude: 0,
                      longitude: 0,
                      address: "${itemData.label} - ${itemData.subLabel}");

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenImageViewer(imageDetail: imgDetail),
                      ));
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.file(File(photoPath), fit: BoxFit.cover),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text("Ketuk untuk perbesar",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _takePhoto(itemData);
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text("Ambil Ulang Foto"),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.orange.shade700),
                      foregroundColor: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
      ));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Belum ada Material diinput",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
