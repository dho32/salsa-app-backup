// lib/screens/service_call/service_call_detail/components/service_call_detail_body_mobile.dart

import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// --- Impor BLoC & State yang relevan ---
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/service_call/sc_form/sc_form_cubit.dart';
import '../../../../blocs/service_call/sc_form/sc_form_state.dart';
import '../../../../blocs/service_call/service_call_detail/service_call_detail_bloc.dart';
import '../../../../blocs/service_call/service_call_detail/service_call_detail_state.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_bloc.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
// ---

import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart'; // Untuk MeasurementLimits
import '../../../../models/service_call/problem_source_model.dart';
import '../../../../models/service_call/service_call_detail_model.dart'; // Untuk Header & Detail
import '../../../../models/service_call/service_call_validation_entry_model.dart';
import '../../../../models/service_call/transaction_info_model.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../service_call_validation/components/remote_validation/remote_validation_screen.dart';
import '../../service_call_validation/service_call_validation_screen.dart';

class ServiceCallDetailBodyMobile extends StatefulWidget {
  final String transNo;
  final Box<TransactionInfoModel>
      transactionInfoBox; // Mungkin tidak lagi dipakai

  const ServiceCallDetailBodyMobile({
    super.key,
    required this.transNo,
    required this.transactionInfoBox,
  });

  @override
  State<ServiceCallDetailBodyMobile> createState() =>
      _ServiceCallDetailBodyMobileState();
}

class _ServiceCallDetailBodyMobileState
    extends State<ServiceCallDetailBodyMobile> {
  // --- Kelola Semua Controller di Sini ---
  late final TextEditingController _picNameController;
  late final TextEditingController _picPhoneController;
  late final TextEditingController _picNikController;
  late final TextEditingController _picPositionController;
  late final TextEditingController _technician1Controller;
  late final TextEditingController _technician2Controller;
  late final TextEditingController _technician3Controller;
  late final TextEditingController _finalTempController;

  bool _showTechnician3 = false;
  Future<Map<String, ValidationStatus>>? _validationStatusFuture;
  String technicianName = '';
  String maintenanceBy = '';
  String maintenanceByIP = '';
  bool _isTakingPicPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndIP();

    final initialFormState = context.read<ScFormCubit>().state;

    // Inisialisasi controller dari state Cubit
    _picNameController = TextEditingController(text: initialFormState.picName);
    _picPhoneController =
        TextEditingController(text: initialFormState.picPhone);
    _picNikController = TextEditingController(text: initialFormState.picNik);
    _picPositionController =
        TextEditingController(text: initialFormState.picPosition);
    _technician1Controller =
        TextEditingController(); // Diisi oleh _loadUserInfo
    _technician2Controller =
        TextEditingController(text: initialFormState.technician2);
    _technician3Controller =
        TextEditingController(text: initialFormState.technician3);
    _finalTempController =
        TextEditingController(text: initialFormState.finalTempIn);

    _showTechnician3 = initialFormState.showTechnician3;

    // Tambahkan Listener UI -> Cubit
    _addListeners();
  }

  void _addListeners() {
    final formCubit = context.read<ScFormCubit>();
    _picNameController.addListener(() {
      if (formCubit.state.picName != _picNameController.text) {
        formCubit.picNameChanged(_picNameController.text);
        formCubit.onFieldChanged();
      }
    });
    _picPhoneController.addListener(() {
      if (formCubit.state.picPhone != _picPhoneController.text) {
        formCubit.picPhoneChanged(_picPhoneController.text);
        formCubit.onFieldChanged();
      }
    });
    _picNikController.addListener(() {
      if (formCubit.state.picNik != _picNikController.text) {
        formCubit.picNikChanged(_picNikController.text);
        formCubit.onFieldChanged();
      }
    });
    _picPositionController.addListener(() {
      if (formCubit.state.picPosition != _picPositionController.text) {
        formCubit.picPositionChanged(_picPositionController.text);
        formCubit.onFieldChanged();
      }
    });
    _technician2Controller.addListener(() {
      if (formCubit.state.technician2 != _technician2Controller.text) {
        formCubit.technician2Changed(_technician2Controller.text);
        formCubit.onFieldChanged();
      }
    });
    _technician3Controller.addListener(() {
      if (formCubit.state.technician3 != _technician3Controller.text) {
        formCubit.technician3Changed(_technician3Controller.text);
        formCubit.onFieldChanged();
      }
    });
  }

  @override
  void dispose() {
    _picNameController.dispose();
    _picPhoneController.dispose();
    _picNikController.dispose();
    _picPositionController.dispose();
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _finalTempController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfoAndIP() async {
    final user = await AuthStorage.getUser();
    final ip = await getPublicIpAddress();
    if (mounted) {
      setState(() {
        technicianName = user['name'] ?? '';
        maintenanceBy = user['user_id'] ?? '';
        _technician1Controller.text = technicianName;
        maintenanceByIP = ip;
      });
    }
  }

  Future<Map<String, ValidationStatus>> _loadValidationStatuses(
      String transNo) async {
    try {
      // <-- Tambahkan try-catch di sini
      final box =
          Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final statuses = <String, ValidationStatus>{};
      final entries = box.values.where((e) => e.transNo == transNo);

      for (final entry in entries) {
        final serial = entry.serialNo.trim().toUpperCase();
        statuses[serial] = entry.isCompleted
            ? ValidationStatus.completed
            : ValidationStatus.inProgress;
      }
      print(
          "✅ Selesai _loadValidationStatuses. Ditemukan ${statuses.length} status."); // Log Sukses
      return statuses;
    } catch (e) {
      print("🔴 ERROR di _loadValidationStatuses: $e"); // Log Error
      // Jika gagal, kembalikan map kosong agar FutureBuilder tidak macet
      return {};
    }
  }

  void _refreshSerials() {
    final blocState = context.read<ServiceCallDetailBloc>().state;
    if (blocState is ServiceCallDetailLoaded) {
      // Panggil _loadValidationStatuses dan TANGANI hasilnya
      _loadValidationStatuses(blocState.data.header.transNo).then((statuses) {
        // Hanya panggil setState jika widget masih ada
        if (mounted) {
          // Kita tidak perlu menyimpan Future lagi, langsung update UI jika perlu
          // atau trigger BLoC jika state bergantung pada status ini.
          // Untuk sekarang, kita anggap FutureBuilder akan menangani tampilan status.
          // Cukup pastikan future-nya dipanggil.
          setState(() {
            // Jika Anda masih pakai FutureBuilder, update future nya di sini
            _validationStatusFuture = Future.value(statuses);
          });
          print("🔄 Status validasi di-refresh di UI.");
        }
      }).catchError((error) {
        print("🔴 Gagal me-refresh status validasi: $error");
        if (mounted) {
          // Opsional: Tampilkan SnackBar error
          _showValidationSnackbar(
              context, "Gagal memuat status validasi unit.");
          setState(() {
            _validationStatusFuture =
                Future.value({}); // Beri nilai default jika error
          });
        }
      });
    } else {
      print("ℹ️ _refreshSerials dipanggil TAPI detailState bukan Loaded.");
      // Set future ke nilai default agar FutureBuilder tidak loading terus
      if (mounted) {
        setState(() {
          _validationStatusFuture = Future.value({});
        });
      }
    }
  }

  bool _hasRetryUploadState(ServiceCallSubmittedState state) {
    return state is ValidationUploadPartial &&
        state.transNo == widget.transNo &&
        state.failedFiles.isNotEmpty;
  }

  // --- BUILD METHOD UTAMA ---
  @override
  Widget build(BuildContext context) {
    return BlocListener<ScFormCubit, ScFormState>(
      listenWhen: (prev, current) =>
          prev.picName != current.picName ||
          prev.picPhone != current.picPhone ||
          prev.picNik != current.picNik ||
          prev.picPosition != current.picPosition ||
          prev.technician2 != current.technician2 ||
          prev.technician3 != current.technician3 ||
          prev.finalTempIn != current.finalTempIn ||
          prev.showTechnician3 != current.showTechnician3,
      listener: (context, state) {
        if (_picNameController.text != state.picName) {
          _picNameController.text = state.picName;
        }
        if (_picPhoneController.text != state.picPhone) {
          _picPhoneController.text = state.picPhone;
        }
        if (_picNikController.text != state.picNik) {
          _picNikController.text = state.picNik;
        }
        if (_picPositionController.text != state.picPosition) {
          _picPositionController.text = state.picPosition;
        }
        if (_technician2Controller.text != state.technician2) {
          _technician2Controller.text = state.technician2;
        }
        if (_technician3Controller.text != state.technician3) {
          _technician3Controller.text = state.technician3;
        }
        if (_finalTempController.text != state.finalTempIn) {
          _finalTempController.text = state.finalTempIn;
        }
        if (_showTechnician3 != state.showTechnician3) {
          setState(() => _showTechnician3 = state.showTechnician3);
        }
      },
      child: BlocConsumer<ServiceCallDetailBloc, ServiceCallDetailState>(
        listener: (context, detailState) {
          // Panggil _refreshSerials SETELAH data detail berhasil dimuat
          if (detailState is ServiceCallDetailLoaded) {
            print(
                "🚀 ServiceCallDetailBloc Loaded. Memanggil _refreshSerials...");
            _refreshSerials();
          } else if (detailState is ServiceCallDetailError) {
            print("🔴 ServiceCallDetailBloc Error: ${detailState.message}");
            // Set future ke nilai default agar FutureBuilder tidak loading terus
            if (mounted) {
              setState(() {
                _validationStatusFuture = Future.value({});
              });
            }
          }
        },
        builder: (context, detailState) {
          if (detailState is ServiceCallDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (detailState is ServiceCallDetailError) {
            return Center(child: Text("Error: ${detailState.message}"));
          } else if (detailState is ServiceCallDetailLoaded) {
            final header = detailState.data.header;
            final detailList = detailState.data.detail;

            return BlocBuilder<ScFormCubit, ScFormState>(
              builder: (context, formState) {
                if (_validationStatusFuture == null) {
                  return const Center(
                      child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.orange)));
                }
                return FutureBuilder<Map<String, ValidationStatus>>(
                  future: _validationStatusFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.green)));
                    }

                    if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              "Error memuat status unit: ${snapshot.error}"));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final validationStatuses = snapshot.data ?? {};
                    final stateUpload =
                        context.watch<ServiceCallSubmittedBloc>().state;

                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 65.0),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 35),
                            child: Column(
                              children: [
                                _buildCustomerSection(header),
                                _buildSection(
                                    title: 'Tiket Service Call',
                                    child: _buildTicketSection(header)),
                                _buildPicPanel(context, formState),
                                _buildSection(
                                    title: 'Teknisi Bertugas',
                                    child: _buildTechnicianPanel(
                                        context, formState)),
                                _buildSection(
                                  title: 'Validasi Unit',
                                  child: Column(
                                    children: [
                                      _buildScanQRButton(context, detailState),
                                      const SizedBox(height: 8),
                                      ...detailList.map((item) =>
                                          _buildDetailCard(header, item,
                                              validationStatuses)),
                                    ],
                                  ),
                                ),
                                // Widget Suhu Akhir (Kondisional)
                                BlocBuilder<ScFormCubit, ScFormState>(
                                  buildWhen: (prev, current) =>
                                      prev.allUnitsValidated !=
                                      current.allUnitsValidated,
                                  builder: (context, formStateForTemp) {
                                    final bool isEnabled =
                                        formStateForTemp.allUnitsValidated;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Stack(
                                        children: [
                                          Opacity(
                                            opacity: isEnabled ? 1.0 : 0.5,
                                            child: AbsorbPointer(
                                              absorbing: !isEnabled,
                                              child: _buildFinalTempSection(
                                                  context, formStateForTemp),
                                            ),
                                          ),
                                          if (!isEnabled)
                                            Positioned.fill(
                                              child: InkWell(
                                                onTap: () =>
                                                    _showValidationSnackbar(
                                                        context,
                                                        'Selesaikan validasi semua unit dahulu.'),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Container(
                                                    color: Colors.transparent),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Tombol Submit/Retry
                        if (_hasRetryUploadState(stateUpload))
                          _buildRetryButton(
                              stateUpload as ValidationUploadPartial)
                        else
                          _buildSubmitButton(context, header, formState),
                      ],
                    );
                  },
                );
              },
            );
          }
          return const Center(child: Text("Data belum dimuat"));
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (title.isNotEmpty) const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ServiceCallHeader header) {
    return _buildSection(
      title: 'Informasi Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toko: ${header.storeName} (${header.storeId})',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Alamat: ${header.storeAddress}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Kontak: ${header.contactName} (${header.contactPhone})',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Cabang: ${header.branchName} (${header.branchId})',
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTicketSection(ServiceCallHeader header) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
                child: Text('No: ${header.transNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold)))
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Text('Posted: ${header.postedDate.split('T')[0]}') // Asumsi format
          ]),
          const SizedBox(height: 4),
          Text('Status: ${header.status}',
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Kategori: ${header.complaintCategory}'),
          Text('Keluhan: ${header.complaintSubject}',
              style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      );

  Widget _buildPicPanel(BuildContext context, ScFormState formState) {
    final formCubit = context.read<ScFormCubit>();
    return _buildSection(
      title: 'PIC Toko',
      child: Column(
        children: [
          _buildCustomTextField(
            controller: _picNameController,
            hintText: 'Nama Lengkap PIC',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _picPhoneController,
            hintText: 'Nomor Telepon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  controller: _picNikController,
                  hintText: 'NIK',
                  icon: Icons.badge_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomTextField(
                  controller: _picPositionController,
                  hintText: 'Jabatan',
                  icon: Icons.work_outline,
                ),
              ),
            ],
          ),
          // Tambahkan logika foto PIC di sini jika diperlukan
          const SizedBox(height: 12),
          _buildPicPhotoButton(context, formState),
        ],
      ),
    );
  }

  Widget _buildPicPhotoButton(BuildContext context, ScFormState formState) {
    final formCubit = context.read<ScFormCubit>();
    final imageDetail = formState.picImageDetail; // Ambil dari state

    if (_isTakingPicPhoto) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (imageDetail != null) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          GestureDetector(
            onTap: () => _showFullSizeImage(imageDetail),
            child: Hero(
              tag: imageDetail.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imageDetail.imagePath),
                  width: double.infinity, // Lebarkan
                  height: 150, // Sesuaikan tinggi
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              formCubit.picImageChanged(null); // Update Cubit
              formCubit.onFieldChanged();
            },
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _takePicPhoto,
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('Ambil Foto PIC'),
        ),
      );
    }
  }

  Widget _buildTechnicianPanel(BuildContext context, ScFormState formState) {
    final formCubit = context.read<ScFormCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildCustomTextField(
              controller: _technician1Controller,
              hintText: 'Teknisi 1',
              icon: Icons.engineering,
              readOnly: true),
          const SizedBox(height: 12),
          _buildCustomTextField(
              controller: _technician2Controller,
              hintText: 'Teknisi 2',
              icon: Icons.engineering),
          const SizedBox(height: 8),
          if (_showTechnician3)
            _buildCustomTextField(
              controller: _technician3Controller,
              hintText: 'Teknisi 3',
              icon: Icons.engineering,
              iconBtn: IconButton(
                  onPressed: () {
                    formCubit.technician3Changed('');
                    formCubit.toggleTechnician3(false);
                  },
                  icon: const Icon(Icons.cancel, color: Colors.red)),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Teknisi 3'),
                onPressed: () => formCubit.toggleTechnician3(true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanQRButton(
      BuildContext context, ServiceCallDetailLoaded detailState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const Icon(FontAwesomeIcons.qrcode, size: 16),
          label: const Text('Scan QR'),
          onPressed: () async {
            final String? scannedSerialNo = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QrScanPage()),
            );
            if (scannedSerialNo == null || !mounted) return;

            final matchingItem = detailState.data.detail.firstWhereOrNull(
              (e) =>
                  e.serialNo.trim().toUpperCase() ==
                  scannedSerialNo.trim().toUpperCase(),
            );

            if (matchingItem != null) {
              final box = Hive.box<ServiceCallValidationEntryModel>(
                  kServiceCallHiveBox);
              final existingData = box.values.firstWhereOrNull(
                (entry) =>
                    entry.serialNo.trim().toUpperCase() ==
                        scannedSerialNo.trim().toUpperCase() &&
                    entry.transNo == widget.transNo,
              );

              final outdoorSerials = detailState.data.outdoor
                  .map((unit) => unit.serialNo)
                  .toList();
              final problemSources = detailState.data.problems;
              final detailData = detailState.data;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ServiceCallValidationScreen(
                    transNo: widget.transNo,
                    serialNo: matchingItem.serialNo,
                    lineNo: matchingItem.lineNo,
                    assetAge: matchingItem.assetAge,
                    rentDate: matchingItem.rentDate,
                    leasesEndingDate: matchingItem.leasesEndingDate,
                    complaintDetails: matchingItem.complaintDetails,
                    imageFile: matchingItem.imageFile,
                    initialData: existingData,
                    allAvailableOutdoorSerials: outdoorSerials,
                    problemSources: problemSources,
                    detailData: detailData,
                  ),
                ),
              );

              if (result == true && mounted) {
                _refreshSerials(); // JALANKAN REFRESH DI SINI
              }
            } else {
              _showValidationSnackbar(
                  context, "Serial number tidak ditemukan di transaksi ini.");
            }
          },
        ),
      ],
    );
  }

  Widget _buildDetailCard(
      ServiceCallHeader header,
      ServiceCallUnitDetail detail,
      Map<String, ValidationStatus> validationStatuses) {
    final isRemote = detail.articleNameUnit.toUpperCase().contains('REMOTE');
    final String serialKey = detail.serialNo.trim().toUpperCase();
    final status = validationStatuses[serialKey] ?? ValidationStatus.notStarted;
    IconData iconData;
    Color iconColor;
    switch (status) {
      case ValidationStatus.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case ValidationStatus.inProgress:
        iconData = Icons.pending_actions;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(detail.articleNameUnit,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Serial No: ${detail.serialNo}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Keluhan: ${detail.complaintDetails}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Icon(iconData, color: iconColor, size: 28),
        onTap: () async {
          final box =
              Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
          final existingEntry = box.values.firstWhereOrNull((e) =>
              e.serialNo.trim().toUpperCase() == serialKey &&
              e.transNo == header.transNo);
          // Ambil detail state terbaru
          final detailState = context.read<ServiceCallDetailBloc>().state;
          if (detailState is! ServiceCallDetailLoaded) return; // Guard clause

          final outdoorSerials =
              detailState.data.outdoor.map((unit) => unit.serialNo).toList();
          final problemSources = detailState.data.problems;

          if (isRemote) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RemoteValidationScreen(
                  transNo: header.transNo,
                  uniqueId: detail.serialNo,
                  // Gunakan serialNo sebagai uniqueId
                  articleName: detail.articleNameUnit,
                  initialData: existingEntry,
                  complaintDetails: detail.complaintDetails,
                  imageFile: header.pathAttachment,
                  // Mungkin imageFile dari detail? Sesuaikan
                  problemSources: problemSources,
                ),
              ),
            );

            if (result == true && mounted) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Validasi berhasil disimpan!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              _refreshSerials(); // JALANKAN REFRESH DI SINI
            }
          } else {
            final detailData = (context.read<ServiceCallDetailBloc>().state
                    as ServiceCallDetailLoaded)
                .data;

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceCallValidationScreen(
                  serialNo: detail.serialNo,
                  lineNo: detail.lineNo,
                  transNo: header.transNo,
                  initialData: existingEntry,
                  assetAge: detail.assetAge,
                  rentDate: detail.rentDate,
                  leasesEndingDate: detail.leasesEndingDate,
                  complaintDetails: detail.complaintDetails,
                  imageFile: detail.imageFile,
                  allAvailableOutdoorSerials: outdoorSerials,
                  problemSources: problemSources,
                  detailData: detailData,
                ),
              ),
            );

            if (result == true && mounted) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Validasi berhasil disimpan!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              _refreshSerials(); // JALANKAN REFRESH DI SINI
            }
          }
        },
      ),
    );
  }

  Widget _buildFinalTempSection(BuildContext context, ScFormState formState) {
    final formCubit = context.read<ScFormCubit>();
    final baseLimits = kMeasurementLimits['final_temp_in_sc']!;
    final double minLimit = formState.minFinalTempInLimit ?? baseLimits.min;
    final String label = '${baseLimits.label} (Min: ${minLimit.toStringAsFixed(1)}${baseLimits.unit})';

    final finalTempLimits = MeasurementLimits(
      id: baseLimits.id,
      label: label,
      min: minLimit,
      max: baseLimits.max,
      unit: baseLimits.unit,
      normalMin: baseLimits.normalMin,
      normalMax: baseLimits.normalMax,
    );

    return _buildSection(
      title: 'Pengukuran Akhir (*Wajib)',
      child: MeasurementInputWidget(
        controller: _finalTempController,
        label: finalTempLimits.label,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        limits: finalTempLimits,
        transNo: widget.transNo,
        initialImage: formState.finalTempInImage,
        onEditingComplete: (finalValue) {
          if (formCubit.state.finalTempIn != finalValue) {
            formCubit.finalTempInChanged(finalValue);
            formCubit.onFieldChanged();
          }
        },
        onImageChanged: (newImage) {
          formCubit.finalTempInImageChanged(newImage);
          formCubit.onFieldChanged();
        },
      ),
    );
  }

  Widget _buildSubmitButton(
      BuildContext context, ServiceCallHeader header, ScFormState formState) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text("Selesai"),
            style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
            onPressed: () {
              FocusScope.of(context).unfocus();
              final scFormCubit = context.read<ScFormCubit>();
              // Paksa sinkronisasi controller suhu akhir
              if (scFormCubit.state.finalTempIn != _finalTempController.text) {
                scFormCubit.finalTempInChanged(_finalTempController.text);
                scFormCubit.onFieldChanged();
              }
              final latestFormState = scFormCubit.state;

              if (latestFormState.isFormReadyToSubmit) {
                // Langsung kirim event submit SC
                final progressCubit = context.read<UploadProgressCubit>();
                context.read<ServiceCallSubmittedBloc>().add(
                      SubmitValidation(
                        transNo: header.transNo,
                        createdBy: maintenanceBy,
                        createdByName: technicianName,
                        createdByIP: maintenanceByIP,
                        pathAttachment: header.pathAttachment,
                        progressCubit: progressCubit,
                      ),
                    );
              } else {
                // Tampilkan pesan error spesifik
                if (!latestFormState.isPicStoreValid) {
                  _showValidationSnackbar(context, 'Lengkapi info PIC.');
                } else if (!latestFormState.allUnitsValidated) {
                  _showValidationSnackbar(
                      context, 'Lengkapi validasi semua unit.');
                } else if (!latestFormState.isFinalTempValid) {
                  _showValidationSnackbar(
                      context, 'Lengkapi suhu akhir & fotonya.');
                } else {
                  _showValidationSnackbar(
                      context, 'Periksa kembali data Anda.');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(ValidationUploadPartial partial) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text("Coba Upload Ulang Foto Gagal"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final uploadCubit = context.read<UploadProgressCubit>();
              uploadCubit.reset();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => BlocProvider.value(
                  value: uploadCubit,
                  child: const UploadProgressDialog(),
                ),
              );
              context.read<ServiceCallSubmittedBloc>().add(
                    RetryUpload(
                      transNo: partial.transNo,
                      failedFiles: partial.failedFiles,
                      presignedDetail: partial.presignedDetail,
                      progressCubit: uploadCubit,
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    IconButton? iconBtn,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: hintText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        suffixIcon: iconBtn,
        isDense: true,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        // Warna berbeda jika readonly
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      inputFormatters: [
        TextInputFormatter.withFunction(
          (oldValue, newValue) =>
              newValue.copyWith(text: newValue.text.toUpperCase()),
        ),
      ],
    );
  }

  void _showValidationSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Fungsi foto PIC
  Future<void> _takePicPhoto() async {
    setState(() => _isTakingPicPhoto = true);
    final formCubit = context.read<ScFormCubit>();
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null || !mounted) return;

      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
          tempDir.path, 'pic_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final XFile? compressedImage =
          await FlutterImageCompress.compressAndGetFile(
        photo.path,
        targetPath,
        quality: 70,
        minWidth: 1080,
        minHeight: 1920,
      );
      if (compressedImage == null) return;

      final userData = await AuthStorage.getUser();
      final capturedDetail = CapturedImageDetail(
        imagePath: compressedImage.path,
        timestamp: DateTime.now(),
        latitude: 0,
        longitude: 0,
        address: "",
        technicianName: userData['name'] ?? 'Unknown',
        deviceModel: userData['device_model'] ?? 'Unknown Device',
        transNo: widget.transNo,
      );

      formCubit.picImageChanged(capturedDetail); // Update Cubit
      formCubit.onFieldChanged();
    } catch (e) {
      if (mounted)
        _showValidationSnackbar(context, "Gagal mengambil detail foto: $e");
    } finally {
      if (mounted) setState(() => _isTakingPicPhoto = false);
    }
  }

  void _showFullSizeImage(CapturedImageDetail? imageDetail) {
    if (imageDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(imageDetail: imageDetail)),
      );
    }
  }
}
