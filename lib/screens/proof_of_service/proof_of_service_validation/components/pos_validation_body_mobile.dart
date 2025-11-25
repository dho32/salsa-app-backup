// pos_validation_body_mobile.dart

import 'dart:io';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../components/widgets/generic_measurement_input_section.dart';
import '../../../../components/widgets/photo_grid.dart';
import '../../../../models/common/measurement_entry.dart';

class PosValidationBodyMobile extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String unitType;
  final String articleDesc;
  final String articleUnitDesc;
  final TextEditingController noteController;
  final double? indoorTemp;
  final List<String> noteOptions;

  const PosValidationBodyMobile({
    super.key,
    required this.transNo,
    required this.serialNo,
    required this.unitType,
    required this.articleDesc,
    required this.articleUnitDesc,
    required this.noteController,
    required this.indoorTemp,
    required this.noteOptions,
  });

  @override
  State<PosValidationBodyMobile> createState() =>
      _PosValidationBodyMobileState();
}

class _PosValidationBodyMobileState extends State<PosValidationBodyMobile> {
  bool _isTakingPhoto = false;
  final Map<String, TextEditingController> _controllers = {};
  String labelUnitIndoor = "Foto Unit Indoor & Evaporator";
  String labelUnitOutdoor = "Foto Unit Outdoor & Kondensor";
  String labelUnit = "";
  final TextEditingController _noteSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.unitType.toUpperCase() == 'IN') {
      labelUnit = labelUnitIndoor;
    } else if (widget.unitType.toUpperCase() == 'OUT') {
      labelUnit = labelUnitOutdoor;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers(List<MeasurementEntry> measurements) {
    // Hapus controller lama untuk mencegah memory leak
    _disposeControllers();

    for (var measurement in measurements) {
      final valueText =
          measurement.value == measurement.value.truncateToDouble()
              ? measurement.value.truncate().toString()
              : measurement.value.toStringAsFixed(1);

      _controllers[measurement.measurementId] =
          TextEditingController(text: valueText == "0" ? "" : valueText);
    }
  }

  void _disposeControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  Future<void> _handlePhoto(BuildContext context,
      {required bool isBefore}) async {
    final currentState = context.read<PosValidationBloc>().state;
    if (currentState is PosValidationLoaded) {
      final photoList =
      isBefore ? currentState.photosBefore : currentState.photosAfter;
      if (photoList.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal hanya bisa upload 2 foto.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isTakingPhoto = true);

    try {
      // Bersihkan memori gambar sebelum membuka kamera berat
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

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
        if (!await imagesDir.exists()) {
          await imagesDir.create();
        }

        // 2. Tentukan Path Target
        final targetPath = p.join(
            imagesDir.path, 'WM_POS_${timestamp.millisecondsSinceEpoch}.jpg');

        // 3. PROSES WATERMARK (Background Transparan + Teks)
        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          timestamp: timestamp,
          technicianName: technicianName,
          deviceModel: deviceModel,
        );

        final String? finalImagePath = await WatermarkService.processImage(request);

        if (finalImagePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memproses foto")));
          }
          return;
        }

        // 4. Simpan ke BLoC
        final capturedImageDetail = CapturedImageDetail(
          imagePath: finalImagePath, // Path hasil watermark
          timestamp: timestamp,
          latitude: 0.0, // (Isi jika pakai GPS)
          longitude: 0.0,
          address: "",
          technicianName: technicianName,
          deviceModel: deviceModel,
          transNo: widget.transNo,
        );

        if (mounted) {
          final bloc = context.read<PosValidationBloc>();
          if (isBefore) {
            bloc.add(AddPhotoBefore(capturedImageDetail));
          } else {
            bloc.add(AddPhotoAfter(capturedImageDetail));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosValidationBloc, PosValidationState>(
      listener: (context, state) {
        if (state is PosValidationLoaded) {
          // Setiap kali BLoC memuat data, kita buat ulang controllernya
          // setState dipanggil agar UI tahu ada controller baru
          setState(() {
            _initializeControllers(state.measurementsAfter);
          });
        }
      },
      child: BlocBuilder<PosValidationBloc, PosValidationState>(
        builder: (context, state) {
          if (state is PosValidationLoading || state is PosValidationInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PosValidationError) {
            return Center(child: Text("Error: ${state.message}"));
          }
          if (state is PosValidationLoaded) {
            // Safety check: Jangan tampilkan UI sebelum controller siap
            if (_controllers.length != state.measurementsAfter.length) {
              return const Center(child: CircularProgressIndicator());
            }

            return Stepper(
              type: StepperType.horizontal,
              currentStep: state.currentStep,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                _buildStep1(context, state),
                _buildStep2(context, state),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Step _buildStep1(BuildContext context, PosValidationLoaded state) {
    return Step(
      title: const Text('Sebelum'),
      isActive: state.currentStep >= 0,
      content: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildValidationHeader(),
            if (state.unitType.toUpperCase() == 'OUT')
              _buildIndoorPairingDropdown(context, state),
            buildPhotoSection(
              context: context,
              title: '$labelUnit Sebelum Perawatan',
              photos: state.photosBefore,
              isLoading: _isTakingPhoto,
              isBefore: true,
              onAddPhoto: () => _handlePhoto(context, isBefore: true),
              onRemovePhoto: (path) => context
                  .read<PosValidationBloc>()
                  .add(RemovePhotoBefore(path)),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStep2(BuildContext context, PosValidationLoaded state) {
    final bool isAnyMeasurementSkipped =
        state.measurementsAfter.any((m) => m.isSkipped ?? false);

    const double itemHeight = 40.0; // Tinggi satu item di menu
    const double searchBarHeight = 50.0; // Tinggi kotak pencarian
    const double verticalPadding = 20.0; // Padding atas & bawah

    // Batas maksimum tinggi dropdown (misal: 40% dari tinggi layar)
    final double maxAllowedHeight = MediaQuery.of(context).size.height * 0.8;

    // Hitung total tinggi yang dibutuhkan oleh semua item + search bar
    final double calculatedContentHeight =
        (widget.noteOptions.length * itemHeight) +
            searchBarHeight +
            verticalPadding;

    // Tentukan tinggi akhir: ambil nilai terkecil antara tinggi yg dihitung dan batas maks
    final double dynamicMaxHeight =
        min(calculatedContentHeight, maxAllowedHeight);

    return Step(
      title: const Text('Sesudah'),
      isActive: state.currentStep >= 1,
      content: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            _buildValidationHeader(),
            if (state.unitType.toUpperCase() == 'OUT' &&
                state.pairedIndoorSerial != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Dipasangkan dengan Indoor: ',
                            style: TextStyle(color: Colors.grey.shade800),
                            children: [
                              TextSpan(
                                text: state.pairedIndoorSerial!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            buildPhotoSection(
              context: context,
              title: '$labelUnit Sesudah Perawatan',
              photos: state.photosAfter,
              isLoading: _isTakingPhoto,
              isBefore: false,
              onAddPhoto: () => _handlePhoto(context, isBefore: false),
              onRemovePhoto: (path) =>
                  context.read<PosValidationBloc>().add(RemovePhotoAfter(path)),
            ),
            const SizedBox(height: 8),
            GenericMeasurementInputSection(
              key: ValueKey(widget.unitType),
              controllers: _controllers,
              transNo: widget.transNo,
              measurements: state.measurementsAfter,
              indoorTemp: widget.indoorTemp,
              onUpdate: (measurement) {
                context
                    .read<PosValidationBloc>()
                    .add(UpdateMeasurementAfter(measurement));
              },
              onMaybeResetNote: () {
                // Dipanggil setiap kali ada measurement yg di-unskip
                // Cek state BLoC saat ini
                final currentState = context.read<PosValidationBloc>().state;
                if (currentState is PosValidationLoaded) {
                  // Periksa apakah MASIH ADA measurement lain yg di-skip
                  final anyOtherSkipped = currentState.measurementsAfter
                      .any((m) => m.isSkipped ?? false);

                  // Jika TIDAK ADA lagi yg di-skip, baru reset controller note
                  if (!anyOtherSkipped) {
                    print(
                        "📝 No other measurements skipped, clearing note controller."); // Log untuk debug
                    widget.noteController.clear();
                    // Opsional: Kirim event ke BLoC untuk membersihkan state note jika perlu
                    // context.read<PosValidationBloc>().add(ClearNoteAfter());
                  } else {
                    print(
                        "📝 Still other measurements skipped, note controller remains."); // Log untuk debug
                  }
                }
              },
            ),
            if (isAnyMeasurementSkipped)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: DropdownButtonFormField2<String>(
                  value: widget.noteController.text.isNotEmpty
                      ? widget.noteController.text
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Catatan (Wajib jika skip pengukuran)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 12),
                  ),
                  hint: const Text(
                    'Pilih Catatan',
                    style: TextStyle(fontSize: 14),
                  ),
                  items: widget.noteOptions
                      .map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                item,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    widget.noteController.text = value ?? '';
                    FocusScope.of(context).unfocus();
                    context.read<PosValidationBloc>().add(UpdateNoteAfter(value ?? ''));
                  },
                  dropdownStyleData: DropdownStyleData(
                    maxHeight: dynamicMaxHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    height: itemHeight,
                    // Gunakan konstanta yg sudah didefinisikan
                    padding: EdgeInsets.only(left: 14, right: 14),
                  ),
                  dropdownSearchData: DropdownSearchData(
                    searchController: _noteSearchController,
                    searchInnerWidgetHeight: searchBarHeight,
                    // Gunakan konstanta
                    searchInnerWidget: Container(
                      height: searchBarHeight,
                      padding: const EdgeInsets.all(8),
                      child: TextFormField(
                        expands: true,
                        maxLines: null,
                        controller: _noteSearchController,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          hintText: 'Cari catatan...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value
                          .toString()
                          .toLowerCase()
                          .contains(searchValue.toLowerCase());
                    },
                  ),
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      _noteSearchController.clear();
                    }
                  },
                  selectedItemBuilder: (context) {
                    return widget.noteOptions.map((item) {
                      return Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          overflow: TextOverflow.ellipsis,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                      );
                    }).toList();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildPhotoSection({
    required BuildContext context,
    required String title,
    required List<CapturedImageDetail> photos,
    required bool isLoading,
    required bool isBefore,
    required VoidCallback onAddPhoto,
    required ValueChanged<String> onRemovePhoto,
  }) {
    final Color primary = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        if (photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildPhotoGrid(context, photos,
                isLoading: isLoading, onRemovePhoto: onRemovePhoto),
          ),
        isLoading
            ? const Center(
                child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(title),
                  onPressed: onAddPhoto,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: BorderSide(color: primary),
                    foregroundColor: primary,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildValidationHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.articleDesc,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.ac_unit, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    widget.articleUnitDesc,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.qr_code, size: 16, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    widget.serialNo,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndoorPairingDropdown(
      BuildContext context, PosValidationLoaded state) {
    List<DropdownMenuItem<String>> items = state.availableIndoorSerials
        .map((serial) => DropdownMenuItem(
              value: serial,
              child: Text(serial),
            ))
        .toList();

    if (state.pairedIndoorSerial != null &&
        !state.availableIndoorSerials.contains(state.pairedIndoorSerial)) {
      items.insert(
          0,
          DropdownMenuItem(
            value: state.pairedIndoorSerial,
            child: Text(state.pairedIndoorSerial!),
          ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pasangkan dengan Unit Indoor (*Wajib diisi)',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: state.pairedIndoorSerial,
            hint: const Text('Pilih Serial No. Indoor'),
            isExpanded: true,
            items: items,
            onChanged: (newValue) {
              context.read<PosValidationBloc>().add(
                    PairOutdoorWithIndoor(
                      outdoorSerialNo: widget.serialNo,
                      indoorSerialNo: newValue,
                    ),
                  );
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
