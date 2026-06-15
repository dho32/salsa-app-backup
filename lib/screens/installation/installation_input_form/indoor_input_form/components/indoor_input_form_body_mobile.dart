import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';

import 'package:salsa/components/widgets/scan_qr.dart';
import 'package:salsa/components/widgets/generic_measurement_input_section.dart';
import 'package:salsa/components/widgets/measurement_note_dropdown.dart';

import 'package:salsa/components/widgets/full_screen_image_viewer.dart';

import '../../../../../components/services/watermark_service.dart';
import '../../../../../components/shared_function.dart';
import '../../../../../models/common/captured_image_detail.dart';
import '../../../../../models/common/measurement_entry.dart';
import '../../../../../models/common/measurement_limits.dart';

// Slot foto berlabel (pola sama dengan POS Freezer), semuanya wajib.
// Urutan list = urutan index measurementId IN_INSTALL_PHOTO_1..3.
class _InstallPhotoSlot {
  final String id;
  final String label;
  final bool isMandatory;
  const _InstallPhotoSlot(this.id, this.label, {this.isMandatory = false});
}

const List<_InstallPhotoSlot> _kInstallPhotoSlots = [
  // Tampak dekat: cek perapihan sudah sesuai atau belum.
  _InstallPhotoSlot('close', 'Tampak Dekat Indoor', isMandatory: true),
  // Tampak jauh: cek posisi indoor ada di atas apa.
  _InstallPhotoSlot('far', 'Tampak Jauh Indoor', isMandatory: true),
  // Stiker barcode: cek stiker sudah dipasang oleh MTC/vendor.
  _InstallPhotoSlot('barcode', 'Stiker Barcode', isMandatory: true),
];

class IndoorInputFormBodyMobile extends StatefulWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel? existingData;
  final String transNo;

  const IndoorInputFormBodyMobile({
    super.key,
    required this.target,
    this.existingData,
    this.transNo = "TRX-INSTALLATION",
  });

  @override
  State<IndoorInputFormBodyMobile> createState() =>
      _IndoorInputFormBodyMobileState();
}

class _IndoorInputFormBodyMobileState extends State<IndoorInputFormBodyMobile> {
  // ID Konstanta
  final String _kTempId = 'temperature';
  final String _kInstallPhotoBaseId = 'IN_INSTALL_PHOTO';

  final _snController = TextEditingController(); // Untuk Normal & Scanner

  // --- [PERUBAHAN ALUR 3] Controller Khusus Vendor Sthira ---
  final _sthiraSnPartController = TextEditingController();
  final _sthiraTypePartController = TextEditingController();
  String _vendorCode = '';

  // --------------------------------------------------------

  final TextEditingController _remarkController = TextEditingController();
  final Map<String, TextEditingController> _measurementControllers = {};

  Timer? _debounceTimer;

  Map<String, MeasurementLimits> _limitsMap = {};
  List<MeasurementNoteOption> _noteOptions = [];
  List<MeasurementEntry> _measurementEntries = [];

  String? _selectedNoteReason;
  List<CapturedImageDetail> _notePhotos = [];
  bool _isTakingNotePhoto = false;

  final Map<String, CapturedImageDetail> _installPhotoSlots = {};
  String? _capturingSlotId;
  bool _isProcessingWatermark = false;

  bool _isSubmittingFinal = false;

  bool get _isOriginalCompleted => widget.existingData?.status == 'COMPLETED';

  @override
  void initState() {
    super.initState();
    _loadMasterDataFromBloc();
    _fetchVendorCode(); // Ambil kode vendor saat layar dibuka
    _initializeFormData();

    _snController.addListener(_onFormChanged);
    _sthiraSnPartController.addListener(_onFormChanged);
    _sthiraTypePartController.addListener(_onFormChanged);
    _remarkController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _snController.dispose();
    _sthiraSnPartController.dispose();
    _sthiraTypePartController.dispose();
    _remarkController.dispose();
    for (var c in _measurementControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- [PERUBAHAN ALUR 3] Ambil ID Vendor ---
  Future<void> _fetchVendorCode() async {
    try {
      final user = await AuthStorage.getUser();
      if (mounted) {
        setState(() {
          _vendorCode = user['maintenance_by'] ?? '';
        });
      }
    } catch (_) {}
  }

  void _onFormChanged() {
    if (_isOriginalCompleted) return;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _dispatchSave(isFinal: false);
    });
  }

  void _forceSaveDraft() {
    if (_isOriginalCompleted) return;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _dispatchSave(isFinal: false);
  }

  void _loadMasterDataFromBloc() {
    final state = context.read<InstallationBloc>().state;
    _limitsMap = Map<String, MeasurementLimits>.from(state.measurementLimits);

    if (!_limitsMap.containsKey(_kTempId)) {
      _limitsMap[_kTempId] = const MeasurementLimits(
          id: 'temperature',
          label: 'Suhu Indoor AC',
          min: 4,
          max: 25,
          normalMin: 4,
          normalMax: 25,
          unit: '°C');
    }

    if (state.taskDetail != null &&
        state.taskDetail!.noteIndoorOptions.isNotEmpty) {
      _noteOptions = state.taskDetail!.noteIndoorOptions.map((opt) {
        return MeasurementNoteOption(
            label: opt.label, requireRemark: opt.requireRemark);
      }).toList();
    } else {
      _noteOptions = [
        const MeasurementNoteOption(label: 'Unit Belum Terpasang'),
        const MeasurementNoteOption(label: 'Lainnya', requireRemark: true),
      ];
    }
  }

  void _initializeFormData() {
    if (widget.existingData != null) {
      final savedSn = widget.existingData!.serialNo;
      _snController.text = savedSn;

      // --- [PERUBAHAN ALUR 3] Pecah SN jika sudah ada format Sthira ---
      if (savedSn.contains('|in|')) {
        final parts = savedSn.split('|in|');
        if (parts.length == 2) {
          _sthiraSnPartController.text = parts[0];
          _sthiraTypePartController.text = parts[1];
        }
      } else {
        // Fallback jika SN belum reformat Sthira tapi login sbg Sthira
        _sthiraSnPartController.text = savedSn;
      }
      // ----------------------------------------------------------------

      _remarkController.text = widget.existingData!.remark;
      _notePhotos = widget.existingData!.remarkPhotos
          .map((p) => _mapPhotoModelToDetail(p))
          .toList();
    }

    double initialVal = 0;
    bool initialSkip = false;
    CapturedImageDetail? initialImage;

    if (widget.existingData != null) {
      final tempMetric = widget.existingData!.measurements.firstWhere(
          (m) => m.measurementId == _kTempId,
          orElse: () => InstallationMeasurementModel(
              measurementId: '', unit: '', value: 0));

      if (tempMetric.value == -1 || tempMetric.isSkipped) {
        initialSkip = true;
      } else {
        initialVal = tempMetric.value ?? 0;
      }

      if (!initialSkip && tempMetric.photo != null) {
        initialImage = _mapPhotoModelToDetail(tempMetric.photo!);
      }

      if (initialSkip && widget.existingData!.note != null) {
        String noteRaw = widget.existingData!.note!;
        if (_noteOptions.any((opt) => opt.label == noteRaw)) {
          _selectedNoteReason = noteRaw;
        } else {
          _parseExistingNote(noteRaw);
        }
      }

      final installMetrics = widget.existingData!.measurements
          .where((m) => m.measurementId.startsWith(_kInstallPhotoBaseId))
          .toList();

      installMetrics.sort((a, b) => a.measurementId.compareTo(b.measurementId));

      for (var m in installMetrics) {
        if (m.photo == null) continue;
        final detail = _mapPhotoModelToDetail(m.photo!);
        final idx = int.tryParse(m.measurementId.split('_').last);
        if (idx != null && idx >= 1 && idx <= _kInstallPhotoSlots.length) {
          _installPhotoSlots[_kInstallPhotoSlots[idx - 1].id] = detail;
        } else if (idx == null) {
          // Draft lama tanpa index valid -> isi slot kosong pertama.
          for (final slot in _kInstallPhotoSlots) {
            if (!_installPhotoSlots.containsKey(slot.id)) {
              _installPhotoSlots[slot.id] = detail;
              break;
            }
          }
        }
        // idx di luar jumlah slot (foto "Tambahan" dari versi lama) diabaikan.
      }
    }

    final entry = MeasurementEntry(
      measurementId: _kTempId,
      value: initialVal,
      isSkipped: initialSkip,
      capturedImage: initialImage,
      unit: '°C',
    );
    _measurementEntries = [entry];

    _measurementControllers[_kTempId] = TextEditingController(
        text:
            initialSkip ? '' : (initialVal == 0 ? '' : initialVal.toString()));

    _measurementControllers[_kTempId]?.addListener(_onFormChanged);
  }

  CapturedImageDetail _mapPhotoModelToDetail(InstallationPhotoModel p) {
    return CapturedImageDetail(
        imagePath: p.imagePath,
        timestamp: DateTime.tryParse(p.timestamp) ?? DateTime.now(),
        latitude: p.latitude,
        longitude: p.longitude,
        address: '',
        technicianName: '',
        deviceModel: p.deviceModel,
        transNo: widget.transNo);
  }

  void _parseExistingNote(String fullNote) {
    String? matchedOption;
    for (var opt in _noteOptions) {
      if (fullNote.startsWith(opt.label)) {
        matchedOption = opt.label;
        break;
      }
    }
    if (matchedOption != null) {
      _selectedNoteReason = matchedOption;
      if (_remarkController.text.isEmpty &&
          fullNote.length > matchedOption.length + 3) {
        _remarkController.text = fullNote.substring(matchedOption.length + 3);
      }
    } else {
      _selectedNoteReason = fullNote.split(' - ')[0];
    }
  }

  InstallationUnitModel? _buildUnitModel({required bool isFinal}) {
    // --- [PERUBAHAN ALUR 3] Jahit SN jika Sthira ---
    String finalSn = "";

    if (_vendorCode == 'V000062') {
      final snPart = _sthiraSnPartController.text.toUpperCase().trim();
      final typePart = _sthiraTypePartController.text.toUpperCase().trim();

      if (snPart.isNotEmpty || typePart.isNotEmpty) {
        // Jahit format: SN|in|type_ac
        finalSn = "$snPart|IN|$typePart";
      }
    } else {
      finalSn = _snController.text.toUpperCase().trim();
    }

    // ------------------------------------------------
    // Validasi tambahan jika Final dan Sthira
    if (isFinal && _vendorCode == 'V000062') {
      if (_sthiraSnPartController.text.isEmpty ||
          _sthiraTypePartController.text.isEmpty) {
        _showErrorSnack("Nomor SN dan Tipe AC wajib diisi lengkap!");
        return null;
      }
    }

    final tempEntry =
        _measurementEntries.firstWhere((e) => e.measurementId == _kTempId);
    final bool isSkipped = tempEntry.isSkipped ?? false;

    InstallationPhotoModel? measurementPhoto;

    if (!isSkipped && tempEntry.capturedImage != null) {
      measurementPhoto = _buildPhotoModel(tempEntry.capturedImage!);
    }

    List<InstallationMeasurementModel> measurements = [];

    measurements.add(InstallationMeasurementModel(
      measurementId: _kTempId,
      unit: '°C',
      value: isSkipped ? 0 : tempEntry.value,
      isSkipped: isSkipped,
      note: '',
      photo: measurementPhoto,
    ));

    for (int i = 0; i < _kInstallPhotoSlots.length; i++) {
      final slot = _kInstallPhotoSlots[i];
      final img = _installPhotoSlots[slot.id];
      if (img == null) continue;
      measurements.add(InstallationMeasurementModel(
        measurementId: "${_kInstallPhotoBaseId}_${i + 1}",
        unit: '',
        value: 0,
        isSkipped: false,
        note: 'Foto ${slot.label}',
        photo: _buildPhotoModel(img),
      ));
    }

    String noteDropdown = '';
    String remarkManual = '';
    List<InstallationPhotoModel> remarkPhotosModel = [];

    if (isSkipped) {
      noteDropdown = _selectedNoteReason ?? '';
      remarkManual = _remarkController.text;

      if (_notePhotos.isNotEmpty) {
        remarkPhotosModel =
            _notePhotos.map((p) => _buildPhotoModel(p)).toList();
      }
    }

    String currentStatus =
        isFinal ? 'COMPLETED' : (_isOriginalCompleted ? 'COMPLETED' : 'DRAFT');

    return InstallationUnitModel(
      unitIndex: widget.target.unitIndex,
      articleNo: widget.target.articleNo,
      articleDesc: widget.target.description,
      articleType: 'IN',
      serialNo: finalSn,
      // <-- Menggunakan SN yang sudah dijahit
      note: noteDropdown,
      measurements: measurements,
      materials: InstallationMaterialsModel(),
      pairedSerialNo: widget.existingData?.pairedSerialNo,
      status: currentStatus,
      remark: remarkManual,
      remarkPhotos: remarkPhotosModel,
      reffLineNo: widget.target.reffLineNo,
    );
  }

  Future<void> _handleTakeSlotPhoto(_InstallPhotoSlot slot) async {
    if (_capturingSlotId != null) return;
    setState(() => _capturingSlotId = slot.id);
    try {
      final imgDetail = await _captureWatermarkedImage(photoLabel: slot.label);
      if (imgDetail != null) {
        setState(() => _installPhotoSlots[slot.id] = imgDetail);
        if (!_isOriginalCompleted) _forceSaveDraft();
      }
    } finally {
      if (mounted) setState(() => _capturingSlotId = null);
    }
  }

  Future<void> _handleTakeNotePhoto() async {
    if (_notePhotos.isNotEmpty) {
      _showErrorSnack("Maksimal 1 foto bukti kendala.");
      return;
    }
    setState(() => _isTakingNotePhoto = true);
    try {
      final imgDetail =
          await _captureWatermarkedImage(photoLabel: 'Bukti Kendala Suhu');
      if (imgDetail != null) {
        setState(() => _notePhotos = [imgDetail]);
        if (!_isOriginalCompleted) _forceSaveDraft();
      }
    } finally {
      if (mounted) setState(() => _isTakingNotePhoto = false);
    }
  }

  Future<CapturedImageDetail?> _captureWatermarkedImage(
      {String? photoLabel}) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (image == null) return null;

      setState(() => _isProcessingWatermark = true);

      final user = await AuthStorage.getUser();
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'WM_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String targetPath = p.join(directory.path, fileName);
      final String techName = user['name'] ?? 'Teknisi';
      final String deviceModel = user['device_model'] ?? 'Unknown Device';
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
        deviceModel: deviceModel,
        location: '',
        photoLabel: photoLabel,
      );

      final String? resultPath = await WatermarkService.processImage(req);

      if (resultPath == null) {
        _showErrorSnack("Gagal memproses watermark foto.");
        return null;
      }

      return CapturedImageDetail(
          imagePath: resultPath,
          timestamp: timestamp,
          technicianName: techName,
          deviceModel: req.deviceModel,
          transNo: widget.transNo,
          latitude: 0,
          longitude: 0,
          address: '');
    } catch (e) {
      debugPrint("Error photo: $e");
      _showErrorSnack("Gagal mengambil foto.");
      return null;
    } finally {
      if (mounted) setState(() => _isProcessingWatermark = false);
    }
  }

  void _openImageViewer(CapturedImageDetail img) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imageDetail: img)));
  }

  InstallationPhotoModel _buildPhotoModel(CapturedImageDetail img) {
    return InstallationPhotoModel(
        imagePath: img.imagePath,
        imageFileName: img.imagePath.split('/').last,
        timestamp: img.timestamp.toIso8601String(),
        latitude: img.latitude,
        longitude: img.longitude,
        deviceModel: img.deviceModel);
  }

  void _dispatchSave({required bool isFinal}) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (isFinal) {
      final newUnit = _buildUnitModel(isFinal: isFinal);
      if (newUnit == null) return; // Validasi Sthira gagal

      final snToValidate = newUnit.serialNo;

      if (snToValidate.isEmpty) {
        _showErrorSnack("Serial Number wajib diisi!");
        return;
      }

      final currentState = context.read<InstallationBloc>().state;
      final draft = currentState.draftEntry;
      if (draft != null && draft.units.isNotEmpty) {
        final isDuplicate = draft.units.any((u) =>
            u.serialNo == snToValidate &&
            u.unitIndex != widget.target.unitIndex);
        if (isDuplicate) {
          _showErrorSnack("Serial Number sudah digunakan di unit lain!");
          return;
        }
      }

      final tempEntry =
          _measurementEntries.firstWhere((e) => e.measurementId == _kTempId);
      final bool isSkipped = tempEntry.isSkipped ?? false;

      if (!isSkipped) {
        if (tempEntry.value <= 0) {
          _showErrorSnack("Suhu Indoor AC wajib diisi!");
          return;
        }
        if (tempEntry.capturedImage == null) {
          _showErrorSnack("Foto Pengukuran Suhu wajib diambil!");
          return;
        }
      }

      if (isSkipped) {
        if (_selectedNoteReason == null) {
          _showErrorSnack("Alasan Skip wajib dipilih!");
          return;
        }
        final option = _noteOptions.firstWhere(
            (o) => o.label == _selectedNoteReason,
            orElse: () => const MeasurementNoteOption(label: ''));
        if (option.requireRemark) {
          if (_remarkController.text.trim().length < 20) {
            _showErrorSnack("Keterangan minimal 20 huruf!");
            return;
          }
          if (_notePhotos.isEmpty) {
            _showErrorSnack("Foto Bukti Kendala wajib ada!");
            return;
          }
        }
      }

      for (final slot in _kInstallPhotoSlots) {
        if (slot.isMandatory && _installPhotoSlots[slot.id] == null) {
          _showErrorSnack("Foto ${slot.label} wajib diambil!");
          return;
        }
      }
    }

    final savedUnit = _buildUnitModel(isFinal: isFinal);

    if (savedUnit != null) {
      context.read<InstallationBloc>().add(SaveIndoorUnit(savedUnit));

      if (isFinal) {
        _isSubmittingFinal = true;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Data Indoor Tersimpan"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        debugPrint("Auto-saved draft for unit ${widget.target.unitIndex}");
      }
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message))
        ]),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final bool isAnyMeasurementSkipped =
        _measurementEntries.any((m) => m.isSkipped == true);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSubmittingFinal) {
          if (context.mounted) Navigator.of(context).pop(result);
          return;
        }
        if (_isOriginalCompleted) {
          if (context.mounted) Navigator.of(context).pop(result);
          return;
        }
        _forceSaveDraft();
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) Navigator.of(context).pop(result);
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSection(
                      title: "Informasi Unit",
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.target.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Article No: ${widget.target.articleNo}",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 13)),
                          ]),
                    ),
                  ),

                  // --- [PERUBAHAN ALUR 3] BUILDER FORM SN ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildSection(
                      title: "Identitas Unit",
                      child: _vendorCode == 'V000062'
                          ? _buildSthiraSnForm()
                          : _buildNormalSnForm(),
                    ),
                  ),
                  // ------------------------------------------

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInstallationPhotoSection(),
                  ),
                  const SizedBox(height: 24),
                  GenericMeasurementInputSection(
                    transNo: widget.transNo,
                    measurements: _measurementEntries,
                    controllers: _measurementControllers,
                    limitsMap: _limitsMap,
                    indoorTemp: null,
                    onUpdate: (updatedEntry) {
                      setState(() {
                        final index = _measurementEntries.indexWhere((e) =>
                            e.measurementId == updatedEntry.measurementId);
                        if (index != -1) {
                          _measurementEntries[index] = updatedEntry;
                        }
                        if (updatedEntry.isSkipped == false) {
                          _selectedNoteReason = null;
                          _remarkController.clear();
                          _notePhotos = [];
                        }
                      });
                      _onFormChanged();
                    },
                  ),
                  if (isAnyMeasurementSkipped)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildSection(
                        title: "Catatan Kendala Suhu",
                        child: MeasurementNoteDropdown(
                          label: "Alasan Skip",
                          value: _selectedNoteReason,
                          options: _noteOptions,
                          remarkController: _remarkController,
                          onChanged: (val) {
                            setState(() {
                              _selectedNoteReason = val;
                              _remarkController.clear();
                            });
                            _onFormChanged();
                          },
                          photos: _notePhotos,
                          isTakingPhoto: _isTakingNotePhoto,
                          onAddPhoto: _handleTakeNotePhoto,
                          onRemovePhoto: (path) {
                            setState(() => _notePhotos
                                .removeWhere((p) => p.imagePath == path));
                            _onFormChanged();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4))
            ]),
            child: ElevatedButton(
              onPressed: _isProcessingWatermark
                  ? null
                  : () => _dispatchSave(isFinal: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_isProcessingWatermark)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.save_as_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                    _isProcessingWatermark
                        ? "MEMPROSES FOTO..."
                        : "SIMPAN DATA INDOOR",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white))
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- [PERUBAHAN ALUR 3] BUILDER SN NORMAL ---
  Widget _buildNormalSnForm() {
    return _buildCustomTextField(
      controller: _snController,
      label: "Serial Number (Wajib)",
      icon: FontAwesomeIcons.barcode,
      suffixIcon: IconButton(
        icon: const Icon(FontAwesomeIcons.qrcode, color: Color(0xFF1565C0)),
        onPressed: () async {
          final res = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const QrScanPage()));
          if (res != null) setState(() => _snController.text = res);
        },
      ),
    );
  }

  // --- [PERUBAHAN ALUR 3] BUILDER SN KHUSUS STHIRA ---
  Widget _buildSthiraSnForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tombol Scan Global untuk Sthira
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final res = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()));
              if (res != null) {
                // Kalau hasil scan dari alat, langsung pecah masukin ke kotak
                if (res.contains('|in|') || res.contains('|IN|')) {
                  final parts =
                      res.split(RegExp(r'\|in\|', caseSensitive: false));
                  if (parts.length == 2) {
                    setState(() {
                      _sthiraSnPartController.text = parts[0];
                      _sthiraTypePartController.text = parts[1];
                    });
                    _onFormChanged();
                  }
                } else {
                  _showErrorSnack(
                      "Barcode tidak valid for vendor ini. Harus format SN|IN|TIPE.");
                }
              }
            },
            icon: const Icon(FontAwesomeIcons.qrcode,
                color: Color(0xFF1565C0), size: 18),
            label: const Text("Scan Barcode"),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ),
        const SizedBox(height: 16),

        // Input Pecahan
        Row(
          children: [
            Expanded(
              flex: 5,
              child: _buildCustomTextField(
                  controller: _sthiraSnPartController,
                  label: "Nomor SN",
                  icon: FontAwesomeIcons.hashtag,
                  hintText: "Cth: 00034"),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
              child: Text("| IN |",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey)),
            ),
            Expanded(
              flex: 4,
              child: _buildCustomTextField(
                  controller: _sthiraTypePartController,
                  label: "Tipe AC",
                  icon: FontAwesomeIcons.tag,
                  hintText: "Cth: SC234"),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildInstallationPhotoSection() {
    final filledCount = _installPhotoSlots.length;

    return _buildSection(
      title: "Dokumentasi Pemasangan",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Foto Unit Terpasang (Wajib)",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Text("$filledCount/${_kInstallPhotoSlots.length} Foto",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          _buildPhotoSlotRow(_kInstallPhotoSlots),
          if (_isProcessingWatermark && _capturingSlotId != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Sedang memberi watermark...",
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic)),
            )
        ],
      ),
    );
  }

  // Baris slot foto. [columns] menyamakan lebar tile antar baris (baris
  // opsional yang isinya 2 slot tetap memakai grid 3 kolom).
  Widget _buildPhotoSlotRow(List<_InstallPhotoSlot> slots, {int? columns}) {
    final colCount = columns ?? slots.length;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < colCount; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
              child: i < slots.length
                  ? _buildPhotoSlotTile(slots[i])
                  : const SizedBox.shrink()),
        ],
      ],
    );
  }

  // Tile slot foto — pola sama dengan slot foto POS Freezer: kosong -> tap
  // untuk ambil foto, terisi -> tap untuk preview full-screen, X untuk hapus.
  Widget _buildPhotoSlotTile(_InstallPhotoSlot slot) {
    final photo = _installPhotoSlots[slot.id];
    final filled = photo != null;
    final capturing = _capturingSlotId == slot.id;
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: _capturingSlotId != null
          ? null
          : (filled ? () => _openImageViewer(photo) : () => _handleTakeSlotPhoto(slot)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled ? primary : Colors.grey.shade300,
              width: filled ? 1.5 : 1,
            ),
            image: filled
                ? DecorationImage(
                    image: FileImage(File(photo.imagePath)), fit: BoxFit.cover)
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!filled)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: Colors.grey.shade600, size: 26),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(slot.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700)),
                    ),
                  ],
                ),
              if (filled) ...[
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: Colors.black54,
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                    child: Text(slot.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white)),
                  ),
                ),
                const Positioned(
                  top: 3,
                  left: 3,
                  child:
                      Icon(Icons.check_circle, color: Colors.white, size: 18),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _installPhotoSlots.remove(slot.id));
                      if (!_isOriginalCompleted) _forceSaveDraft();
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
              if (capturing && !filled)
                const Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child
        ]));
  }

  // --- [PERUBAHAN ALUR 3] Menerima Parameter hintText tambahan ---
  Widget _buildCustomTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      Widget? suffixIcon,
      String? hintText}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
            hintText: hintText ?? "Masukkan $label",
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 18),
            suffixIcon: suffixIcon,
            isDense: true,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
        inputFormatters: [
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                newValue.copyWith(text: newValue.text.toUpperCase()),
          ),
        ],
      )
    ]);
  }
}
