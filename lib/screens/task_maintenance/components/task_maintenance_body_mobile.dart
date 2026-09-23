import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salsa/screens/rro_cut_off/rro_cut_off_detail/rro_cut_off_detail_screen.dart';
import 'package:salsa/screens/task_maintenance/components/widget/task_maintenance_widgets.dart';
import '../../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_event.dart';
import '../../../blocs/task_maintenance/task_maintenance_repository.dart';
import '../../../blocs/task_maintenance/task_maintenance_state.dart';
import '../../../components/constants.dart';
import '../../../components/widgets/salsa_pending_dialog.dart';
import '../../../components/widgets/scan_qr.dart';
import '../../../models/task_maintenance/task_maintenance_model.dart';
import '../../common/failed_uploads/failed_uploads_screen.dart';
import '../../installation/installation_detail/installation_detail_screen.dart';
import '../../proof_of_service/proof_of_service_detail/proof_of_service_detail_screen.dart';
import '../../proof_of_service_freezer/proof_of_service_freezer_detail/proof_of_service_freezer_detail_screen.dart';
import '../../service_call/service_call_detail/service_call_detail_screen.dart';
import '../../service_call_freezer/scf_detail/scf_detail_screen.dart';

/// Bagian data toko yang belum terdaftar, diturunkan dari field `status`
/// milik suggestion `task_maintenance/v4`.
enum _MissingStoreData {
  /// Email & titik lokasi sama-sama kosong.
  emailDanLokasi,

  /// Titik lokasi sudah ada, email belum.
  email,

  /// Email sudah ada, titik lokasi belum.
  lokasi,

  /// Status non-AKTIF lain (misal transaksi ditutup) — bukan urusan dialog ini.
  none,
}

/// Menerjemahkan status dari server ke [_MissingStoreData].
///
/// Dicocokkan dulu dengan konstanta resmi (`kStatus*BelumTerdaftar` di
/// constants.dart) secara case-insensitive. Bila tidak persis sama, dipakai
/// pencocokan kata kunci sebagai jaring pengaman supaya variasi penulisan dari
/// backend (mis. "Lokasi Toko Belum Terdaftar" vs "Titik Lokasi Toko Belum
/// Terdaftar") tetap terbaca dan dialog tidak berhenti muncul.
_MissingStoreData _classifyMissingStoreData(String status) {
  final normalized = status.trim().toLowerCase();

  if (normalized == kStatusEmailDanLokasiBelumTerdaftar.toLowerCase()) {
    return _MissingStoreData.emailDanLokasi;
  }
  if (normalized == kStatusEmailBelumTerdaftar.toLowerCase()) {
    return _MissingStoreData.email;
  }
  if (normalized == kStatusLokasiBelumTerdaftar.toLowerCase()) {
    return _MissingStoreData.lokasi;
  }

  // Fallback: deteksi berbasis kata kunci.
  if (!normalized.contains('belum terdaftar')) return _MissingStoreData.none;

  final missingEmail = normalized.contains('email');
  final missingLokasi = normalized.contains('lokasi');

  if (missingEmail && missingLokasi) return _MissingStoreData.emailDanLokasi;
  if (missingEmail) return _MissingStoreData.email;
  if (missingLokasi) return _MissingStoreData.lokasi;
  return _MissingStoreData.none;
}

class TaskMaintenanceBodyMobile extends StatefulWidget {
  final Map<String, String?> userData;

  const TaskMaintenanceBodyMobile({super.key, required this.userData});

  @override
  State<TaskMaintenanceBodyMobile> createState() =>
      _TaskMaintenanceBodyMobileState();
}

class _TaskMaintenanceBodyMobileState extends State<TaskMaintenanceBodyMobile> {
  final _storeCodeController = TextEditingController();
  final _transNoController = TextEditingController();
  List<TransactionSuggestion> _apiPendingList = [];

  @override
  void initState() {
    super.initState();
    final maintenanceBy = widget.userData['maintenance_by'] ?? '';
    final createdBy = widget.userData['user_id'] ?? '';

    if (maintenanceBy.isNotEmpty) {
      context
          .read<TaskMaintenanceBloc>()
          .add(FetchPendingTasks(maintenanceBy, createdBy));
    }
  }

  @override
  void dispose() {
    _storeCodeController.dispose();
    _transNoController.dispose();
    super.dispose();
  }

  void process() {
    FocusScope.of(context).unfocus();
    final cleanStoreCode = _storeCodeController.text.trim().toUpperCase();
    final cleanTransNo = _transNoController.text.trim().toUpperCase();

    if (cleanStoreCode.isEmpty) {
      _showSnackBar('Kode Toko tidak boleh kosong!', Colors.red);
      return;
    }

    if (cleanTransNo.isEmpty) {
      _showSnackBar('Nomor transaksi tidak boleh kosong!', Colors.red);
      return;
    }

    context.read<TaskMaintenanceBloc>().add(
          SearchPO(cleanTransNo, widget.userData['maintenance_by']!),
        );
  }

  Future<void> _scanAndProcess() async {
    final String? scannedResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (scannedResult != null && mounted) {
      _transNoController.text = scannedResult;
      // Langsung proses jika QR di-scan
      process();
    }
  }

  void _showPendingValidationDialog({required VoidCallback onProceed}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SalsaPendingDialog(
        transNo: _apiPendingList.first.transNo,
        customerCode: _apiPendingList.first.customerCode,
        customerName: _apiPendingList.first.customerName,
        onUploadPressed: () {
          Navigator.pop(dialogContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<FailedUploadsBloc>(),
                child: FailedUploadsScreen(apiPendingList: _apiPendingList),
              ),
            ),
          );
        },
        onContinuePressed: () {
          Navigator.pop(dialogContext);
          onProceed();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskMaintenanceBloc, TaskMaintenanceState>(
      listener: (context, state) {
        if (state is TaskListLoaded) {
          setState(() {
            _apiPendingList = state.tasks
                .where(
                    (t) => t.status == 'NEED UPLOAD' || t.status == 'PARTIAL')
                .toList();
          });
        } else if (state is POSearchSuccess) {
          _handleSearchSuccess(state);
        } else if (state is POSearchFailure) {
          _showSnackBar(state.message, Colors.red);
        }
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildHeaderTaskMaintenance(
                title: "Welcome to SALSA",
                user: widget.userData['name'] ?? 'Guest',
                company: widget.userData['maintenance_by_name'] ?? 'N/A',
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // 1. Kolom Nomor DO / SC (Sekarang Di Atas)
                    TextField(
                      controller: _transNoController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Masukkan No. Transaksi (SC/DO)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(FontAwesomeIcons.qrcode),
                          onPressed: _scanAndProcess,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase()),
                        ),
                      ],
                      textInputAction: TextInputAction
                          .next, // 🔥 Saat di-enter di keyboard, pindah ke Kode Toko
                    ),
                    const SizedBox(height: 16),

                    // 2. Kolom Kode Toko (Sekarang Di Bawah)
                    TextField(
                      controller: _storeCodeController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Masukkan Kode Toko',
                        prefixIcon: const Icon(Icons.storefront),
                        suffixIcon: const Icon(Icons.storefront, color: Colors.transparent,),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (oldValue, newValue) => newValue.copyWith(
                              text: newValue.text.toUpperCase()),
                        ),
                      ],
                      onSubmitted: (_) => process(),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Proses
                    ElevatedButton(
                      onPressed: () => process(),
                      style: ElevatedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 14),
                      ),
                      child: const Text('Lanjutkan',
                          style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),

                    BlocBuilder<TaskMaintenanceBloc, TaskMaintenanceState>(
                      builder: (context, taskState) {
                        if (taskState is POSearchLoading) {
                          return _buildLoadingCard();
                        }

                        return BlocBuilder<FailedUploadsBloc,
                            FailedUploadsState>(
                          builder: (context, failedState) {
                            final localFailedList =
                                failedState.failedTransactions;
                            int zombieCount = 0;
                            for (var apiTask in _apiPendingList) {
                              bool existsInLocal = localFailedList
                                  .any((t) => t['transNo'] == apiTask.transNo);
                              if (!existsInLocal) zombieCount++;
                            }

                            int normalRetryCount = localFailedList.length;
                            int totalIssues = normalRetryCount + zombieCount;

                            if (totalIssues == 0)
                              return const SizedBox.shrink();

                            bool hasCriticalError = zombieCount > 0;
                            Color boxColor = hasCriticalError
                                ? Colors.red.shade50
                                : Colors.orange.shade50;
                            Color borderColor = hasCriticalError
                                ? Colors.red.shade200
                                : Colors.orange.shade200;
                            Color iconColor = hasCriticalError
                                ? Colors.red
                                : Colors.orange.shade800;
                            Color textColor = hasCriticalError
                                ? Colors.red.shade900
                                : Colors.orange.shade900;

                            return InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<FailedUploadsBloc>(),
                                      child: FailedUploadsScreen(
                                          apiPendingList: _apiPendingList),
                                    ),
                                  ),
                                );
                                context.read<TaskMaintenanceBloc>().add(
                                      FetchPendingTasks(
                                          widget.userData['maintenance_by']!,
                                          widget.userData['user_id']!),
                                    );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Card(
                                color: boxColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: borderColor),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                          hasCriticalError
                                              ? Icons.error_outline
                                              : Icons.sync_problem_outlined,
                                          color: iconColor,
                                          size: 28),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              hasCriticalError
                                                  ? "$totalIssues Transaksi Bermasalah"
                                                  : "$totalIssues Transaksi Perlu Upload",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              hasCriticalError
                                                  ? "$zombieCount Transaksi gagal di proses. Ketuk untuk memproses."
                                                  : "Beberapa foto gagal di-upload. Ketuk untuk memperbaiki.",
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right,
                                          color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearchSuccess(POSearchSuccess state) {
    final rawSuggestions = state.suggestions;
    final enteredStoreCode = _storeCodeController.text.trim().toUpperCase();

    if (rawSuggestions.isEmpty) {
      _showSnackBar('Transaksi tidak ditemukan.', Colors.red);
      return;
    }

    // 🔥 4. CROSS-CHECK KODE TOKO DENGAN DATA API
    final suggestions = rawSuggestions.where((s) {
      return s.customerCode.trim().toUpperCase() == enteredStoreCode;
    }).toList();

    // Jika kosong (artinya ada No. DO, tapi Kode Tokonya Beda), maka di-BLOCK!
    if (suggestions.isEmpty) {
      _showSnackBar('Kode Toko tidak cocok dengan Nomor DO/SC!', Colors.red);
      return;
    }

    // --- MULAI LOGIC ASLI DARI SINI (Menggunakan `suggestions` yang sudah di-filter) ---
    if (suggestions.length == 1) {
      final singleItem = suggestions.first;
      if (singleItem.status.toUpperCase() != 'AKTIF') {
        switch (_classifyMissingStoreData(singleItem.status)) {
          case _MissingStoreData.emailDanLokasi:
            // Belum ada dua-duanya: minta email, titik lokasi diambil sekalian.
            _showUpdateEmailDialog(singleItem, captureLocation: true);
          case _MissingStoreData.email:
            // Titik lokasi sudah terdaftar, cukup lengkapi email.
            _showUpdateEmailDialog(singleItem, captureLocation: false);
          case _MissingStoreData.lokasi:
            // Email sudah terdaftar, cukup ambil titik lokasi.
            _showUpdateLocationDialog(singleItem);
          case _MissingStoreData.none:
            _showSnackBar(singleItem.status, Colors.orange[500]!);
        }
        return;
      }
    }

    final activeSuggestions =
        suggestions.where((s) => s.status.toUpperCase() == 'AKTIF').toList();

    if (activeSuggestions.isEmpty) {
      _showSnackBar('Tidak ada transaksi aktif.', Colors.red);
    } else if (activeSuggestions.length == 1) {
      if (_apiPendingList.isEmpty) {
        _navigateToDetail(activeSuggestions.first);
      } else {
        _showPendingValidationDialog(
            onProceed: () => _navigateToDetail(activeSuggestions.first));
      }
    } else {
      _showSuggestionDialog(activeSuggestions);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuggestionDialog(List<TransactionSuggestion> suggestions) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Pilih Transaksi",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Ditemukan beberapa transaksi yang cocok:",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];
                    final bool isServiceCall =
                        suggestion.type == 'service_call';

                    return Card(
                      elevation: 1,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              (isServiceCall ? Colors.orange : Colors.blue)
                                  .withOpacity(0.1),
                          child: Icon(
                            isServiceCall
                                ? Icons.build_circle_outlined
                                : Icons.wash_outlined,
                            color: isServiceCall
                                ? Colors.orange.shade700
                                : Colors.blue.shade700,
                          ),
                        ),
                        title: Text(suggestion.transNo,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(suggestion.customerName),
                        onTap: () {
                          Navigator.pop(context);
                          if (_apiPendingList.isEmpty) {
                            _navigateToDetail(suggestion);
                          } else {
                            _showPendingValidationDialog(
                                onProceed: () => _navigateToDetail(suggestion));
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(TransactionSuggestion suggestion) {
    _transNoController.text = suggestion.transNo;
    Widget? destinationScreen;

    if (suggestion.type == 'SERVICE') {
      destinationScreen = ServiceCallDetailScreen(
        transNo: suggestion.transNo,
        maintenanceBy: widget.userData['maintenance_by']!,
      );
    } else if (suggestion.type == 'CUCI') {
      destinationScreen =
          ProofOfServiceDetailScreen(transNo: suggestion.transNo);
    } else if (suggestion.type == 'INSTALLATION') {
      destinationScreen = InstallationDetailScreen(
        transNo: suggestion.transNo,
        vendorId: widget.userData['maintenance_by']!,
      );
    } else if (suggestion.type == 'RRO') {
      destinationScreen = RROCutOffDetailScreen(
        transNo: suggestion.transNo,
        vendorId: widget.userData['maintenance_by']!,
      );
    } else if (suggestion.type == 'CUCI_FREEZER') {
      destinationScreen =
          ProofOfServiceFreezerDetailScreen(transNo: suggestion.transNo);
    } else if (suggestion.type == 'SERVICE_FREEZER') {
      destinationScreen = ScfDetailScreen(
        transNo: suggestion.transNo,
        vendorId: widget.userData['maintenance_by'] ?? '',
      );
    } else {
      _showSnackBar(
          "Tipe transaksi tidak dikenali: ${suggestion.type}", Colors.red);
      return;
    }

    Navigator.push(
            context, MaterialPageRoute(builder: (_) => destinationScreen!))
        .then((_) {
      if (widget.userData['maintenance_by'] != null) {
        context.read<TaskMaintenanceBloc>().add(FetchPendingTasks(
            widget.userData['maintenance_by']!,
            widget.userData['user_id'] ?? ''));
      }
      context.read<FailedUploadsBloc>().add(LoadFailedUploads());
    });
  }

  /// Dialog pengkinian EMAIL toko.
  ///
  /// Dipakai untuk dua kondisi:
  /// - [captureLocation] `false` → titik lokasi toko sudah terdaftar, yang
  ///   dikirim ke server hanya email.
  /// - [captureLocation] `true`  → email dan titik lokasi sama-sama belum ada,
  ///   jadi koordinat ikut diambil otomatis saat tombol Simpan ditekan.
  Future<void> _showUpdateEmailDialog(
    TransactionSuggestion suggestion, {
    required bool captureLocation,
  }) async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final String dynamicDomain = suggestion.domainMail ?? "@STORE.SAT.CO.ID";

    final String infoText = captureLocation
        ? "Email dan Titik Lokasi untuk toko \"${suggestion.customerName}\" belum terdaftar.\n\nSilahkan tanyakan Email Toko kepada Pejabat Toko, lalu masukan USERNAME email saja (tanpa @STORE....) untuk proses pengkinian data.\n\nTitik lokasi toko akan ikut terekam otomatis dari posisi Anda. Pastikan berada ditoko saat akan memproses data."
        : "Email untuk toko \"${suggestion.customerName}\" belum terdaftar. Titik lokasi toko sudah terdaftar sebelumnya.\n\nSilahkan tanyakan Email Toko kepada Pejabat Toko, lalu masukan USERNAME email saja (tanpa @STORE....) untuk proses pengkinian data.";

    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return _buildUpdateDialogShell(
              formKey: formKey,
              icon: Icons.store_mall_directory_rounded,
              title: captureLocation ? "Update Data Toko" : "Update Email Toko",
              infoTitle: "Data Belum Lengkap",
              infoText: infoText,
              errorMessage: errorMessage,
              isLoading: isLoading,
              confirmLabel: "Simpan & Lanjut",
              onCancel: () => Navigator.pop(dialogContext),
              onConfirm: () async {
                if (!formKey.currentState!.validate()) return;

                setStateDialog(() {
                  isLoading = true;
                  errorMessage = null;
                });
                try {
                  // Koordinat hanya diambil bila titik lokasi memang belum ada.
                  final pos = captureLocation ? await _getCurrentLocation() : null;
                  final rawUsername =
                      emailController.text.trim().toUpperCase();
                  final finalEmail = "$rawUsername$dynamicDomain";

                  await _callUpdateApi(
                    updatedBy: widget.userData['user_id']!,
                    customerCode: suggestion.customerCode,
                    email: finalEmail,
                    latitude: pos?.latitude,
                    longitude: pos?.longitude,
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _navigateToDetail(suggestion);
                  }
                } catch (e) {
                  setStateDialog(
                      () => errorMessage = "Gagal update: ${_readableError(e)}");
                } finally {
                  if (mounted) {
                    setStateDialog(() => isLoading = false);
                  }
                }
              },
              field: TextFormField(
                controller: emailController,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) =>
                      newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection)),
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Username Email Toko',
                  hintText: 'CONTOH: SATBABAKAN.MLG',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixText: dynamicDomain,
                  suffixStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Username email wajib diisi';
                  }
                  if (val.contains('@')) {
                    return 'Cukup masukkan username, hapus tanda @';
                  }
                  return null;
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Dialog pengkinian TITIK LOKASI toko (email toko sudah terdaftar).
  /// Tidak ada input yang perlu diisi — teknisi cukup memastikan dirinya
  /// sedang berada di toko, koordinat diambil dari GPS saat tombol ditekan.
  Future<void> _showUpdateLocationDialog(
      TransactionSuggestion suggestion) async {
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return _buildUpdateDialogShell(
              icon: Icons.location_on_rounded,
              title: "Update Titik Lokasi Toko",
              infoTitle: "Titik Lokasi Belum Terdaftar",
              infoText:
                  "Titik lokasi untuk toko \"${suggestion.customerName}\" belum terdaftar. Email toko sudah terdaftar sebelumnya.\n\nTitik lokasi akan diambil dari posisi Anda saat ini. PASTIKAN ANDA BERADA DI DALAM/DEPAN TOKO dan GPS aktif sebelum menekan tombol di bawah.",
              errorMessage: errorMessage,
              isLoading: isLoading,
              confirmLabel: "Ambil Titik & Lanjut",
              onCancel: () => Navigator.pop(dialogContext),
              onConfirm: () async {
                setStateDialog(() {
                  isLoading = true;
                  errorMessage = null;
                });
                try {
                  final pos = await _getCurrentLocation();

                  // Email tidak dikirim (null) supaya email lama tidak tertimpa.
                  await _callUpdateApi(
                    updatedBy: widget.userData['user_id']!,
                    customerCode: suggestion.customerCode,
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                  );

                  if (mounted) {
                    Navigator.pop(dialogContext);
                    _navigateToDetail(suggestion);
                  }
                } catch (e) {
                  setStateDialog(
                      () => errorMessage = "Gagal update: ${_readableError(e)}");
                } finally {
                  if (mounted) {
                    setStateDialog(() => isLoading = false);
                  }
                }
              },
            );
          },
        );
      },
    );
  }

  /// Kerangka visual bersama dialog pengkinian data toko (email & titik lokasi),
  /// supaya kedua dialog tampil konsisten. [field] opsional — dialog titik
  /// lokasi tidak punya input apa pun.
  Widget _buildUpdateDialogShell({
    GlobalKey<FormState>? formKey,
    required IconData icon,
    required String title,
    required String infoTitle,
    required String infoText,
    required String? errorMessage,
    required bool isLoading,
    required String confirmLabel,
    required VoidCallback onCancel,
    required Future<void> Function() onConfirm,
    Widget? field,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: Colors.blue.shade700),
          ),
        ),
        const SizedBox(height: 16),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: Colors.orange.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(infoTitle,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                infoText,
                style: const TextStyle(
                    fontSize: 13, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
        ),
        if (field != null) ...[
          const SizedBox(height: 20),
          field,
        ],
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(errorMessage,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12))),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: Text(confirmLabel),
                ),
              ),
            ],
          ),
      ],
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: formKey == null
              ? content
              : Form(key: formKey, child: content),
        ),
      ),
    );
  }

  /// Buang prefix "Exception: " supaya pesan error enak dibaca teknisi.
  String _readableError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  Future<Position> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception(
          'Gagal mendeteksi lokasi. Pastikan GPS aktif, lalu coba lagi di area terbuka.');
    }
  }

  Future<void> _callUpdateApi({
    required String updatedBy,
    required String customerCode,
    String? email,
    double? latitude,
    double? longitude,
  }) async {
    final repository = TaskMaintenanceRepository();
    await repository.updateStoreInfo(
        updatedBy: updatedBy,
        customerCode: customerCode,
        email: email,
        latitude: latitude,
        longitude: longitude);
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(
                      width: 120,
                      height: 10,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
