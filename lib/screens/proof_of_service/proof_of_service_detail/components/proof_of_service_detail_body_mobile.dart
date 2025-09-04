import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_state.dart';
import 'package:salsa/components/shared_function.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/otp/otp_repository.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../../models/schedule/proof_of_service/proof_of_service_detail_data.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../proof_of_service_validation/pos_validation_screen.dart';

class ProofOfServiceDetailBodyMobile extends StatelessWidget {
  final String transNo;
  final String technician1Name;

  const ProofOfServiceDetailBodyMobile({
    super.key,
    required this.transNo,
    required this.technician1Name,
  });

  bool _hasRetryUploadState(PosSubmittedState state) {
    return state is PosValidationUploadPartial &&
        state.transNo == transNo &&
        state.failedFiles.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
      listener: (context, detailState) {
        // Listener ini akan terpanggil setiap kali status unit berubah
        if (detailState is ProofOfServiceDetailLoaded) {
          final allUnitsValidated = detailState.data.detail.every((detail) {
            final serialKey = detail.serialNo.trim().toUpperCase();
            return detailState.validationStatuses[serialKey] ==
                ValidationStatus.completed;
          });
          // Beri tahu PosFormCubit tentang status terbaru
          context
              .read<PosFormCubit>()
              .updateAllUnitsValidated(allUnitsValidated);
        }
      },
      child: BlocBuilder<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
        builder: (context, detailState) {
          if (detailState is ProofOfServiceDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (detailState is ProofOfServiceDetailError) {
            return Center(child: Text("Error: ${detailState.message}"));
          }
          if (detailState is ProofOfServiceDetailLoaded) {
            final header = detailState.data.header;
            final detailList = detailState.data.detail;

            return BlocBuilder<PosFormCubit, PosFormState>(
              builder: (context, formState) {
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

                final stateUpload = context.watch<PosSubmittedBloc>().state;

                return Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 80.0),
                      // Beri ruang untuk tombol
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 35),
                        child: Column(
                          children: [
                            _buildCustomerSection(header),
                            const SizedBox(height: 16),
                            _buildTicketSection(header),
                            const SizedBox(height: 16),
                            _buildPicPanel(context, formState),
                            const SizedBox(height: 16),
                            _buildSection(
                              title: 'Teknisi Bertugas',
                              child: _buildTechnicianPanel(context, formState),
                            ),
                            const SizedBox(height: 16),
                            _buildServiceInfoPanel(context, formState),
                            const SizedBox(height: 16),
                            _buildSection(
                              title: 'Validasi Unit',
                              fullWidth: true,
                              headerAction: _buildScanQrButton(
                                  context, header, detailList, formState),
                              child: Column(
                                children: [
                                  if (indoorUnits.isNotEmpty)
                                    _buildUnitGroupCard(
                                      context: context,
                                      title: 'INDOOR',
                                      units: indoorUnits,
                                      icon: FontAwesomeIcons.wind,
                                      color: Colors.blue.shade700,
                                      header: header,
                                      validationStatuses:
                                          detailState.validationStatuses,
                                      isEnabled: formState.tempIn.isNotEmpty &&
                                          formState.tempIn != '0',
                                    ),
                                  if (outdoorUnits.isNotEmpty)
                                    _buildUnitGroupCard(
                                      context: context,
                                      title: 'OUTDOOR',
                                      units: outdoorUnits,
                                      icon: FontAwesomeIcons.fan,
                                      color: Colors.orange.shade800,
                                      header: header,
                                      validationStatuses:
                                          detailState.validationStatuses,
                                      isEnabled: formState.tempOut.isNotEmpty &&
                                          formState.tempOut != '0',
                                    ),
                                  if (setUnits.isNotEmpty)
                                    _buildUnitGroupCard(
                                      context: context,
                                      title: 'SET AC',
                                      units: setUnits,
                                      icon: Icons.inventory_2_outlined,
                                      color: Colors.grey.shade700,
                                      header: header,
                                      validationStatuses:
                                          detailState.validationStatuses,
                                      isEnabled: formState.tempIn.isNotEmpty &&
                                          formState.tempOut.isNotEmpty,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_hasRetryUploadState(stateUpload))
                      _buildRetryButton(
                          context, stateUpload as PosValidationUploadPartial)
                    else
                      _buildSubmitButton(context, header, formState),
                  ],
                );
              },
            );
          }
          return const Center(child: Text("Memuat data..."));
        },
      ),
    );
  }

  // --- WIDGET BUILDER METHODS ---

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
          if (title.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (headerAction != null) headerAction,
              ],
            ),
          if (title.isNotEmpty) const SizedBox(height: 8),
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

  Widget _buildScanQrButton(BuildContext context, ProofOfServiceHeader header,
      List<ProofOfServiceItemDetail> detailList, PosFormState formState) {
    return ElevatedButton.icon(
      icon: const Icon(FontAwesomeIcons.qrcode, size: 16),
      label: const Text('Scan QR'),
      onPressed: formState.isServiceInfoValid
          ? () async {
              final String? scannedSerialNo = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => QrScanPage()),
              );

              if (scannedSerialNo != null && context.mounted) {
                try {
                  final tappedDetail = detailList.firstWhere((d) =>
                      d.serialNo.trim().toUpperCase() ==
                      scannedSerialNo.trim().toUpperCase());
                  _navigateToValidation(
                      context, header, tappedDetail, formState.tempIn);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'QR Code tidak sesuai dengan daftar unit pada tiket ini.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          : null,
    );
  }

  Widget _buildPicPanel(BuildContext context, PosFormState formState) {
    final formCubit = context.read<PosFormCubit>();
    return _buildSection(
      title: 'PIC Toko',
      child: Column(
        children: [
          _buildCustomTextField(
            initialValue: formState.picName,
            hintText: 'Nama Lengkap PIC',
            icon: Icons.person_outline,
            onChanged: (value) {
              formCubit.picNameChanged(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            initialValue: formState.picPhone,
            hintText: 'Nomor Telepon',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              formCubit.picPhoneChanged(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomTextField(
                  initialValue: formState.picNik,
                  hintText: 'NIK',
                  icon: Icons.badge_outlined,
                  onChanged: (value) {
                    formCubit.picNikChanged(value);
                    formCubit.onFieldChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomTextField(
                  initialValue: formState.picPosition,
                  hintText: 'Jabatan',
                  icon: Icons.work_outline,
                  onChanged: (value) {
                    formCubit.picPositionChanged(value);
                    formCubit.onFieldChanged();
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTechnicianPanel(BuildContext context, PosFormState formState) {
    final formCubit = context.read<PosFormCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildCustomTextField(
            initialValue: technician1Name,
            hintText: 'Teknisi 1',
            icon: Icons.engineering,
            readOnly: true,
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            initialValue: formState.technician2,
            hintText: 'Teknisi 2',
            icon: Icons.engineering,
            onChanged: (value) {
              formCubit.technician2Changed(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 8),
          if (formState.showTechnician3)
            _buildCustomTextField(
              initialValue: formState.technician3,
              hintText: 'Teknisi 3',
              icon: Icons.engineering,
              onChanged: (value) {
                formCubit.technician3Changed(value);
                formCubit.onFieldChanged();
              },
              suffixIcon: IconButton(
                onPressed: () {
                  formCubit.technician3Changed(''); // Kosongkan nilainya
                  formCubit.toggleTechnician3(false);
                  formCubit.onFieldChanged();
                },
                icon: const Icon(Icons.cancel, color: Colors.red),
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

  Widget _buildServiceInfoPanel(BuildContext context, PosFormState formState) {
    final formCubit = context.read<PosFormCubit>();
    return _buildSection(
      title: 'Informasi Servis',
      child: Column(
        children: [
          MeasurementInputWidget(
            controller: TextEditingController(text: formState.tempIn),
            label: 'Suhu Dalam Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: MeasurementLimits(
                id: 'temp_in',
                label: 'Suhu Dalam',
                min: 0,
                max: 100,
                normalMax: 0,
                normalMin: 100,
                unit: '°C'),
            transNo: transNo,
            initialImage: formState.temperatureInImage,
            onChanged: (value) {
              formCubit.tempInChanged(value);
              formCubit.onFieldChanged();
            },
            onImageChanged: (newImage) {
              formCubit.tempInImageChanged(newImage);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          MeasurementInputWidget(
            controller: TextEditingController(text: formState.tempOut),
            label: 'Suhu Luar Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: MeasurementLimits(
                id: 'temp_out',
                label: 'Suhu Luar',
                min: 0,
                max: 100,
                normalMax: 0,
                normalMin: 100,
                unit: '°C'),
            transNo: transNo,
            initialImage: formState.temperatureOutImage,
            onChanged: (value) {
              formCubit.tempOutChanged(value);
              formCubit.onFieldChanged();
            },
            onImageChanged: (newImage) {
              formCubit.tempOutImageChanged(newImage);
              formCubit.onFieldChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnitGroupCard({
    required BuildContext context,
    required String title,
    required List<ProofOfServiceItemDetail> units,
    required IconData icon,
    required Color color,
    required ProofOfServiceHeader header,
    required Map<String, ValidationStatus> validationStatuses,
    required bool isEnabled,
  }) {
    final String snackBarMessage = title == 'INDOOR'
        ? 'Harap isi Suhu Dalam Ruangan (°C) terlebih dahulu.'
        : 'Harap isi Suhu Luar Ruangan (°C) terlebih dahulu.';

    return Stack(
      children: [
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
                          ? 'Isi Suhu Dalam & foto'
                          : 'Isi Suhu Luar & foto',
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ]
              ],
            ),
          ),
        ),
        if (!isEnabled)
          Positioned.fill(
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
      ],
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
    final formState = context.read<PosFormCubit>().state;

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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
      onTap: () =>
          _navigateToValidation(context, header, detail, formState.tempIn),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ProofOfServiceHeader header,
      PosFormState formState) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_circle),
            label: const Text("Selesai"),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () async {
              if (formState.isFormReadyToSubmit) {
                final user = await AuthStorage.getUser();
                final maintenanceByIP = await getPublicIpAddress();
                final technicianName = user['name'] ?? '';
                final maintenanceBy = user['maintenance_by'] ?? '';

                await showDialog<void>(
                  context: context,
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider(
                          create: (_) => OtpBloc(repository: OtpRepository())),
                    ],
                    child: OtpDialog(
                      shipTo: header.shipToCode,
                      email: header.storeEmail,
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
                if (!formState.isPicStoreValid) {
                  _showValidationSnackbar(context,
                      'Harap lengkapi informasi PIC Toko terlebih dahulu.');
                } else if (!formState.isServiceInfoValid) {
                  _showValidationSnackbar(context,
                      'Harap lengkapi informasi servis dan foto pengukuran suhu.');
                } else if (!formState.allUnitsValidated) {
                  // <-- Gunakan state dari Cubit
                  _showValidationSnackbar(context,
                      'Harap lengkapi semua validasi unit terlebih dahulu.');
                } else {
                  _showValidationSnackbar(context,
                      'Pastikan semua data sudah terisi dengan benar.');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRetryButton(
      BuildContext context, PosValidationUploadPartial partial) {
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () {
              final uploadCubit = context.read<UploadProgressCubit>();
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => BlocProvider.value(
                        value: uploadCubit,
                        child: const UploadProgressDialog(),
                      ));
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

  Widget _buildCustomTextField({
    String initialValue = '',
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: hintText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        suffixIcon: suffixIcon,
        isDense: true,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.grey.shade100,
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

  // --- HELPER METHODS ---

  Future<void> _navigateToValidation(
      BuildContext context,
      ProofOfServiceHeader header,
      ProofOfServiceItemDetail detail,
      String tempIn) async {
    final box =
        await Hive.openBox<PosValidationEntryModel>(kPosValidationHiveBox);
    final existingData = box.get(detail.serialNo.trim().toUpperCase());
    final double? indoorTemp = double.tryParse(tempIn);

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

    if (context.mounted) {
      context
          .read<ProofOfServiceDetailBloc>()
          .add(FetchProofOfServiceDetail(header.transNo.trim().toUpperCase()));
    }
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
}
