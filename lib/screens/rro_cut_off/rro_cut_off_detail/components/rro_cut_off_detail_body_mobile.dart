import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_detail_bloc.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_detail_state.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_form/rro_form_cubit.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_form/rro_form_state.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../models/rro_cut_off/rro_cut_off_detail_model.dart';
import '../../../../models/rro_cut_off/rro_cut_off_entry_model.dart';
import '../../rro_cut_off_input_form/rro_cut_off_input_form_screen.dart';
import '../../rro_cut_off_summary/rro_cut_off_summary_screen.dart';

class RROCutOffDetailBodyMobile extends StatefulWidget {
  final String transNo;

  const RROCutOffDetailBodyMobile({super.key, required this.transNo});

  @override
  State<RROCutOffDetailBodyMobile> createState() =>
      _RROCutOffDetailBodyMobileState();
}

class _RROCutOffDetailBodyMobileState extends State<RROCutOffDetailBodyMobile> {
  late final TextEditingController _picNameController;
  late final TextEditingController _picPhoneController;
  late final TextEditingController _picNikController;
  late final TextEditingController _picPositionController;
  late final TextEditingController _technician1Controller;
  late final TextEditingController _technician2Controller;
  late final TextEditingController _technician3Controller;

  bool _isWH = false;
  bool _isLoadingUser = true;

  // 🔥 VARIABLE UNTUK TOGGLE PIC
  bool _isAdaPic = true;

  String? _storeFrontPhotoPath;
  double _storeFrontLat = 0.0;
  double _storeFrontLng = 0.0;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    _picNameController = TextEditingController();
    _picPhoneController = TextEditingController();
    _picNikController = TextEditingController();
    _picPositionController = TextEditingController();
    _technician1Controller = TextEditingController();
    _technician2Controller = TextEditingController();
    _technician3Controller = TextEditingController();

    _initializeData();
  }

  void _saveDraftLocally() {
    Hive.openBox('rro_form_draft_box').then((box) {
      box.put('${widget.transNo}_picName', _picNameController.text);
      box.put('${widget.transNo}_picPhone', _picPhoneController.text);
      box.put('${widget.transNo}_picNik', _picNikController.text);
      box.put('${widget.transNo}_picPosition', _picPositionController.text);
      box.put('${widget.transNo}_tech1', _technician1Controller.text);
      box.put('${widget.transNo}_tech2', _technician2Controller.text);
      box.put('${widget.transNo}_tech3', _technician3Controller.text);
      box.put('${widget.transNo}_storeFrontPhoto', _storeFrontPhotoPath ?? '');
      box.put('${widget.transNo}_storeFrontLat', _storeFrontLat);
      box.put('${widget.transNo}_storeFrontLng', _storeFrontLng);
      // 🔥 SIMPAN PILIHAN TOGGLE TEKNISI
      box.put('${widget.transNo}_isPicActive', _isAdaPic);
    });
  }

  Future<void> _initializeData() async {
    try {
      final user = await AuthStorage.getUser();
      final vendorCode = user['maintenance_by']?.toString() ?? '';
      final userName = user['name']?.toString() ?? '';
      _isWH = vendorCode.isEmpty || vendorCode.toUpperCase() == 'WH';

      final box = await Hive.openBox('rro_form_draft_box');
      final savedPicName = box.get('${widget.transNo}_picName', defaultValue: '');
      final savedPicPhone = box.get('${widget.transNo}_picPhone', defaultValue: '');
      final savedPicNik = box.get('${widget.transNo}_picNik', defaultValue: '');
      final savedPicPosition = box.get('${widget.transNo}_picPosition', defaultValue: '');
      final savedTech1 = box.get('${widget.transNo}_tech1', defaultValue: '');
      final savedTech2 = box.get('${widget.transNo}_tech2', defaultValue: '');
      final savedTech3 = box.get('${widget.transNo}_tech3', defaultValue: '');
      final savedStoreFront = box.get('${widget.transNo}_storeFrontPhoto', defaultValue: '');

      // 🔥 LOAD PILIHAN TOGGLE DARI HIVE (DEFAULT TRUE)
      _isAdaPic = box.get('${widget.transNo}_isPicActive', defaultValue: true);

      if (savedStoreFront.isNotEmpty) _storeFrontPhotoPath = savedStoreFront;

      _storeFrontLat = box.get('${widget.transNo}_storeFrontLat', defaultValue: 0.0);
      _storeFrontLng = box.get('${widget.transNo}_storeFrontLng', defaultValue: 0.0);

      if (savedPicName.isNotEmpty || savedTech1.isNotEmpty || savedPicPhone.isNotEmpty) {
        _picNameController.text = savedPicName;
        _picPhoneController.text = savedPicPhone;
        _picNikController.text = savedPicNik;
        _picPositionController.text = savedPicPosition;
        _technician1Controller.text = savedTech1;
        _technician2Controller.text = savedTech2;
        _technician3Controller.text = savedTech3;
      } else {
        _technician1Controller.text = userName;
      }

      final formCubit = context.read<RROFormCubit>();
      formCubit.picNameChanged(_picNameController.text);
      formCubit.picPhoneChanged(_picPhoneController.text);
      formCubit.picNikChanged(_picNikController.text);
      formCubit.picPositionChanged(_picPositionController.text);
      formCubit.technician1Changed(_technician1Controller.text);
      formCubit.technician2Changed(_technician2Controller.text);
      formCubit.technician3Changed(_technician3Controller.text);

      if (_technician3Controller.text.isNotEmpty) {
        formCubit.toggleTechnician3(true);
      }
    } catch (e) {
      debugPrint("Gagal Load Form: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _handleTakeStoreFrontPhoto() async {
    setState(() => _isTakingPhoto = true);
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera, maxWidth: 1280, maxHeight: 1280, imageQuality: 85);

      if (image != null) {
        final user = await AuthStorage.getUser();
        final String techName = user['name'] ?? 'Teknisi';
        final deviceModel = user['device_model'] ?? 'Unknown Device';
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'WM_STORE_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String targetPath = p.join(directory.path, fileName);
        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate = '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(timestamp)} $zone';

        String locationString = '';
        double tempLat = 0.0;
        double tempLng = 0.0;

        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
            tempLat = position.latitude;
            tempLng = position.longitude;
            locationString = '$tempLat, $tempLng';
          }
        } catch (e) {
          debugPrint("Gagal narik lokasi GPS: $e");
        }

        final req = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: techName,
          deviceModel: deviceModel,
          location: locationString,
        );

        final String? resultPath = await WatermarkService.processImage(req);
        if (resultPath != null) {
          setState(() {
            _storeFrontPhotoPath = resultPath;
            _storeFrontLat = tempLat;
            _storeFrontLng = tempLng;
          });
          _saveDraftLocally();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengambil foto')));
    } finally {
      setState(() => _isTakingPhoto = false);
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RROFormCubit, RROFormState>(
      listenWhen: (previous, current) =>
      previous.picName != current.picName ||
          previous.picPhone != current.picPhone ||
          previous.picNik != current.picNik ||
          previous.picPosition != current.picPosition ||
          previous.technician1 != current.technician1 ||
          previous.technician2 != current.technician2 ||
          previous.technician3 != current.technician3,
      listener: (context, state) {
        if (_picNameController.text != state.picName) _picNameController.text = state.picName;
        if (_picPhoneController.text != state.picPhone) _picPhoneController.text = state.picPhone;
        if (_picNikController.text != state.picNik) _picNikController.text = state.picNik;
        if (_picPositionController.text != state.picPosition) _picPositionController.text = state.picPosition;
        if (_technician1Controller.text != state.technician1) _technician1Controller.text = state.technician1;
        if (_technician2Controller.text != state.technician2) _technician2Controller.text = state.technician2;
        if (_technician3Controller.text != state.technician3) _technician3Controller.text = state.technician3;
      },
      child: BlocBuilder<RROCutOffDetailBloc, RROCutOffDetailState>(
        builder: (context, detailState) {
          if (detailState is RROCutOffDetailLoading || detailState is RROCutOffDetailInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (detailState is RROCutOffDetailError) {
            return Center(child: Text("Error: ${detailState.message}", style: const TextStyle(color: Colors.red)));
          }

          if (detailState is RROCutOffDetailLoaded) {
            final header = detailState.data.header;
            final detailList = detailState.data.detail;

            final indoorUnits = detailList.where((d) => d.unitType.toUpperCase() == 'IN').toList();
            final outdoorUnits = detailList.where((d) => d.unitType.toUpperCase() == 'OUT').toList();

            return BlocBuilder<RROFormCubit, RROFormState>(
              builder: (context, formState) {
                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 85),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomerSection(header),
                          const SizedBox(height: 16),
                          _buildStoreFrontPhotoSection(),
                          const SizedBox(height: 16),

                          // 🔥 WIDGET TOGGLE MUNCUL JIKA BACKEND is_pic == false 🔥
                          if (header?.isPic == false) ...[
                            _buildSection(
                              title: '',
                              child: SwitchListTile(
                                title: const Text("Ada PIC di Lokasi?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                subtitle: const Text("Matikan jika toko tutup atau PIC tidak ada di tempat.", style: TextStyle(fontSize: 12)),
                                value: _isAdaPic,
                                activeColor: Colors.green.shade700,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isAdaPic = value;
                                  });
                                  _saveDraftLocally();
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 🔥 PANEL PIC MUNCUL JIKA BACKEND=1 ATAU TOGGLE=NYALA 🔥
                          if (header?.isPic == true || _isAdaPic) ...[
                            _buildPicPanel(context, formState),
                            const SizedBox(height: 16),
                          ],

                          _buildTechnicianPanel(context, formState),
                          const SizedBox(height: 16),
                          if (indoorUnits.isNotEmpty)
                            _buildUnitGroupCard(
                                title: 'INDOOR', units: indoorUnits, icon: FontAwesomeIcons.wind, color: Colors.blue.shade700),
                          if (outdoorUnits.isNotEmpty)
                            _buildUnitGroupCard(
                                title: 'OUTDOOR', units: outdoorUnits, icon: FontAwesomeIcons.fan, color: Colors.orange.shade800),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.grey.shade100,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text("Selesai Bongkar",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                              shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            _saveDraftLocally();

                            if (_storeFrontPhotoPath == null || _storeFrontPhotoPath!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Harap ambil Foto Toko Tampak Depan.')));
                              return;
                            }

                            // 🔥 VALIDASI: HANYA BERLAKU JIKA BACKEND=1 ATAU TOGGLE=NYALA 🔥
                            if ((header?.isPic == true || _isAdaPic) && !formState.isPicStoreValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Harap lengkapi Nama dan No HP PIC.')));
                              return;
                            }

                            if (!formState.isTechnicianValid) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Harap isi Nama Teknisi 1.')));
                              return;
                            }

                            final entryBox = await Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox);
                            bool allUnitsCompleted = true;
                            int uncompletedCount = 0;

                            for (var unit in detailList) {
                              final uniqueKey = '${widget.transNo}_${unit.unitType}_${unit.unitIndex}';
                              final entry = entryBox.get(uniqueKey);
                              if (entry == null || entry.isCompleted != true) {
                                allUnitsCompleted = false;
                                uncompletedCount++;
                              }
                            }

                            if (!allUnitsCompleted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Row(children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('Gagal! Masih ada $uncompletedCount unit yang belum diinput fotonya.')),
                                ]),
                                backgroundColor: Colors.red.shade800,
                                behavior: SnackBarBehavior.floating,
                              ));
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RROCutOffSummaryScreen(transNo: widget.transNo, header: header!)),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildStoreFrontPhotoSection() {
    return _buildSection(
      title: 'Foto Toko Tampak Depan',
      child: _isTakingPhoto
          ? Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(child: CircularProgressIndicator()),
      )
          : _storeFrontPhotoPath != null && _storeFrontPhotoPath!.isNotEmpty
          ? Stack(
        children: [
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
                        child: Image.file(File(_storeFrontPhotoPath!)),
                      ),
                      Positioned(
                        top: 10, right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                          onPressed: () => Navigator.pop(context),
                        ),
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
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_storeFrontPhotoPath!), fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          ),
          Positioned(
            top: 8, right: 8,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Hapus Foto?"),
                    content: const Text("Foto toko akan dihapus dan Anda bisa mengambil ulang foto."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BATAL")),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _storeFrontPhotoPath = null;
                            _storeFrontLat = 0.0;
                            _storeFrontLng = 0.0;
                          });
                          _saveDraftLocally();
                        },
                        child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              child: const Icon(Icons.cancel, color: Colors.red, size: 25),
            ),
          ),
        ],
      )
          : InkWell(
        onTap: _handleTakeStoreFrontPhoto,
        child: Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text("Ambil Foto Toko", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
            ],
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
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: (value) {
        if (onChanged != null) onChanged(value);
        _saveDraftLocally();
      },
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: hintText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        suffixIcon: suffixIcon,
        isDense: true,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) => newValue.copyWith(text: newValue.text.toUpperCase())),
      ],
    );
  }

  Widget _buildCustomerSection(RROCutOffHeader? header) {
    if (header == null) return const SizedBox.shrink();
    return _buildSection(
      title: 'Informasi Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toko: ${header.shipToName} (${header.poCustNo})', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Alamat: ${header.shipToAddress}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Cabang: ${header.branchName}', style: const TextStyle(fontSize: 13)),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text('No RRO: ${header.transNo}', style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.build_circle_outlined, size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text('Tipe: ${header.rroType}', style: const TextStyle(fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicPanel(BuildContext context, RROFormState formState) {
    final formCubit = context.read<RROFormCubit>();
    final String? currentPosition = formState.picPosition.isEmpty ? null : formState.picPosition;

    return _buildSection(
      title: 'PIC Toko',
      child: Column(
        children: [
          _buildCustomTextField(
            controller: _picNameController,
            hintText: 'Nama Lengkap PIC',
            icon: Icons.person_outline,
            onChanged: (value) => formCubit.picNameChanged(value),
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _picPhoneController,
            hintText: 'Nomor Telepon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (value) => formCubit.picPhoneChanged(value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  controller: _picNikController,
                  hintText: 'NIK',
                  icon: Icons.badge_outlined,
                  onChanged: (value) => formCubit.picNikChanged(value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: currentPosition,
                  items: kJabatanOptions.map((String jabatan) {
                    return DropdownMenuItem<String>(
                        value: jabatan,
                        child: Text(jabatan, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      _picPositionController.text = newValue;
                      formCubit.picPositionChanged(newValue);
                      _saveDraftLocally();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Jabatan',
                    hintText: 'Pilih Jabatan',
                    prefixIcon: Icon(Icons.work_outline, color: Colors.grey.shade600, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  isExpanded: true,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTechnicianPanel(BuildContext context, RROFormState formState) {
    final formCubit = context.read<RROFormCubit>();
    if (_isLoadingUser) return const Center(child: CircularProgressIndicator());

    return _buildSection(
      title: 'Teknisi Bertugas',
      child: Column(
        children: [
          _buildCustomTextField(
            controller: _technician1Controller,
            hintText: 'Teknisi 1 (Wajib)',
            icon: Icons.engineering,
            readOnly: _isWH,
            onChanged: (value) => formCubit.technician1Changed(value),
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _technician2Controller,
            hintText: 'Teknisi 2',
            icon: Icons.engineering,
            onChanged: (value) => formCubit.technician2Changed(value),
          ),
          const SizedBox(height: 8),
          if (formState.showTechnician3)
            _buildCustomTextField(
              controller: _technician3Controller,
              hintText: 'Teknisi 3',
              icon: Icons.engineering,
              onChanged: (value) => formCubit.technician3Changed(value),
              suffixIcon: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () {
                  _technician3Controller.clear();
                  formCubit.technician3Changed('');
                  _saveDraftLocally();
                  formCubit.toggleTechnician3(false);
                },
              ),
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

  Widget _buildUnitGroupCard(
      {required String title,
        required List<RROCutOffDetailItem> units,
        required IconData icon,
        required Color color}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: FaIcon(icon, size: 18, color: color)),
        title: Text('$title (${units.length} Unit)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8).copyWith(bottom: 8),
        shape: const Border(),
        children: [
          for (int i = 0; i < units.length; i++) ...[
            Builder(builder: (context) {
              return FutureBuilder<Box<RROCutOffEntryModel>>(
                  future: Hive.openBox<RROCutOffEntryModel>(kRROCutOffEntryBox),
                  builder: (context, snapshot) {
                    bool isCompleted = false;
                    String? savedSn;
                    if (snapshot.hasData) {
                      final box = snapshot.data!;
                      final uniqueKey = '${widget.transNo}_${units[i].unitType}_${units[i].unitIndex}';
                      final entry = box.get(uniqueKey);
                      if (entry != null) {
                        isCompleted = entry.isCompleted;
                        savedSn = entry.selectedSerialNumber;
                      }
                    }
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(units[i].articleNameUnit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UNIT $title: ${units[i].unitIndex}', style: const TextStyle(fontSize: 12)),
                          if (isCompleted && savedSn != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('SN: $savedSn', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      trailing: isCompleted
                          ? const Icon(Icons.check_circle, size: 20, color: Colors.green)
                          : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () async {
                        final serialNumbers = (context.read<RROCutOffDetailBloc>().state as RROCutOffDetailLoaded).data.serialNumber;
                        final isUpdated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RROCutOffInputFormScreen(
                                  transNo: widget.transNo, unitData: units[i], availableSerialNumbers: serialNumbers)),
                        );
                        if (isUpdated == true && mounted) setState(() {});
                      },
                    );
                  });
            }),
            if (i < units.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ]
        ],
      ),
    );
  }
}