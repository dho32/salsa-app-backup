// ignore_for_file: unused_element

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_state.dart';
import 'package:salsa/models/proof_of_service/proof_of_service_detail_model.dart';

import 'dart:io';

import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import '../../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../components/constants.dart';
import '../../../../components/services/watermark_service.dart';
import '../../../../components/shared_function.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/ddl_pic_position.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/remark_photo_picker.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/captured_image_detail.dart';
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
  late final TextEditingController _tempInSkipRemarkController;
  late final TextEditingController _tempOutSkipRemarkController;
  late final TextEditingController _finalTempSkipRemarkController;

  // Grup foto bukti skip yang sedang mengambil foto ('temp_in' / 'temp_out' /
  // 'final_temp'), null bila tidak ada.
  String? _takingSkipPhotoGroup;

  // Status konfirmasi "angka sesuai foto" per suhu. Nilai dari draft yang sudah
  // lengkap dianggap terkonfirmasi (dilaporkan MeasurementInputWidget saat load).
  bool _tempOutConfirmed = false;
  bool _tempInConfirmed = false;
  bool _finalTempConfirmed = false;

  final TextEditingController _noteSearchController = TextEditingController();
  final TextEditingController _tech2SearchController = TextEditingController();
  final TextEditingController _tech3SearchController = TextEditingController();

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

    final initialFormState = context
        .read<PosFormCubit>()
        .state;
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
    _tempInSkipRemarkController =
        TextEditingController(text: initialFormState.tempInSkipRemark);
    _tempOutSkipRemarkController =
        TextEditingController(text: initialFormState.tempOutSkipRemark);
    _finalTempSkipRemarkController =
        TextEditingController(text: initialFormState.finalTempInSkipRemark);
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
    _tempInSkipRemarkController.dispose();
    _tempOutSkipRemarkController.dispose();
    _finalTempSkipRemarkController.dispose();
    _noteSearchController.dispose();
    _tech2SearchController.dispose();
    _tech3SearchController.dispose();
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
                final mapKey = detail.isGeneric
                    ? '${detail.unitType}_${detail.unitIndex}'
                    : detail.serialNo.trim().toUpperCase();
                return detailState.validationStatuses[mapKey] ==
                    ValidationStatus.completed;
              });
              final formCubit = context.read<PosFormCubit>();
              // Cubit perlu master catatan untuk cek flag require_remark
              // pada validasi skip suhu.
              formCubit
                  .setNoteOptions(detailState.data.noteIndoorOptions ?? []);
              formCubit.updateAllUnitsValidated(allUnitsValidated);
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
              previous.tempInSkipRemark != current.tempInSkipRemark ||
              previous.tempOutSkipRemark != current.tempOutSkipRemark ||
              previous.finalTempInSkipRemark !=
                  current.finalTempInSkipRemark ||
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
            if (_tempInSkipRemarkController.text != state.tempInSkipRemark) {
              _tempInSkipRemarkController.text = state.tempInSkipRemark;
            }
            if (_tempOutSkipRemarkController.text != state.tempOutSkipRemark) {
              _tempOutSkipRemarkController.text = state.tempOutSkipRemark;
            }
            if (_finalTempSkipRemarkController.text !=
                state.finalTempInSkipRemark) {
              _finalTempSkipRemarkController.text =
                  state.finalTempInSkipRemark;
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

                // Gating validasi unit: SELURUH suhu ruangan (Luar & Dalam)
                // harus selesai dulu — terisi (angka + foto + KONFIRMASI sesuai
                // foto) ATAU di-skip dengan alasan lengkap. Baru setelah itu
                // semua kartu unit (INDOOR/OUTDOOR/SET) bisa dibuka.
                final formCubit = context.read<PosFormCubit>();
                final bool tempOutDone = (formState.tempOut.isNotEmpty &&
                    formState.temperatureOutImage != null &&
                    _tempOutConfirmed) ||
                    (formState.isTempOutSkipped &&
                        formCubit.isSkipComplete(
                            formState.tempOutNote,
                            formState.tempOutSkipRemark,
                            formState.tempOutSkipPhotos));
                final bool tempInDone = (formState.tempIn.isNotEmpty &&
                    formState.temperatureInImage != null &&
                    _tempInConfirmed) ||
                    (formState.isTempInSkipped &&
                        formCubit.isSkipComplete(
                            formState.tempInNote,
                            formState.tempInSkipRemark,
                            formState.tempInSkipPhotos));
                final bool roomTempsDone = tempOutDone && tempInDone;

                final stateUpload = context
                    .watch<PosSubmittedBloc>()
                    .state;

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
                                      isEnabled: roomTempsDone,
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
                                      isEnabled: roomTempsDone,
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
                                      isEnabled: roomTempsDone,
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
                                      current.minFinalTempInLimit ||
                                  prev.finalTempInImage !=
                                      current.finalTempInImage ||
                                  // Tanpa ini, memilih alasan skip ber-flag
                                  // require_remark tidak memicu rebuild —
                                  // field keterangan+foto bukti tidak pernah
                                  // muncul walau datanya sudah tersimpan.
                                  prev.finalTempInNote !=
                                      current.finalTempInNote ||
                                  prev.finalTempInSkipRemark !=
                                      current.finalTempInSkipRemark ||
                                  prev.finalTempInSkipPhotos !=
                                      current.finalTempInSkipPhotos,
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

    // Suhu Luar wajib selesai dulu: (angka + foto + KONFIRMASI sesuai foto)
    // ATAU (skip + alasan lengkap). Baru setelah itu Suhu Dalam terbuka.
    final bool tempOutDone = (formState.tempOut.isNotEmpty &&
        formState.temperatureOutImage != null &&
        _tempOutConfirmed) ||
        (formState.isTempOutSkipped &&
            formCubit.isSkipComplete(formState.tempOutNote,
                formState.tempOutSkipRemark, formState.tempOutSkipPhotos));

    return _buildSection(
      title: 'Informasi Servis Sebelum Cleaning',
      child: Column(
        children: [
          // --- 1) SUHU LUAR RUANGAN (diinput lebih dulu) ---
          MeasurementInputWidget(
            controller: _tempOutController,
            label: 'Suhu Luar Ruangan (°C)',
            photoLabel: 'Suhu Luar Ruangan',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: _outdoorLimits,
            transNo: widget.transNo,
            initialImage: formState.temperatureOutImage,
            enableConfirmDialog: true,
            onConfirmedChanged: (c) =>
                setState(() => _tempOutConfirmed = c),
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
            _buildSkipNoteSection(
              context: context,
              dropdownLabel: 'Catatan Suhu Luar (Wajib)',
              noteController: _tempOutNoteController,
              remarkController: _tempOutSkipRemarkController,
              noteOptions: noteOptions,
              selectedNote: formState.tempOutNote,
              photos: formState.tempOutSkipPhotos,
              photoGroup: 'temp_out',
              photoLabel: 'Bukti Kendala Suhu Luar',
              onNoteChanged: (value) {
                _tempOutNoteController.text = value ?? '';
                _tempOutSkipRemarkController.clear();
                formCubit.tempOutNoteChanged(value ?? '');
              },
              onRemarkChanged: formCubit.tempOutSkipRemarkChanged,
              onPhotoCaptured: formCubit.addTempOutSkipPhoto,
              onPhotoRemoved: formCubit.removeTempOutSkipPhoto,
            ),
          const SizedBox(height: 12),
          // --- 2) SUHU DALAM RUANGAN (terkunci sampai Suhu Luar selesai) ---
          Stack(
            children: [
              Opacity(
                opacity: tempOutDone ? 1.0 : 0.5,
                child: AbsorbPointer(
                  absorbing: !tempOutDone,
                  child: Column(
                    children: [
                      MeasurementInputWidget(
                        controller: _tempInController,
                        label: 'Suhu Dalam Ruangan (°C)',
                        photoLabel: 'Suhu Dalam Ruangan - Before Cleaning',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        limits: _indoorLimits,
                        transNo: widget.transNo,
                        initialImage: formState.temperatureInImage,
                        enableConfirmDialog: true,
                        onConfirmedChanged: (c) =>
                            setState(() => _tempInConfirmed = c),
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
                        _buildSkipNoteSection(
                          context: context,
                          dropdownLabel: 'Catatan Suhu Dalam (Wajib)',
                          noteController: _tempInNoteController,
                          remarkController: _tempInSkipRemarkController,
                          noteOptions: noteOptions,
                          selectedNote: formState.tempInNote,
                          photos: formState.tempInSkipPhotos,
                          photoGroup: 'temp_in',
                          photoLabel: 'Bukti Kendala Suhu Dalam',
                          onNoteChanged: (value) {
                            _tempInNoteController.text = value ?? '';
                            _tempInSkipRemarkController.clear();
                            formCubit.tempInNoteChanged(value ?? '');
                          },
                          onRemarkChanged: formCubit.tempInSkipRemarkChanged,
                          onPhotoCaptured: formCubit.addTempInSkipPhoto,
                          onPhotoRemoved: formCubit.removeTempInSkipPhoto,
                        ),
                    ],
                  ),
                ),
              ),
              if (!tempOutDone)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _showValidationSnackbar(context,
                            'Selesaikan Suhu Luar Ruangan terlebih dahulu (angka + foto, atau alasan skip lengkap).');
                      },
                    ),
                  ),
                ),
            ],
          ),
          if (!tempOutDone)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Suhu Dalam Ruangan terbuka setelah Suhu Luar Ruangan selesai diisi.',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  /// Dropdown alasan skip + (bila alasan ber-flag require_remark) keterangan
  /// tambahan min. 20 huruf + foto bukti kendala — pola sama dengan SC.
  Widget _buildSkipNoteSection({
    required BuildContext context,
    required String dropdownLabel,
    required TextEditingController noteController,
    required TextEditingController remarkController,
    required List<NoteOption> noteOptions,
    required String selectedNote,
    required List<CapturedImageDetail> photos,
    required String photoGroup,
    required String photoLabel,
    required ValueChanged<String?> onNoteChanged,
    required ValueChanged<String> onRemarkChanged,
    required ValueChanged<CapturedImageDetail> onPhotoCaptured,
    required ValueChanged<String> onPhotoRemoved,
  }) {
    final bool requireRemark =
    context.read<PosFormCubit>().noteRequiresRemark(selectedNote);

    return Column(
      children: [
        _buildNoteDropdown(
          context: context,
          label: dropdownLabel,
          controller: noteController,
          noteOptions: noteOptions,
          onChanged: onNoteChanged,
        ),
        if (requireRemark) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: TextFormField(
              controller: remarkController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Keterangan Tambahan (*Wajib)',
                hintText: 'Jelaskan detail kendala (Min. 20 huruf)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding:
                const EdgeInsets.only(top: 10, bottom: 10, right: 12),
                prefixIcon: const Icon(Icons.edit_note, size: 25),
              ),
              maxLines: 2,
              onChanged: onRemarkChanged,
              validator: (value) {
                final text = value ?? '';
                if (text
                    .trim()
                    .isEmpty) return 'Wajib diisi';
                final int charCount = text
                    .replaceAll(' ', '')
                    .length;
                if (charCount < 20) {
                  return 'Kurang ${20 - charCount} huruf lagi (tanpa spasi)';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          RemarkPhotoPicker(
            photos: photos,
            isLoading: _takingSkipPhotoGroup == photoGroup,
            isReadOnly: false,
            onAddTap: () =>
                _handleSkipEvidencePhoto(
                  group: photoGroup,
                  photoLabel: photoLabel,
                  currentCount: photos.length,
                  onCaptured: onPhotoCaptured,
                ),
            onRemoveTap: onPhotoRemoved,
          ),
        ],
      ],
    );
  }

  /// Ambil foto bukti kendala skip (watermark pola sama dengan foto remark
  /// di validasi unit POS).
  Future<void> _handleSkipEvidencePhoto({
    required String group,
    required String photoLabel,
    required int currentCount,
    required ValueChanged<CapturedImageDetail> onCaptured,
  }) async {
    if (currentCount >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Maksimal hanya bisa upload 5 foto bukti.')));
      return;
    }
    setState(() => _takingSkipPhotoGroup = group);
    try {
      PaintingBinding.instance.imageCache.clear();
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 80);
      if (image != null) {
        final userData = await AuthStorage.getUser();
        final timestamp = DateTime.now();
        final zone = getIndonesianTimezoneAbbreviation(timestamp);
        final formattedDate =
            '${DateFormat('dd MMM yyyy, HH:mm:ss', 'id_ID').format(
            timestamp)} $zone';
        final appDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory(p.join(appDir.path, 'draft_images'));
        if (!await imagesDir.exists()) await imagesDir.create();
        final targetPath = p.join(imagesDir.path,
            'WM_SKIP_${timestamp.millisecondsSinceEpoch}.jpg');

        final request = WatermarkRequest(
          originalPath: image.path,
          targetPath: targetPath,
          transNo: widget.transNo,
          formattedDate: formattedDate,
          technicianName: userData['name'] ?? 'Unknown',
          deviceModel: userData['device_model'] ?? 'Unknown Device',
          photoLabel: photoLabel,
        );
        final String? finalImagePath =
        await WatermarkService.processImage(request);
        if (finalImagePath == null) throw Exception('Gagal watermark');

        final capturedImageDetail = CapturedImageDetail(
          imagePath: finalImagePath,
          timestamp: timestamp,
          latitude: 0.0,
          longitude: 0.0,
          address: "",
          technicianName: userData['name'] ?? 'Unknown',
          deviceModel: userData['device_model'] ?? 'Unknown',
          transNo: widget.transNo,
        );
        onCaptured(capturedImageDetail);
      }
    } catch (e) {
      debugPrint('Error foto bukti skip: $e');
    } finally {
      if (mounted) setState(() => _takingSkipPhotoGroup = null);
    }
  }

  Widget _buildServiceInfoAfterPanel(BuildContext context,
      PosFormState formState, List<NoteOption> noteOptions) {
    final formCubit = context.read<PosFormCubit>();


    final String label = 'Suhu Dalam Ruangan (°C)';

    // Max tidak boleh melebihi suhu luar ruangan (jika diisi & tidak di-skip)
    final tempOutValue = double.tryParse(formState.tempOut);
    final double effectiveMax = (!formState.isTempOutSkipped &&
        tempOutValue != null)
        ? min(_finalTempBaseLimits.max, tempOutValue - 0.1)
        : _finalTempBaseLimits.max;

    final finalTempLimits = MeasurementLimits(
      id: _finalTempBaseLimits.id,
      label: label,
      min: _finalTempBaseLimits.min,
      max: effectiveMax,
      unit: _finalTempBaseLimits.unit,
      normalMin: _finalTempBaseLimits.normalMin,
      normalMax: _finalTempBaseLimits.normalMax,
    );

    return _buildSection(
      title: 'Informasi Servis Sesudah Cleaning',
      child: Column(
        children: [
          MeasurementInputWidget(
            controller: _finalTempController,
            label: 'Suhu Dalam Ruangan (°C)',
            photoLabel: 'Suhu Dalam Ruangan - After Cleaning',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            limits: finalTempLimits,
            transNo: widget.transNo,
            initialImage: formState.finalTempInImage,
            enableConfirmDialog: true,
            onConfirmedChanged: (c) =>
                setState(() => _finalTempConfirmed = c),
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
            _buildSkipNoteSection(
              context: context,
              dropdownLabel: 'Catatan Suhu Dalam (Wajib)',
              noteController: _finalTempInNoteController,
              remarkController: _finalTempSkipRemarkController,
              noteOptions: noteOptions,
              selectedNote: formState.finalTempInNote,
              photos: formState.finalTempInSkipPhotos,
              photoGroup: 'final_temp',
              photoLabel: 'Bukti Kendala Suhu Dalam - After Cleaning',
              onNoteChanged: (value) {
                _finalTempInNoteController.text = value ?? '';
                _finalTempSkipRemarkController.clear();
                formCubit.finalTempInNoteChanged(value ?? '');
              },
              onRemarkChanged: formCubit.finalTempInSkipRemarkChanged,
              onPhotoCaptured: formCubit.addFinalTempInSkipPhoto,
              onPhotoRemoved: formCubit.removeFinalTempInSkipPhoto,
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
    final double maxAllowedHeight = MediaQuery
        .of(context)
        .size
        .height * 0.8;
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
            .map((opt) =>
            DropdownMenuItem<String>(
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
    final bool isWH = formCubit.userType == 'WH';
    final technicianList = formCubit.technicianList;
    final bool useDropdown = isWH && technicianList.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _buildCustomTextField(
            controller: _technician1Controller,
            hintText: 'Teknisi 1',
            icon: Icons.engineering,
            readOnly: isWH,
            onChanged: (value) {
              formCubit.technician1Changed(value);
              formCubit.onFieldChanged();
            },
          ),
          const SizedBox(height: 12),
          if (useDropdown)
            _buildTechnicianDropdown(
              context: context,
              label: 'Teknisi 2',
              value: formState.technician2,
              technicianList: technicianList,
              excludedName: formState.technician3,
              searchController: _tech2SearchController,
              onChanged: (value) {
                formCubit.technician2Changed(value ?? '');
                formCubit.onFieldChanged();
              },
              onClear: formState.technician2.isNotEmpty ? () {
                formCubit.technician2Changed('');
                formCubit.onFieldChanged();
              } : null,
            )
          else
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
            if (useDropdown)
              Row(
                children: [
                  Expanded(
                    child: _buildTechnicianDropdown(
                      context: context,
                      label: 'Teknisi 3',
                      value: formState.technician3,
                      technicianList: technicianList,
                      excludedName: formState.technician2,
                      searchController: _tech3SearchController,
                      onChanged: (value) {
                        formCubit.technician3Changed(value ?? '');
                        formCubit.onFieldChanged();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      formCubit.technician3Changed('');
                      formCubit.toggleTechnician3(false);
                      formCubit.onFieldChanged();
                    },
                    icon: const Icon(Icons.cancel, color: Colors.red),
                  ),
                ],
              )
            else
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
                    formCubit.technician3Changed('');
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

  Widget _buildTechnicianDropdown({
    required BuildContext context,
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

    // Jika nilai tersimpan tidak ada di daftar (mis. draft lama atau roster teknisi
    // berubah), sisipkan sebagai item agar tetap tampil & ikut ter-submit — bukan
    // hilang diam-diam dari tampilan sementara datanya masih dikirim.
    if (value.isNotEmpty &&
        !filtered.any((t) => t['technician_name'] == value)) {
      filtered.insert(0, {'technician_id': '', 'technician_name': value});
    }
    final currentValue = filtered.any((t) => t['technician_name'] == value)
        ? value
        : null;

    final dropdown = DropdownButtonFormField2<String>(
      value: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
            Icons.engineering, color: Colors.grey.shade600, size: 20),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(label, style: const TextStyle(fontSize: 14)),
      onChanged: onChanged,
      items: filtered
          .map((t) =>
          DropdownMenuItem<String>(
            value: t['technician_name'],
            child: Text(
              t['technician_name'] ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ))
          .toList(),
      dropdownStyleData: DropdownStyleData(
        maxHeight: MediaQuery
            .of(context)
            .size
            .height * 0.4,
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
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              hintText: 'Cari teknisi...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) =>
            item.value.toString().toLowerCase().contains(
                searchValue.toLowerCase()),
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
    // Semua kartu unit kini dibuka oleh syarat yang sama: seluruh suhu ruangan
    // (Luar & Dalam) sudah selesai diisi/di-skip.
    const String snackBarMessage =
        'Lengkapi Suhu Luar & Suhu Dalam Ruangan terlebih dahulu (isi angka + foto, atau skip dengan alasan lengkap).';

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
                  : const Text(
                'Lengkapi Suhu Luar & Suhu Dalam Ruangan dulu sebelum validasi unit',
                style: TextStyle(
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

  Widget _buildDetailCard(BuildContext context,
      ProofOfServiceHeader header,
      ProofOfServiceItemDetail detail,
      Map<String, ValidationStatus> validationStatuses,) {
    final mapKey = detail.isGeneric
        ? '${detail.unitType}_${detail.unitIndex}'
        : detail.serialNo.trim().toUpperCase();
    final status = validationStatuses[mapKey] ?? ValidationStatus.notStarted;
    final formState = context
        .read<PosFormCubit>()
        .state;

    // 🔥 Ganti tulisan "AC - 1" dengan SN Asli dari Hive (jika ada)
    final detailState = context
        .read<ProofOfServiceDetailBloc>()
        .state;
    String displaySerial = detail.serialNo;
    if (detailState is ProofOfServiceDetailLoaded &&
        detailState.savedSerials.containsKey(mapKey)) {
      displaySerial = detailState.savedSerials[mapKey]!;
    }

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
            // 🔥 Tampilkan SN Asli di sini
            Text('Serial No: $displaySerial',
                style: TextStyle(
                    color: detail.isGeneric
                        ? Colors.blue.shade700
                        : Colors.black87,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: Icon(iconData, color: iconColor, size: 28),
        onTap: () {
          FocusScope.of(context).unfocus();
          _navigateToValidation(context, header, detail, formState.tempIn);
        });
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
              if (formCubit.state.tempInSkipRemark !=
                  _tempInSkipRemarkController.text) {
                formCubit
                    .tempInSkipRemarkChanged(_tempInSkipRemarkController.text);
              }
              if (formCubit.state.tempOutSkipRemark !=
                  _tempOutSkipRemarkController.text) {
                formCubit.tempOutSkipRemarkChanged(
                    _tempOutSkipRemarkController.text);
              }
              if (formCubit.state.finalTempInSkipRemark !=
                  _finalTempSkipRemarkController.text) {
                formCubit.finalTempInSkipRemarkChanged(
                    _finalTempSkipRemarkController.text);
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
                // Blokir bila ada suhu (non-skip) yang belum dikonfirmasi
                // "sesuai foto" — mis. diubah setelah unit tervalidasi.
                if (!latestFormState.isTempOutSkipped && !_tempOutConfirmed) {
                  _showValidationSnackbar(context,
                      'Konfirmasi Suhu Luar Ruangan sesuai foto terlebih dahulu.');
                  return;
                }
                if (!latestFormState.isTempInSkipped && !_tempInConfirmed) {
                  _showValidationSnackbar(context,
                      'Konfirmasi Suhu Dalam Ruangan sesuai foto terlebih dahulu.');
                  return;
                }
                if (!latestFormState.isFinalTempInSkipped &&
                    !_finalTempConfirmed) {
                  _showValidationSnackbar(context,
                      'Konfirmasi Suhu Dalam Ruangan (Sesudah) sesuai foto terlebih dahulu.');
                  return;
                }

                final tempInValue = double.tryParse(latestFormState.tempIn);
                final tempOutValue = double.tryParse(latestFormState.tempOut);
                final finalTempInValue =
                double.tryParse(latestFormState.finalTempIn);

                // 🔥 Kabel 'minLimit' dinamis sudah kita buang!

                if (tempInValue != null) {
                  if (tempInValue < kIndoorLimits.min ||
                      tempInValue > kIndoorLimits.max) {
                    _showValidationSnackbar(context,
                        'Suhu Dalam Ruangan ($tempInValue°C) harus di antara ${_indoorLimits
                            .min}°C dan ${_indoorLimits.max}°C.');
                    return; // Hentikan proses jika tidak valid
                  }
                }

                if (tempOutValue != null) {
                  if (tempOutValue < kOutdoorLimits.min ||
                      tempOutValue > kOutdoorLimits.max) {
                    _showValidationSnackbar(context,
                        'Suhu Luar Ruangan ($tempOutValue°C) harus di antara ${_outdoorLimits
                            .min}°C dan ${_outdoorLimits.max}°C.');
                    return; // Hentikan proses jika tidak valid
                  }
                }

                if (!latestFormState.isFinalTempInSkipped &&
                    finalTempInValue != null) {
                  // 🔥 POTONG KABEL: Gunakan murni base limit dari API
                  final baseMin = _finalTempBaseLimits.min;
                  final baseMax = _finalTempBaseLimits.max;

                  if (finalTempInValue < baseMin ||
                      finalTempInValue > baseMax) {
                    _showValidationSnackbar(context,
                        'Suhu Final ($finalTempInValue°C) harus di antara ${baseMin
                            .toStringAsFixed(1)}°C dan ${baseMax
                            .toStringAsFixed(0)}°C.');
                    return;
                  }

                  if (!latestFormState.isTempOutSkipped &&
                      tempOutValue != null &&
                      finalTempInValue >= tempOutValue) {
                    _showValidationSnackbar(context,
                        'Suhu setelah cleaning ($finalTempInValue°C) harus lebih kecil dari suhu luar ruangan ($tempOutValue°C).');
                    return;
                  }
                }

                context.read<PosSubmittedBloc>().add(FinalValidationRequested(
                  transNo: header.transNo,
                  formState: latestFormState,
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
                } else if (latestFormState.isTempOutSkipped &&
                    !formCubit.isSkipComplete(
                        latestFormState.tempOutNote,
                        latestFormState.tempOutSkipRemark,
                        latestFormState.tempOutSkipPhotos)) {
                  _showValidationSnackbar(context,
                      'Lengkapi keterangan tambahan (min. 20 huruf) & foto bukti kendala Suhu Luar Ruangan.');
                } else if (latestFormState.isTempInSkipped &&
                    !formCubit.isSkipComplete(
                        latestFormState.tempInNote,
                        latestFormState.tempInSkipRemark,
                        latestFormState.tempInSkipPhotos)) {
                  _showValidationSnackbar(context,
                      'Lengkapi keterangan tambahan (min. 20 huruf) & foto bukti kendala Suhu Dalam Ruangan.');
                } else if (latestFormState.allUnitsValidated &&
                    latestFormState.isFinalTempInSkipped &&
                    latestFormState.finalTempInNote.isEmpty) {
                  _showValidationSnackbar(
                      context, 'Catatan Suhu Final wajib diisi.');
                } else if (latestFormState.allUnitsValidated &&
                    latestFormState.isFinalTempInSkipped &&
                    !formCubit.isSkipComplete(
                        latestFormState.finalTempInNote,
                        latestFormState.finalTempInSkipRemark,
                        latestFormState.finalTempInSkipPhotos)) {
                  _showValidationSnackbar(context,
                      'Lengkapi keterangan tambahan (min. 20 huruf) & foto bukti kendala Suhu Final.');
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

  Widget _buildRetryButton(BuildContext context,
      PosValidationUploadPartial partial) {
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
                  builder: (_) =>
                      BlocProvider.value(
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
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
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

  Future<void> _navigateToValidation(BuildContext context,
      ProofOfServiceHeader header,
      ProofOfServiceItemDetail detail,
      String tempIn) async {
    final box = await Hive.openBox<PosValidationEntryModel>(
        kPosValidationHiveBox);
    PosValidationEntryModel? existingData;

    if (detail.isGeneric) {
      existingData = box.values.firstWhereOrNull((e) =>
      e.transNo == header.transNo &&
          e.unitIndex == detail.unitIndex &&
          e.articleType == detail.unitType);
    } else {
      existingData = box.get(detail.serialNo.trim().toUpperCase());
    }

    final double? indoorTemp = double.tryParse(tempIn);
    final detailState = context
        .read<ProofOfServiceDetailBloc>()
        .state;
    List<String> allIndoorSerials = [];
    List<NoteOption> noteOptionsToSend = [];

    if (detailState is ProofOfServiceDetailLoaded) {
      // 🔥 SMART DROPDOWN LOGIC 🔥
      final indoorUnits = detailState.data.detail.where((d) =>
      d.unitType.toUpperCase() == 'IN');
      for (var indoor in indoorUnits) {
        if (indoor.isGeneric) {
          final mapKey = '${indoor.unitType}_${indoor.unitIndex}';
          final realSn = detailState.savedSerials[mapKey];

          // HANYA MASUKKAN KE DROPDOWN JIKA TEKNISI SUDAH INPUT SN (Dan bukan "AC")
          if (realSn != null && realSn.isNotEmpty &&
              !realSn.toUpperCase().startsWith('AC')) {
            allIndoorSerials.add(realSn);
          }
        } else {
          // Untuk unit sewa, langsung masukin SN dari API
          allIndoorSerials.add(indoor.serialNo);
        }
      }

      final rawOptions = detail.unitType == 'IN'
          ? detailState.data.noteIndoorOptions ?? []
          : detailState.data.noteOutdoorOptions ?? [];

      noteOptionsToSend = rawOptions ?? [];
    }

    if (!context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PosValidationScreen(
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
              // Dropdown udah bersih
              noteOptions: noteOptionsToSend,
              isGeneric: detail.isGeneric,
              unitIndex: detail.unitIndex,
              reffLineNo: detail.reffLineNo,
            ),
      ),
    );

    if (context.mounted) {
      context.read<ProofOfServiceDetailBloc>().add(
          FetchProofOfServiceDetail(header.transNo.trim().toUpperCase()));
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
