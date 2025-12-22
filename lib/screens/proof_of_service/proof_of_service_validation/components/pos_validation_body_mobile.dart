import 'dart:io';
import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/models/common/captured_image_detail.dart';
import 'package:salsa/models/common/measurement_limits.dart';
import 'package:salsa/models/common/note_option.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_validation/pos_validation_state.dart';
import '../../../../components/constants.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../components/widgets/generic_measurement_input_section.dart';
import '../../../../components/widgets/photo_grid.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../models/common/measurement_entry.dart';

class PosValidationBodyMobile extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String unitType;
  final String articleDesc;
  final String articleUnitDesc;
  final TextEditingController noteController;
  final double? indoorTemp;
  final List<NoteOption> noteOptions;

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
  bool _isTakingPhotoRemark = false;
  final Map<String, TextEditingController> _controllers = {};
  late final TextEditingController _remarkController;
  String labelUnitIndoor = "Foto Unit Indoor & Evaporator";
  String labelUnitOutdoor = "Foto Unit Outdoor & Kondensor";
  String labelUnit = "";

  final TextEditingController _noteSearchController = TextEditingController();

  // Variable Limit Dinamis
  late final Map<String, MeasurementLimits> _limitsPosAfter;

  @override
  void initState() {
    super.initState();
    if (widget.unitType.toUpperCase() == 'IN') {
      labelUnit = labelUnitIndoor;
    } else if (widget.unitType.toUpperCase() == 'OUT') {
      labelUnit = labelUnitOutdoor;
    }

    // --- Load Limit Dinamis dari Hive ---
    final configBox = Hive.box(kAppConfigBox);
    final rawLimits = configBox.get('limits_pos_after');
    final Map<String, MeasurementLimits> limitsMap = {};

    if (rawLimits is Map) {
      rawLimits.forEach((key, value) {
        if (key is String && value is MeasurementLimits) {
          limitsMap[key] = value;
        }
      });
    }

    // Fallback ke kPOSMeasurementLimits jika Hive kosong
    _limitsPosAfter = limitsMap.isNotEmpty ? limitsMap : kPOSMeasurementLimits;

    final state = context.read<PosValidationBloc>().state;
    String initialRemark = '';
    if (state is PosValidationLoaded) {
      initialRemark = state.noteRemark ?? '';
    }
    _remarkController = TextEditingController(text: initialRemark);
  }

  @override
  void dispose() {
    _disposeControllers();
    _noteSearchController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _initializeControllers(List<MeasurementEntry> measurements) {
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
      // Bersihkan memori gambar sebelum membuka kamera berat (Anti OOM)
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

        // Path Target Watermark
        final targetPath = p.join(
            imagesDir.path, 'WM_POS_${timestamp.millisecondsSinceEpoch}.jpg');

        // Proses Watermark di Background
        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          timestamp: timestamp,
          technicianName: technicianName,
          deviceModel: deviceModel,
        );

        final String? finalImagePath =
            await WatermarkService.processImage(request);

        if (finalImagePath == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Gagal memproses foto")));
          }
          return;
        }

        final capturedImageDetail = CapturedImageDetail(
          imagePath: finalImagePath,
          timestamp: timestamp,
          latitude: 0.0,
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

  Future<void> _handleRemarkPhoto(BuildContext context) async {
    final currentState = context.read<PosValidationBloc>().state;

    // 1. Cek Limit Foto (Misal Max 2)
    if (currentState is PosValidationLoaded) {
      final currentPhotos = currentState.remarkPhotos ?? [];
      if (currentPhotos.length >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maksimal hanya bisa upload 2 foto remark.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isTakingPhotoRemark = true);

    try {
      // 2. Bersihkan Cache Gambar
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 3. Ambil Foto
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

        // 4. Proses Watermark (Sama seperti handlePhoto biasa)
        final targetPath = p.join(
            imagesDir.path, 'WM_REMARK_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          timestamp: timestamp,
          technicianName: technicianName,
          deviceModel: deviceModel,
        );

        final String? finalImagePath =
        await WatermarkService.processImage(request);

        if (finalImagePath == null) throw Exception("Gagal watermark");

        final capturedImageDetail = CapturedImageDetail(
          imagePath: finalImagePath,
          timestamp: timestamp,
          latitude: 0.0,
          longitude: 0.0,
          address: "",
          technicianName: technicianName,
          deviceModel: deviceModel,
          transNo: widget.transNo,
        );

        if (mounted) {
          // 5. Kirim Event AddRemarkPhoto ke BLoC
          context.read<PosValidationBloc>().add(AddRemarkPhoto(capturedImageDetail));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPhotoRemark = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosValidationBloc, PosValidationState>(
      listener: (context, state) {
        if (state is PosValidationLoaded) {
          setState(() {
            _initializeControllers(state.measurementsAfter);
            if (_remarkController.text != (state.noteRemark ?? '')) {
              _remarkController.text = state.noteRemark ?? '';
            }
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
                final currentState = context.read<PosValidationBloc>().state;
                if (currentState is PosValidationLoaded) {
                  final anyOtherSkipped = currentState.measurementsAfter
                      .any((m) => m.isSkipped ?? false);

                  if (!anyOtherSkipped) {
                    widget.noteController.clear();
                  }
                }
              },
              limitsMap: _limitsPosAfter, // Pass limit dinamis
            ),
            if (isAnyMeasurementSkipped)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

                // Gunakan Widget Dropdown Dinamis
                child: _buildNoteDropdown(
                  context: context,
                  label: 'Catatan (Wajib jika skip pengukuran)',
                  controller: widget.noteController,
                  noteOptions: widget.noteOptions,
                  remarkPhotos: state.remarkPhotos ?? [],
                  onChanged: (value) {
                    widget.noteController.text = value ?? '';
                    _remarkController.clear();
                    context.read<PosValidationBloc>().add(UpdateNoteRemark(''));
                    FocusScope.of(context).unfocus();
                    context
                        .read<PosValidationBloc>()
                        .add(UpdateNoteAfter(value ?? ''));

                    setState(() {});
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DROPDOWN DINAMIS ---
  Widget _buildNoteDropdown({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required List<NoteOption> noteOptions,
    required ValueChanged<String?> onChanged,
    required List<CapturedImageDetail> remarkPhotos,
  }) {
    final double maxDropdownHeight = MediaQuery.of(context).size.height * 0.4;

    // 1. Filter System Only
    final filteredOptions = noteOptions.where((opt) {
      return !opt.isSystemOnly || opt.label == controller.text;
    }).toList();

    // 2. Cek Read-Only
    final selectedOptionObj = filteredOptions
        .where((opt) => opt.label == controller.text)
        .firstOrNull;
    final bool isReadOnlySystemValue = selectedOptionObj?.isSystemOnly ?? false;
    final bool requireRemark = selectedOptionObj?.requireRemark ?? false;

    return Column(
      children: [
        DropdownButtonFormField2<String>(
          value: controller.text.isNotEmpty ? controller.text : null,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            filled: true,
            fillColor:
                isReadOnlySystemValue ? Colors.grey.shade200 : Colors.white,
          ),
          hint: const Text('Pilih Catatan', style: TextStyle(fontSize: 14)),
          onChanged: isReadOnlySystemValue
              ? null
              : (value) {
                  onChanged(value);
                  FocusScope.of(context).unfocus();
                },
          items: filteredOptions
              .map((item) => DropdownMenuItem<String>(
                    value: item.label,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(item.label,
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ))
              .toList(),
          selectedItemBuilder: (context) {
            return noteOptions.map((item) {
              return Text(
                item.label,
                style: const TextStyle(
                    fontSize: 14, overflow: TextOverflow.ellipsis),
                maxLines: 1,
              );
            }).toList();
          },
          dropdownStyleData: DropdownStyleData(
            maxHeight: maxDropdownHeight,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 14),
          ),
          dropdownSearchData: DropdownSearchData(
            searchController: _noteSearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Container(
              height: 50,
              padding: const EdgeInsets.all(8),
              child: TextFormField(
                expands: true,
                maxLines: null,
                controller: _noteSearchController,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  hintText: 'Cari catatan...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            searchMatchFn: (item, searchValue) => item.value
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase()),
          ),
          onMenuStateChange: (isOpen) {
            if (!isOpen) _noteSearchController.clear();
          },
        ),
        if (requireRemark)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: TextFormField(
                  controller: _remarkController,
                  // Gunakan controller state
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Keterangan Tambahan (*Wajib)',
                    hintText: 'Jelaskan detail masalah (Min. 20 huruf)...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                  onChanged: (val) {
                    // Simpan ke BLoC
                    context.read<PosValidationBloc>().add(UpdateNoteRemark(val));
                  },
                  validator: (value) {
                    final text = value ?? '';
                    if (text.trim().isEmpty) return 'Wajib diisi';
                    final int charCount = text.replaceAll(' ', '').length;
                    if (charCount < 20) {
                      return 'Kurang ${20 - charCount} huruf lagi (tanpa spasi)';
                    }
                    return null;
                  },
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 12),

              RemarkPhotoPicker(
                photos: remarkPhotos,
                isLoading: _isTakingPhotoRemark,
                isReadOnly: false, // Atau sesuaikan dengan logic isCompleted
                onAddTap: () => _handleRemarkPhoto(context),
                onRemoveTap: (path) {
                  context.read<PosValidationBloc>().add(RemoveRemarkPhoto(path));
                },
              ),
            ],
          ),
      ],
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
