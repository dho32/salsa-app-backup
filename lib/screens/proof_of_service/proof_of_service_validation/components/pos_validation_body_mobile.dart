import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk InputFormatter
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
import '../../../../components/shared_function.dart';
import '../../../../components/widgets/generic_measurement_input_section.dart';
import '../../../../components/widgets/photo_grid.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../components/widgets/scan_qr.dart'; // Pastikan import ini ada
import '../../../../models/common/measurement_entry.dart';
import '../../../../models/proof_of_service/proof_of_service_detail_model.dart'; // 🔥 IMPORT BARU

class PosValidationBodyMobile extends StatefulWidget {
  final String transNo;
  final String serialNo;
  final String unitType;
  final String articleDesc;
  final String articleUnitDesc;
  final TextEditingController noteController;
  final double? indoorTemp;
  final List<NoteOption> noteOptions;

  /// Dipanggil saat status konfirmasi "sesuai foto" sebuah pengukuran berubah.
  final void Function(String measurementId, bool confirmed)?
      onMeasurementConfirmedChanged;

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
    this.onMeasurementConfirmedChanged,
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

  // 🔥 Controller Baru untuk Input Serial Number (Generic)
  late final TextEditingController _serialInputController;

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

    _serialInputController = TextEditingController();

    // 🔥 --- Load Limit Gabungan (Global + API) --- 🔥
    final configBox = Hive.box(kAppConfigBox);
    final rawLimits = configBox.get('limits_pos_after');
    final Map<String, MeasurementLimits> mergedLimits = {};

    // 1. Ambil Limit Global (Bawaan Login)
    if (rawLimits is Map) {
      rawLimits.forEach((key, value) {
        if (key is String && value is MeasurementLimits) {
          mergedLimits[key] = value;
        }
      });
    }

    // 2. Timpa dengan Custom Limit dari API Customer
    try {
      if (Hive.isBoxOpen(kPosDetailCacheBox)) {
        final detailBox =
            Hive.box<ProofOfServiceDetailModel>(kPosDetailCacheBox);
        final detailData = detailBox.get(widget.transNo.trim().toUpperCase());

        // Jika di API ada limit khusus, timpa limit global
        if (detailData != null && detailData.customLimitsAfter != null) {
          detailData.customLimitsAfter!.forEach((key, value) {
            mergedLimits[key] = value;
          });
        }
      }
    } catch (e) {
      print("Gagal mengambil limit API di UI POS: $e");
    }

    // 3. Pasang ke UI
    _limitsPosAfter =
        mergedLimits.isNotEmpty ? mergedLimits : kPOSMeasurementLimits;
    // 🔥 ----------------------------------------- 🔥

    final state = context.read<PosValidationBloc>().state;
    String initialRemark = '';
    if (state is PosValidationLoaded) {
      initialRemark = state.noteRemark ?? '';

      if (state.isGeneric && state.serialNo.isNotEmpty) {
        final snUpperCase = state.serialNo.trim().toUpperCase();
        if (!RegExp(r'^AC\s*-\s*\d+$').hasMatch(snUpperCase)) {
          _serialInputController.text = state.serialNo;
        }
      }
    }
    _remarkController = TextEditingController(text: initialRemark);
  }

  @override
  void dispose() {
    _disposeControllers();
    _noteSearchController.dispose();
    _remarkController.dispose();
    _serialInputController.dispose(); // 🔥
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

  // Label watermark foto unit sesuai tipe unit yang sedang divalidasi.
  String get _unitPhotoLabel {
    switch (widget.unitType.toUpperCase()) {
      case 'IN':
        return 'Unit Indoor';
      case 'OUT':
        return 'Unit Outdoor';
      default:
        return 'Unit';
    }
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
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) {
          await imagesDir.create();
        }

        final targetPath = p.join(
            imagesDir.path, 'WM_POS_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: technicianName,
          deviceModel: deviceModel,
          photoLabel: '$_unitPhotoLabel - ${isBefore ? "Before" : "After"}',
        );

        final String? finalImagePath =
            await WatermarkService.processImage(request);

        if (finalImagePath == null) return;

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
      // Error handling
    } finally {
      if (mounted) setState(() => _isTakingPhoto = false);
    }
  }

  Future<void> _handleRemarkPhoto(BuildContext context) async {
    final currentState = context.read<PosValidationBloc>().state;
    if (currentState is PosValidationLoaded) {
      final currentPhotos = currentState.remarkPhotos ?? [];
      if (currentPhotos.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Maksimal hanya bisa upload 5 foto remark.')));
        return;
      }
    }
    setState(() => _isTakingPhotoRemark = true);
    try {
      PaintingBinding.instance.imageCache.clear();
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 80);
      if (image != null) {
        final userData = await AuthStorage.getUser();
        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) await imagesDir.create();
        final targetPath = p.join(imagesDir.path,
            'WM_REMARK_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: userData['name'] ?? 'Unknown',
          deviceModel: userData['device_model'] ?? 'Unknown Device',
          photoLabel: 'Bukti Remark',
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
          technicianName: userData['name'] ?? 'Unknown',
          deviceModel: userData['device_model'] ?? 'Unknown',
          transNo: widget.transNo,
        );
        if (mounted)
          context
              .read<PosValidationBloc>()
              .add(AddRemarkPhoto(capturedImageDetail));
      }
    } catch (e) {
      // Error
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

            // 🔥 LOGIC BARU JUGA DI SINI
            if (state.isGeneric && state.serialNo.isNotEmpty) {
              final snUpperCase = state.serialNo.trim().toUpperCase();

              // Cegah "AC - 1" dkk masuk ke TextField, tapi biarkan hasil scan masuk
              if (!RegExp(r'^AC\s*-\s*\d+$').hasMatch(snUpperCase) &&
                  _serialInputController.text != state.serialNo) {
                if (_serialInputController.text.isEmpty) {
                  _serialInputController.text = state.serialNo;
                }
              }
            }
          });
        }
      },
      child: BlocBuilder<PosValidationBloc, PosValidationState>(
        buildWhen: (previous, current) => current is! PosValidationSaveSuccess,
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
            _buildValidationHeader(state), // Pass state

            // 🔥 LOGIC BARU: INPUT SN UNTUK GENERIC UNIT 🔥
            if (state.isGeneric) _buildGenericSerialInput(context, state),

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
            _buildValidationHeader(state),
            if (state.unitType.toUpperCase() == 'OUT' &&
                state.pairedIndoorSerial != null)
              _buildPairedInfo(state),
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
              enableConfirmDialog: true,
              onMeasurementConfirmedChanged:
                  widget.onMeasurementConfirmedChanged,
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
                    // 🔥 Reset juga excludeQty jika tidak ada yang diskip
                    context
                        .read<PosValidationBloc>()
                        .add(UpdateExcludeQtyFlag(false));
                  }
                }
              },
              limitsMap: _limitsPosAfter,
            ),
            if (isAnyMeasurementSkipped)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  // 🔥 TANGKAP FLAG EXCLUDE QTY DI SINI
                  onExcludeQtyChanged: (bool excludeValue) {
                    // Kirim ke BLoC untuk disimpan ke model Hive yang baru
                    context
                        .read<PosValidationBloc>()
                        .add(UpdateExcludeQtyFlag(excludeValue));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 🔥 WIDGET BARU: INPUT SERIAL NUMBER 🔥
  Widget _buildGenericSerialInput(
      BuildContext context, PosValidationLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Input Serial Number Unit (*Wajib)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _serialInputController,
                  decoration: InputDecoration(
                    hintText: 'Ketik atau Scan SN...',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-]')),
                  ],
                  onChanged: (value) {
                    context
                        .read<PosValidationBloc>()
                        .add(UpdateInputSerial(value));
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(14),
                      backgroundColor: Colors.blue.shade700),
                  onPressed: () async {
                    final scannedCode = await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => QrScanPage()));

                    if (scannedCode != null) {
                      _serialInputController.text = scannedCode;
                      if (context.mounted) {
                        context
                            .read<PosValidationBloc>()
                            .add(UpdateInputSerial(scannedCode));
                      }
                    }
                  },
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white))
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 WIDGET BARU: INFO PAIRING OTOMATIS (GHOST PAIRING) 🔥
  Widget _buildAutoPairingInfo(PosValidationLoaded state) {
    if (state.pairedIndoorSerial == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.link, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Terhubung Otomatis dengan Indoor: \n',
                  style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                  children: [
                    TextSpan(
                      text: state.pairedIndoorSerial!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET DROPDOWN (Existing) ---
  Widget _buildNoteDropdown({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required List<NoteOption> noteOptions,
    required ValueChanged<String?> onChanged,
    required List<CapturedImageDetail> remarkPhotos,
    ValueChanged<bool>? onExcludeQtyChanged,
  }) {
    final double maxDropdownHeight = MediaQuery.of(context).size.height * 0.4;
    final filteredOptions = noteOptions
        .where((opt) => !opt.isSystemOnly || opt.label == controller.text)
        .toList();
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
            filled: true,
            fillColor:
                isReadOnlySystemValue ? Colors.grey.shade200 : Colors.white,
          ),
          hint: const Text('Pilih Catatan'),
          onChanged: isReadOnlySystemValue
              ? null
              : (value) {
                  onChanged(value);

                  if (value != null && onExcludeQtyChanged != null) {
                    final selectedOpt = noteOptions.firstWhere(
                      (opt) => opt.label == value,
                      orElse: () => NoteOption(label: '', excludeQty: false),
                    );
                    onExcludeQtyChanged(selectedOpt.excludeQty);
                  }

                  FocusScope.of(context).unfocus();
                },
          items: filteredOptions
              .map((item) => DropdownMenuItem(
                  value: item.label,
                  child: Text(item.label, overflow: TextOverflow.ellipsis)))
              .toList(),
          dropdownStyleData: DropdownStyleData(
              maxHeight: maxDropdownHeight,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(15))),
          dropdownSearchData: DropdownSearchData(
            searchController: _noteSearchController,
            searchInnerWidgetHeight: 50,
            searchInnerWidget: Padding(
                padding: const EdgeInsets.all(8),
                child: TextFormField(
                    controller: _noteSearchController,
                    decoration: const InputDecoration(
                        hintText: 'Cari...', border: OutlineInputBorder()))),
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
                  decoration: const InputDecoration(
                      labelText: 'Keterangan Tambahan (*Wajib)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note)),
                  onChanged: (val) => context
                      .read<PosValidationBloc>()
                      .add(UpdateNoteRemark(val)),
                ),
              ),
              const SizedBox(height: 12),
              RemarkPhotoPicker(
                photos: remarkPhotos,
                isLoading: _isTakingPhotoRemark,
                isReadOnly: false,
                onAddTap: () => _handleRemarkPhoto(context),
                onRemoveTap: (path) => context
                    .read<PosValidationBloc>()
                    .add(RemoveRemarkPhoto(path)),
              ),
            ],
          ),
      ],
    );
  }

  // --- WIDGET PHOTO SECTION (Existing) ---
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
                    child: CircularProgressIndicator()))
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: Text(title),
                  onPressed: onAddPhoto,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      side: BorderSide(color: primary),
                      foregroundColor: primary),
                ),
              ),
      ],
    );
  }

  Widget _buildValidationHeader(PosValidationLoaded state) {
    final displaySerial = state.isGeneric && state.serialNo.isEmpty
        ? "Unit #${state.unitIndex}"
        : state.serialNo;

    final displayColor =
        state.isGeneric ? Colors.blue.shade700 : Colors.black54;

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
                  Icon(state.isGeneric ? Icons.edit : Icons.qr_code,
                      size: 16, color: displayColor),
                  const SizedBox(width: 8),
                  Text(
                    displaySerial, // 🔥 Dynamic Serial
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 12,
                        color: displayColor,
                        fontWeight: FontWeight.bold),
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

  Widget _buildPairedInfo(PosValidationLoaded state) {
    if (state.pairedIndoorSerial == null) return const SizedBox.shrink();

    return Padding(
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
