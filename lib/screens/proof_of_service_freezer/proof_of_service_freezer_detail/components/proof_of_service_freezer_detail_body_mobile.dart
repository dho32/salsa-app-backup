import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/proof_of_service_freezer/posf_form/posf_form_cubit.dart';
import '../../../../blocs/proof_of_service_freezer/posf_form/posf_form_state.dart';
import '../../../../blocs/proof_of_service_freezer/posf_submitted/posf_submitted_bloc.dart';
import '../../../../blocs/proof_of_service_freezer/posf_submitted/posf_submitted_repository.dart';
import '../../../../blocs/proof_of_service_freezer/proof_of_service_freezer_detail/proof_of_service_freezer_detail_bloc.dart';
import '../../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_constants.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_detail_model.dart';
import '../../../../models/proof_of_service_freezer/proof_of_service_freezer_entry_model.dart';
import '../../proof_of_service_freezer_validation/proof_of_service_freezer_validation_screen.dart';

class ProofOfServiceFreezerDetailBodyMobile extends StatefulWidget {
  final String transNo;

  const ProofOfServiceFreezerDetailBodyMobile({super.key, required this.transNo});

  @override
  State<ProofOfServiceFreezerDetailBodyMobile> createState() =>
      _ProofOfServiceFreezerDetailBodyMobileState();
}

class _ProofOfServiceFreezerDetailBodyMobileState
    extends State<ProofOfServiceFreezerDetailBodyMobile> {
  final _picNameController = TextEditingController();
  final _picNikController = TextEditingController();
  final _picPhoneController = TextEditingController();
  final _technician1Controller = TextEditingController();
  final _technician2Controller = TextEditingController();
  final _technician3Controller = TextEditingController();
  final _tech2SearchController = TextEditingController();
  final _tech3SearchController = TextEditingController();

  @override
  void dispose() {
    _picNameController.dispose();
    _picNikController.dispose();
    _picPhoneController.dispose();
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _tech2SearchController.dispose();
    _tech3SearchController.dispose();
    super.dispose();
  }

  void _syncControllers(PosfFormState s) {
    if (_picNameController.text != s.picName) _picNameController.text = s.picName;
    if (_picNikController.text != s.picNik) _picNikController.text = s.picNik;
    if (_picPhoneController.text != s.picPhone) {
      _picPhoneController.text = s.picPhone;
    }
    if (_technician1Controller.text != s.technician1) {
      _technician1Controller.text = s.technician1;
    }
    if (_technician2Controller.text != s.technician2) {
      _technician2Controller.text = s.technician2;
    }
    if (_technician3Controller.text != s.technician3) {
      _technician3Controller.text = s.technician3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PosfFormCubit, PosfFormState>(
      listener: (context, state) => _syncControllers(state),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<ProofOfServiceFreezerDetailBloc, ProofOfServiceFreezerDetailState>(
              builder: (context, detailState) {
                if (detailState is ProofOfServiceFreezerDetailLoading ||
                    detailState is ProofOfServiceFreezerDetailInitial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (detailState is ProofOfServiceFreezerDetailError) {
                  return _buildError(context, detailState.message);
                }
                final loaded = detailState as ProofOfServiceFreezerDetailLoaded;
                final header = loaded.data.header;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (header != null) _buildCustomerPanel(header),
                    if (header != null) _buildTicketPanel(header),
                    _buildPicPanel(),
                    _buildTechnicianPanel(),
                    _buildFreezerListPanel(loaded),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text('Gagal memuat data: $message', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context
                  .read<ProofOfServiceFreezerDetailBloc>()
                  .add(FetchProofOfServiceFreezerDetail(widget.transNo)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Panel-panel
  // ---------------------------------------------------------------------------

  // Format panel sama dengan POS: Container putih + shadow lembut (tanpa Card/Divider).
  Widget _panel({required String title, Widget? headerAction, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
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
      ),
    );
  }

  Widget _buildCustomerPanel(ProofOfServiceFreezerHeader h) {
    return _panel(
      title: 'Informasi Customer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Toko: ${h.shipToName} (${h.shipTo})',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text('Alamat: ${h.shipToAddress}',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Cabang: ${h.branchName} (${h.branchCode})',
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTicketPanel(ProofOfServiceFreezerHeader h) {
    return _panel(
      title: 'Informasi Tiket',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(child: Text('No: ${h.transNo}')),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text('Jadwal Cuci: ${h.poDate}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicPanel() {
    return BlocBuilder<PosfFormCubit, PosfFormState>(
      buildWhen: (p, c) =>
          p.picName != c.picName ||
          p.picNik != c.picNik ||
          p.picPosition != c.picPosition ||
          p.picPhone != c.picPhone,
      builder: (context, state) {
        final cubit = context.read<PosfFormCubit>();
        return _panel(
          title: 'PIC Toko',
          child: Column(
            children: [
              _buildTextField(
                controller: _picNameController,
                label: 'Nama Lengkap PIC',
                icon: Icons.person_outline,
                onChanged: (v) {
                  cubit.picNameChanged(v);
                  cubit.onFieldChanged();
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _picPhoneController,
                label: 'Nomor Telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (v) {
                  cubit.picPhoneChanged(v);
                  cubit.onFieldChanged();
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _picNikController,
                      label: 'NIK',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        cubit.picNikChanged(v);
                        cubit.onFieldChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPositionDropdown(state.picPosition, (v) {
                      cubit.picPositionChanged(v ?? '');
                      cubit.onFieldChanged();
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTechnicianPanel() {
    return BlocBuilder<PosfFormCubit, PosfFormState>(
      buildWhen: (p, c) =>
          p.technician1 != c.technician1 ||
          p.technician2 != c.technician2 ||
          p.technician3 != c.technician3 ||
          p.showTechnician3 != c.showTechnician3,
      builder: (context, state) {
        final cubit = context.read<PosfFormCubit>();
        final bool isWH = cubit.userType == 'WH';
        final technicianList = cubit.technicianList;
        final bool useDropdown = isWH && technicianList.isNotEmpty;

        return _panel(
          title: 'Teknisi Bertugas',
          child: Column(
            children: [
              _buildTextField(
                controller: _technician1Controller,
                label: 'Teknisi 1',
                icon: Icons.engineering,
                readOnly: isWH,
                onChanged: (v) {
                  cubit.technician1Changed(v);
                  cubit.onFieldChanged();
                },
              ),
              const SizedBox(height: 10),
              if (useDropdown)
                _buildTechnicianDropdown(
                  label: 'Teknisi 2',
                  value: state.technician2,
                  technicianList: technicianList,
                  excludedName: state.technician3,
                  searchController: _tech2SearchController,
                  onChanged: (v) {
                    cubit.technician2Changed(v ?? '');
                    cubit.onFieldChanged();
                  },
                  onClear: state.technician2.isNotEmpty
                      ? () {
                          cubit.technician2Changed('');
                          cubit.onFieldChanged();
                        }
                      : null,
                )
              else
                _buildTextField(
                  controller: _technician2Controller,
                  label: 'Teknisi 2',
                  icon: Icons.engineering,
                  onChanged: (v) {
                    cubit.technician2Changed(v);
                    cubit.onFieldChanged();
                  },
                ),
              const SizedBox(height: 8),
              if (state.showTechnician3)
                if (useDropdown)
                  Row(
                    children: [
                      Expanded(
                        child: _buildTechnicianDropdown(
                          label: 'Teknisi 3',
                          value: state.technician3,
                          technicianList: technicianList,
                          excludedName: state.technician2,
                          searchController: _tech3SearchController,
                          onChanged: (v) {
                            cubit.technician3Changed(v ?? '');
                            cubit.onFieldChanged();
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          cubit.technician3Changed('');
                          cubit.toggleTechnician3(false);
                          cubit.onFieldChanged();
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                      ),
                    ],
                  )
                else
                  _buildTextField(
                    controller: _technician3Controller,
                    label: 'Teknisi 3',
                    icon: Icons.engineering,
                    suffixIcon: IconButton(
                      onPressed: () {
                        cubit.technician3Changed('');
                        cubit.toggleTechnician3(false);
                        cubit.onFieldChanged();
                      },
                      icon: const Icon(Icons.cancel, color: Colors.red),
                    ),
                    onChanged: (v) {
                      cubit.technician3Changed(v);
                      cubit.onFieldChanged();
                    },
                  )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => cubit.toggleTechnician3(true),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Teknisi 3'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFreezerListPanel(ProofOfServiceFreezerDetailLoaded loaded) {
    final items = loaded.data.items;
    return _panel(
      title: 'Daftar Freezer (${items.length})',
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _onScanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
            ),
          ),
          const SizedBox(height: 4),
          ...items.map((item) {
            final key = freezerEntryKey(
                widget.transNo, item.serialNo, item.isGeneric, item.unitIndex);
            final status =
                loaded.statuses[key] ?? FreezerValidationStatus.notStarted;
            return _buildFreezerTile(item, status);
          }),
        ],
      ),
    );
  }

  Widget _buildFreezerTile(ProofOfServiceFreezerItem item, FreezerValidationStatus status) {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (status) {
      case FreezerValidationStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Selesai';
        break;
      case FreezerValidationStatus.inProgress:
        icon = Icons.timelapse;
        color = Colors.orange;
        label = 'Berlangsung';
        break;
      case FreezerValidationStatus.notStarted:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
        label = 'Belum';
        break;
    }
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(item.articleDesc,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(item.serialNo, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11)),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
        onTap: () => _onTapFreezer(item),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<PosfFormCubit, PosfFormState>(
      buildWhen: (p, c) => p.isFormReadyToSubmit != c.isFormReadyToSubmit,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: state.isFormReadyToSubmit ? _onSubmit : null,
              child: const Text('Selesai'),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Field helpers
  // ---------------------------------------------------------------------------

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        isDense: true,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildPositionDropdown(String value, ValueChanged<String?> onChanged) {
    final currentValue = kJabatanOptions.contains(value) ? value : null;
    return DropdownButtonFormField<String>(
      value: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Jabatan',
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: const Text('Pilih jabatan', style: TextStyle(fontSize: 14)),
      items: kJabatanOptions
          .map((j) => DropdownMenuItem(value: j, child: Text(j)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTechnicianDropdown({
    required String label,
    required String value,
    required List<Map<String, String>> technicianList,
    required String excludedName,
    required TextEditingController searchController,
    required ValueChanged<String?> onChanged,
    VoidCallback? onClear,
  }) {
    final filtered = technicianList
        .where((t) =>
            excludedName.isEmpty || t['technician_name'] != excludedName)
        .toList();

    // Nilai tersimpan yang tidak ada di daftar (draft lama / roster berubah)
    // tetap ditampilkan sebagai item agar tidak hilang diam-diam.
    if (value.isNotEmpty &&
        !filtered.any((t) => t['technician_name'] == value)) {
      filtered.insert(0, {'technician_id': '', 'technician_name': value});
    }
    final currentValue =
        filtered.any((t) => t['technician_name'] == value) ? value : null;

    final dropdown = DropdownButtonFormField2<String>(
      value: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(Icons.engineering, color: Colors.grey.shade600, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: 'Cari teknisi...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) => item.value
            .toString()
            .toLowerCase()
            .contains(searchValue.toLowerCase()),
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

  // ---------------------------------------------------------------------------
  // Actions (sebagian masih placeholder — diselesaikan di fase berikutnya)
  // ---------------------------------------------------------------------------

  Future<void> _openWizard(ProofOfServiceFreezerItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProofOfServiceFreezerValidationScreen(
          transNo: widget.transNo,
          serialNo: item.serialNo,
          isGeneric: item.isGeneric,
          unitIndex: item.unitIndex,
          articleNo: item.articleNo,
          articleDesc: item.articleDesc,
        ),
      ),
    );
    // Refresh status freezer setelah kembali dari wizard.
    if (!mounted) return;
    context
        .read<ProofOfServiceFreezerDetailBloc>()
        .add(FetchProofOfServiceFreezerDetail(widget.transNo));
  }

  void _onTapFreezer(ProofOfServiceFreezerItem item) => _openWizard(item);

  Future<void> _onScanBarcode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final state = context.read<ProofOfServiceFreezerDetailBloc>().state;
    if (state is! ProofOfServiceFreezerDetailLoaded) return;

    final matches = state.data.items.where(
      (it) => it.serialNo.trim().toUpperCase() == scanned.trim().toUpperCase(),
    );
    if (matches.isEmpty) {
      _showSnack('Freezer "$scanned" tidak ada di daftar tugas ini.');
      return;
    }
    _openWizard(matches.first);
  }

  Future<void> _onSubmit() async {
    final detailState = context.read<ProofOfServiceFreezerDetailBloc>().state;
    if (detailState is! ProofOfServiceFreezerDetailLoaded ||
        detailState.data.header == null) {
      return;
    }
    final header = detailState.data.header!;
    final formCubit = context.read<PosfFormCubit>();
    final otpBloc = context.read<OtpBloc>();
    final locationBloc = context.read<LocationValidationBloc>();
    final uploadCubit = context.read<UploadProgressCubit>();
    final submittedBloc = context.read<PosfSubmittedBloc>();

    // Freezer "Ada Keluhan" wajib punya tiket SC aktif (pola POS). Bila belum
    // ada, blokir submit & arahkan teknisi koordinasi dengan PIC toko.
    final blokirKarenaSc = await _checkServiceCallBlocking(header.transNo);
    if (!mounted || blokirKarenaSc) return;

    final isPhotoReady = formCubit.state.picImageDetail != null;
    final wajibOtp = await OtpStorage.isOtpRequired();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: otpBloc),
          BlocProvider.value(value: locationBloc),
          BlocProvider.value(value: uploadCubit),
        ],
        child: OtpDialog(
          transNo: header.transNo,
          shipTo: header.shipTo,
          email: header.shipToMail,
          storeLat: header.latitude,
          storeLong: header.longitude,
          isPhotoExisting: isPhotoReady,
          isOtpRequired: wajibOtp,
          onVerified: () async {
            Navigator.pop(context); // tutup OTP dialog
            final user = await AuthStorage.getUser();
            final ip = await getPublicIpAddress();
            if (!mounted) return;
            submittedBloc.add(SubmitPosfValidation(
              transNo: header.transNo,
              createdBy: user['user_id'] ?? '',
              createdByName: user['name'] ?? '',
              createdByIP: ip,
              progressCubit: uploadCubit,
            ));
          },
        ),
      ),
    );
  }

  /// Bila ada freezer berkondisi "Ada Keluhan" tapi toko belum punya tiket SC
  /// aktif, tampilkan dialog info (pola POS) & kembalikan `true` untuk memblokir
  /// submit. Mengembalikan `false` bila tidak ada keluhan atau SC sudah ada.
  Future<bool> _checkServiceCallBlocking(String transNo) async {
    final tx = transNo.trim().toUpperCase();
    final entryBox =
        Hive.box<ProofOfServiceFreezerEntryModel>(kProofOfServiceFreezerEntryBox);
    final adaKeluhan = entryBox.values.any((e) =>
        e.transNo.trim().toUpperCase() == tx &&
        e.generalCondition == kPosfConditionComplaint);
    if (!adaKeluhan) return false;

    final hasActiveSc =
        await PosfSubmittedRepository().checkActiveServiceCall(tx);
    if (!mounted || hasActiveSc) return false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Unit Bermasalah Terdeteksi'),
        content: const Text(kStringDialogUnitProblem),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
    return true;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
