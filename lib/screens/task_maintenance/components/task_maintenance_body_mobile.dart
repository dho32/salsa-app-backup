import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:salsa/screens/task_maintenance/components/widget/task_maintenance_widgets.dart';

import '../../../blocs/task_maintenance/task_maintenance_bloc.dart';
import '../../../blocs/task_maintenance/task_maintenance_event.dart';
import '../../../blocs/task_maintenance/task_maintenance_state.dart';
import '../../../components/widgets/scan_qr.dart';
import '../../../models/task_maintenance/task_maintenance_model.dart';
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
    if (transNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor transaksi tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(content: Text('Format nomor transaksi tidak dikenali.')),
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: IntrinsicHeight(
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(suggestions.first.status),
                              backgroundColor: Colors.orange[500],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // KONDISI 2: Navigasi langsung (1 hasil aktif & cocok persis)
                        if (suggestions.length == 1 &&
                            suggestions.first.transNo.trim().toUpperCase() ==
                                userInput.toUpperCase()) {
                          _navigateToDetail(suggestions.first);
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
                              backgroundColor: Colors.red),
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
    // Sesuaikan 'service_call' dengan nilai `type` dari API Anda
    if (suggestion.type == 'service_call') {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceCallDetailScreen(
              transNo: suggestion.transNo,
              maintenanceBy: widget.userData['maintenance_by']!,
            ),
          ));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProofOfServiceDetailScreen(transNo: suggestion.transNo),
          ));
    }
  }
}
