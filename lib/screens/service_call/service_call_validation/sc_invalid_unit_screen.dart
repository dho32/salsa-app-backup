import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../blocs/auth/auth_storage.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_bloc.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_event.dart';
import '../../../blocs/service_call/validation_dropdown/validation_dropdown_state.dart';
import '../../../components/services/watermark_service.dart';
import '../../../models/common/captured_image_detail.dart';

class ScInvalidUnitScreen extends StatefulWidget {
  final String transNo;
  final String serialNo;

  const ScInvalidUnitScreen({
    super.key,
    required this.transNo,
    required this.serialNo,
  });

  @override
  State<ScInvalidUnitScreen> createState() => _ScInvalidUnitScreenState();
}

class _ScInvalidUnitScreenState extends State<ScInvalidUnitScreen> {
  final List<CapturedImageDetail> _proofPhotos = [];
  bool _isTakingPhoto = false;

  // Fungsi ambil foto (Copy-Paste logic dari yang sudah ada)
  Future<void> _takePhoto() async {
    setState(() => _isTakingPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (image != null) {
        final userData = await AuthStorage.getUser();
        final technicianName = userData['name'] ?? 'Unknown';
        final deviceModel = userData['device_model'] ?? 'Unknown Device';
        final timestamp = DateTime.now();

        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) await imagesDir.create();

        final targetPath = p.join(imagesDir.path,
            'WM_INVALID_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          timestamp: timestamp,
          technicianName: technicianName,
          deviceModel: deviceModel,
        );

        final String? finalPath = await WatermarkService.processImage(request);

        if (finalPath != null) {
          setState(() {
            _proofPhotos.add(CapturedImageDetail(
              imagePath: finalPath,
              timestamp: timestamp,
              latitude: 0, longitude: 0, address: "",
              technicianName: technicianName,
              deviceModel: deviceModel,
              transNo: widget.transNo,
            ));
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil foto: $e")),
      );
    } finally {
      setState(() => _isTakingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ValidationDropdownBloc, ValidationDropdownState>(
      listenWhen: (prev, current) =>
      prev is ValidationDropdownLoaded &&
          current is ValidationDropdownLoaded &&
          prev.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (state is ValidationDropdownLoaded) {
          if (state.saveStatus == ValidationSaveStatus.successFinal) {

            Navigator.of(context).pop();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Unit berhasil di batalkan"), backgroundColor: Colors.green),
            );
          } else if (state.saveStatus == ValidationSaveStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.saveMessage ?? "Gagal"), backgroundColor: Colors.red),
            );
          }
        }
      },
      child: BlocBuilder<ValidationDropdownBloc, ValidationDropdownState>(
        builder: (context, state) {
          // Cek status saving untuk loading overlay
          bool isSaving = false;
          if (state is ValidationDropdownLoaded) {
            isSaving = state.saveStatus == ValidationSaveStatus.saving;
          }

          return Stack(
            children: [
              Scaffold(
                appBar: AppBar(
                  title: const Text("Batalkan Pengerjaan Unit"),
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade900,
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. WARNING CARD
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Perhatian!",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text("Anda akan menandai unit ini sebagai 'Unit Tidak Sesuai'.\n\n"
                                      "• Semua data pengukuran untuk unit ini akan di lewati.\n"
                                      "• Alasan: 'Unit AC yang di komplain tidak sesuai'."),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. PHOTO SECTION
                      const Text("Foto Bukti Unit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),

                      if (_proofPhotos.isEmpty)
                        InkWell(
                          onTap: isSaving ? null : _takePhoto,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade600),
                                const SizedBox(height: 8),
                                Text("Ketuk untuk ambil foto", style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
                          ),
                          itemCount: _proofPhotos.length < 2 ? _proofPhotos.length + 1 : _proofPhotos.length,
                          itemBuilder: (context, index) {
                            // Tombol tambah foto (jika slot masih ada)
                            if (index == _proofPhotos.length) {
                              return InkWell(
                                onTap: isSaving ? null : _takePhoto,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Center(child: Icon(Icons.add, size: 32)),
                                ),
                              );
                            }

                            // Preview Foto
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(File(_proofPhotos[index].imagePath), fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4, right: 4,
                                  child: GestureDetector(
                                    onTap: isSaving ? null : () => setState(() => _proofPhotos.removeAt(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      child: const Icon(Icons.delete, color: Colors.red, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                bottomNavigationBar: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: (_proofPhotos.isNotEmpty && !isSaving && !_isTakingPhoto)
                        ? () {
                      // KIRIM EVENT KE BLOC
                      context.read<ValidationDropdownBloc>().add(
                        MarkUnitAsInvalid(
                          transNo: widget.transNo,
                          serialNo: widget.serialNo,
                          proofPhotos: _proofPhotos,
                          reason: "Unit AC yang di komplain tidak sesuai",
                        ),
                      );
                    }
                        : null,
                    child: const Text("Konfirmasi Salah Unit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              // LOADING OVERLAY
              if (isSaving || _isTakingPhoto)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}