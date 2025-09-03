import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/otp/otp_repository.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/full_screen_image_viewer.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/captured_image_detail.dart';
import '../../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../proof_of_service_validation/pos_validation_screen.dart';

class ProofOfServiceDetailBodyMobile extends StatefulWidget {
  final String transNo;
  final Box<PosTransactionInfoModel> transactionInfoBox;

  const ProofOfServiceDetailBodyMobile({
    super.key,
    required this.transNo,
    required this.transactionInfoBox,
  });

  @override
  State<ProofOfServiceDetailBodyMobile> createState() =>
      _ProofOfServiceDetailBodyMobileState();
}

class _ProofOfServiceDetailBodyMobileState
    extends State<ProofOfServiceDetailBodyMobile> {
  final _picNikController = TextEditingController();
  final _picPositionController = TextEditingController();
  final _tempInController = TextEditingController();
  final _tempOutController = TextEditingController();
  final _serviceTimeController = TextEditingController();
  final _picNameController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _technician1Controller = TextEditingController();
  final _technician2Controller = TextEditingController();
  final _technician3Controller = TextEditingController();
  bool _showTechnician3 = false;
  String technicianName = '';
  String maintenanceBy = '';
  String maintenanceByIP = '';
  CapturedImageDetail? _picImageDetail;
  bool _isTakingPicPhoto = false;
  CapturedImageDetail? _temperatureInImage;
  CapturedImageDetail? _temperatureOutImage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadTransactionInfo();
    _addListeners();
  }

  void _triggerRebuild() {
    // Memanggil setState kosong sudah cukup untuk memberitahu Flutter
    // agar menjalankan ulang build method.
    setState(() {});
  }

  @override
  void dispose() {
    _removeListeners();
    _disposeControllers();
    super.dispose();
  }

  void _addListeners() {
    _picNikController.addListener(_saveTransactionInfo);
    _picNameController.addListener(_saveTransactionInfo);
    _picPositionController.addListener(_saveTransactionInfo);
    _picPhoneController.addListener(_saveTransactionInfo);
    _technician2Controller.addListener(_saveTransactionInfo);
    _technician3Controller.addListener(_saveTransactionInfo);
    _tempInController.addListener(_saveTransactionInfo);
    _tempOutController.addListener(_saveTransactionInfo);
    _serviceTimeController.addListener(_saveTransactionInfo);

    _picNameController.addListener(_triggerRebuild);
    _picPhoneController.addListener(_triggerRebuild);
    _picNikController.addListener(_triggerRebuild);
    _picPositionController.addListener(_triggerRebuild);
    _tempInController.addListener(_triggerRebuild);
    _tempOutController.addListener(_triggerRebuild);
    _serviceTimeController.addListener(_triggerRebuild);
  }

  void _removeListeners() {
    _picNikController.removeListener(_saveTransactionInfo);
    _picNameController.removeListener(_saveTransactionInfo);
    _picPositionController.removeListener(_saveTransactionInfo);
    _picPhoneController.removeListener(_saveTransactionInfo);
    _technician2Controller.removeListener(_saveTransactionInfo);
    _technician3Controller.removeListener(_saveTransactionInfo);
    _tempInController.removeListener(_saveTransactionInfo);
    _tempOutController.removeListener(_saveTransactionInfo);
    _serviceTimeController.removeListener(_saveTransactionInfo);

    _picNameController.removeListener(_triggerRebuild);
    _picPhoneController.removeListener(_triggerRebuild);
    _picNikController.removeListener(_triggerRebuild);
    _picPositionController.removeListener(_triggerRebuild);
    _tempInController.removeListener(_triggerRebuild);
    _tempOutController.removeListener(_triggerRebuild);
    _serviceTimeController.removeListener(_triggerRebuild);
  }

  void _disposeControllers() {
    _picNikController.dispose();
    _picNameController.dispose();
    _picPositionController.dispose();
    _picPhoneController.dispose();
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _tempInController.dispose();
    _tempOutController.dispose();
    _serviceTimeController.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = await AuthStorage.getUser();
    maintenanceByIP = await getPublicIpAddress();
    final String loggedInUserName = user['name'] ?? '';
    if (mounted) {
      setState(() {
        _technician1Controller.text = loggedInUserName;
        technicianName = loggedInUserName; // <-- Simpan untuk dikirim
        maintenanceBy = user['maintenance_by'] ?? '';
      });
    }
  }

  void _loadTransactionInfo() {
    final hiveKey = getHiveKeyForTransaction(widget.transNo);
    final info = widget.transactionInfoBox.get(hiveKey);
    if (info != null) {
      _picNameController.text = info.picName ?? '';
      _picNikController.text = info.picNik ?? '';
      _picPositionController.text = info.picPosition ?? '';
      _picPhoneController.text = info.picPhone ?? '';
      _technician2Controller.text = info.technician2 ?? '';
      _technician3Controller.text = info.technician3 ?? '';
      _tempInController.text = info.temperatureIn ?? '';
      _tempOutController.text = info.temperatureOut ?? '';
      _serviceTimeController.text = info.serviceTime ?? '';
      _picImageDetail = info.picImageDetail;
      if (mounted) {
        setState(() {
          _temperatureInImage = info.temperatureInImage;
          _temperatureOutImage = info.temperatureOutImage;
        });
      }
      if (info.technician3 != null && info.technician3!.isNotEmpty) {
        if (mounted) setState(() => _showTechnician3 = true);
      }
    }
  }

  void _saveTransactionInfo() {
    final hiveKey = getHiveKeyForTransaction(widget.transNo);
    final infoToSave = widget.transactionInfoBox.get(hiveKey) ??
        PosTransactionInfoModel(transNo: widget.transNo);

    infoToSave.picName = _picNameController.text;
    infoToSave.picNik = _picNikController.text;
    infoToSave.picPosition = _picPositionController.text;
    infoToSave.picPhone = _picPhoneController.text;
    infoToSave.technician2 = _technician2Controller.text;
    infoToSave.technician3 = _technician3Controller.text;
    infoToSave.temperatureIn = _tempInController.text;
    infoToSave.temperatureOut = _tempOutController.text;
    infoToSave.serviceTime = _serviceTimeController.text;
    infoToSave.picImageDetail = _picImageDetail;
    infoToSave.temperatureInImage = _temperatureInImage;
    infoToSave.temperatureOutImage = _temperatureOutImage;

    widget.transactionInfoBox.put(hiveKey, infoToSave);
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
          await FlutterImageCompress.compressAndGetFile(photo.path, targetPath,
              quality: 70, minWidth: 1080, minHeight: 1920);
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

  Future<void> _selectServiceTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && mounted) {
      // Format waktu menjadi HH:mm
      final formattedTime = pickedTime.format(context);
      setState(() {
        _serviceTimeController.text = formattedTime;
      });
      // Simpan perubahan ke Hive
      _saveTransactionInfo();
    }
  }

  bool _hasRetryUploadState(PosSubmittedState state) {
    return state is PosValidationUploadPartial &&
        state.transNo == widget.transNo &&
        state.failedFiles.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
      builder: (context, state) {
        if (state is ProofOfServiceDetailLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProofOfServiceDetailError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        if (state is ProofOfServiceDetailLoaded) {
          final header = state.data.header;
          final detailList = state.data.detail;
          final validationStatuses = state.validationStatuses;

          final indoorUnits = detailList
              .where((d) => d.unitType.toUpperCase() == 'IN')
              .toList();
          final outdoorUnits = detailList
              .where((d) => d.unitType.toUpperCase() == 'OUT')
              .toList();
          final setUnits = detailList.where((d) {
            final unitType = d.unitType.toUpperCase();
            return unitType != 'IN' && unitType != 'OUT';
          }).toList();

          final bool allUnitsValidated = detailList.every((detail) {
            final serialKey = detail.serialNo.trim().toUpperCase();
            return validationStatuses[serialKey] == ValidationStatus.completed;
          });

          // final bool isPicPhotoTaken = _picImageDetail != null;

          final bool informationService = _tempInController.text.isNotEmpty &&
              _tempOutController.text.isNotEmpty &&
              _temperatureInImage != null &&
              _temperatureOutImage != null;

          final bool picStore = _picNameController.text.isNotEmpty &&
              _picNikController.text.isNotEmpty &&
              _picPositionController.text.isNotEmpty &&
              _picPhoneController.text.isNotEmpty;

          final allDone = allUnitsValidated && picStore && informationService;

          final stateUpload = context.watch<PosSubmittedBloc>().state;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 35.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 35),
                  child: Column(
                    children: [
                      _buildCustomerSection(header),
                      const SizedBox(height: 16),
                      _buildTicketSection(header),
                      const SizedBox(height: 16),
                      _buildPicPanel(),
                      const SizedBox(height: 16),
                      _buildSection(
                          title: 'Teknisi Bertugas',
                          child: _buildTechnicianPanel()),
                      const SizedBox(height: 16),
                      _buildServiceInfoPanel(),
                      const SizedBox(height: 16),
                      _buildSection(
                        title: '',
                        fullWidth: true,
                        headerAction: ElevatedButton.icon(
                          icon: const Icon(FontAwesomeIcons.qrcode, size: 16),
                          label: const Text('Scan QR'),
                          onPressed: _tempInController.text.isNotEmpty &&
                                  _tempInController.text != '0' &&
                                  _tempOutController.text.isNotEmpty &&
                                  _tempOutController.text != '0'
                              ? () async {
                                  detailList
                                      .map((e) =>
                                          e.serialNo.trim().toUpperCase())
                                      .toList();

                                  final String? scannedSerialNo =
                                      await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QrScanPage(),
                                    ),
                                  );

                                  if (scannedSerialNo != null && mounted) {
                                    // Cari detail unit yang sesuai dengan hasil pindaian
                                    final tappedDetail = detailList.firstWhere(
                                      (d) =>
                                          d.serialNo.trim().toUpperCase() ==
                                          scannedSerialNo.trim().toUpperCase(),
                                    );

                                    // Buka halaman validasi untuk unit tersebut
                                    final box = await Hive.openBox<
                                            PosValidationEntryModel>(
                                        kPosValidationHiveBox);
                                    final existingData = box.get(tappedDetail
                                        .serialNo
                                        .trim()
                                        .toUpperCase());

                                    final double? indoorTemp =
                                        double.tryParse(_tempInController.text);
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PosValidationScreen(
                                          transNo: header.transNo,
                                          serialNo: tappedDetail.serialNo,
                                          unitType: tappedDetail.unitType,
                                          initialData: existingData,
                                          articleNo: tappedDetail.articleNo,
                                          articleDesc: tappedDetail.articleDesc,
                                          articleUnitDesc:
                                              tappedDetail.unitDesc,
                                          capacity: 0,
                                          indoorTemp: indoorTemp,
                                        ),
                                      ),
                                    );

                                    // Refresh halaman detail setelah kembali dari validasi
                                    context
                                        .read<ProofOfServiceDetailBloc>()
                                        .add(FetchProofOfServiceDetail(header
                                            .transNo
                                            .trim()
                                            .toUpperCase()));
                                  }
                                }
                              : null,
                        ),
                        child: Column(
                          children: [
                            // Tampilkan blok INDOOR jika ada isinya
                            if (indoorUnits.isNotEmpty)
                              _buildUnitGroupCard(
                                  title: 'INDOOR',
                                  units: indoorUnits,
                                  icon: FontAwesomeIcons.wind,
                                  color: Colors.blue.shade700,
                                  header: header,
                                  validationStatuses: validationStatuses,
                                  isEnabled:
                                      _tempInController.text.isNotEmpty &&
                                          _tempInController.text != '0'),

                            // Tampilkan blok OUTDOOR jika ada isinya
                            if (outdoorUnits.isNotEmpty)
                              _buildUnitGroupCard(
                                  title: 'OUTDOOR',
                                  units: outdoorUnits,
                                  icon: FontAwesomeIcons.fan,
                                  color: Colors.orange.shade800,
                                  header: header,
                                  validationStatuses: validationStatuses,
                                  isEnabled:
                                      _tempOutController.text.isNotEmpty &&
                                          _tempOutController.text != '0'),

                            // Tampilkan blok SET jika ada isinya
                            if (setUnits.isNotEmpty)
                              _buildUnitGroupCard(
                                  title: 'SET AC',
                                  units: setUnits,
                                  icon: Icons.inventory_2_outlined,
                                  color: Colors.grey.shade700,
                                  header: header,
                                  validationStatuses: validationStatuses,
                                  isEnabled:
                                      _tempInController.text.isNotEmpty &&
                                          _tempOutController.text.isNotEmpty),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_hasRetryUploadState(stateUpload))
                _buildRetryButton(stateUpload as PosValidationUploadPartial)
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
                                  // OtpBloc tetap dibutuhkan oleh dialog
                                  BlocProvider(
                                      create: (_) =>
                                          OtpBloc(repository: OtpRepository())),
                                ],
                                child: OtpDialog(
                                  shipTo: header.shipToCode,
                                  email: header.storeEmail,
                                  // Ganti dengan email tujuan OTP

                                  // Berikan fungsi onVerified yang spesifik untuk Proof of Service
                                  onVerified: () {
                                    final progressCubit =
                                        context.read<UploadProgressCubit>();
                                    context.read<PosSubmittedBloc>().add(
                                          SubmitPosValidation(
                                            transNo: header.transNo,
                                            createdBy: maintenanceBy,
                                            createdByName: technicianName,
                                            createdByIP: maintenanceByIP,
                                            progressCubit: progressCubit,
                                          ),
                                        );
                                  },
                                ),
                              ),
                            );
                          } else {
                            if (!picStore) {
                              print(picStore);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Harap lengkapi informasi PIC Toko terlebih dahulu.'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else if (!informationService) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Harap lengkapi informasi servis dan wajib sertakan foto untuk setiap pengukuran suhu.'),
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
        }
        return const Center(child: Text("Memuat data..."));
      },
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    bool fullWidth = false,
    Widget? headerAction,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ProofOfServiceHeader header) {
    return _buildSection(
      title: 'Informasi Customer',
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toko: ${header.shipToName} (${header.shipToCode})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Alamat: ${header.shipToAddress}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Cabang: ${header.branchName} (${header.branchCode})',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketSection(ProofOfServiceHeader header) {
    return _buildSection(
      title: 'Tiket Cuci',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text('No: ${header.transNo}')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text('Jadwal Cuci: ${header.poDate.split('T')[0]}'),
            ],
          ),
        ],
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

  Widget _buildTechnicianPanel() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextFormField(
              controller: _technician1Controller,
              readOnly: true,
              decoration: const InputDecoration(
                  labelText: 'Teknisi 1',
                  prefixIcon: Icon(Icons.engineering),
                  filled: true,
                  fillColor: Colors.black12)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _technician2Controller,
            decoration: const InputDecoration(
              labelText: 'Teknisi 2',
              prefixIcon: Icon(Icons.engineering),
            ),
            inputFormatters: [
              TextInputFormatter.withFunction(
                (oldValue, newValue) =>
                    newValue.copyWith(text: newValue.text.toUpperCase()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_showTechnician3)
            TextFormField(
              controller: _technician3Controller,
              decoration: InputDecoration(
                labelText: 'Teknisi 3',
                prefixIcon: const Icon(Icons.engineering),
                suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _showTechnician3 = false;
                        _technician3Controller.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.cancel,
                      color: Colors.red,
                    )),
              ),
              inputFormatters: [
                TextInputFormatter.withFunction(
                  (oldValue, newValue) =>
                      newValue.copyWith(text: newValue.text.toUpperCase()),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Teknisi 3'),
                onPressed: () => setState(() => _showTechnician3 = true),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoPanel() {
    return _buildSection(
      title: 'Informasi Servis',
      child: Column(
        children: [
          MeasurementInputWidget(
            controller: _tempInController,
            label: 'Suhu Dalam Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Buat limits sederhana, karena mungkin tidak butuh validasi min/max di sini
            limits: MeasurementLimits(
              id: 'temp_in',
              label: 'Suhu Dalam',
              min: 0,
              max: 100,
              normalMax: 0,
              normalMin: 100,
              unit: '°C',
            ),
            transNo: widget.transNo,
            initialImage: _temperatureInImage,
            onChanged: (value) {
              // Cukup panggil _saveTransactionInfo karena listener sudah ada di controller
              _saveTransactionInfo();
            },
            onImageChanged: (newImage) {
              setState(() {
                _temperatureInImage = newImage;
              });
              _saveTransactionInfo();
            },
          ),
          const SizedBox(height: 12),
          // GANTI INPUT SUHU LUAR
          MeasurementInputWidget(
            controller: _tempOutController,
            label: 'Suhu Luar Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: MeasurementLimits(
              id: 'temp_out',
              label: 'Suhu Luar',
              min: 0,
              max: 100,
              normalMax: 0,
              normalMin: 100,
              unit: '°C',
            ),
            transNo: widget.transNo,
            initialImage: _temperatureOutImage,
            onChanged: (value) {
              _saveTransactionInfo();
            },
            onImageChanged: (newImage) {
              setState(() {
                _temperatureOutImage = newImage;
              });
              _saveTransactionInfo();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    ProofOfServiceHeader header,
    ProofOfServiceItemDetail detail,
    Map<String, ValidationStatus> validationStatuses,
  ) {
    final serialKey = detail.serialNo.trim().toUpperCase();
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
      case ValidationStatus.notStarted:
        iconData = Icons.radio_button_unchecked;
        iconColor = Colors.grey;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(detail.articleDesc,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(detail.unitDesc),
            Text('Serial No: ${detail.serialNo}'),
          ],
        ),
        trailing: Icon(iconData, color: iconColor, size: 28),
        onTap: () async {
          // Buka box Hive untuk mencari draft yang mungkin sudah ada
          final box = await Hive.openBox<PosValidationEntryModel>(
              kPosValidationHiveBox);
          final existingData = box.get(detail.serialNo.trim().toUpperCase());

          // Navigasi ke halaman validasi
          final double? indoorTemp = double.tryParse(_tempInController.text);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PosValidationScreen(
                transNo: header.transNo,
                serialNo: detail.serialNo,
                unitType: detail.unitType,
                initialData: existingData,
                articleNo: detail.articleNo,
                articleDesc: detail.articleDesc,
                articleUnitDesc: detail.unitDesc,
                capacity: 0,
                indoorTemp: indoorTemp,
              ),
            ),
          );

          if (mounted) {
            context.read<ProofOfServiceDetailBloc>().add(
                FetchProofOfServiceDetail(header.transNo.trim().toUpperCase()));
          }
        },
      ),
    );
  }

  Widget _buildUnitGroupCard({
    required String title,
    required List<ProofOfServiceItemDetail> units,
    required IconData icon,
    required Color color,
    required ProofOfServiceHeader header,
    required Map<String, ValidationStatus> validationStatuses,
    required bool isEnabled,
  }) {
    // Pesan untuk SnackBar, dibuat dinamis berdasarkan judul kartu
    final String snackBarMessage = title == 'INDOOR'
        ? 'Harap isi Suhu Dalam Ruangan (°C) terlebih dahulu.'
        : 'Harap isi Suhu Luar Ruangan (°C) terlebih dahulu.';

    return Stack(
      children: [
        // WIDGET ASLI: Kartu dengan Opacity
        // Ini adalah widget yang sama seperti solusi sebelumnya,
        // hanya saja tidak dibungkus AbsorbPointer lagi.
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              // Penting: Kita nonaktifkan interaksi internal ExpansionTile jika disabled
              // agar tidak ada efek visual saat diklik (seperti ripple effect).
              enabled: isEnabled,
              leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: FaIcon(icon, size: 18, color: color),
              ),
              title: Text(
                '$title (${units.length} Unit)',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              subtitle: isEnabled
                  ? const Text('Ketuk untuk lihat detail')
                  : Text(
                      title == 'INDOOR'
                          ? 'Isi Suhu Dalam Ruangan Sebelum melanjutkan'
                          : 'Isi Suhu Luar Ruangan Sebelum melanjutkan',
                      style: const TextStyle(
                          color: Colors.orange, fontWeight: FontWeight.w500),
                    ),
              initiallyExpanded: true,
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 8),
              shape: const Border(),
              children: [
                for (int i = 0; i < units.length; i++) ...[
                  _buildDetailCard(
                      context, header, units[i], validationStatuses),
                  if (i < units.length - 1)
                    const Divider(
                      height: 1,
                      color: Colors.grey,
                    ),
                ]
              ],
            ),
          ),
        ),

        // LAPISAN INTERAKTIF: Hanya muncul jika kartu non-aktif
        if (!isEnabled)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Tampilkan SnackBar saat lapisan ini diklik
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(snackBarMessage),
                    backgroundColor: Colors.orange.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              // Beri sedikit visual feedback saat diklik (opsional)
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(snackBarMessage),
                        backgroundColor: Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
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

  Widget _buildRetryButton(PosValidationUploadPartial partial) {
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
              // Tampilkan dialog progress
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                        value: uploadCubit,
                        child: const UploadProgressDialog(),
                      ));
              // Kirim event retry
              context.read<PosSubmittedBloc>().add(
                    RetryPosUpload(
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
}
