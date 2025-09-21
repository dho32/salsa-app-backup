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
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_state.dart';
import 'package:salsa/models/service_call/service_call_validation_entry_model.dart';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/otp/otp_repository.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_bloc.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import '../../../../blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/service_call/problem_source_model.dart';
import '../../../../models/service_call/transaction_info_model.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../service_call_validation/components/remote_validation/remote_validation_screen.dart';
import '../../service_call_validation/service_call_validation_screen.dart';

class ServiceCallDetailBodyMobile extends StatefulWidget {
  final String transNo;
  final Box<TransactionInfoModel> transactionInfoBox;

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
  final _picNameController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _technician1Controller = TextEditingController();
  final _technician2Controller = TextEditingController();
  final _technician3Controller = TextEditingController();
  bool _showTechnician3 = false;
  Future<Map<String, ValidationStatus>>? _validationStatusFuture;
  String technicianName = '';
  String maintenanceBy = '';
  String maintenanceByIP = '';

  CapturedImageDetail? _picImageDetail;
  bool _isTakingPicPhoto = false;
  final _picNikController = TextEditingController();
  final _picPositionController = TextEditingController();

  String _normalizeHiveKey(String key) => key.replaceAll('/', '');

  bool _hasRetryUploadState(ServiceCallSubmittedState state) {
    return state is ValidationUploadPartial &&
        state.transNo == widget.transNo &&
        state.failedFiles.isNotEmpty;
  }

  Future<Map<String, ValidationStatus>> _loadValidationStatuses(
      String transNo) async {
    final box = await Hive.openBox<ServiceCallValidationEntryModel>(
        kServiceCallHiveBox);
    final statuses = <String, ValidationStatus>{};

    final entries = box.values.where((e) => e.transNo == transNo);

    for (final entry in entries) {
      final serial = entry.serialNo.trim().toUpperCase();
      if (entry.isCompleted) {
        statuses[serial] = ValidationStatus.completed;
      } else {
        statuses[serial] = ValidationStatus.inProgress;
      }
    }
    return statuses;
  }

  void _refreshSerials() {
    final blocState = context.read<ServiceCallDetailBloc>().state;
    if (blocState is ServiceCallDetailLoaded) {
      setState(() {
        _validationStatusFuture =
            _loadValidationStatuses(blocState.data.header.transNo);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadTransactionInfo();
    _refreshSerials();

    _picNameController.addListener(_saveTransactionInfo);
    _picPhoneController.addListener(_saveTransactionInfo);
    _technician2Controller.addListener(_saveTransactionInfo);
    _technician3Controller.addListener(_saveTransactionInfo);
    _picNikController.addListener(_saveTransactionInfo);
    _picPositionController.addListener(_saveTransactionInfo);

    _picNameController.addListener(_triggerRebuild);
    _picPhoneController.addListener(_triggerRebuild);
    _picNikController.addListener(_triggerRebuild);
    _picPositionController.addListener(_triggerRebuild);
  }

  void _triggerRebuild() {
    // Memanggil setState kosong sudah cukup untuk memberitahu Flutter
    // agar menjalankan ulang build method.
    setState(() {});
  }

  @override
  void dispose() {
    // Jangan lupa dispose controller & listener
    _picNameController.removeListener(_triggerRebuild);
    _picPhoneController.removeListener(_triggerRebuild);
    _picNikController.removeListener(_triggerRebuild);
    _picPositionController.removeListener(_triggerRebuild);

    _picNameController.removeListener(_saveTransactionInfo);
    _picPhoneController.removeListener(_saveTransactionInfo);
    _technician2Controller.removeListener(_saveTransactionInfo);
    _technician3Controller.removeListener(_saveTransactionInfo);
    _picNikController.removeListener(_saveTransactionInfo);
    _picPositionController.removeListener(_saveTransactionInfo);

    _picNameController.dispose();
    _picPhoneController.dispose();
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _picNikController.dispose();
    _picPositionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthStorage.getUser();
    maintenanceByIP = await getPublicIpAddress();

    // Ambil nama pengguna dari data yang di-fetch
    final String loggedInUserName = user['name'] ?? '';

    setState(() {
      // Update state-state yang lain
      technicianName = loggedInUserName;
      maintenanceBy = user['user_id'] ?? '';

      // Update controller langsung dengan nilai yang sudah pasti ada
      _technician1Controller.text = loggedInUserName;
    });
  }

  Future<void> _loadTransactionInfo() async {
    final normalizedKey = _normalizeHiveKey(widget.transNo.toUpperCase());
    final info = widget.transactionInfoBox.get(normalizedKey);
    if (info != null) {
      _picNameController.text = info.picName ?? '';
      _picPhoneController.text = info.picPhone ?? '';
      _technician2Controller.text = info.technician2 ?? '';
      _technician3Controller.text = info.technician3 ?? '';
      _picNikController.text = info.picNik ?? '';
      _picPositionController.text = info.picPosition ?? '';
      _picImageDetail = info.picImageDetail;
      if (info.technician3 != null && info.technician3!.isNotEmpty) {
        setState(() {
          _showTechnician3 = true;
        });
      }
    }
  }

  void _saveTransactionInfo() {
    final normalizedKey = _normalizeHiveKey(widget.transNo.toUpperCase());
    final infoToSave = widget.transactionInfoBox.get(normalizedKey) ??
        TransactionInfoModel(transNo: widget.transNo.toUpperCase());

    infoToSave.picName = _picNameController.text;
    infoToSave.picPhone = _picPhoneController.text;
    infoToSave.technician2 = _technician2Controller.text;
    infoToSave.technician3 = _technician3Controller.text;
    infoToSave.picNik = _picNikController.text;
    infoToSave.picPosition = _picPositionController.text;
    infoToSave.picImageDetail = _picImageDetail;

    widget.transactionInfoBox.put(normalizedKey, infoToSave);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCallDetailBloc, ServiceCallDetailState>(
      builder: (context, state) {
        if (state is ServiceCallDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ServiceCallDetailError) {
          return Center(child: Text("Error: ${state.message}"));
        } else if (state is ServiceCallDetailLoaded) {
          final header = state.data.header;
          final detailList = state.data.detail;
          _validationStatusFuture ??= _loadValidationStatuses(header.transNo);
          return FutureBuilder<Map<String, ValidationStatus>>(
            future: _validationStatusFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final validationStatuses = snapshot.data!;
              final bool picStore = _picNameController.text.isNotEmpty &&
                  _picNikController.text.isNotEmpty &&
                  _picPositionController.text.isNotEmpty &&
                  _picPhoneController.text.isNotEmpty;
              // final bool isPicPhotoTaken = _picImageDetail != null;
              final allUnitsValidated = detailList.every((d) =>
                  validationStatuses[d.serialNo.trim().toUpperCase()] ==
                  ValidationStatus.completed);
              final stateUpload =
                  context.watch<ServiceCallSubmittedBloc>().state;
              bool allDone = picStore && allUnitsValidated;
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 35.0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 35),
                      child: Column(
                        children: [
                          _buildCustomerSection(header),
                          _buildSection(
                              title: 'Tiket Service Call',
                              child: _buildTicketSection(header)),
                          _buildPicPanel(),
                          _buildSection(
                              title: 'Teknisi Bertugas',
                              child: _buildTechnicianPanel()),
                          _buildSection(
                            title: '',
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      icon: const Icon(FontAwesomeIcons.qrcode,
                                          size: 16),
                                      label: const Text('Scan QR'),
                                      onPressed: () async {
                                        // 1. Buka scanner dan tunggu hasilnya (serial number)
                                        final String? scannedSerialNo =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const QrScanPage()),
                                        );

                                        // Jika tidak ada hasil, hentikan proses
                                        if (scannedSerialNo == null ||
                                            !mounted) {
                                          return;
                                        }

                                        // 2. LOGIKA SPESIFIK SERVICE CALL
                                        final detailState = context
                                            .read<ServiceCallDetailBloc>()
                                            .state;
                                        if (detailState
                                            is ServiceCallDetailLoaded) {
                                          final matchingItem = detailState
                                              .data.detail
                                              .firstWhereOrNull(
                                            (e) => e.serialNo
                                                .trim()
                                                .toUpperCase()
                                                .contains(scannedSerialNo
                                                    .trim()
                                                    .toUpperCase()),
                                          );

                                          if (matchingItem != null) {
                                            final box = await Hive.openBox<
                                                    ServiceCallValidationEntryModel>(
                                                kServiceCallHiveBox);
                                            final existingData =
                                                box.values.firstWhereOrNull(
                                              (entry) => entry.serialNo
                                                  .trim()
                                                  .toUpperCase()
                                                  .contains(scannedSerialNo
                                                      .trim()
                                                      .toUpperCase()),
                                            );

                                            List<String> outdoorSerials = [];
                                            List<ProblemSourceModel>
                                                problemSources = [];
                                            outdoorSerials = detailState
                                                .data.outdoor
                                                .map((unit) => unit.serialNo)
                                                .toList();

                                            problemSources =
                                                detailState.data.problems;

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ServiceCallValidationScreen(
                                                  transNo: widget.transNo,
                                                  serialNo:
                                                      matchingItem.serialNo,
                                                  lineNo: matchingItem.lineNo,
                                                  assetAge:
                                                      matchingItem.assetAge,
                                                  rentDate:
                                                      matchingItem.rentDate,
                                                  leasesEndingDate: matchingItem
                                                      .leasesEndingDate,
                                                  complaintDetails: matchingItem
                                                      .complaintDetails,
                                                  imageFile:
                                                      matchingItem.imageFile,
                                                  initialData: existingData,
                                                  allAvailableOutdoorSerials:
                                                      outdoorSerials,
                                                  problemSources:
                                                      problemSources,
                                                ),
                                              ),
                                            );
                                          } else {
                                            // Tampilkan pesan jika tidak cocok
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                                    content: Text(
                                                        "Serial number tidak ditemukan di transaksi ini.")));
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...detailList.map((item) => _buildDetailCard(
                                    header, item, validationStatuses)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_hasRetryUploadState(stateUpload))
                    _buildRetryButton(stateUpload as ValidationUploadPartial)
                  else
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SafeArea(
                        minimum: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle),
                            label: const Text("Selesai"),
                            onPressed: () async {
                              if (allDone) {
                                await showDialog<void>(
                                  context: context,
                                  builder: (_) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider(
                                          create: (_) => OtpBloc(
                                              repository: OtpRepository())),
                                    ],
                                    child: OtpDialog(
                                      transNo: header.transNo,
                                      shipTo: header.storeId,
                                      email: header.storeEmail,
                                      storeLat: 0,
                                      storeLong: 0,
                                      // Ganti dengan email tujuan OTP

                                      // Berikan fungsi onVerified yang spesifik untuk Proof of Service
                                      onVerified: () {
                                        final progressCubit =
                                            context.read<UploadProgressCubit>();
                                        context
                                            .read<ServiceCallSubmittedBloc>()
                                            .add(
                                              SubmitValidation(
                                                  transNo: header.transNo,
                                                  createdBy: maintenanceBy,
                                                  createdByName: technicianName,
                                                  createdByIP: maintenanceByIP,
                                                  pathAttachment:
                                                      header.pathAttachment,
                                                  progressCubit: progressCubit),
                                            );
                                      },
                                    ),
                                  ),
                                );
                              } else {
                                if (!picStore) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Harap lengkapi informasi PIC Toko terlebih dahulu.'),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } else if (!allUnitsValidated) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Harap lengkapi semua validasi unit terlebih dahulu.'),
                                      backgroundColor: Colors.orange,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        }
        return const Center(child: Text("Data belum dimuat"));
      },
    );
  }

  Widget _buildTechnicianPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildCustomTextField(
            controller: _technician1Controller,
            hintText: 'Teknisi 1',
            icon: Icons.engineering,
            readOnly: true,
          ),
          _buildCustomTextField(
            controller: _technician2Controller,
            hintText: 'Teknisi 2',
            icon: Icons.engineering,
          ),
          const SizedBox(height: 8),
          if (_showTechnician3)
            _buildCustomTextField(
              controller: _technician3Controller,
              hintText: 'Teknisi 3',
              icon: Icons.engineering,
              iconBtn: IconButton(
                  onPressed: () {
                    setState(() {
                      _showTechnician3 = false;
                      _technician3Controller.clear();
                    });
                  },
                  icon: Icon(
                    Icons.cancel,
                    color: Colors.red,
                  )),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Teknisi 3'),
                onPressed: () {
                  setState(() {
                    _showTechnician3 = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildCustomerSection(header) {
    return _buildSection(
      title: 'Informasi Customer',
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toko: ${header.storeName} (${header.storeId})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Alamat: ${header.storeAddress}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Kontak: ${header.contactName} (${header.contactPhone})',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Cabang: ${header.branchName} (${header.branchId})',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSection(header) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.confirmation_number, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text('No: ${header.transNo}',
                    style: const TextStyle(fontWeight: FontWeight.bold)))
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 8),
            Text('Posted: ${header.postedDate.split('T')[0]}')
          ]),
          const SizedBox(height: 4),
          Text('Status: ${header.status}',
              style: const TextStyle(color: Colors.blue)),
          const SizedBox(height: 8),
          Text('Kategori: ${header.complaintCategory}'),
          Text('Keluhan: ${header.complaintSubject}',
              style: const TextStyle(fontStyle: FontStyle.italic)),
        ],
      );

  Widget _buildDetailCard(
      header, detail, Map<String, ValidationStatus> validationStatuses) {
    final isRemote = detail.articleNameUnit.toUpperCase().contains('REMOTE');
    final String uniqueId = detail.serialNo;

    final normalizedSerial = uniqueId.trim().toUpperCase();

    final status =
        validationStatuses[normalizedSerial] ?? ValidationStatus.notStarted;
    IconData iconData;
    Color iconColor;
    switch (status) {
      case ValidationStatus.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case ValidationStatus.inProgress:
        iconData = Icons.pending_actions; // Atau Icons.hourglass_top
        iconColor = Colors.orange;
        break;
      case ValidationStatus.notStarted:
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
        break;
    }

    return InkWell(
      onTap: () async {
        final box = await Hive.openBox<ServiceCallValidationEntryModel>(
            kServiceCallHiveBox);

        final existingEntry = box.values.firstWhereOrNull((e) {
          return e.serialNo.trim().toUpperCase() == normalizedSerial &&
              e.transNo == header.transNo;
        });

        final detailState = context.read<ServiceCallDetailBloc>().state;
        List<ProblemSourceModel> problemSources = [];
        List<String> outdoorSerials = [];
        if (detailState is ServiceCallDetailLoaded) {
          outdoorSerials =
              detailState.data.outdoor.map((unit) => unit.serialNo).toList();
          problemSources = detailState.data.problems;

        }

        if (isRemote) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RemoteValidationScreen(
                transNo: header.transNo,
                uniqueId: uniqueId,
                // Gunakan uniqueId yang sudah kita buat
                articleName: detail.articleNameUnit,
                initialData: existingEntry,
                complaintDetails: detail.complaintDetails,
                imageFile: header.pathAttachment,
                problemSources: problemSources,
              ),
            ),
          );

          if (mounted) {
            _refreshSerials();
          }
        } else {
          await Navigator.push(
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
              ),
            ),
          );
          if (mounted) {
            _refreshSerials();
          }
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(detail.articleNameUnit,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Text(detail.serialNo.contains('REMOTE') ? '-' : detail.serialNo,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Keluhan: ${detail.complaintDetails}',
                  style: const TextStyle(fontSize: 12)),
              // Text('Umur: ${detail.assetAge}',
              //     style: const TextStyle(fontSize: 12)),
              // Text('Sewa: ${detail.rentDate} - ${detail.leasesEndingDate}',
              //     style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Icon(iconData, color: iconColor),
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
                builder: (_) {
                  // Berikan instance cubit yang sudah ada ke pohon widget dialog
                  return BlocProvider.value(
                    value: uploadCubit,
                    child:
                        const UploadProgressDialog(), // Gunakan widget baru kita
                  );
                },
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

  Widget _buildPicPanel() {
    return _buildSection(
      title: 'PIC Toko',
      child: Column(
        children: [
          // Row(
          //   children: [
          //     Expanded(
          //       child: Column(
          //         children: [
          //           _buildCustomTextField(
          //             controller: _picNameController,
          //             hintText: 'Nama Lengkap PIC',
          //             icon: Icons.person_outline,
          //           ),
          //           const SizedBox(height: 12),
          //           _buildCustomTextField(
          //             controller: _picPhoneController,
          //             hintText: 'Nomor Telepon',
          //             icon: Icons.phone_outlined,
          //             keyboardType: TextInputType.phone,
          //           ),
          //         ],
          //       ),
          //     ),
          //     const SizedBox(width: 12),
          //     Stack(
          //       alignment: Alignment.topRight,
          //       children: [
          //         GestureDetector(
          //           onTap: _isTakingPicPhoto
          //               ? null
          //               : _picImageDetail != null
          //                   ? _showFullSizeImage
          //                   : _takePicPhoto,
          //           child: Container(
          //             width: 100,
          //             height: 100,
          //             decoration: BoxDecoration(
          //               color: Colors.grey.shade200,
          //               borderRadius: BorderRadius.circular(8),
          //               border:
          //                   Border.all(color: Colors.grey.shade400, width: 1),
          //             ),
          //             child: _isTakingPicPhoto
          //                 ? const Center(child: CircularProgressIndicator())
          //                 : _picImageDetail != null
          //                     ? ClipRRect(
          //                         borderRadius: BorderRadius.circular(8),
          //                         child: Image.file(
          //                             File(_picImageDetail!.imagePath),
          //                             fit: BoxFit.cover),
          //                       )
          //                     : Icon(Icons.camera_alt_outlined,
          //                         size: 32, color: Colors.grey.shade600),
          //           ),
          //         ),
          //         if (_picImageDetail != null)
          //           GestureDetector(
          //             onTap: () {
          //               setState(() => _picImageDetail = null);
          //               _saveTransactionInfo();
          //             },
          //             child: Container(
          //               padding: const EdgeInsets.all(4),
          //               decoration: const BoxDecoration(
          //                 color: Colors.black54,
          //                 shape: BoxShape.circle,
          //               ),
          //               child: const Icon(Icons.close,
          //                   color: Colors.white, size: 14),
          //             ),
          //           ),
          //       ],
          //     ),
          //   ],
          // ),
          Column(
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
            ],
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
          )
        ],
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
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Hilangkan border
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

  Future<void> _takePicPhoto() async {
    setState(() => _isTakingPicPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null || !mounted) return;

      final tempDir = await getTemporaryDirectory();
      final targetPath = p.join(
          tempDir.path, 'pic_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final XFile? compressedImage =
          await FlutterImageCompress.compressAndGetFile(
        photo.path, targetPath,
        quality: 70,
        minWidth: 1080, //ukuran full HD
        minHeight: 1920,
      ); //ukuran full HD
      if (compressedImage == null) return;

      // Position position = await Geolocator.getCurrentPosition(
      //     desiredAccuracy: LocationAccuracy.high);
      // List<Placemark> placemarks =
      //     await placemarkFromCoordinates(position.latitude, position.longitude);
      // Placemark place = placemarks.first;
      // String address =
      //     "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";

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

      setState(() {
        _picImageDetail = capturedDetail;
      });
      _saveTransactionInfo();
    } catch (e) {
      // Handle error (misal: GPS tidak aktif)
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil detail foto: $e")));
    } finally {
      // 3. Apapun yang terjadi, set loading kembali ke false
      if (mounted) {
        setState(() => _isTakingPicPhoto = false);
      }
    }
  }

  void _showFullSizeImage() {
    if (_picImageDetail != null) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FullScreenImageViewer(imageDetail: _picImageDetail!),
          ));
    }
  }
}
