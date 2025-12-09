// ignore_for_file: unused_element

import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_state.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/ddl_pic_position.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/measurement_limits.dart';
import '../../../../models/common/note_option.dart';
import '../../../../models/proof_of_service/pos_validation_entry_model.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../proof_of_service_validation/pos_validation_screen.dart';

class ProofOfServiceDetailBodyMobile extends StatefulWidget {
  final String transNo;

  const ProofOfServiceDetailBodyMobile({
    super.key,
    required this.transNo,
  });

  @override
  State<ProofOfServiceDetailBodyMobile> createState() =>
      _ProofOfServiceDetailBodyMobileState();
}

class _ProofOfServiceDetailBodyMobileState
    extends State<ProofOfServiceDetailBodyMobile> {
  late final TextEditingController _technician1Controller;
  late final TextEditingController _technician2Controller;
  late final TextEditingController _technician3Controller;
  late final TextEditingController _tempInController;
  late final TextEditingController _tempOutController;
  late final TextEditingController _finalTempController;
  late final TextEditingController _tempInNoteController;
  late final TextEditingController _tempOutNoteController;
  late final TextEditingController _finalTempInNoteController;
  final TextEditingController _noteSearchController = TextEditingController();

  late final MeasurementLimits _indoorLimits;
  late final MeasurementLimits _outdoorLimits;
  late final MeasurementLimits _finalTempBaseLimits;

  late final TextEditingController _picNameController;
  late final TextEditingController _picPhoneController;
  late final TextEditingController _picNikController;

  @override
  void initState() {
    super.initState();
    final configBox = Hive.box(kAppConfigBox);
    final Map<String, MeasurementLimits> headerLimits =
        Map<String, MeasurementLimits>.from(
            configBox.get('limits_temp_header') ?? {});

    _indoorLimits = headerLimits['temp_in'] ?? kIndoorLimits;
    _outdoorLimits = headerLimits['temp_out'] ?? kOutdoorLimits;
    _finalTempBaseLimits = headerLimits['temp_in'] ?? kIndoorLimits;

    final initialFormState = context.read<PosFormCubit>().state;
    _tempInController = TextEditingController(text: initialFormState.tempIn);
    _tempOutController = TextEditingController(text: initialFormState.tempOut);
    _finalTempController =
        TextEditingController(text: initialFormState.finalTempIn);
    _tempInNoteController =
        TextEditingController(text: initialFormState.tempInNote);
    _tempOutNoteController =
        TextEditingController(text: initialFormState.tempOutNote);
    _finalTempInNoteController =
        TextEditingController(text: initialFormState.finalTempInNote);
    _technician1Controller =
        TextEditingController(text: initialFormState.technician1);
    _technician2Controller =
        TextEditingController(text: initialFormState.technician2);
    _technician3Controller =
        TextEditingController(text: initialFormState.technician3);
    _picNameController = TextEditingController(text: initialFormState.picName);
    _picPhoneController =
        TextEditingController(text: initialFormState.picPhone);
    _picNikController = TextEditingController(text: initialFormState.picNik);
  }

  @override
  void dispose() {
    // Jangan lupa dispose controller
    _tempInController.dispose();
    _tempOutController.dispose();
    _finalTempController.dispose();
    _tempInNoteController.dispose();
    _tempOutNoteController.dispose();
    _finalTempInNoteController.dispose();
    _noteSearchController.dispose();
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _picNameController.dispose();
    _picPhoneController.dispose();
    _picNikController.dispose();
    super.dispose();
  }

  bool _hasRetryUploadState(PosSubmittedState state) {
    return state is PosValidationUploadPartial &&
        state.transNo == widget.transNo &&
        state.failedFiles.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listener untuk sinkronisasi validasi unit
        BlocListener<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
          listener: (context, detailState) {
            if (detailState is ProofOfServiceDetailLoaded) {
              final allUnitsValidated = detailState.data.detail.every((detail) {
                final serialKey = detail.serialNo.trim().toUpperCase();
                return detailState.validationStatuses[serialKey] ==
                    ValidationStatus.completed;
              });
              context
                  .read<PosFormCubit>()
                  .updateAllUnitsValidated(allUnitsValidated);
            }
          },
        ),
        // LANGKAH 3: SINKRONISASI CONTROLLER DENGAN BLOC STATE
        BlocListener<PosFormCubit, PosFormState>(
          listenWhen: (previous, current) =>
              previous.tempIn != current.tempIn ||
              previous.tempOut != current.tempOut ||
              previous.finalTempIn != current.finalTempIn ||
              previous.tempInNote != current.tempInNote ||
              previous.tempOutNote != current.tempOutNote ||
              previous.finalTempInNote != current.finalTempInNote ||
              previous.technician1 != current.technician1 ||
              previous.technician2 != current.technician2 ||
              previous.technician3 != current.technician3 ||
              previous.picName != current.picName ||
              previous.picPhone != current.picPhone ||
              previous.picNik != current.picNik,
          listener: (context, state) {
            // (Sinkronisasi Suhu & Note SAMA)
            if (_tempInController.text != state.tempIn) {
              _tempInController.text = state.tempIn;
            }
            // ... (tempOut, finalTempIn, tempInNote, tempOutNote, finalTempInNote)
            if (_tempOutController.text != state.tempOut) {
              _tempOutController.text = state.tempOut;
            }
            if (_finalTempController.text != state.finalTempIn) {
              _finalTempController.text = state.finalTempIn;
            }
            if (_tempInNoteController.text != state.tempInNote) {
              _tempInNoteController.text = state.tempInNote;
            }
            if (_tempOutNoteController.text != state.tempOutNote) {
              _tempOutNoteController.text = state.tempOutNote;
            }
            if (_finalTempInNoteController.text != state.finalTempInNote) {
              _finalTempInNoteController.text = state.finalTempInNote;
            }
            if (_technician1Controller.text != state.technician1) {
              _technician1Controller.text = state.technician1;
            }
            if (_technician2Controller.text != state.technician2) {
              _technician2Controller.text = state.technician2;
            }
            if (_technician3Controller.text != state.technician3) {
              _technician3Controller.text = state.technician3;
            }
            if (_picNameController.text != state.picName) {
              _picNameController.text = state.picName;
            }
            if (_picPhoneController.text != state.picPhone) {
              _picPhoneController.text = state.picPhone;
            }
            if (_picNikController.text != state.picNik) {
              _picNikController.text = state.picNik;
            }
          },
        ),
      ],
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
            final List<NoteOption> noteOptions =
                detailState.data.noteIndoorOptions ?? [];

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
                      padding: const EdgeInsets.only(bottom: 65.0),
                      // Beri ruang untuk tombol
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 35),
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
                            _buildServiceInfoPanel(
                                context, formState, noteOptions),
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
                                      isEnabled: (
                                          // Kondisi 1: Diisi dan valid
                                          (formState.tempIn.isNotEmpty &&
                                                  ((double.tryParse(formState
                                                                  .tempIn) ??
                                                              0) >=
                                                          _indoorLimits.min &&
                                                      (double.tryParse(formState
                                                                  .tempIn) ??
                                                              0) <=
                                                          _indoorLimits.max)) ||
                                              // Kondisi 2: Atau di-skip
                                              formState.isTempInSkipped),
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
                                      isEnabled: (
                                          // Kondisi 1: Diisi dan valid
                                          (formState.tempOut.isNotEmpty &&
                                                  ((double.tryParse(formState
                                                                  .tempOut) ??
                                                              0) >=
                                                          _outdoorLimits.min &&
                                                      (double.tryParse(formState
                                                                  .tempOut) ??
                                                              0) <=
                                                          _outdoorLimits
                                                              .max)) ||
                                              // Kondisi 2: Atau di-skip
                                              formState.isTempOutSkipped),
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
                                      isEnabled: ((formState.tempIn.isNotEmpty &&
                                                  ((double.tryParse(formState.tempIn) ??
                                                              0) >=
                                                          _indoorLimits.min &&
                                                      (double.tryParse(formState
                                                                  .tempIn) ??
                                                              0) <=
                                                          _indoorLimits.max)) ||
                                              formState.isTempInSkipped) &&
                                          ((formState.tempOut.isNotEmpty &&
                                                  ((double.tryParse(formState.tempOut) ??
                                                              0) >=
                                                          _outdoorLimits.min &&
                                                      (double.tryParse(formState
                                                                  .tempOut) ??
                                                              0) <=
                                                          _outdoorLimits
                                                              .max)) ||
                                              formState.isTempOutSkipped),
                                    ),
                                ],
                              ),
                            ),
                            BlocBuilder<PosFormCubit, PosFormState>(
                              buildWhen: (prev, current) =>
                                  prev.allUnitsValidated !=
                                      current.allUnitsValidated ||
                                  prev.isFinalTempInSkipped !=
                                      current.isFinalTempInSkipped ||
                                  prev.minFinalTempInLimit !=
                                      current.minFinalTempInLimit,
                              builder: (context, formState) {
                                final bool isEnabled =
                                    formState.allUnitsValidated;

                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Stack(
                                    children: [
                                      // Layer 1: Widget utama yang diredupkan & dinonaktifkan
                                      Opacity(
                                        opacity: isEnabled ? 1.0 : 0.5,
                                        child: AbsorbPointer(
                                          absorbing: !isEnabled,
                                          child: _buildServiceInfoAfterPanel(
                                              context, formState, noteOptions),
                                        ),
                                      ),

                                      // Layer 2: Overlay tak terlihat untuk menangkap klik saat disabled
                                      if (!isEnabled)
                                        Positioned.fill(
                                          child: InkWell(
                                            onTap: () {
                                              _showValidationSnackbar(
                                                context,
                                                'Selesaikan validasi semua unit terlebih dahulu untuk mengaktifkan.',
                                              );
                                            },
                                            // Beri radius agar efek ripple cocok dengan card
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

  Widget _buildServiceInfoPanel(BuildContext context, PosFormState formState,
      List<NoteOption> noteOptions) {
    final formCubit = context.read<PosFormCubit>();
    return _buildSection(
      title: 'Informasi Servis Sebelum Cleaning',
      child: Column(
        children: [
          MeasurementInputWidget(
            // LANGKAH 4: GUNAKAN CONTROLLER YANG SUDAH DIBUAT
            controller: _tempInController,
            label: 'Suhu Dalam Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: _indoorLimits,
            transNo: widget.transNo,
            initialImage: formState.temperatureInImage,
            onEditingComplete: (finalValue) {
              formCubit.tempInChanged(finalValue);
              formCubit.onFieldChanged();
            },
            onImageChanged: (newImage) {
              formCubit.tempInImageChanged(newImage);
              formCubit.onFieldChanged();
            },
            isSkipEnabled: true,
            isSkipped: formState.isTempInSkipped,
            onSkipChanged: (isSkipped) {
              formCubit.tempInSkipped(isSkipped);
              if (isSkipped) _tempInController.clear();
            },
          ),
          if (formState.isTempInSkipped)
            _buildNoteDropdown(
              context: context,
              label: 'Catatan Suhu Dalam (Wajib)',
              controller: _tempInNoteController,
              noteOptions: noteOptions,
              onChanged: (value) {
                _tempInNoteController.text = value ?? '';
                formCubit.tempInNoteChanged(value ?? '');
              },
            ),
          const SizedBox(height: 12),
          MeasurementInputWidget(
            // LANGKAH 4: GUNAKAN CONTROLLER YANG SUDAH DIBUAT
            controller: _tempOutController,
            label: 'Suhu Luar Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: _outdoorLimits,
            transNo: widget.transNo,
            initialImage: formState.temperatureOutImage,
            onEditingComplete: (finalValue) {
              formCubit.tempOutChanged(finalValue);
              formCubit.onFieldChanged();
            },
            onImageChanged: (newImage) {
              formCubit.tempOutImageChanged(newImage);
              formCubit.onFieldChanged();
            },
            isSkipEnabled: true,
            isSkipped: formState.isTempOutSkipped,
            onSkipChanged: (isSkipped) {
              formCubit.tempOutSkipped(isSkipped);
              if (isSkipped) _tempOutController.clear();
            },
          ),
          if (formState.isTempOutSkipped)
            _buildNoteDropdown(
              context: context,
              label: 'Catatan Suhu Luar (Wajib)',
              controller: _tempOutNoteController,
              noteOptions: noteOptions,
              onChanged: (value) {
                _tempOutNoteController.text = value ?? '';
                formCubit.tempOutNoteChanged(value ?? '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildServiceInfoAfterPanel(
      BuildContext context, PosFormState formState, List<NoteOption> noteOptions) {
    final formCubit = context.read<PosFormCubit>();

    // Batasan untuk suhu akhir, bisa sama atau beda dari suhu awal
    final minLimit = formState.minFinalTempInLimit;

    final String label = minLimit != null
        ? 'Suhu Dalam Ruangan (Min: ${minLimit.toStringAsFixed(1)}°C)'
        : 'Suhu Dalam Ruangan (°C)';

    final finalTempLimits = MeasurementLimits(
      id: _finalTempBaseLimits.id,
      label: label,
      min: minLimit ?? _finalTempBaseLimits.min,
      max: _finalTempBaseLimits.max,
      unit: _finalTempBaseLimits.unit,
      normalMin: minLimit ?? _finalTempBaseLimits.normalMin,
      normalMax: _finalTempBaseLimits.normalMax,
    );

    return _buildSection(
      title: 'Informasi Servis Sesudah Cleaning',
      child: Column(
        children: [
          MeasurementInputWidget(
            controller: _finalTempController,
            label: 'Suhu Dalam Ruangan (°C)',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: finalTempLimits,
            transNo: widget.transNo,
            initialImage: formState.finalTempInImage,
            onEditingComplete: (finalValue) {
              formCubit.finalTempInChanged(finalValue);
              formCubit.onFieldChanged();
            },
            onImageChanged: (newImage) {
              formCubit.finalTempInImageChanged(newImage);
              formCubit.onFieldChanged();
            },
            isSkipEnabled: true,
            isSkipped: formState.isFinalTempInSkipped,
            onSkipChanged: (isSkipped) {
              formCubit.finalTempInSkipped(isSkipped);
              if (isSkipped) _finalTempController.clear();
            },
          ),
          if (formState.isFinalTempInSkipped)
            _buildNoteDropdown(
              context: context,
              label: 'Catatan Suhu Dalam (Wajib)',
              controller: _finalTempInNoteController,
              noteOptions: noteOptions,
              onChanged: (value) {
                _finalTempInNoteController.text = value ?? '';
                formCubit.finalTempInNoteChanged(value ?? '');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoteDropdown({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required List<NoteOption> noteOptions,
    required ValueChanged<String?> onChanged,
  }) {
    // Salin logika perhitungan tinggi dropdown
    const double itemHeight = 40.0;
    const double searchBarHeight = 50.0;
    const double verticalPadding = 20.0;
    final double maxAllowedHeight = MediaQuery.of(context).size.height * 0.8;
    final double calculatedContentHeight =
        (noteOptions.length * itemHeight) + searchBarHeight + verticalPadding;
    final double dynamicMaxHeight =
        min(calculatedContentHeight, maxAllowedHeight);

    final filteredOptions = noteOptions.where((opt) {
      return !opt.isSystemOnly || opt.label == controller.text;
    }).toList();

    final selectedOption = filteredOptions
        .where((opt) => opt.label == controller.text)
        .firstOrNull;

    final bool isReadOnlySystemValue = selectedOption?.isSystemOnly ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: DropdownButtonFormField2<String>(
        value: filteredOptions.any((opt) => opt.label == controller.text)
            ? controller.text
            : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        hint: const Text(
          'Pilih Catatan',
          style: TextStyle(fontSize: 14),
        ),
        onChanged: isReadOnlySystemValue
            ? null
            : (value) {
                onChanged(value);
                FocusScope.of(context).unfocus();
              },
        items: filteredOptions
            .map((opt) => DropdownMenuItem<String>(
                  value: opt.label,
                  child: Text(
                    opt.label,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ))
            .toList(),
        dropdownStyleData: DropdownStyleData(
          maxHeight: dynamicMaxHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: itemHeight,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: _noteSearchController,
          searchInnerWidgetHeight: searchBarHeight,
          searchInnerWidget: Container(
            height: searchBarHeight,
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: _noteSearchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'Cari catatan...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          searchMatchFn: (item, searchValue) {
            return item.value
                .toString()
                .toLowerCase()
                .contains(searchValue.toLowerCase());
          },
        ),
        onMenuStateChange: (isOpen) {
          if (!isOpen) {
            _noteSearchController.clear();
          }
        },
        selectedItemBuilder: (context) {
          return noteOptions.map((item) {
            return Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                overflow: TextOverflow.ellipsis,
                color: Colors.black,
              ),
              maxLines: 1,
            );
          }).toList();
        },
      ),
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
            controller: _picNameController,
            hintText: 'Nama Lengkap PIC',
            icon: Icons.person_outline,
            onChanged: (value) {
              formCubit.picNameChanged(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _picPhoneController,
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
                  controller: _picNikController,
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
                child: posPositionDropdown(context, formState),
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
            controller: _technician1Controller,
            hintText: 'Teknisi 1',
            icon: Icons.engineering,
            readOnly: false,
            onChanged: (value) {
              formCubit.technician1Changed(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildCustomTextField(
            controller: _technician2Controller,
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
              controller: _technician3Controller,
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
        ? 'Suhu Dalam Ruangan harus di antara ${_indoorLimits.min}°C dan ${_indoorLimits.max}°C.'
        : 'Suhu Luar Ruangan harus di antara ${_outdoorLimits.min}°C dan ${_outdoorLimits.max}°C.';

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
                          ? 'Isi Suhu Dalam antara ${_indoorLimits.min}°C dan ${_indoorLimits.max}°C & foto hasil pengukuran'
                          : 'Isi Suhu Luar antara ${_outdoorLimits.min}°C dan ${_outdoorLimits.max}°C & foto hasil pengukuran',
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
      onTap: () {
        FocusScope.of(context).unfocus();
        _navigateToValidation(context, header, detail, formState.tempIn);
      }
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
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text("Selesai"),
            style: ElevatedButton.styleFrom(
                shape: const StadiumBorder(),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: () {
              // 1. Tutup keyboard
              FocusScope.of(context).unfocus();
              final formCubit = context.read<PosFormCubit>();
              if (formCubit.state.tempIn != _tempInController.text) {
                formCubit.tempInChanged(_tempInController.text);
                formCubit
                    .onFieldChanged(); // Ini juga akan memicu validasi ulang di Cubit
              }
              if (formCubit.state.tempOut != _tempOutController.text) {
                formCubit.tempOutChanged(_tempOutController.text);
                formCubit
                    .onFieldChanged(); // Ini juga akan memicu validasi ulang di Cubit
              }
              if (formCubit.state.finalTempIn != _finalTempController.text) {
                formCubit.finalTempInChanged(_finalTempController.text);
                formCubit
                    .onFieldChanged(); // Ini juga akan memicu validasi ulang di Cubit
              }
              if (formCubit.state.tempInNote != _tempInNoteController.text) {
                formCubit.tempInNoteChanged(_tempInNoteController.text);
              }
              if (formCubit.state.tempOutNote != _tempOutNoteController.text) {
                formCubit.tempOutNoteChanged(_tempOutNoteController.text);
              }
              if (formCubit.state.finalTempInNote !=
                  _finalTempInNoteController.text) {
                formCubit
                    .finalTempInNoteChanged(_finalTempInNoteController.text);
              }
              if (formCubit.state.technician1 != _technician1Controller.text) {
                formCubit.technician1Changed(_technician1Controller.text);
              }
              if (formCubit.state.technician2 != _technician2Controller.text) {
                formCubit.technician2Changed(_technician2Controller.text);
              }
              if (formCubit.state.technician3 != _technician3Controller.text) {
                formCubit.technician3Changed(_technician3Controller.text);
              }
              formCubit.onFieldChanged();

              // 2. Baca state form terakhir untuk validasi dasar
              final latestFormState = formCubit.state;

              if (latestFormState.isFormReadyToSubmit) {
                final tempInValue = double.tryParse(latestFormState.tempIn);
                final tempOutValue = double.tryParse(latestFormState.tempOut);
                final finalTempInValue =
                    double.tryParse(latestFormState.finalTempIn);
                final minLimit = latestFormState.minFinalTempInLimit;

                if (tempInValue != null) {
                  if (tempInValue < kIndoorLimits.min ||
                      tempInValue > kIndoorLimits.max) {
                    _showValidationSnackbar(context,
                        'Suhu Dalam Ruangan ($tempInValue°C) harus di antara ${_indoorLimits.min}°C dan ${_indoorLimits.max}°C.');
                    return; // Hentikan proses jika tidak valid
                  }
                }

                if (tempOutValue != null) {
                  if (tempOutValue < kOutdoorLimits.min ||
                      tempOutValue > kOutdoorLimits.max) {
                    _showValidationSnackbar(context,
                        'Suhu Luar Ruangan ($tempOutValue°C) harus di antara ${_outdoorLimits.min}°C dan ${_outdoorLimits.max}°C.');
                    return; // Hentikan proses jika tidak valid
                  }
                }

                if (!latestFormState.isFinalTempInSkipped &&
                    finalTempInValue != null) {
                  // Gunakan base limit dari API jika 'minLimit' dinamis tidak ada
                  final baseMin = minLimit ?? _finalTempBaseLimits.min;
                  final baseMax = _finalTempBaseLimits.max;

                  if (finalTempInValue < baseMin ||
                      finalTempInValue > baseMax) {
                    _showValidationSnackbar(context,
                        'Suhu Final ($finalTempInValue°C) harus di antara ${baseMin.toStringAsFixed(1)}°C dan ${baseMax.toStringAsFixed(0)}°C.');
                    return;
                  }
                }

                context.read<PosSubmittedBloc>().add(FinalValidationRequested(
                      transNo: header.transNo,
                      customerCode: header.shipToCode,
                    ));
              } else {
                // Logika untuk menampilkan snackbar jika form belum siap (ini sudah benar)
                if (!latestFormState.isPicStoreValid) {
                  _showValidationSnackbar(context,
                      'Harap lengkapi informasi PIC Toko terlebih dahulu.');
                } else if (latestFormState.technician1.isEmpty) {
                  _showValidationSnackbar(context, 'Harap isi nama Teknisi 1.');
                } else if (!latestFormState.isServiceInfoValid) {
                  _showValidationSnackbar(context,
                      'Harap lengkapi informasi servis dan foto pengukuran suhu.');
                } else if (!latestFormState.allUnitsValidated) {
                  _showValidationSnackbar(context,
                      'Harap lengkapi semua validasi unit terlebih dahulu.');
                } else if (latestFormState.isTempInSkipped &&
                    latestFormState.tempInNote.isEmpty) {
                  _showValidationSnackbar(
                      context, 'Catatan Suhu Dalam Ruangan wajib diisi.');
                } else if (latestFormState.isTempOutSkipped &&
                    latestFormState.tempOutNote.isEmpty) {
                  _showValidationSnackbar(
                      context, 'Catatan Suhu Luar Ruangan wajib diisi.');
                } else if (latestFormState.allUnitsValidated &&
                    latestFormState.isFinalTempInSkipped &&
                    latestFormState.finalTempInNote.isEmpty) {
                  _showValidationSnackbar(
                      context, 'Catatan Suhu Final wajib diisi.');
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
                shape: const StadiumBorder(),
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
    final detailState = context.read<ProofOfServiceDetailBloc>().state;
    List<String> allIndoorSerials = [];
    List<NoteOption> noteOptionsToSend = [];

    if (detailState is ProofOfServiceDetailLoaded) {
      // 3. Filter hanya unit indoor, lalu ambil serial number-nya
      allIndoorSerials = detailState.data.detail
          .where((d) => d.unitType.toUpperCase() == 'IN')
          .map((d) => d.serialNo)
          .toList();

      final rawOptions = detail.unitType == 'IN'
          ? detailState.data.noteIndoorOptions ?? []
          : detailState.data.noteOutdoorOptions ?? [];

      noteOptionsToSend = rawOptions ?? [];

    }

    if (!context.mounted) return;

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
          allIndoorSerials: allIndoorSerials,
          noteOptions: noteOptionsToSend,
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
