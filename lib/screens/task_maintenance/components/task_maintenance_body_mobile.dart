import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salsa/screens/task_maintenance/components/widget/task_maintenance_widgets.dart';

import '../../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../blocs/failed_uploads/failed_uploads_event.dart';
import '../../../blocs/failed_uploads/failed_uploads_state.dart';
import '../../../blocs/task_maintenance/task_maintenance_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_event.dart';
import '../../../blocs/task_maintenance/task_maintenance_repository.dart';
import '../../../blocs/task_maintenance/task_maintenance_state.dart';
import '../../../components/constants.dart';
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _transNoController.dispose();
    super.dispose();
  }

  void process(String transNo) {
    FocusScope.of(context).unfocus();
    if (transNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nomor transaksi tidak boleh kosong!'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // Logika untuk mendeteksi tipe transaksi
    late MaintenanceType taskType;
    if (transNo.toUpperCase().contains('SC')) {
      taskType = MaintenanceType.service;
    } else if (transNo.toUpperCase().contains('PO') ||
        transNo.toUpperCase().contains('SRO')) {
      taskType = MaintenanceType.cuci;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Format nomor transaksi tidak dikenali.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    context.read<TaskMaintenanceBloc>().add(
          SearchPO(transNo, widget.userData['maintenance_by']!, taskType),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Section Header: Informasi Maintenance & Waktu ---
            buildHeaderTaskMaintenance(
              title: "Welcome to SALSA",
              user: widget.userData['name'] ?? 'Guest',
              company: widget.userData['maintenance_by_name'] ?? 'N/A',
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Search Bar Universal
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
                    child:
                        const Text('Lanjutkan', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),

                  BlocBuilder<FailedUploadsBloc, FailedUploadsState>(
                    builder: (context, state) {
                      if (state.failedTransactions.isEmpty) {
                        return const SizedBox.shrink(); // Tampilkan kosong jika tidak ada error
                      }
                      final count = state.failedTransactions.length;
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<FailedUploadsBloc>(),
                                child: FailedUploadsScreen(),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          color: Colors.orange.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.orange.shade200),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(Icons.sync_problem_outlined, color: Colors.orange.shade800, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "$count transaksi butuh perhatian",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade900
                                        ),
                                      ),
                                      const Text(
                                        "Beberapa foto gagal di-upload. Ketuk untuk memperbaiki.",
                                        style: TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Indikator loading dari BLoC
                  BlocListener<TaskMaintenanceBloc, POSearchState>(
                    listener: (context, state) {
                      if (state is POSearchSuccess) {
                        final suggestions = state.suggestions;
                        final userInput = _transNoController.text.trim();

                        if (suggestions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                  'Transaksi tidak ditemukan.',
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating),
                          );
                          return;
                        }

                        // KONDISI 1: Hanya ada 1 hasil DAN itu sudah selesai
                        if (suggestions.length == 1 &&
                            suggestions.first.status.toUpperCase() != 'AKTIF') {
                          final suggestion = suggestions.first;
                          if (suggestion.status == "Email & Lokasi Toko Belum Terdaftar") {
                            // Tampilkan dialog update
                            _showUpdateInfoDialog(suggestion);
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(suggestions.first.status),
                                backgroundColor: Colors.orange[500],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }

                        // KONDISI 2: Navigasi langsung (1 hasil aktif & cocok persis)
                        if (suggestions.length == 1 &&
                            suggestions.first.transNo.trim().toUpperCase() ==
                                userInput.toUpperCase()) {

                          final suggestion = suggestions.first;
                          _navigateToDetail(suggestion);
                        }
                        // KONDISI 3: Tampilkan dialog sugesti (lebih dari 1 hasil, atau 1 hasil tapi tidak cocok persis)
                        else {
                          // Saring dulu untuk hanya menampilkan yang aktif
                          final activeSuggestions = suggestions
                              .where((s) => s.status.toUpperCase() == 'AKTIF')
                              .toList();
                          if (activeSuggestions.isNotEmpty) {
                            _showSuggestionDialog(activeSuggestions);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Tidak ada transaksi.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      } else if (state is POSearchFailure) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(state.message),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    child: BlocBuilder<TaskMaintenanceBloc, POSearchState>(
                      builder: (context, state) {
                        if (state is POSearchLoading) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              // --- Header Dialog ---
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

              // --- Daftar Sugesti ---
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
                          _navigateToDetail(suggestion);
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
    // Tentukan halaman tujuan
    final Widget destinationScreen = suggestion.type == 'service_call'
        ? ServiceCallDetailScreen(
      transNo: suggestion.transNo,
      maintenanceBy: widget.userData['maintenance_by']!,
    )
        : ProofOfServiceDetailScreen(transNo: suggestion.transNo);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destinationScreen),
    ).then((_) {
      print('✅ Kembali ke Task Maintenance, memuat ulang daftar gagal...');
      context.read<FailedUploadsBloc>().add(LoadFailedUploads());
    });
  }

  Future<void> _showUpdateInfoDialog(TransactionSuggestion suggestion) async {
    final emailController = TextEditingController();
    // Gunakan GlobalKey untuk mengakses FormState jika perlu validasi email
    final formKey = GlobalKey<FormState>();
    bool isLoading = false; // State lokal untuk loading di dalam dialog
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false, // User harus berinteraksi
      builder: (dialogContext) {
        // StatefulBuilder agar bisa update loading di dalam dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Update Info Toko'),
              content: SingleChildScrollView( // Agar tidak overflow jika keyboard muncul
                child: Form( // Bungkus dengan Form
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Email dan lokasi untuk toko "${suggestion.customerName}" (${suggestion.customerCode}) belum terdaftar.'),
                      const SizedBox(height: 16),
                      const Text(kStringDialogUpdateLocation),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Toko',
                          hintText: 'contoh@email.com',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) { // Contoh validasi email sederhana
                          if (value == null || value.isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (errorMessage != null) {
                            setStateDialog(() => errorMessage = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      // Tampilkan loading jika sedang proses
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),

                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                // Tombol Batal (nonaktif jika loading)
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                // Tombol Update (nonaktif jika loading)
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    // Validasi form dulu
                    if (formKey.currentState?.validate() ?? false) {
                      setStateDialog(() => isLoading = true); // Mulai loading
                      try {
                        // 1. Ambil Lokasi
                        final position = await _getCurrentLocation();

                        // 2. Panggil API Update (buat fungsi helper)
                        await _callUpdateApi(
                          widget.userData['user_id'] ?? '',
                          suggestion.customerCode,
                          emailController.text,
                          position.latitude,
                          position.longitude,
                        );

                        // 3. Jika Sukses: Tutup dialog & Navigasi
                        if (mounted) {
                          Navigator.of(dialogContext).pop(); // Tutup dialog update
                          _navigateToDetail(suggestion); // Lanjutkan navigasi
                        }

                      } catch (e) {
                        // 4. Jika Gagal: Tampilkan error
                        if (mounted) {
                          final String displayError = e.toString().replaceFirst("Exception: ", "");
                          if (mounted) {
                            // Set state DI DALAM dialog untuk menampilkan error
                            setStateDialog(() => errorMessage = displayError);
                          }
                        }
                      } finally {
                        // Pastikan loading berhenti
                        if (mounted) {
                          setStateDialog(() => isLoading = false);
                        }
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      // Opsional: Buka pengaturan aplikasi
      // await openAppSettings();
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      // Tingkatkan akurasi dan tambahkan timeout
      return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
      );
    } on TimeoutException {
      print("🔴 [Location] TimeoutException"); // Log timeout
      return Future.error('Gagal mendapatkan lokasi: Waktu habis. Coba lagi.');
    } catch (e) {
      print("🔴 [Location] Other Exception: ${e.toString()}"); // Log error lain
      return Future.error('Gagal mendapatkan lokasi: ${e.toString()}');
    }
  }

  Future<void> _callUpdateApi(
      String updatedBy,
      String customerCode,
      String email,
      double latitude,
      double longitude
      ) async {
    // Buat instance dari repository Anda
    final repository = TaskMaintenanceRepository();

    try {
      // Panggil method baru yang ada di repository
      await repository.updateStoreInfo(
        updatedBy: updatedBy,
        customerCode: customerCode,
        email: email,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      throw Exception(e.toString()); // Lempar pesan error asli
    }
  }
}
