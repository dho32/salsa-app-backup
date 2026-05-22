import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../../../../blocs/location_validation/location_validation_state.dart';
import '../../../../blocs/otp/otp_state.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../models/rro_cut_off/rro_cut_off_detail_model.dart';
import '../../../../models/rro_cut_off/rro_cut_off_entry_model.dart';
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_submit/rro_cut_off_submit_bloc.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_submit/rro_cut_off_submit_event.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_submit/rro_cut_off_submit_state.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../blocs/location_validation/location_validation_bloc.dart';

class RROCutOffSummaryBodyMobile extends StatefulWidget {
  final String transNo;
  final RROCutOffHeader header;

  const RROCutOffSummaryBodyMobile({
    super.key,
    required this.transNo,
    required this.header,
  });

  @override
  State<RROCutOffSummaryBodyMobile> createState() =>
      _RROCutOffSummaryBodyMobileState();
}

class _RROCutOffSummaryBodyMobileState
    extends State<RROCutOffSummaryBodyMobile> {
  bool _isLoading = true;
  Map<String, dynamic> _formData = {};
  List<RROCutOffEntryModel> _unitEntries = [];
  String? _storeFrontPhotoPath;
  String? _picPhotoPath;
  double _picLat = 0.0;
  double _picLng = 0.0;

  // 🔥 VARIABLE PENAMPUNG STATE TOGGLE
  bool _isPicActive = true;

  // Validasi scroll & checkbox
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isDataVerified = false;

  @override
  void initState() {
    super.initState();
    _loadSummaryData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 20) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  void _checkIfScrollable() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent <= 0) {
      setState(() {
        _hasScrolledToBottom = true;
      });
    }
  }

  Future<void> _loadSummaryData() async {
    try {
      final draftBox = await Hive.openBox('rro_form_draft_box');
      _formData = {
        'picName': draftBox.get('${widget.transNo}_picName', defaultValue: '-'),
        'picPhone': draftBox.get('${widget.transNo}_picPhone', defaultValue: '-'),
        'picNik': draftBox.get('${widget.transNo}_picNik', defaultValue: '-'),
        'picPosition': draftBox.get('${widget.transNo}_picPosition', defaultValue: '-'),
        'tech1': draftBox.get('${widget.transNo}_tech1', defaultValue: '-'),
        'tech2': draftBox.get('${widget.transNo}_tech2', defaultValue: '-'),
        'tech3': draftBox.get('${widget.transNo}_tech3', defaultValue: '-'),
      };

      _storeFrontPhotoPath = draftBox.get('${widget.transNo}_storeFrontPhoto', defaultValue: '');

      // 🔥 LOAD STATE TOGGLE DARI HIVE
      _isPicActive = draftBox.get('${widget.transNo}_isPicActive', defaultValue: true);

      final entryBox = await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
      _unitEntries = entryBox.values.where((e) => e.transNo == widget.transNo).toList();
    } catch (e) {
      debugPrint("Error load summary: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkIfScrollable();
        });
      }
    }
  }

  Future<Map<String, dynamic>> _generatePayload() async {
    final user = await AuthStorage.getUser();
    final String vendorCode = user['maintenance_by']?.toString() ?? '';
    final String createdBy = user['user_id']?.toString() ?? '';
    final String deviceModel = user['device_model']?.toString() ?? 'Mobile App';

    final draftBox = await Hive.openBox('rro_form_draft_box');
    final storeFrontPath = draftBox.get('${widget.transNo}_storeFrontPhoto', defaultValue: '');
    final storeFrontLat = draftBox.get('${widget.transNo}_storeFrontLat', defaultValue: 0.0);
    final storeFrontLng = draftBox.get('${widget.transNo}_storeFrontLng', defaultValue: 0.0);

    // 🔥 VARIABEL MUTLAK PENENTU PIC
    final bool finalIsPic = widget.header.isPic || _isPicActive;

    final List<RROCutOffEntryModel> indoorEntries = _unitEntries.where((u) => u.unitType.toUpperCase() == 'IN').toList();
    final List<RROCutOffEntryModel> outdoorEntries = _unitEntries.where((u) => u.unitType.toUpperCase() == 'OUT').toList();

    List<Map<String, dynamic>> unitsIndoor = indoorEntries.map((unit) {
      return {
        "line_no": unit.lineNo,
        "unit_index": unit.unitIndex,
        "unit_type": unit.unitType,
        "article_no": unit.rroArticleNo,
        "serial_no": unit.selectedSerialNumber,
        "dismantle_images": unit.photos.map((p) => p.toJson()).toList(),
      };
    }).toList();

    List<Map<String, dynamic>> unitsOutdoor = outdoorEntries.map((unit) {
      return {
        "line_no": unit.lineNo,
        "unit_index": unit.unitIndex,
        "unit_type": unit.unitType,
        "article_no": unit.rroArticleNo,
        "serial_no": unit.selectedSerialNumber,
        "dismantle_images": unit.photos.map((p) => p.toJson()).toList(),
      };
    }).toList();

    String getFileTimestamp(String path) {
      try {
        final file = File(path);
        if (file.existsSync()) return file.lastModifiedSync().toIso8601String();
      } catch (_) {}
      return DateTime.now().toIso8601String();
    }

    return {
      "trans_no": widget.transNo,
      "vendor_code": vendorCode,
      "is_pic": finalIsPic, // 🔥 PAKAI VARIABEL PENENTU
      "pic_name": finalIsPic ? _formData['picName'] : "",
      "pic_phone": finalIsPic ? _formData['picPhone'] : "",
      "pic_nik": finalIsPic ? _formData['picNik'] : "",
      "pic_position": finalIsPic ? _formData['picPosition'] : "",
      "pic_image_detail": (finalIsPic && _picPhotoPath != null && _picPhotoPath!.isNotEmpty)
          ? {
        "image_file_name": _picPhotoPath!.split('/').last,
        "timestamp": getFileTimestamp(_picPhotoPath!),
        "latitude": _picLat,
        "longitude": _picLng,
        "device": deviceModel
      }
          : null,
      "technician_1": _formData['tech1'],
      "technician_2": _formData['tech2'],
      "technician_3": _formData['tech3'],
      "start_date": DateTime.now().toIso8601String(),
      "finish_date": DateTime.now().toIso8601String(),
      "created_by": createdBy,
      "store_front_image": (storeFrontPath.isNotEmpty)
          ? {
        "image_file_name": storeFrontPath.split('/').last,
        "timestamp": getFileTimestamp(storeFrontPath),
        "latitude": storeFrontLat,
        "longitude": storeFrontLng,
        "device": deviceModel
      }
          : null,
      "units_indoor": unitsIndoor,
      "units_outdoor": unitsOutdoor,
    };
  }

  void _confirmSubmit() {
    final submitBloc = context.read<RROCutOffSubmitBloc>();
    final uploadCubit = context.read<UploadProgressCubit>();
    final otpBloc = context.read<OtpBloc>();
    final locationBloc = context.read<LocationValidationBloc>();

    // 🔥 VARIABEL MUTLAK PENENTU PIC
    final bool finalIsPic = widget.header.isPic || _isPicActive;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Kirim Data?"),
        content: const Text(
            "Pastikan semua data sudah benar. Data yang sudah dikirim tidak dapat diubah kembali."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("BATAL")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;

              // 🔥 BYPASS OTP JIKA FINAL PIC == FALSE
              if (finalIsPic == false) {
                final payloadData = await _generatePayload();
                submitBloc.add(SubmitRroData(
                    payload: payloadData,
                    progressCubit: uploadCubit,
                    transNo: widget.transNo,
                    storeName: widget.header.shipToName)); // 🔥 TAMBAHAN STORE NAME
                return;
              }

              final wajibOtp = await OtpStorage.isOtpRequired();

              if (!mounted) return;

              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (otpContext) {
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: otpBloc),
                      BlocProvider.value(value: uploadCubit),
                      BlocProvider.value(value: locationBloc),
                    ],
                    child: BlocListener<LocationValidationBloc,
                        LocationValidationState>(
                      listener: (context, state) {
                        if (state is LocationPhotoLoaded && state.photo != null) {
                          _picPhotoPath = state.photo!.imagePath;
                          _picLat = state.photo!.latitude;
                          _picLng = state.photo!.longitude;
                        } else if (state is LocationValidationFailure && state.photo != null) {
                          _picPhotoPath = state.photo!.imagePath;
                          _picLat = state.photo!.latitude;
                          _picLng = state.photo!.longitude;
                        }
                      },
                      child: OtpDialog(
                        transNo: widget.transNo,
                        shipTo: widget.header.shipTo,
                        email: widget.header.shipToMail,
                        storeLat: double.tryParse(widget.header.latitude.toString()) ?? 0.0,
                        storeLong: double.tryParse(widget.header.longitude.toString()) ?? 0.0,
                        isPhotoExisting: true,
                        isOtpRequired: wajibOtp,
                        onVerified: () async {
                          Navigator.pop(otpContext);

                          final isViaOtp = otpBloc.state is OtpVerified;

                          if (isViaOtp) {
                            setState(() {
                              _picPhotoPath = null;
                              _picLat = 0.0;
                              _picLng = 0.0;
                            });
                          } else {
                            if (_picPhotoPath != null) {
                              final draftBox = await Hive.openBox('rro_form_draft_box');
                              await draftBox.put('${widget.transNo}_picPhotoPath', _picPhotoPath);
                              await draftBox.put('${widget.transNo}_picLat', _picLat);
                              await draftBox.put('${widget.transNo}_picLng', _picLng);
                            }
                          }

                          final payloadData = await _generatePayload();
                          submitBloc.add(SubmitRroData(
                              payload: payloadData,
                              progressCubit: uploadCubit,
                              transNo: widget.transNo,
                              storeName: widget.header.shipToName)); // 🔥 TAMBAHAN STORE NAME
                        },
                      ),
                    ),
                  );
                },
              );
            },
            child: const Text("YA, KIRIM"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    // 🔥 VARIABEL MUTLAK PENENTU PIC UI
    final bool finalIsPic = widget.header.isPic || _isPicActive;

    Map<int, List<RROCutOffEntryModel>> groupedUnits = {};
    for (var unit in _unitEntries) {
      groupedUnits.putIfAbsent(unit.unitIndex, () => []).add(unit);
    }

    return BlocListener<RROCutOffSubmitBloc, RROCutOffSubmitState>(
      listener: (context, state) {
        if (state.status == RROCutOffSubmitStatus.uploading) {
          final uploadCubit = context.read<UploadProgressCubit>();
          showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => BlocProvider.value(
                  value: uploadCubit, child: const UploadProgressDialog()));
        } else if (state.status == RROCutOffSubmitStatus.success) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          showSuccessDialog(context, "Data RRO Cut Off berhasil dikirim.",
              onOk: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst));
        } else if (state.status == RROCutOffSubmitStatus.uploadPartial) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          showPartialUploadDialog(context, state.successCount,
              state.failureCount, state.failedFiles);
        } else if (state.status == RROCutOffSubmitStatus.failure) {
          if (Navigator.canPop(context)) Navigator.pop(context);
          showFailureDialog(context, state.errorMessage);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerSection(widget.header),
                  const SizedBox(height: 16),
                  _buildStoreFrontPhotoCard(),
                  const SizedBox(height: 16),

                  // 🔥 TAMPILAN PIC MENGGUNAKAN LOGIC MUTLAK
                  if (finalIsPic) ...[
                    _buildTeamInfoCard(),
                    const SizedBox(height: 24),
                  ] else ...[
                    _buildTechOnlyCard(),
                    const SizedBox(height: 24),
                  ],

                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Daftar Unit Selesai Bongkar",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...groupedUnits.entries.map((entry) =>
                            _buildGroupedUnitCard(entry.key, entry.value)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _hasScrolledToBottom
                ? Container(
              key: const ValueKey('checkbox_area'),
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isDataVerified,
                    activeColor: Colors.green.shade700,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDataVerified = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDataVerified = !_isDataVerified;
                        });
                      },
                      child: const Text(
                        "Saya memastikan bahwa data & foto bongkar yang diinput sudah benar.",
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            )
                : Container(
              key: const ValueKey('scroll_hint_area'),
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.keyboard_double_arrow_down,
                      color: Colors.orange.shade800),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Silakan scroll layar ke paling bawah untuk menyetujui data.",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("KIRIM DATA SEKARANG",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: (_hasScrolledToBottom && _isDataVerified)
                    ? Colors.green.shade700
                    : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (!_hasScrolledToBottom) return;
                if (!_isDataVerified) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Harap centang persetujuan data terlebih dahulu.')),
                  );
                  return;
                }
                _confirmSubmit();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreFrontPhotoCard() {
    if (_storeFrontPhotoPath == null || _storeFrontPhotoPath!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Foto Toko Tampak Depan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      InteractiveViewer(
                          child: Image.file(File(_storeFrontPhotoPath!))),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: IconButton(
                            icon: const Icon(Icons.cancel,
                                color: Colors.white, size: 36),
                            onPressed: () => Navigator.pop(context)),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_storeFrontPhotoPath!),
                    fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(RROCutOffHeader header) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Customer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('Toko: ${header.shipToName} (${header.poCustNo})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Alamat: ${header.shipToAddress}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Cabang: ${header.branchName}',
              style: const TextStyle(fontSize: 13)),
          const Divider(height: 24),
          Row(children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
                child: Text('No RRO: ${header.transNo}',
                    style: const TextStyle(fontWeight: FontWeight.w600)))
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.build_circle_outlined,
                size: 16, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
                child: Text('Tipe: ${header.rroType}',
                    style: const TextStyle(fontSize: 13)))
          ]),
        ],
      ),
    );
  }

  Widget _buildTeamInfoCard() {
    return Container(
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
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.person, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 6),
                    const Text("PIC Toko",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))
                  ]),
                  const SizedBox(height: 12),
                  Text("${_formData['picName']} | ${_formData['picPosition']}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(_formData['picPhone'],
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700)))
                  ]),
                ],
              ),
            ),
            const VerticalDivider(
                width: 32, thickness: 1, color: Colors.black12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.engineering,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 6),
                    const Text("Teknisi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))
                  ]),
                  const SizedBox(height: 12),
                  Text("1. ${_formData['tech1']}",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (_formData['tech2'].isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text("2. ${_formData['tech2']}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                  if (_formData['tech3'].isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text("3. ${_formData['tech3']}",
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey.shade800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechOnlyCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.engineering, size: 16, color: Colors.orange.shade800),
            const SizedBox(width: 6),
            const Text("Tim Teknisi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
          ]),
          const SizedBox(height: 12),
          Text("1. ${_formData['tech1']}",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          if (_formData['tech2'].isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("2. ${_formData['tech2']}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          if (_formData['tech3'].isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text("3. ${_formData['tech3']}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildGroupedUnitCard(int index, List<RROCutOffEntryModel> units) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(children: [
              const Icon(Icons.inventory_2, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text("SET AC - INDEX $index",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87))
            ]),
          ),
          ...units.map((u) {
            bool isIndoor = u.unitType.toUpperCase() == 'IN';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(
                            isIndoor
                                ? FontAwesomeIcons.wind
                                : FontAwesomeIcons.fan,
                            size: 14,
                            color: isIndoor
                                ? Colors.blue.shade700
                                : Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Text(isIndoor ? "INDOOR" : "OUTDOOR",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isIndoor
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade800))
                      ]),
                      Text("SN: ${u.selectedSerialNumber}",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: u.photos
                            .map((photo) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(File(photo.imagePath),
                                    width: 45,
                                    height: 45,
                                    fit: BoxFit.cover))))
                            .toList()),
                  ),
                  if (u != units.last)
                    const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Divider(height: 1, thickness: 1)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}