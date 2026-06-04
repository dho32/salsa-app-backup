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

class OutdoorInputFormBodyMobile extends StatefulWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel? existingData;
  final String transNo;

  const OutdoorInputFormBodyMobile({
    super.key,
    required this.target,
    this.existingData,
    this.transNo = "TRX-INSTALLATION",
  });

  @override
  State<OutdoorInputFormBodyMobile> createState() =>
      _OutdoorInputFormBodyMobileState();
}

class _OutdoorInputFormBodyMobileState
    extends State<OutdoorInputFormBodyMobile> {
  // --- KONSTANTA ---
  final String _kInstallPhotoBaseId = 'OUT_INSTALL_PHOTO';

  final _snController = TextEditingController(); // Normal/Scanner

  // --- [PERUBAHAN ALUR 3] Controller Sthira ---
  final _sthiraSnPartController = TextEditingController();
  final _sthiraTypePartController = TextEditingController();
  String _vendorCode = '';

  // --------------------------------------------

  // -- Controllers ELEKTRIKAL (FISIK) --
  final TextEditingController _elecRemarkController = TextEditingController();
  final Map<String, TextEditingController> _elecControllers = {};
  List<MeasurementEntry> _elecEntries = [];
  String? _selectedElecNote;
  List<CapturedImageDetail> _elecNotePhotos = [];
  bool _isTakingElecPhoto = false;

  // -- Controllers PSI (TEKANAN) --
  final TextEditingController _psiRemarkController = TextEditingController();
  final Map<String, TextEditingController> _psiControllers = {};
  List<MeasurementEntry> _psiEntries = [];
  String? _selectedPsiNote;
  List<CapturedImageDetail> _psiNotePhotos = [];
  bool _isTakingPsiPhoto = false;

  // -- Foto Dokumentasi --
  final List<CapturedImageDetail> _installPhotos = [];
  bool _isTakingInstallPhoto = false;

  // -- Data Master --
  Map<String, MeasurementLimits> _limitsMap = {};
  List<MeasurementNoteOption> _elecNoteOptions = [];
  List<MeasurementNoteOption> _psiNoteOptions = [];

  // -- Logic --
  Timer? _debounceTimer;
  bool _isProcessingWatermark = false;
  bool _isSubmittingFinal = false;

  bool get _isOriginalCompleted => widget.existingData?.status == 'COMPLETED';

  @override
  void initState() {
    super.initState();
    _loadMasterDataFromBloc();
    _fetchVendorCode(); // [ALUR 3] Load Vendor
    _initializeFormData();

    _snController.addListener(_onFormChanged);
    _sthiraSnPartController.addListener(_onFormChanged);
    _sthiraTypePartController.addListener(_onFormChanged);
    _elecRemarkController.addListener(_onFormChanged);
    _psiRemarkController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _snController.dispose();
    _sthiraSnPartController.dispose();
    _sthiraTypePartController.dispose();
    _elecRemarkController.dispose();
    _psiRemarkController.dispose();
    for (var c in _elecControllers.values) {
      c.dispose();
    }
    for (var c in _psiControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- [PERUBAHAN ALUR 3] Fetch Vendor ---
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

    if (!_limitsMap.containsKey('ampere')) {
      _limitsMap['ampere'] = const MeasurementLimits(
          id: 'ampere',
          label: 'Arus',
          min: 0,
          max: 20,
          unit: 'A',
          normalMin: 0,
          normalMax: 20);
    }
    if (!_limitsMap.containsKey('volt')) {
      _limitsMap['volt'] = const MeasurementLimits(
          id: 'volt',
          label: 'Tegangan',
          min: 0,
          max: 300,
          unit: 'V',
          normalMin: 0,
          normalMax: 300);
    }
    if (!_limitsMap.containsKey('psi')) {
      _limitsMap['psi'] = const MeasurementLimits(
          id: 'psi',
          label: 'Tekanan',
          min: 0,
          max: 200,
          unit: 'PSI',
          normalMin: 0,
          normalMax: 200);
    }

    if (state.taskDetail != null &&
        state.taskDetail!.noteOutdoorOptions.isNotEmpty) {
      _elecNoteOptions = state.taskDetail!.noteOutdoorOptions
          .map((opt) => MeasurementNoteOption(
              label: opt.label, requireRemark: opt.requireRemark))
          .toList();
    } else {
      _elecNoteOptions = [
        const MeasurementNoteOption(label: 'Lainnya', requireRemark: true)
      ];
    }

    if (state.taskDetail != null &&
        state.taskDetail!.noteOutdoorPSIOptions.isNotEmpty) {
      _psiNoteOptions = state.taskDetail!.noteOutdoorPSIOptions
          .map((opt) => MeasurementNoteOption(
              label: opt.label, requireRemark: opt.requireRemark))
          .toList();
    } else {
      _psiNoteOptions = _elecNoteOptions;
    }
  }

  void _initializeFormData() {
    if (widget.existingData != null) {
      final savedSn = widget.existingData!.serialNo;
      _snController.text = savedSn;

      // --- [PERUBAHAN ALUR 3] Pecah SN jika ada ---
      if (savedSn.contains('|ou|') || savedSn.contains('|OU|')) {
        final parts = savedSn.split(RegExp(r'\|ou\|', caseSensitive: false));
        if (parts.length == 2) {
          _sthiraSnPartController.text = parts[0];
          _sthiraTypePartController.text = parts[1];
        }
      } else {
        _sthiraSnPartController.text = savedSn;
      }
      // -------------------------------------------

      _elecRemarkController.text = widget.existingData!.remark;
      _elecNotePhotos = widget.existingData!.remarkPhotos
          .map((p) => _mapPhotoModelToDetail(p))
          .toList();

      _psiRemarkController.text = widget.existingData!.remarkPsi;
      _psiNotePhotos = widget.existingData!.remarkPhotosPsi
          .map((p) => _mapPhotoModelToDetail(p))
          .toList();
    }

    MeasurementEntry loadEntry(String id) {
      double val = 0;
      CapturedImageDetail? img;
      bool skipped = false;

      if (widget.existingData != null) {
        final m = widget.existingData!.measurements.firstWhere(
            (e) => e.measurementId == id,
            orElse: () => InstallationMeasurementModel(
                measurementId: id, unit: '', value: 0));

        if (m.value == -1 || m.isSkipped) {
          skipped = true;
        } else {
          val = m.value ?? 0;
        }

        if (!skipped && m.photo != null) {
          img = _mapPhotoModelToDetail(m.photo!);
        }
      }
      return MeasurementEntry(
          measurementId: id,
          value: val,
          unit: _limitsMap[id]?.unit ?? '',
          isSkipped: skipped,
          capturedImage: img);
    }

    _elecEntries = [loadEntry('volt'), loadEntry('ampere')];
    for (var e in _elecEntries) {
      _elecControllers[e.measurementId] = TextEditingController(
          text: e.isSkipped! ? '' : (e.value == 0 ? '' : e.value.toString()));
      _elecControllers[e.measurementId]?.addListener(_onFormChanged);
    }

    _psiEntries = [loadEntry('psi')];
    for (var e in _psiEntries) {
      _psiControllers[e.measurementId] = TextEditingController(
          text: e.isSkipped! ? '' : (e.value == 0 ? '' : e.value.toString()));
      _psiControllers[e.measurementId]?.addListener(_onFormChanged);
    }

    if (widget.existingData != null) {
      if (_elecEntries.first.isSkipped == true) {
        String rawNote = widget.existingData!.note ?? '';
        if (_elecNoteOptions.any((o) => o.label == rawNote)) {
          _selectedElecNote = rawNote;
        } else if (rawNote.isNotEmpty) {
          _loadExistingNote(rawNote, _elecNoteOptions, (reason, remark) {
            _selectedElecNote = reason;
            if (_elecRemarkController.text.isEmpty) {
              _elecRemarkController.text = remark;
            }
          });
        }
      }

      if (_psiEntries.first.isSkipped == true) {
        String rawNotePsi = widget.existingData!.notePsi;
        if (_psiNoteOptions.any((o) => o.label == rawNotePsi)) {
          _selectedPsiNote = rawNotePsi;
        } else if (widget.existingData!.note != null &&
            widget.existingData!.note!.contains("PSI")) {
          _loadExistingNote(widget.existingData!.note!, _psiNoteOptions,
              (reason, remark) {
            _selectedPsiNote = reason;
          });
        }
      }

      final installMetrics = widget.existingData!.measurements
          .where((m) => m.measurementId.startsWith(_kInstallPhotoBaseId))
          .toList();
      installMetrics.sort((a, b) => a.measurementId.compareTo(b.measurementId));

      for (var m in installMetrics) {
        if (m.photo != null) {
          _installPhotos.add(_mapPhotoModelToDetail(m.photo!));
        }
      }
    }
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

  void _loadExistingNote(String fullNote, List<MeasurementNoteOption> options,
      Function(String, String) onParsed) {
    if (fullNote.isEmpty) return;
    if (fullNote.contains("[Listrik:")) return;

    String? matchedOption;
    for (var opt in options) {
      if (fullNote.startsWith(opt.label)) {
        matchedOption = opt.label;
        break;
      }
    }
    String reason = matchedOption ?? fullNote.split(' - ')[0];
    String remark = '';
    if (matchedOption != null && fullNote.length > matchedOption.length + 3) {
      remark = fullNote.substring(matchedOption.length + 3);
    }
    onParsed(reason, remark);
  }

  Future<void> _takePhoto(
      {bool isInstallPhoto = false,
      bool isElec = false,
      bool isPsi = false}) async {
    if (isInstallPhoto) {
      if (_installPhotos.length >= 5) {
        _showErrorSnack("Maksimal 5 foto dokumentasi.");
        return;
      }
    } else {
      final targetList = isElec ? _elecNotePhotos : _psiNotePhotos;
      if (targetList.isNotEmpty) {
        _showErrorSnack("Maksimal 1 foto bukti.");
        return;
      }
    }

    setState(() {
      if (isInstallPhoto) {
        _isTakingInstallPhoto = true;
      } else if (isElec) {
        _isTakingElecPhoto = true;
      } else {
        _isTakingPsiPhoto = true;
      }
    });

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85);

      if (image != null) {
        setState(() => _isProcessingWatermark = true);
        final user = await AuthStorage.getUser();
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'WM_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
        setState(() => _isProcessingWatermark = false);

        if (resultPath != null) {
          final imgDetail = CapturedImageDetail(
              imagePath: resultPath,
              timestamp: timestamp,
              technicianName: req.technicianName,
              deviceModel: req.deviceModel,
              transNo: widget.transNo,
              latitude: 0,
              longitude: 0,
              address: '');

          setState(() {
            if (isInstallPhoto) {
              _installPhotos.add(imgDetail);
            } else if (isElec) {
              _elecNotePhotos = [imgDetail];
            } else {
              _psiNotePhotos = [imgDetail];
            }
          });

          if (!_isOriginalCompleted) _forceSaveDraft();
        } else {
          _showErrorSnack("Gagal watermark foto.");
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() {
        _isProcessingWatermark = false;
        if (isInstallPhoto) {
          _isTakingInstallPhoto = false;
        } else if (isElec) {
          _isTakingElecPhoto = false;
        } else {
          _isTakingPsiPhoto = false;
        }
      });
    }
  }

  void _updateElec(MeasurementEntry updated) {
    setState(() {
      final idx = _elecEntries
          .indexWhere((e) => e.measurementId == updated.measurementId);
      if (idx != -1) _elecEntries[idx] = updated;

      if (updated.isSkipped == true) {
        for (var i = 0; i < _elecEntries.length; i++) {
          _elecEntries[i] = _elecEntries[i].copyWith(isSkipped: true);
          _elecControllers[_elecEntries[i].measurementId]?.clear();
        }
      } else {
        bool allSkipped = _elecEntries.every((e) => e.isSkipped == true);
        if (!allSkipped) {
          for (var i = 0; i < _elecEntries.length; i++) {
            _elecEntries[i] = _elecEntries[i].copyWith(isSkipped: false);
          }
          _selectedElecNote = null;
          _elecRemarkController.clear();
          _elecNotePhotos = [];
        }
      }
    });
    _onFormChanged();
  }

  void _updatePsi(MeasurementEntry updated) {
    setState(() {
      _psiEntries[0] = updated;
      if (updated.isSkipped == false) {
        _selectedPsiNote = null;
        _psiRemarkController.clear();
        _psiNotePhotos = [];
      }
    });
    _onFormChanged();
  }

  InstallationUnitModel? _buildUnitModel({required bool isFinal}) {
    // --- [PERUBAHAN ALUR 3] Jahit SN Outdoor Sthira ---
    String finalSn = "";

    if (_vendorCode == 'V000062') {
      final snPart = _sthiraSnPartController.text.toUpperCase().trim();
      final typePart = _sthiraTypePartController.text.toUpperCase().trim();

      if (snPart.isNotEmpty || typePart.isNotEmpty) {
        finalSn = "$snPart|OU|$typePart"; // <-- Pakai |OU|
      }
    } else {
      finalSn = _snController.text.toUpperCase().trim();
    }
    // --------------------------------------------------

    final state = context.read<InstallationBloc>().state;
    final indoorUnit = state.draftEntry?.units.firstWhere(
        (u) => u.unitIndex == widget.target.unitIndex && u.articleType == 'IN',
        orElse: () => InstallationUnitModel(
            serialNo: '',
            unitIndex: -1,
            articleNo: '',
            articleDesc: '',
            articleType: '',
            measurements: [],
            materials: InstallationMaterialsModel()));
    final autoPairedSN = indoorUnit?.serialNo ?? '';

    if (isFinal && finalSn.isEmpty) return null;

    // Validasi Sthira
    if (isFinal && _vendorCode == 'V000062') {
      if (_sthiraSnPartController.text.isEmpty ||
          _sthiraTypePartController.text.isEmpty) {
        _showErrorSnack("Nomor SN dan Tipe AC wajib diisi lengkap!");
        return null;
      }
    }

    bool isElecSkipped = _elecEntries.first.isSkipped ?? false;
    bool isPsiSkipped = _psiEntries.first.isSkipped ?? false;

    String noteOutdoor = '';
    String remarkOutdoor = '';
    List<InstallationPhotoModel> remarkPhotosOutdoor = [];

    if (isElecSkipped) {
      noteOutdoor = _selectedElecNote ?? '';
      remarkOutdoor = _elecRemarkController.text;
      if (_elecNotePhotos.isNotEmpty) {
        remarkPhotosOutdoor =
            _elecNotePhotos.map((p) => _buildPhotoModel(p)).toList();
      }
    }

    String notePsi = '';
    String remarkPsi = '';
    List<InstallationPhotoModel> remarkPhotosPsi = [];

    if (isPsiSkipped) {
      notePsi = _selectedPsiNote ?? '';
      remarkPsi = _psiRemarkController.text;
      if (_psiNotePhotos.isNotEmpty) {
        remarkPhotosPsi =
            _psiNotePhotos.map((p) => _buildPhotoModel(p)).toList();
      }
    }

    List<InstallationMeasurementModel> finalMeasurements = [];

    for (var e in _elecEntries) {
      InstallationPhotoModel? mPhoto;
      if (!isElecSkipped && e.capturedImage != null) {
        mPhoto = _buildPhotoModel(e.capturedImage!);
      }

      finalMeasurements.add(InstallationMeasurementModel(
          measurementId: e.measurementId,
          unit: e.unit,
          value: isElecSkipped ? 0 : e.value,
          isSkipped: isElecSkipped,
          note: '',
          photo: mPhoto));
    }

    final psiE = _psiEntries.first;
    InstallationPhotoModel? psiMPhoto;
    if (!isPsiSkipped && psiE.capturedImage != null) {
      psiMPhoto = _buildPhotoModel(psiE.capturedImage!);
    }

    finalMeasurements.add(InstallationMeasurementModel(
        measurementId: psiE.measurementId,
        unit: psiE.unit,
        value: isPsiSkipped ? 0 : psiE.value,
        isSkipped: isPsiSkipped,
        note: '',
        photo: psiMPhoto));

    for (int i = 0; i < _installPhotos.length; i++) {
      final img = _installPhotos[i];
      final id = "${_kInstallPhotoBaseId}_${i + 1}";
      finalMeasurements.add(InstallationMeasurementModel(
        measurementId: id,
        unit: '',
        value: 0,
        isSkipped: false,
        note: 'Dokumentasi Outdoor ${i + 1}',
        photo: _buildPhotoModel(img),
      ));
    }

    String currentStatus =
        isFinal ? 'COMPLETED' : (_isOriginalCompleted ? 'COMPLETED' : 'DRAFT');

    return InstallationUnitModel(
      unitIndex: widget.target.unitIndex,
      articleNo: widget.target.articleNo,
      articleDesc: widget.target.description,
      articleType: 'OUT',
      serialNo: finalSn,
      // <-- Jahitan SN masuk sini

      note: noteOutdoor,
      remark: remarkOutdoor,
      remarkPhotos: remarkPhotosOutdoor,

      notePsi: notePsi,
      remarkPsi: remarkPsi,
      remarkPhotosPsi: remarkPhotosPsi,

      measurements: finalMeasurements,
      materials: InstallationMaterialsModel(),
      pairedSerialNo: autoPairedSN,
      status: currentStatus,
      reffLineNo: widget.target.reffLineNo,
    );
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

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating));
  }

  void _openImageViewer(CapturedImageDetail img) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imageDetail: img)));
  }

  void _dispatchSave({required bool isFinal}) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    final state = context.read<InstallationBloc>().state;
    final indoorUnit = state.draftEntry?.units.firstWhere(
        (u) => u.unitIndex == widget.target.unitIndex && u.articleType == 'IN',
        orElse: () => InstallationUnitModel(
            serialNo: '',
            unitIndex: -1,
            articleNo: '',
            articleDesc: '',
            articleType: '',
            measurements: [],
            materials: InstallationMaterialsModel()));
    final autoPairedSN = indoorUnit?.serialNo ?? '';

    if (isFinal) {
      final newUnit = _buildUnitModel(isFinal: isFinal);
      if (newUnit == null) return; // Validasi Sthira

      final snToValidate = newUnit.serialNo;

      if (snToValidate.isEmpty) {
        _showErrorSnack("Serial Number wajib diisi!");
        return;
      }


      final draft = state.draftEntry;
      if (draft != null && draft.units.isNotEmpty) {
        final isDuplicate = draft.units.any((u) =>
            u.serialNo == snToValidate &&
            u.unitIndex != widget.target.unitIndex);
        if (isDuplicate) {
          _showErrorSnack("Serial Number sudah digunakan di unit lain!");
          return;
        }
      }

      bool isElecSkipped = _elecEntries.first.isSkipped ?? false;
      if (isElecSkipped) {
        if (_selectedElecNote == null) {
          _showErrorSnack("Alasan Skip Listrik wajib dipilih!");
          return;
        }
        final opt = _elecNoteOptions.firstWhere(
            (o) => o.label == _selectedElecNote,
            orElse: () => const MeasurementNoteOption(label: ''));
        if (opt.requireRemark &&
            (_elecRemarkController.text.length < 20 ||
                _elecNotePhotos.isEmpty)) {
          _showErrorSnack(
              "Data Skip Listrik belum lengkap (Remark 20 char + Foto)!");
          return;
        }
      } else {
        if (_elecEntries.any((e) => e.value <= 0)) {
          _showErrorSnack("Nilai pengukuran listrik wajib diisi!");
          return;
        }
        if (_elecEntries.any((e) => e.capturedImage == null)) {
          _showErrorSnack("Foto pengukuran listrik wajib ada!");
          return;
        }
      }

      // PSI validation hidden
      if (false) {
      bool isPsiSkipped = _psiEntries.first.isSkipped ?? false;
      if (isPsiSkipped) {
        if (_selectedPsiNote == null) {
          _showErrorSnack("Alasan Skip PSI wajib dipilih!");
          return;
        }
        final opt = _psiNoteOptions.firstWhere(
            (o) => o.label == _selectedPsiNote,
            orElse: () => const MeasurementNoteOption(label: ''));
        if (opt.requireRemark &&
            (_psiRemarkController.text.length < 20 || _psiNotePhotos.isEmpty)) {
          _showErrorSnack(
              "Data Skip PSI belum lengkap (Remark 20 char + Foto)!");
          return;
        }
      } else {
        if (_psiEntries.first.value <= 0) {
          _showErrorSnack("Nilai PSI wajib diisi!");
          return;
        }
        if (_psiEntries.first.capturedImage == null) {
          _showErrorSnack("Foto PSI wajib ada!");
          return;
        }
      }
      } // end PSI validation

      if (_installPhotos.length < 4) {
        _showErrorSnack("Wajib ambil minimal 4 Foto Dokumentasi Pemasangan!");
        return;
      }
    }

    final savedUnit = _buildUnitModel(isFinal: isFinal);
    if (savedUnit != null) {
      context.read<InstallationBloc>().add(
          SaveOutdoorUnit(unit: savedUnit, pairedIndoorSerial: autoPairedSN));

      if (isFinal) {
        _isSubmittingFinal = true;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Data Outdoor Tersimpan"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating));
      } else {
        debugPrint("Auto-saved draft Outdoor unit ${widget.target.unitIndex}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isElecSkipped = _elecEntries.first.isSkipped ?? false;
    bool isPsiSkipped = _psiEntries.first.isSkipped ?? false;
    final state = context.read<InstallationBloc>().state;
    final indoorUnit = state.draftEntry?.units.firstWhere(
        (u) => u.unitIndex == widget.target.unitIndex && u.articleType == 'IN',
        orElse: () => InstallationUnitModel(
            serialNo: '',
            unitIndex: -1,
            articleNo: '',
            articleDesc: '',
            articleType: '',
            measurements: [],
            materials: InstallationMaterialsModel()));
    final pairedSN = indoorUnit?.serialNo ?? '';
    final isPaired = pairedSN.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isSubmittingFinal || _isOriginalCompleted) {
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("Article No: ${widget.target.articleNo}",
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 13))
                              ]))),

                  // --- [PERUBAHAN ALUR 3] BUILDER SN ---
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSection(
                          title: "Identitas Unit",
                          child: _vendorCode == 'V000062'
                              ? _buildSthiraSnForm()
                              : _buildNormalSnForm())),
                  // -------------------------------------

                  const SizedBox(height: 16),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSection(
                          title: "Pairing Indoor (Otomatis)",
                          child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: isPaired
                                      ? Colors.blue.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isPaired
                                          ? Colors.blue.shade200
                                          : Colors.red.shade200)),
                              child: Row(children: [
                                Icon(isPaired ? Icons.link : Icons.link_off,
                                    color: isPaired ? Colors.blue : Colors.red),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          isPaired
                                              ? "Terhubung dengan Indoor:"
                                              : "Indoor Belum Diinput",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isPaired
                                                  ? Colors.blue[900]
                                                  : Colors.red[900])),
                                      if (isPaired)
                                        Text(pairedSN,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold))
                                    ])),
                                if (isPaired)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 20)
                              ])))),
                  const SizedBox(height: 24),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildInstallationPhotoSection()),
                  const SizedBox(height: 24),
                  Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text("PENGUKURAN LISTRIK",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13))),
                  GenericMeasurementInputSection(
                      transNo: widget.transNo,
                      measurements: _elecEntries,
                      controllers: _elecControllers,
                      limitsMap: _limitsMap,
                      indoorTemp: null,
                      onUpdate: _updateElec),
                  if (isElecSkipped)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _buildSection(
                            title: "Kendala Listrik",
                            child: MeasurementNoteDropdown(
                                label: "Alasan Skip Listrik",
                                value: _selectedElecNote,
                                options: _elecNoteOptions,
                                remarkController: _elecRemarkController,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedElecNote = val;
                                    _elecRemarkController.clear();
                                  });
                                  _onFormChanged();
                                },
                                photos: _elecNotePhotos,
                                isTakingPhoto: _isTakingElecPhoto,
                                onAddPhoto: () => _takePhoto(isElec: true),
                                onRemovePhoto: (path) {
                                  setState(() => _elecNotePhotos
                                      .removeWhere((p) => p.imagePath == path));
                                  _onFormChanged();
                                }))),
                  // PSI section hidden
                  if (false) ...[
                  const SizedBox(height: 16),
                  Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: Text("PENGUKURAN TEKANAN (FREON)",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13))),
                  GenericMeasurementInputSection(
                      transNo: widget.transNo,
                      measurements: _psiEntries,
                      controllers: _psiControllers,
                      limitsMap: _limitsMap,
                      indoorTemp: null,
                      onUpdate: _updatePsi),
                  if (isPsiSkipped)
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: _buildSection(
                            title: "Kendala Tekanan",
                            child: MeasurementNoteDropdown(
                                label: "Alasan Skip PSI",
                                value: _selectedPsiNote,
                                options: _psiNoteOptions,
                                remarkController: _psiRemarkController,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedPsiNote = val;
                                    _psiRemarkController.clear();
                                  });
                                  _onFormChanged();
                                },
                                photos: _psiNotePhotos,
                                isTakingPhoto: _isTakingPsiPhoto,
                                onAddPhoto: () => _takePhoto(isPsi: false),
                                onRemovePhoto: (path) {
                                  setState(() => _psiNotePhotos
                                      .removeWhere((p) => p.imagePath == path));
                                  _onFormChanged();
                                }))),
                  ], // end PSI section
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
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isProcessingWatermark)
                          const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                        else
                          const Icon(Icons.save_as_outlined,
                              color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                            _isProcessingWatermark
                                ? "MEMPROSES FOTO..."
                                : "SIMPAN DATA OUTDOOR",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white))
                      ]))),
        ],
      ),
    );
  }

  // --- [PERUBAHAN ALUR 3] WIDGET SN NORMAL ---
  Widget _buildNormalSnForm() {
    return _buildCustomTextField(
        controller: _snController,
        label: "Serial Number (Wajib)",
        icon: FontAwesomeIcons.barcode,
        suffixIcon: IconButton(
            icon: const Icon(FontAwesomeIcons.qrcode, color: Color(0xFF1565C0)),
            onPressed: () async {
              final res = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()));
              if (res != null) setState(() => _snController.text = res);
            }));
  }

  // --- [PERUBAHAN ALUR 3] WIDGET SN STHIRA ---
  Widget _buildSthiraSnForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final res = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const QrScanPage()));
              if (res != null) {
                if (res.contains('|ou|') || res.contains('|OU|')) {
                  final parts =
                      res.split(RegExp(r'\|ou\|', caseSensitive: false));
                  if (parts.length == 2) {
                    setState(() {
                      _sthiraSnPartController.text = parts[0];
                      _sthiraTypePartController.text = parts[1];
                    });
                    _onFormChanged();
                  }
                } else {
                  _showErrorSnack(
                      "Barcode tidak valid! Harus format SN|OU|TIPE.");
                }
              }
            },
            icon: const Icon(FontAwesomeIcons.qrcode,
                color: Color(0xFF1565C0), size: 18),
            label: const Text("Scan Barcode Outdoor"),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ),
        const SizedBox(height: 16),
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
              child: Text("| OU |",
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

  Widget _buildInstallationPhotoSection() {
    return _buildSection(
      title: "Dokumentasi Pemasangan",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Foto Unit Terpasang",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              Text("${_installPhotos.length}/5 Foto",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _installPhotos.length == 5
                          ? Colors.red
                          : Colors.blue)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _installPhotos.length + 1,
              separatorBuilder: (ctx, i) => const SizedBox(width: 12),
              itemBuilder: (ctx, index) {
                if (index == _installPhotos.length) {
                  if (_installPhotos.length >= 5) {
                    return const SizedBox.shrink();
                  }
                  return InkWell(
                    onTap: () => _takePhoto(isInstallPhoto: true),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid)),
                      child: _isTakingInstallPhoto
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                  Icon(Icons.add_a_photo,
                                      size: 30, color: Colors.grey.shade400),
                                  const SizedBox(height: 4),
                                  Text("Tambah",
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11))
                                ]),
                    ),
                  );
                }

                final img = _installPhotos[index];
                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _openImageViewer(img),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(img.imagePath),
                            width: 120, height: 120, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() => _installPhotos.removeAt(index));
                          if (!_isOriginalCompleted) _forceSaveDraft();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.red),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
          if (_isProcessingWatermark && _isTakingInstallPhoto)
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

  // --- [PERUBAHAN ALUR 3] Tambah param hintText ---
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
