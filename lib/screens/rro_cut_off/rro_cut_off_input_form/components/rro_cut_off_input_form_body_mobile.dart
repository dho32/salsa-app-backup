import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart'; // 🔥 IMPORT GEOLOCATOR DITAMBAHKAN

// 🔥 IMPORT SESUAI PATH APLIKASI AKANG
import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/rro_cut_off/rro_cut_off_detail_model.dart';
import '../../../../models/rro_cut_off/rro_cut_off_entry_model.dart';

// 🔥 JANGAN LUPA IMPORT QR SCAN PAGE AKANG DI SINI
// import 'path/to/qr_scan_page.dart';

// Slot foto bongkar berlabel (pola sama dengan form Installation), semuanya
// wajib. Urutan list = urutan penyimpanan foto di Hive/payload.
class _RROPhotoSlot {
  final String id;
  final String label;
  const _RROPhotoSlot(this.id, this.label);
}

const List<_RROPhotoSlot> _kIndoorSlots = [
  // Posisi unit indoor mana yang dibongkar.
  _RROPhotoSlot('before', 'Indoor Sebelum Dibongkar'),
  // Cek bekas posisi indoor dirapikan atau tidak.
  _RROPhotoSlot('after', 'Bekas Posisi Indoor'),
  // Cek no seri unit yang dibongkar sesuai atau tidak.
  _RROPhotoSlot('barcode', 'Stiker Barcode'),
];

const List<_RROPhotoSlot> _kOutdoorSlots = [
  _RROPhotoSlot('before', 'Outdoor Sebelum Dibongkar'),
  _RROPhotoSlot('after', 'Bekas Outdoor Setelah Dibongkar'),
  _RROPhotoSlot('barcode', 'Stiker Barcode'),
];

class RROCutOffInputFormBodyMobile extends StatefulWidget {
  final String transNo;
  final RROCutOffDetailItem unitData;
  final List<RROCutOffSerialNumber> availableSerialNumbers;

  const RROCutOffInputFormBodyMobile({
    super.key,
    required this.transNo,
    required this.unitData,
    required this.availableSerialNumbers,
  });

  @override
  State<RROCutOffInputFormBodyMobile> createState() =>
      _RROCutOffInputFormBodyMobileState();
}

class _RROCutOffInputFormBodyMobileState
    extends State<RROCutOffInputFormBodyMobile> {
  String? _selectedSerialNumber;
  final Map<String, RROCutOffPhotoModel> _photoSlots = {};

  String? _capturingSlotId;
  bool _isProcessingWatermark = false;

  List<_RROPhotoSlot> get _slots =>
      widget.unitData.unitType.toUpperCase() == 'OUT'
          ? _kOutdoorSlots
          : _kIndoorSlots;

  // 🔥 TAMBAHAN VARIABEL MODE MANUAL UNTUK TRIK PSIKOLOGIS
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _autoSaveToHive() async {
    try {
      final box = await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
      final uniqueKey =
          '${widget.transNo}_${widget.unitData.unitType}_${widget.unitData.unitIndex}';

      final photos = [
        for (final slot in _slots)
          if (_photoSlots[slot.id] != null) _photoSlots[slot.id]!,
      ];

      final entry = RROCutOffEntryModel(
        transNo: widget.transNo,
        rroArticleNo: widget.unitData.rroArticleNo,
        unitType: widget.unitData.unitType,
        unitIndex: widget.unitData.unitIndex,
        lineNo: widget.unitData.lineNo,
        selectedSerialNumber: _selectedSerialNumber,
        photos: photos,
        isCompleted: _selectedSerialNumber != null &&
            _slots.every((s) => _photoSlots.containsKey(s.id)),
      );

      await box.put(uniqueKey, entry);
      debugPrint("✅ Auto-Save Berhasil: $uniqueKey");
    } catch (e) {
      debugPrint("❌ Gagal Auto-Save: $e");
    }
  }

  Future<void> _loadExistingData() async {
    final box = await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
    final uniqueKey =
        '${widget.transNo}_${widget.unitData.unitType}_${widget.unitData.unitIndex}';

    final existingData = box.get(uniqueKey);
    if (existingData != null) {
      final loaded = <String, RROCutOffPhotoModel>{};
      int fallbackIdx = 0;
      for (final photo in existingData.photos) {
        String? sid = photo.slotId;
        if (sid == null || !_slots.any((s) => s.id == sid)) {
          // Foto draft lama tanpa slot -> isi slot kosong berikutnya.
          while (fallbackIdx < _slots.length &&
              loaded.containsKey(_slots[fallbackIdx].id)) {
            fallbackIdx++;
          }
          if (fallbackIdx >= _slots.length) continue;
          sid = _slots[fallbackIdx].id;
        }
        loaded[sid] = photo;
      }
      setState(() {
        _selectedSerialNumber = existingData.selectedSerialNumber;
        _photoSlots
          ..clear()
          ..addAll(loaded);
      });
    }
  }

  // 🔥 FUNGSI UNTUK MANGGIL SCANNER QR
  Future<void> _scanSerialNumber(
      List<String> uniqueSNs, List<String> allOriginalSNs) async {
    try {
      final String? scannedResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const QrScanPage()),
      );

      if (scannedResult != null && scannedResult.isNotEmpty) {
        // KONDISI 1: SN ada dan BELUM dipakai
        if (uniqueSNs.contains(scannedResult)) {
          setState(() {
            _selectedSerialNumber = scannedResult;
            _isManualMode = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Serial Number cocok!'),
                backgroundColor: Colors.green),
          );
          _autoSaveToHive();
        }

        // KONDISI 2: SN aslinya ADA di database, tapi NGGA ADA di uniqueSNs (berarti udah kepakai)
        else if (allOriginalSNs.contains(scannedResult)) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("SN Sudah Digunakan",
                  style: TextStyle(color: Colors.orange)),
              content: Text(
                  "Serial Number ($scannedResult) sudah Anda pilih untuk unit bongkar yang lain.\n\nSilakan scan Serial Number unit yang berbeda."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("TUTUP"))
              ],
            ),
          );
        }

        // KONDISI 3: SN beneran ANEH (Ngga ada di database sama sekali)
        else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("SN Tidak Ditemukan",
                  style: TextStyle(color: Colors.red)),
              content: Text(
                  "Serial Number hasil scan ($scannedResult) tidak ada di dalam daftar unit untuk RRO ini.\n\nSilakan periksa kembali fisik unit atau pilih manual dari Dropdown."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("TUTUP"))
              ],
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnack('Error scanner: $e');
    }
  }

  Future<void> _handleTakeSlotPhoto(_RROPhotoSlot slot) async {
    if (_capturingSlotId != null) return;

    setState(() => _capturingSlotId = slot.id);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isProcessingWatermark = true);

        final user = await AuthStorage.getUser();
        final String techName = user['name'] ?? 'Teknisi';
        final String deviceModel = user['device_model'] ?? 'Mobile App';
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'WM_RRO_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String targetPath = p.join(directory.path, fileName);
        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        String locationString = '';
        double tempLat = 0.0;
        double tempLng = 0.0;

        final req = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: techName,
          deviceModel: deviceModel,
          location: locationString,
          photoLabel: slot.label,
        );

        final String? resultPath = await WatermarkService.processImage(req);
        setState(() => _isProcessingWatermark = false);

        if (resultPath != null) {
          final newPhotoModel = RROCutOffPhotoModel(
            imagePath: resultPath,
            imageFileName: resultPath.split('/').last,
            timestamp: DateTime.now().toIso8601String(),
            latitude: tempLat,
            longitude: tempLng,
            deviceModel: deviceModel,
            slotId: slot.id,
          );

          setState(() {
            _photoSlots[slot.id] = newPhotoModel;
          });
          _autoSaveToHive();
        } else {
          _showErrorSnack("Gagal memproses watermark foto.");
        }
      }
    } catch (e) {
      _showErrorSnack("Gagal mengambil foto.");
    } finally {
      setState(() {
        _isProcessingWatermark = false;
        _capturingSlotId = null;
      });
    }
  }

  void _removeSlotPhoto(String slotId) {
    setState(() {
      _photoSlots.remove(slotId);
    });
    _autoSaveToHive();
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

  Future<void> _saveAndKembali() async {
    if (_selectedSerialNumber == null) {
      _showErrorSnack('Pilih Serial Number terlebih dahulu');
      return;
    }
    for (final slot in _slots) {
      if (!_photoSlots.containsKey(slot.id)) {
        _showErrorSnack('Foto ${slot.label} wajib diambil!');
        return;
      }
    }

    await _autoSaveToHive();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final entryBox = Hive.box<RROCutOffEntryModel>(kRROCutOffEntryBox);
    final allUsedSNs = entryBox.values
        .where((e) =>
            e.transNo == widget.transNo &&
            e.unitType == widget.unitData.unitType &&
            e.rroArticleNo == widget.unitData.rroArticleNo &&
            e.unitIndex != widget.unitData.unitIndex)
        .map((e) => e.selectedSerialNumber)
        .whereType<String>()
        .toSet();

    final uniqueSNs = widget.availableSerialNumbers
        .where((sn) =>
            sn.unitType == widget.unitData.unitType &&
            sn.rroArticleNo == widget.unitData.rroArticleNo &&
            !allUsedSNs.contains(sn.serialNo))
        .map((sn) => sn.serialNo)
        .toSet()
        .toList();

    final allOriginalSNs = widget.availableSerialNumbers
        .where((sn) =>
            sn.unitType == widget.unitData.unitType &&
            sn.rroArticleNo == widget.unitData.rroArticleNo)
        .map((sn) => sn.serialNo)
        .toList();

    String? safeSelectedSerialNumber = uniqueSNs.contains(_selectedSerialNumber)
        ? _selectedSerialNumber
        : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- INFO UNIT ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.unitData.articleNameUnit,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Article No: ${widget.unitData.rroArticleNo}',
                    style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- BAGIAN SERIAL NUMBER ---
          const Text('Serial Number Unit Bongkar',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),

          // 🔥 KONDISI 1: SUDAH ADA YANG TERPILIH (VIA SCAN ATAU MANUAL)
          if (safeSelectedSerialNumber != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("SN Terpilih:",
                            style:
                                TextStyle(fontSize: 12, color: Colors.green)),
                        Text(safeSelectedSerialNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Colors.blue),
                    tooltip: "Ubah SN",
                    onPressed: () {
                      setState(() {
                        _selectedSerialNumber = null;
                        _isManualMode = false;
                      });
                      _autoSaveToHive();
                    },
                  ),
                ],
              ),
            ),
          ]
          // 🔥 KONDISI 2: MODE SCAN DEFAULT (DDL NGUMPET)
          else if (!_isManualMode) ...[
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 24),
                label: const Text("SCAN QR SN UNIT",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () => _scanSerialNumber(uniqueSNs,
                    allOriginalSNs), // Panggil scan & kirim daftar SN
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() => _isManualMode = true); // Pindah ke manual mode
                },
                child: Text("QR Rusak? Pilih Manual",
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.underline)),
              ),
            )
          ]
          // 🔥 KONDISI 3: MODE MANUAL DDL
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text('Pilih Serial Number'),
                        value: safeSelectedSerialNumber,
                        items: uniqueSNs.map((snString) {
                          return DropdownMenuItem<String>(
                              value: snString, child: Text(snString));
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSerialNumber = val);
                          _autoSaveToHive();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: "Batal Manual",
                    onPressed: () =>
                        setState(() => _isManualMode = false), // Balik ke scan
                  ),
                )
              ],
            ),
          ],

          const SizedBox(height: 16),

          // --- BANNER INSTRUKSI ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Expanded(
                    child: Text(
                        "Penting: Pastikan fisik unit AC sesuai dengan Serial Number yang dipilih.",
                        style: TextStyle(
                            color: Color(0xFF0D47A1),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- FOTO UNIT BONGKAR (SLOT BERLABEL, SEMUA WAJIB) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Foto Unit Bongkar (Wajib)',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              Text("${_photoSlots.length}/${_slots.length} Foto",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < _slots.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _buildPhotoSlotTile(_slots[i])),
              ],
            ],
          ),
          const Spacer(),
          if (_isProcessingWatermark)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text("Sedang memproses watermark...",
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orangeAccent,
                        fontStyle: FontStyle.italic))),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isProcessingWatermark ? null : _saveAndKembali,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Simpan Data Unit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // Tile slot foto — pola sama dengan form Installation: kosong -> tap untuk
  // ambil foto, terisi -> tap untuk preview full-screen, X untuk hapus.
  Widget _buildPhotoSlotTile(_RROPhotoSlot slot) {
    final photo = _photoSlots[slot.id];
    final filled = photo != null;
    final capturing = _capturingSlotId == slot.id;
    final primary = Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: _capturingSlotId != null || _isProcessingWatermark
          ? null
          : (filled
              ? () {
                  final imgDetail = CapturedImageDetail(
                      imagePath: photo.imagePath,
                      timestamp:
                          DateTime.tryParse(photo.timestamp) ?? DateTime.now(),
                      latitude: photo.latitude,
                      longitude: photo.longitude,
                      address: '',
                      technicianName: '',
                      deviceModel: photo.deviceModel,
                      transNo: widget.transNo);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                              imageDetail: imgDetail, isNetworkImage: false)));
                }
              : () => _handleTakeSlotPhoto(slot)),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
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
                    onTap: () => _removeSlotPhoto(slot.id),
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
}
