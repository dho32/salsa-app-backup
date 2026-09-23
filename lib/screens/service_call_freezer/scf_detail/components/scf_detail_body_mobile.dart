import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/service_call_freezer/scf_detail/scf_detail_bloc.dart';
import '../../../../blocs/service_call_freezer/scf_form/scf_form_cubit.dart';
import '../../../../blocs/service_call_freezer/scf_form/scf_form_state.dart';
import '../../../../blocs/service_call_freezer/scf_submitted/scf_submitted_bloc.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/service_call_freezer/scf_validation_entry_model.dart';
import '../../../../models/service_call_freezer/service_call_freezer_detail_model.dart';
import '../../scf_validation/scf_validation_screen.dart';

class ScfDetailBodyMobile extends StatefulWidget {
  final String transNo;

  const ScfDetailBodyMobile({super.key, required this.transNo});

  @override
  State<ScfDetailBodyMobile> createState() => _ScfDetailBodyMobileState();
}

class _ScfDetailBodyMobileState extends State<ScfDetailBodyMobile> {
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

  void _syncControllers(ScfFormState s) {
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
    return BlocListener<ScfFormCubit, ScfFormState>(
      listener: (context, state) => _syncControllers(state),
      child: BlocListener<ScfSubmittedBloc, ScfSubmittedState>(
        listener: _onSubmittedState,
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<ScfDetailBloc, ScfDetailState>(
                builder: (context, detailState) {
                  if (detailState is ScfDetailLoading ||
                      detailState is ScfDetailInitial) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (detailState is ScfDetailError) {
                    return _buildError(context, detailState.message);
                  }
                  final loaded = detailState as ScfDetailLoaded;
                  final header = loaded.data.header;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _buildCustomerPanel(header),
                      _buildTicketPanel(header),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submit result / AHO / OTP flow (mirror Service Call)
  // ---------------------------------------------------------------------------
  Future<void> _onSubmittedState(
      BuildContext context, ScfSubmittedState state) async {
    if (state is ScfFinalValidationLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    } else if (state is ScfProceedToAhoDialog) {
      Navigator.of(context, rootNavigator: true).pop();
      await _showAhoDialog(context, state);
    } else if (state is ScfProceedToOtpDialog) {
      Navigator.of(context, rootNavigator: true).pop();
      await _showOtpDialog(context, state);
    } else if (state is ScfUploadInProgress) {
      final uploadCubit = context.read<UploadProgressCubit>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: uploadCubit,
          child: const UploadProgressDialog(),
        ),
      );
    } else if (state is ScfUploadPartial) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      if (state.failureCount > 0) {
        showPartialUploadDialog(
            context, state.successCount, state.failureCount, state.failedFiles);
      }
    } else if (state is ScfSubmitSuccess) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showSuccessDialog(context, 'Data Service Call Freezer berhasil dikirim.',
          onOk: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } else if (state is ScfSubmitFailure) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showFailureDialog(context, state.error);
    }
  }

  // Dialog input nomor AHO (inline — AhoDialog SC terikat ScFormState).
  Future<void> _showAhoDialog(
      BuildContext context, ScfProceedToAhoDialog state) async {
    final controller = TextEditingController(text: state.initialAho ?? '');
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Nomor AHO'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nomor AHO (*Wajib)',
              hintText: 'Masukkan nomor AHO',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nomor AHO wajib diisi' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx);
                context.read<ScfSubmittedBloc>().add(ScfAhoInputCompleted(
                      formState: state.formState,
                      ahoNumber: controller.text.trim(),
                    ));
              }
            },
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Future<void> _showOtpDialog(
      BuildContext context, ScfProceedToOtpDialog state) async {
    final detailState = context.read<ScfDetailBloc>().state;
    if (detailState is! ScfDetailLoaded) return;
    final header = detailState.data.header;

    final otpBloc = context.read<OtpBloc>();
    final locationBloc = context.read<LocationValidationBloc>();
    final uploadCubit = context.read<UploadProgressCubit>();
    final submittedBloc = context.read<ScfSubmittedBloc>();
    final formCubit = context.read<ScfFormCubit>();

    final isPhotoReady = formCubit.state.picImageDetail != null;
    // Freezer (Service Call Freezer) tidak memakai OTP — gerbang submit cukup
    // validasi lokasi via foto PIC toko (geofence). Paksa isOtpRequired=false
    // agar menghapus foto PIC tidak pernah jatuh ke UI OTP.
    if (!context.mounted) return;

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
          shipToName: header.shipToName,
          email: header.shipToMail,
          storeLat: header.latitude,
          storeLong: header.longitude,
          isPhotoExisting: isPhotoReady,
          isOtpRequired: false,
          onVerified: () async {
            Navigator.pop(context);
            final user = await AuthStorage.getUser();
            final ip = await getPublicIpAddress();
            if (!context.mounted) return;
            submittedBloc.add(SubmitScfValidation(
              transNo: header.transNo,
              createdBy: user['user_id'] ?? '',
              createdByName: user['name'] ?? '',
              createdByIP: ip,
              progressCubit: uploadCubit,
              storeName: header.shipToName,
              ahoNumber: state.ahoNumber,
              pathAttachment: header.pathAttachment,
            ));
          },
        ),
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
                  .read<ScfDetailBloc>()
                  .add(FetchScfDetail(widget.transNo)),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Panels
  // ---------------------------------------------------------------------------
  Widget _panel({required String title, required Widget child}) {
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
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerPanel(ScfHeader h) {
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

  Widget _buildTicketPanel(ScfHeader h) {
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
              const Icon(Icons.report_problem_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Keluhan: ${h.complaintSubject}',
                      style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 16, color: Colors.black54),
              const SizedBox(width: 8),
              Text('Tanggal: ${h.postedDate}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPicPanel() {
    return BlocBuilder<ScfFormCubit, ScfFormState>(
      buildWhen: (p, c) =>
          p.picName != c.picName ||
          p.picNik != c.picNik ||
          p.picPosition != c.picPosition ||
          p.picPhone != c.picPhone,
      builder: (context, state) {
        final cubit = context.read<ScfFormCubit>();
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
                      label: 'NIK Karyawan',
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
    return BlocBuilder<ScfFormCubit, ScfFormState>(
      buildWhen: (p, c) =>
          p.technician1 != c.technician1 ||
          p.technician2 != c.technician2 ||
          p.technician3 != c.technician3 ||
          p.showTechnician3 != c.showTechnician3,
      builder: (context, state) {
        final cubit = context.read<ScfFormCubit>();
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

  Widget _buildFreezerListPanel(ScfDetailLoaded loaded) {
    final units = loaded.data.units;
    return _panel(
      title: 'Daftar Freezer (${units.length})',
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
          ...units.map((unit) {
            final key = scfEntryKey(
                widget.transNo, unit.serialNo, unit.isGeneric, unit.unitIndex);
            final status =
                loaded.statuses[key] ?? ScfValidationStatus.notStarted;
            return _buildFreezerTile(unit, status);
          }),
        ],
      ),
    );
  }

  Widget _buildFreezerTile(ScfFreezerUnit unit, ScfValidationStatus status) {
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (status) {
      case ScfValidationStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Selesai';
        break;
      case ScfValidationStatus.inProgress:
        icon = Icons.timelapse;
        color = Colors.orange;
        label = 'Berlangsung';
        break;
      case ScfValidationStatus.notStarted:
        icon = Icons.radio_button_unchecked;
        color = Colors.grey;
        label = 'Belum';
        break;
    }
    final subtitle = unit.isGeneric
        ? 'Generic - ${unit.unitDesc}'
        : unit.serialNo;
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
        title: Text(unit.articleDesc,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 11)),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
        onTap: () => _openWizard(unit),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ScfFormCubit, ScfFormState>(
      buildWhen: (p, c) => p.isFormReadyToSubmit != c.isFormReadyToSubmit,
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
            ],
          ),
          // SafeArea bawah: cegah tombol tertutup navigation bar / gesture bar
          // pada HP yang punya area sistem di bawah layar.
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: state.isFormReadyToSubmit ? _onSubmit : null,
                child: const Text('Selesai'),
              ),
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
  // Actions
  // ---------------------------------------------------------------------------
  Future<void> _openWizard(ScfFreezerUnit unit) async {
    final detailState = context.read<ScfDetailBloc>().state;
    final data =
        detailState is ScfDetailLoaded ? detailState.data : null;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScfValidationScreen(
          transNo: widget.transNo,
          serialNo: unit.serialNo,
          isGeneric: unit.isGeneric,
          unitIndex: unit.unitIndex,
          articleNo: unit.articleNo,
          articleDesc: unit.articleDesc,
          storeName: storeTag(data?.header.shipToName, data?.header.shipTo),
          problems: data?.problems ?? const [],
          skipReasonOptions: data?.skipReasonOptions ?? const [],
          customLimitsBefore: data?.customLimitsBefore ?? const {},
          customLimitsAfter: data?.customLimitsAfter ?? const {},
        ),
      ),
    );
    if (!mounted) return;
    context.read<ScfDetailBloc>().add(FetchScfDetail(widget.transNo));
  }

  Future<void> _onScanBarcode() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;

    final state = context.read<ScfDetailBloc>().state;
    if (state is! ScfDetailLoaded) return;

    final matches = state.data.units.where((u) =>
        u.serialNo.trim().toUpperCase() == scanned.trim().toUpperCase());
    if (matches.isEmpty) {
      _showSnack('Freezer "$scanned" tidak ada di daftar tugas ini.');
      return;
    }
    _openWizard(matches.first);
  }

  void _onSubmit() {
    final detailState = context.read<ScfDetailBloc>().state;
    if (detailState is! ScfDetailLoaded) return;
    final formCubit = context.read<ScfFormCubit>();
    context.read<ScfSubmittedBloc>().add(ScfFinalValidationRequested(
          transNo: widget.transNo,
          formState: formCubit.state,
          problemSources: detailState.data.problems,
        ));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}
