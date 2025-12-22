import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salsa/screens/task_maintenance/components/widget/task_maintenance_widgets.dart';
import '../../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_event.dart';
import '../../../blocs/task_maintenance/task_maintenance_repository.dart';
import '../../../blocs/task_maintenance/task_maintenance_state.dart';
import '../../../components/widgets/salsa_pending_dialog.dart';
import '../../../components/widgets/scan_qr.dart';
import '../../../models/task_maintenance/task_maintenance_model.dart';
import '../../common/failed_uploads/failed_uploads_screen.dart';
import '../../proof_of_service/proof_of_service_detail/proof_of_service_detail_screen.dart';
import '../../service_call/service_call_detail/service_call_detail_screen.dart';

class TaskMaintenanceBodyMobile extends StatefulWidget {
  final Map<String, String?> userData;

  const TaskMaintenanceBodyMobile({super.key, required this.userData});

  @override
  State<TaskMaintenanceBodyMobile> createState() =>
      _TaskMaintenanceBodyMobileState();
}

class _TaskMaintenanceBodyMobileState extends State<TaskMaintenanceBodyMobile> {
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
    _transNoController.dispose();
    super.dispose();
  }

  void process(String transNo) {
    FocusScope.of(context).unfocus();
    final cleanTransNo = transNo.trim().toUpperCase();
    if (cleanTransNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nomor transaksi tidak boleh kosong!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    context.read<TaskMaintenanceBloc>().add(
          SearchPO(transNo, widget.userData['maintenance_by']!),
        );
  }

  Future<void> _scanAndProcess() async {
    final String? scannedResult = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (scannedResult != null && mounted) {
      _transNoController.text = scannedResult;
      process(scannedResult);
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
          onProceed(); // Jalankan fungsi navigasi yang diinginkan
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskMaintenanceBloc, TaskMaintenanceState>(
      listener: (context, state) {
        // 🔥 2. DENGARKAN HASIL API LIST
        if (state is TaskListLoaded) {
          setState(() {
            // Filter hanya yang statusnya butuh upload
            _apiPendingList = state.tasks
                .where(
                    (t) => t.status == 'NEED UPLOAD' || t.status == 'PARTIAL')
                .toList();
          });
        }
        // Listener Search Existing
        else if (state is POSearchSuccess) {
          _handleSearchSuccess(state);
        } else if (state is POSearchFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating),
          );
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
                    // Search Bar
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
                      onSubmitted: (value) => process(value),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Proses
                    ElevatedButton(
                      onPressed: () => process(_transNoController.text),
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
                        // KONDISI 1: JIKA LOADING API -> TAMPILKAN SHIMMER
                        if (taskState is POSearchLoading) {
                          return _buildLoadingCard(); // Panggil Method Shimmer
                        }

                        // KONDISI 2: JIKA SUDAH LOADED -> TAMPILKAN BOX (MERAH/KUNING)
                        return BlocBuilder<FailedUploadsBloc,
                            FailedUploadsState>(
                          builder: (context, failedState) {
                            // A. Data Lokal (Hive)
                            final localFailedList =
                                failedState.failedTransactions;

                            // B. Data Server (API) - Diambil dari variabel _apiPendingList

                            // C. Hitung ZOMBIE (Ada di API, Gak ada di Hive)
                            int zombieCount = 0;
                            for (var apiTask in _apiPendingList) {
                              bool existsInLocal = localFailedList
                                  .any((t) => t['transNo'] == apiTask.transNo);
                              if (!existsInLocal) {
                                zombieCount++;
                              }
                            }

                            // D. Total Masalah
                            int normalRetryCount = localFailedList.length;
                            int totalIssues = normalRetryCount + zombieCount;

                            if (totalIssues == 0) {
                              return const SizedBox.shrink(); // Bersih
                            }

                            // E. Tentukan Warna
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
                                        apiPendingList: _apiPendingList,
                                      ),
                                    ),
                                  ),
                                );

                                context.read<TaskMaintenanceBloc>().add(
                                  FetchPendingTasks(widget.userData['maintenance_by']!, widget.userData['user_id']!),
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
                                                  ? "$zombieCount Transaksi gagal di proses. Ketuk untuk memprosesr."
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
    final suggestions = state.suggestions;

    // 1. Validasi awal (Kosong atau status tidak AKTIF)
    if (suggestions.isEmpty) {
      _showSnackBar('Transaksi tidak ditemukan.', Colors.red);
      return;
    }

    if (suggestions.length == 1) {
      final singleItem = suggestions.first;
      if (singleItem.status.toUpperCase() != 'AKTIF') {
        if (singleItem.status == "Email & Lokasi Toko Belum Terdaftar") {
          _showUpdateInfoDialog(singleItem);
        } else {
          _showSnackBar(singleItem.status, Colors.orange[500]!);
        }
        return;
      }
    }

    // 2. Filter data yang AKTIF
    final activeSuggestions =
        suggestions.where((s) => s.status.toUpperCase() == 'AKTIF').toList();

    // 3. Logika Penentuan Aksi
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
      // Jika lebih dari 1 hasil aktif, tampilkan pilihan seperti biasa
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
    // Logic dialog sugesti lama Akang
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
                    borderRadius: BorderRadius.circular(2),
                  ),
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
    } else if (suggestion.type == 'PASANG') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Modul Pasang AC segera hadir!")),
      );
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Tipe transaksi tidak dikenali: ${suggestion.type}")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destinationScreen!),
    ).then((_) {
      if (widget.userData['maintenance_by'] != null) {
        context.read<TaskMaintenanceBloc>().add(
            FetchPendingTasks(
                widget.userData['maintenance_by']!,
                widget.userData['user_id'] ?? ''
            )
        );
      }

      context.read<FailedUploadsBloc>().add(LoadFailedUploads());

      print('✅ Kembali ke Task Maintenance: Data API & Local di refresh.');
    });
  }

  Future<void> _showUpdateInfoDialog(TransactionSuggestion suggestion) async {
    // ... Logic update info toko Akang (tetap sama) ...
    // Placeholder function call untuk mempersingkat chat, gunakan yang lama.
    // Tapi karena sudah ada di file paste Akang sebelumnya, bisa dipertahankan.
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Update Info Toko'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Email dan lokasi untuk toko "${suggestion.customerName}" belum terdaftar.'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (val) => val!.isEmpty ? 'Isi email' : null,
                      ),
                      if (isLoading)
                        const CircularProgressIndicator()
                      else if (errorMessage != null)
                        Text(errorMessage!, style: TextStyle(color: Colors.red))
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("Batal")),
                ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setStateDialog(() => isLoading = true);
                        try {
                          final pos = await _getCurrentLocation();
                          await _callUpdateApi(
                              widget.userData['user_id']!,
                              suggestion.customerCode,
                              emailController.text,
                              pos.latitude,
                              pos.longitude);
                          Navigator.pop(dialogContext);
                          _navigateToDetail(suggestion);
                        } catch (e) {
                          setStateDialog(() => errorMessage = e.toString());
                        } finally {
                          setStateDialog(() => isLoading = false);
                        }
                      }
                    },
                    child: const Text("Update"))
              ],
            );
          });
        });
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator
        .getCurrentPosition(); // Simplified for brevity, use your full logic
  }

  Future<void> _callUpdateApi(String updatedBy, String customerCode,
      String email, double latitude, double longitude) async {
    final repository = TaskMaintenanceRepository();
    await repository.updateStoreInfo(
        updatedBy: updatedBy,
        customerCode: customerCode,
        email: email,
        latitude: latitude,
        longitude: longitude);
  }

  // 🔥 WIDGET SHIMMER / SKELETON LOADING
  Widget _buildLoadingCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
            ),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
