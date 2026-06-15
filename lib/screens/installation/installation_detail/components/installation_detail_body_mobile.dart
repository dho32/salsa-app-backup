import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/blocs/installation/installation_state.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';

// --- IMPORT SCREENS ---
import 'package:salsa/screens/installation/installation_detail_list/indoor_list/indoor_list_screen.dart';
import 'package:salsa/screens/installation/installation_detail_list/outdoor_list/outdoor_list_screen.dart';
import 'package:salsa/screens/installation/installation_detail_list/material_list/material_list_screen.dart';
import 'package:salsa/screens/installation/installation_detail_list/material_evidence/material_evidence_screen.dart';
import 'package:salsa/screens/installation/installation_summary/installation_summary_screen.dart';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../components/constants.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../models/common/captured_image_detail.dart';

class InstallationDetailBodyMobile extends StatefulWidget {
  const InstallationDetailBodyMobile({super.key});

  @override
  State<InstallationDetailBodyMobile> createState() =>
      _InstallationDetailBodyMobileState();
}

class _InstallationDetailBodyMobileState
    extends State<InstallationDetailBodyMobile> {
  // --- STATE LOKAL ---
  bool _showTechnician3 = false;
  bool _isWH = false;
  List<Map<String, String>> _technicianList = [];
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _tech2SearchController = TextEditingController();
  final TextEditingController _tech3SearchController = TextEditingController();
  DateTime? _selectedDate;

  // State Foto Toko
  bool _isTakingStorePhoto = false;
  CapturedImageDetail? _storeFrontPhoto;

  @override
  void initState() {
    super.initState();
    // [FIX 1] Tarik foto dari draft lokal saat halaman pertama kali dibuka
    _loadUserAndTechnicianList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = context.read<InstallationBloc>().state.draftEntry;
      if (draft?.storeFrontPhoto != null) {
        setState(() {
          _storeFrontPhoto = CapturedImageDetail(
            imagePath: draft!.storeFrontPhoto!.imagePath,
            timestamp: DateTime.tryParse(draft.storeFrontPhoto!.timestamp) ??
                DateTime.now(),
            technicianName: '',
            deviceModel: draft.storeFrontPhoto!.deviceModel,
            transNo: draft.transNo,
            latitude: draft.storeFrontPhoto!.latitude,
            longitude: draft.storeFrontPhoto!.longitude,
            address: '',
          );
        });
      }
    });
  }

  Future<void> _loadUserAndTechnicianList() async {
    final userData = await AuthStorage.getUser();
    final userType = userData['maintenance_type'] ?? 'WH';
    final configBox = Hive.box(kAppConfigBox);
    final rawList = configBox.get('technician_list');
    if (mounted) {
      setState(() {
        _isWH = userType == 'WH';
        if (rawList is List) {
          _technicianList = rawList.whereType<Map>().map((t) => {
            'technician_id': (t['technician_id'] ?? '') as String,
            'technician_name': (t['technician_name'] ?? '') as String,
          }).toList();
        }
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _tech2SearchController.dispose();
    _tech3SearchController.dispose();
    super.dispose();
  }

  // --- DATE PICKER HELPER ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd MMM yyyy').format(picked);
      });
      if (mounted) {
        context.read<InstallationBloc>().add(UpdateTeamInfo(startDate: picked));
      }
    }
  }

  // --- SHOW ERROR DIALOG ---
  void _showValidationDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text("Validasi Gagal", style: TextStyle(color: Colors.red)),
        content: Text(errorMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  // --- LOGIC FOTO TOKO & GPS ---
  Future<void> _takeStoreFrontPhoto(
      BuildContext context, InstallationHeaderDetailModel header) async {
    // 1. CEK & REQUEST PERMISSION LOKASI
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorSnack(context, "Akses lokasi ditolak! Wajib izinkan lokasi.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showErrorSnack(
          context, "Akses lokasi diblokir permanen di pengaturan HP.");
      return;
    }

    setState(() => _isTakingStorePhoto = true);

    try {
      // 2. AMBIL TITIK LOKASI (Akurasi Tinggi)
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. BUKA KAMERA
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 85);

      if (image != null) {
        // 4. PROSES WATERMARK
        final user = await AuthStorage.getUser();
        final deviceModel = user['device_model'] ?? 'Mobile App';
        final directory = await getApplicationDocumentsDirectory();
        final String fileName =
            'WM_STORE_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String targetPath = p.join(directory.path, fileName);

        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        final req = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: header.transNo,
          formattedDate: formattedDate,
          technicianName: user['name'] ?? 'Teknisi',
          deviceModel: deviceModel,
          location: '${position.latitude}, ${position.longitude}',
          photoLabel: 'Toko Tampak Depan',
        );

        final String? resultPath = await WatermarkService.processImage(req);

        if (resultPath != null) {
          // 5. SIMPAN KE STATE (Lengkap dengan Lat/Long)
          setState(() {
            _storeFrontPhoto = CapturedImageDetail(
              imagePath: resultPath,
              timestamp: timestamp,
              technicianName: req.technicianName,
              deviceModel: req.deviceModel,
              transNo: header.transNo,
              latitude: position.latitude,
              longitude: position.longitude,
              address: '',
            );
          });

          // [FIX 2] Langsung tembak ke BLoC agar auto-save ke draft lokal
          final photoModel = InstallationPhotoModel(
            imagePath: resultPath,
            imageFileName: resultPath.split('/').last,
            timestamp: timestamp.toIso8601String(),
            latitude: position.latitude,
            longitude: position.longitude,
            deviceModel: req.deviceModel,
          );
          if (mounted) {
            context
                .read<InstallationBloc>()
                .add(SaveStoreFrontPhoto(photoModel));
          }
        }
      }
    } catch (e) {
      _showErrorSnack(context, "Gagal memproses foto atau lokasi: $e");
    } finally {
      setState(() => _isTakingStorePhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InstallationBloc, InstallationState>(
      listenWhen: (previous, current) {
        return previous.status != current.status;
      },
      listener: (context, state) {
        if (state.status == InstallationStatus.failure) {
          _showValidationDialog(context, state.errorMessage);
        }

        if (state.status == InstallationStatus.snValidationSuccess) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<InstallationBloc>(),
                child: InstallationSummaryScreen(
                    transNo: state.taskDetail?.header.transNo ?? ""),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == InstallationStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.taskDetail == null) return const SizedBox();

        final detail = state.taskDetail!;
        final draft = state.draftEntry;

        if (draft != null) {
          if (!_showTechnician3 && draft.technician3Name.isNotEmpty) {
            _showTechnician3 = true;
          }
          if (_dateController.text.isEmpty && draft.startDate != null) {
            _selectedDate = draft.startDate;
            _dateController.text =
                DateFormat('dd MMM yyyy').format(draft.startDate!);
          }
        }

        // --- PROGRESS CALCULATION LOGIC ---
        final totalIndoor =
            detail.targets.where((t) => t.unitType == 'IN').length;
        final totalOutdoor =
            detail.targets.where((t) => t.unitType == 'OUT').length;

        final doneIndoor = draft?.units
                .where((u) => u.articleType == 'IN' && u.status == 'COMPLETED')
                .length ??
            0;
        final doneOutdoor = draft?.units
                .where((u) => u.articleType == 'OUT' && u.status == 'COMPLETED')
                .length ??
            0;
        final doneMaterial = draft?.units
                .where((u) =>
                    u.articleType == 'OUT' &&
                    u.materialStatus == 'COMPLETED' &&
                    u.materials.pipes.isNotEmpty)
                .length ??
            0;

        // Evidence Calculation
        final Set<String> uniqueMaterialKeys = {};
        if (draft != null) {
          for (var u in draft.units) {
            for (var p in u.materials.pipes) {
              if (p.brandId.isNotEmpty && p.usageType != 'PIPA_DRAIN') {
                uniqueMaterialKeys.add("${p.articleId}_${p.brandId}");
              }
            }
            for (var c in u.materials.cables) {
              if (c.brandId.isNotEmpty && c.usageType != 'KABEL_DUCT') {
                uniqueMaterialKeys.add("${c.articleId}_${c.brandId}");
              }
            }
          }
        }
        final totalEvidenceNeeded = uniqueMaterialKeys.length;
        final doneEvidence = draft?.materialEvidences
                .where((e) =>
                    uniqueMaterialKeys.contains(e.key) &&
                    e.photoPath.isNotEmpty)
                .length ??
            0;

        // Percentages
        double progressIndoor = totalIndoor > 0 ? doneIndoor / totalIndoor : 0;
        double progressOutdoor =
            totalOutdoor > 0 ? doneOutdoor / totalOutdoor : 0;
        double progressMaterial =
            totalOutdoor > 0 ? doneMaterial / totalOutdoor : 0;
        double progressEvidence = 0.0;

        if (totalEvidenceNeeded > 0) {
          progressEvidence = doneEvidence / totalEvidenceNeeded;
        } else if (doneMaterial > 0) {
          progressEvidence = 1.0;
        }

        // --- CEK LOCKING STATUS ---
        bool isIndoorComplete = progressIndoor >= 1.0;
        bool isOutdoorComplete = progressOutdoor >= 1.0;
        bool isMaterialComplete = progressMaterial >= 1.0;
        bool isEvidenceComplete =
            (totalEvidenceNeeded > 0 && progressEvidence >= 1.0) ||
                (totalEvidenceNeeded == 0 && isMaterialComplete);
        bool isDateFilled = _dateController.text.isNotEmpty;

        bool isStorePhotoFilled = draft?.storeFrontPhoto != null;

        // Final Status
        bool isReadyToSubmit = isIndoorComplete &&
            isOutdoorComplete &&
            isMaterialComplete &&
            isEvidenceComplete &&
            isDateFilled &&
            isStorePhotoFilled; // Masuk ke validasi final

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  children: [
                    _buildCustomerSection(detail.header),
                    const SizedBox(height: 8),
                    _buildStoreFrontPhotoSection(detail.header, draft!),
                    const SizedBox(height: 16),
                    _buildTicketSection(detail.header),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: "Tanggal Pengerjaan",
                      child: _buildCustomTextField(
                        controller: _dateController,
                        hintText: 'Pilih Tanggal Mulai',
                        icon: Icons.calendar_today,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: "Teknisi Bertugas",
                      child: _buildTechnicianPanel(context, state),
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      title: "Tahapan Pengerjaan",
                      child: Column(
                        children: [
                          // 1. INDOOR
                          _buildTaskCard(
                            title: "1. Unit Indoor",
                            subtitle: "$doneIndoor / $totalIndoor Unit Selesai",
                            icon: FontAwesomeIcons.wind,
                            progress: progressIndoor,
                            color: Colors.blue[700]!,
                            onTap: () => _navigateToSubPage(
                                context,
                                IndoorListScreen(
                                    transNo: detail.header.poCustNo)),
                          ),
                          const SizedBox(height: 12),

                          // 2. OUTDOOR
                          _buildTaskCard(
                            title: "2. Unit Outdoor",
                            subtitle: "$doneOutdoor / $totalOutdoor Unit Selesai",
                            icon: FontAwesomeIcons.fan,
                            progress: progressOutdoor,
                            color: Colors.orange[800]!,
                            isLocked: false,
                            onTap: () => _navigateToSubPage(
                                context,
                                OutdoorListScreen(
                                    transNo: detail.header.poCustNo)),
                          ),
                          const SizedBox(height: 12),

                          // 3. MATERIAL
                          _buildTaskCard(
                            title: "3. Material & Pipa",
                            subtitle: isOutdoorComplete
                                ? "$doneMaterial / $totalOutdoor Set Terisi"
                                : "Selesaikan Unit Outdoor dahulu",
                            icon: FontAwesomeIcons.rulerCombined,
                            progress: progressMaterial,
                            color: Colors.purple[700]!,
                            isLocked: !isOutdoorComplete,
                            onTap: () => _navigateToSubPage(
                                context,
                                MaterialListScreen(
                                    transNo: detail.header.poCustNo)),
                          ),
                          const SizedBox(height: 12),

                          // 4. EVIDENCE
                          _buildTaskCard(
                            title: "4. Foto Merk Material",
                            subtitle: isMaterialComplete
                                ? (totalEvidenceNeeded == 0
                                    ? "Menunggu input material..."
                                    : "$doneEvidence / $totalEvidenceNeeded Merk Terfoto")
                                : "Selesaikan Input Material dahulu",
                            icon: FontAwesomeIcons.boxOpen,
                            progress: progressEvidence,
                            color: Colors.teal[700]!,
                            isLocked: !isMaterialComplete,
                            onTap: totalEvidenceNeeded > 0
                                ? () => _navigateToSubPage(
                                    context,
                                    MaterialEvidenceScreen(
                                        transNo: detail.header.poCustNo))
                                : () => _showErrorSnack(context,
                                    "Selesaikan Input Material (Tahap 3) terlebih dahulu atau tidak ada merk yang perlu difoto."),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BUTTON
            Container(
              padding: const EdgeInsets.only(
                  bottom: 20, top: 5, left: 16, right: 16),
              child: ElevatedButton(
                onPressed: () {
                  // Validasi Lokal
                  if (!isDateFilled) {
                    _showErrorSnack(
                        context, "⚠️ Tanggal pengerjaan wajib diisi!");
                    return;
                  }
                  if (!isStorePhotoFilled) {
                    _showErrorSnack(
                        context, "⚠️ Foto Tampak Depan Toko wajib diambil!");
                    return;
                  }
                  if (!isIndoorComplete) {
                    _showErrorSnack(context, "⚠️ Unit Indoor belum selesai.");
                    return;
                  }
                  if (!isOutdoorComplete) {
                    _showErrorSnack(context, "⚠️ Unit Outdoor belum selesai.");
                    return;
                  }
                  if (!isMaterialComplete) {
                    _showErrorSnack(
                        context, "⚠️ Input Material belum selesai.");
                    return;
                  }
                  if (!isEvidenceComplete) {
                    _showErrorSnack(
                        context, "⚠️ Foto Bukti Merk belum lengkap.");
                    return;
                  }

                  // HANYA JALAN JIKA SEDANG TIDAK VALIDASI
                  if (state.status != InstallationStatus.validatingSN) {
                    context
                        .read<InstallationBloc>()
                        .add(const ValidateSerialNumbers());
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReadyToSubmit
                      ? const Color(0xFF2E7D32)
                      : Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: isReadyToSubmit ? 6 : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state.status == InstallationStatus.validatingSN) ...[
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      const Text("MEMERIKSA SERIAL NUMBER...",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ] else ...[
                      Icon(
                          isReadyToSubmit
                              ? Icons.check_circle_outline
                              : Icons.lock_outline,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      const Text("LANJUT KE FINAL REVIEW",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required double progress,
    required Color color,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    bool isDone = progress >= 1.0;

    final displayColor = isLocked ? Colors.grey : color;
    final displayIcon =
        isLocked ? Icons.lock : (isDone ? Icons.check_circle : icon);
    final displayIconColor =
        isLocked ? Colors.grey : (isDone ? Colors.green : color);
    final displayBgColor = isLocked ? Colors.grey.shade100 : Colors.white;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: displayBgColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isLocked
                  ? Colors.grey.shade300
                  : (isDone
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.shade300))),
      child: InkWell(
        onTap: isLocked
            ? () => _showErrorSnack(
                context, "🔒 Selesaikan tahapan sebelumnya terlebih dahulu.")
            : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDone
                      ? Colors.green.shade50
                      : (isLocked
                          ? Colors.grey.shade200
                          : color.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(displayIcon, color: displayIconColor, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isLocked ? Colors.grey : Colors.black87)),
                    const SizedBox(height: 4),
                    if (!isLocked) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[100],
                                color: isDone ? Colors.green : color,
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("${(progress * 100).toInt()}%",
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontStyle: isLocked
                                ? FontStyle.italic
                                : FontStyle.normal)),
                  ],
                ),
              ),
              if (!isLocked)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(message))
      ]),
      backgroundColor: Colors.red[800],
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _navigateToSubPage(BuildContext context, Widget screen) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BlocProvider.value(
                value: context.read<InstallationBloc>(), child: screen)));
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold))),
        child
      ]),
    );
  }

  Widget _buildTechnicianPanel(BuildContext context, InstallationState state) {
    final draft = state.draftEntry;
    if (draft == null) return const SizedBox();

    final bool useDropdown = _isWH && _technicianList.isNotEmpty;

    return Column(children: [
      _buildCustomTextField(
          initialValue: draft.technician1Name,
          hintText: 'Teknisi 1',
          icon: Icons.engineering,
          readOnly: true),
      const SizedBox(height: 12),
      if (useDropdown)
        _buildTechnicianDropdown(
          context: context,
          label: 'Teknisi 2',
          value: draft.technician2Name ?? '',
          excludedName: draft.technician3Name ?? '',
          searchController: _tech2SearchController,
          onChanged: (val) => context
              .read<InstallationBloc>()
              .add(UpdateTeamInfo(technician2: val ?? '')),
          onClear: (draft.technician2Name ?? '').isNotEmpty ? () => context
              .read<InstallationBloc>()
              .add(const UpdateTeamInfo(technician2: '')) : null,
        )
      else
        _buildCustomTextField(
            initialValue: draft.technician2Name,
            hintText: 'Teknisi 2',
            icon: Icons.engineering,
            onChanged: (val) => context
                .read<InstallationBloc>()
                .add(UpdateTeamInfo(technician2: val))),
      const SizedBox(height: 8),
      if (_showTechnician3)
        if (useDropdown)
          Row(children: [
            Expanded(
              child: _buildTechnicianDropdown(
                context: context,
                label: 'Teknisi 3',
                value: draft.technician3Name ?? '',
                excludedName: draft.technician2Name ?? '',
                searchController: _tech3SearchController,
                onChanged: (val) => context
                    .read<InstallationBloc>()
                    .add(UpdateTeamInfo(technician3: val ?? '')),
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<InstallationBloc>().add(const UpdateTeamInfo(technician3: ''));
                setState(() => _showTechnician3 = false);
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
          ])
        else
          _buildCustomTextField(
              initialValue: draft.technician3Name,
              hintText: 'Teknisi 3',
              icon: Icons.engineering,
              onChanged: (val) => context
                  .read<InstallationBloc>()
                  .add(UpdateTeamInfo(technician3: val)),
              suffixIcon: IconButton(
                  onPressed: () {
                    context.read<InstallationBloc>().add(const UpdateTeamInfo(technician3: ''));
                    setState(() => _showTechnician3 = false);
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red)))
      else
        Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Teknisi 3'),
                onPressed: () => setState(() => _showTechnician3 = true)))
    ]);
  }

  Widget _buildTechnicianDropdown({
    required BuildContext context,
    required String label,
    required String value,
    required String excludedName,
    required TextEditingController searchController,
    required ValueChanged<String?> onChanged,
    VoidCallback? onClear,
  }) {
    final filtered = _technicianList
        .where((t) => excludedName.isEmpty || t['technician_name'] != excludedName)
        .toList();
    final currentValue = filtered.any((t) => t['technician_name'] == value) ? value : null;

    final dropdown = DropdownButtonFormField2<String>(
      value: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.engineering, color: Colors.grey.shade600, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      hint: Text(label, style: const TextStyle(fontSize: 14)),
      onChanged: onChanged,
      items: filtered
          .map((t) => DropdownMenuItem<String>(
                value: t['technician_name'],
                child: Text(
                  t['technician_name'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
      dropdownStyleData: DropdownStyleData(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      ),
      dropdownSearchData: DropdownSearchData(
        searchController: searchController,
        searchInnerWidgetHeight: 50,
        searchInnerWidget: Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            controller: searchController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: 'Cari teknisi...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) =>
            item.value.toString().toLowerCase().contains(searchValue.toLowerCase()),
      ),
      onMenuStateChange: (isOpen) {
        if (!isOpen) searchController.clear();
      },
    );

    if (onClear != null) {
      return Row(
        children: [
          Expanded(child: dropdown),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.cancel, color: Colors.red),
          ),
        ],
      );
    }
    return dropdown;
  }

  Widget _buildCustomTextField(
      {String? initialValue,
      TextEditingController? controller,
      required String hintText,
      required IconData icon,
      bool readOnly = false,
      Function(String)? onChanged,
      VoidCallback? onTap,
      Widget? suffixIcon}) {
    return TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        initialValue: controller == null ? initialValue : null,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
            labelText: hintText,
            hintText: hintText,
            prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
            suffixIcon: suffixIcon,
            isDense: true,
            filled: true,
            fillColor: readOnly && onTap == null
                ? Colors.grey.shade200
                : Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12)));
  }

  Widget _buildCustomerSection(InstallationHeaderDetailModel header) {
    return _buildSection(
        title: 'Informasi Customer',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Toko: ${header.shipToName}',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Alamat: ${header.shipToAddress}',
              style: const TextStyle(fontSize: 13, height: 1.3)),
          const SizedBox(height: 4),
          Text('Cabang: ${header.branchName}',
              style: const TextStyle(fontSize: 13))
        ]));
  }

  Widget _buildTicketSection(InstallationHeaderDetailModel header) {
    return _buildSection(
        title: 'Surat Tugas',
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Text('No: ${header.transNo}',
                  style: const TextStyle(fontWeight: FontWeight.w500))
            ]),
            Text(header.roPostedDate,
                style: const TextStyle(fontWeight: FontWeight.w500))
          ]),
          Row(children: [
            const Icon(Icons.receipt, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Text('Cust PO No: ${header.poCustNo}',
                style: const TextStyle(fontWeight: FontWeight.w500))
          ])
        ]));
  }

  // Tambahkan parameter `InstallationEntryModel draft`
  Widget _buildStoreFrontPhotoSection(
      InstallationHeaderDetailModel header, InstallationEntryModel draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Foto Tampak Depan Toko",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          const Text("Wajib difoto di lokasi (GPS akan tercatat otomatis)",
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),

          // [FIX] BACA LANGSUNG DARI DRAFT BLOC
          if (draft.storeFrontPhoto != null)
            Stack(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          // Bikin object on-the-fly untuk preview
                          imageDetail: CapturedImageDetail(
                            imagePath: draft.storeFrontPhoto!.imagePath,
                            timestamp: DateTime.tryParse(
                                    draft.storeFrontPhoto!.timestamp) ??
                                DateTime.now(),
                            technicianName: '',
                            deviceModel: draft.storeFrontPhoto!.deviceModel,
                            transNo: header.transNo,
                            latitude: draft.storeFrontPhoto!.latitude,
                            longitude: draft.storeFrontPhoto!.longitude,
                            address: '',
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(draft.storeFrontPhoto!.imagePath),
                        width: double.infinity, height: 180, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    // [FIX] Tombol hapus langsung nembak event null ke BLoC
                    onTap: () => context
                        .read<InstallationBloc>()
                        .add(const SaveStoreFrontPhoto(null)),
                    child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.red, size: 20)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(
                        "Lat: ${draft.storeFrontPhoto!.latitude}\nLon: ${draft.storeFrontPhoto!.longitude}",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                )
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 100,
              child: OutlinedButton.icon(
                onPressed: _isTakingStorePhoto
                    ? null
                    : () => _takeStoreFrontPhoto(context, header),
                icon: _isTakingStorePhoto
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt, color: Colors.blue),
                label: Text(
                    _isTakingStorePhoto ? "Memproses..." : "Ambil Foto Toko"),
                style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
              ),
            )
        ],
      ),
    );
  }
}
