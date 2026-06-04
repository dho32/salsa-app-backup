// lib/screens/service_call/service_call_detail/components/service_call_detail_body_mobile.dart

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

// --- Impor BLoC & State ---
import '../../../../blocs/auth/auth_storage.dart';
import '../../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../../blocs/location_validation/location_validation_event.dart';
import '../../../../blocs/location_validation/location_validation_state.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/otp/otp_event.dart';
import '../../../../blocs/otp/otp_repository.dart';
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
import '../../../../components/widgets/aho_dialog.dart';
import '../../../../components/widgets/ddl_pic_position.dart';
import '../../../../components/widgets/measurement_input_widget.dart';
import '../../../../components/widgets/otp.dart';
import '../../../../components/widgets/scan_qr.dart';
import '../../../../models/common/measurement_limits.dart';
import '../../../../models/common/note_option.dart';
import '../../../../models/service_call/problem_source_model.dart';
import '../../../../models/service_call/service_call_detail_model.dart';
import '../../../../models/service_call/service_call_validation_entry_model.dart';
import '../../../../models/service_call/transaction_info_model.dart';
import '../../../../models/service_call/validation_status.dart';
import '../../service_call_validation/components/remote_validation/remote_validation_screen.dart';
import '../../service_call_validation/service_call_validation_screen.dart';

class ValidationLoadResult {
  final Map<String, ValidationStatus> statuses;
  final List<ServiceCallValidationEntryModel> entries;

  ValidationLoadResult({required this.statuses, required this.entries});
}

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
  late final TextEditingController _picNameController;
  late final TextEditingController _picPhoneController;
  late final TextEditingController _picNikController;
  late final TextEditingController _technician1Controller;
  late final TextEditingController _technician2Controller;
  late final TextEditingController _technician3Controller;
  late final TextEditingController _finalTempController;
  final TextEditingController _finalTempNoteSearchController =
  TextEditingController();
  final TextEditingController _tech2SearchController = TextEditingController();
  final TextEditingController _tech3SearchController = TextEditingController();

  bool _showTechnician3 = false;
  Future<Map<String, ValidationStatus>>? _validationStatusFuture;
  String technicianName = '';
  String maintenanceBy = '';
  String maintenanceByIP = '';
  late final MeasurementLimits _scFinalTempBaseLimits;

  @override
  void initState() {
    super.initState();
    _loadUserInfoAndIP();
    _syncSavedPhoto();

    final configBox = Hive.box(kAppConfigBox);
    final Map<String, MeasurementLimits> headerLimits =
    Map<String, MeasurementLimits>.from(
        configBox.get('limits_temp_header') ?? {});

    _scFinalTempBaseLimits = headerLimits['sc_final_temp_in'] ??
        const MeasurementLimits(
            id: 'sc_final_temp_in',
            label: 'Suhu Dalam Ruangan (SC)',
            min: 4,
            max: 30,
            unit: '°C',
            normalMin: 5,
            normalMax: 18);

    final initialFormState = context.read<ScFormCubit>().state;

    _picNameController = TextEditingController(text: initialFormState.picName);
    _picPhoneController =
        TextEditingController(text: initialFormState.picPhone);
    _picNikController = TextEditingController(text: initialFormState.picNik);
    _technician1Controller =
        TextEditingController(text: initialFormState.technician1);
    _technician2Controller =
        TextEditingController(text: initialFormState.technician2);
    _technician3Controller =
        TextEditingController(text: initialFormState.technician3);
    _finalTempController =
        TextEditingController(text: initialFormState.finalTempIn);

    _showTechnician3 = initialFormState.showTechnician3;

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
    _technician1Controller.addListener(() {
      if (formCubit.state.technician1 != _technician1Controller.text) {
        formCubit.technician1Changed(_technician1Controller.text);
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
    _technician1Controller.dispose();
    _technician2Controller.dispose();
    _technician3Controller.dispose();
    _finalTempController.dispose();
    _finalTempNoteSearchController.dispose();
    _tech2SearchController.dispose();
    _tech3SearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfoAndIP() async {
    final user = await AuthStorage.getUser();
    final ip = await getPublicIpAddress();
    if (mounted) {
      setState(() {
        maintenanceBy = user['user_id'] ?? '';
        maintenanceByIP = ip;
      });
    }
  }

  // ✅ Helper Key yang Konsisten
  String _getHiveKey(String transNo) {
    return transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  void _syncSavedPhoto() {
    try {
      // ✅ Gunakan widget.transactionInfoBox & Helper Key
      final String hiveKey = _getHiveKey(widget.transNo);
      final data = widget.transactionInfoBox.get(hiveKey);

      if (data != null && data.picImageDetail != null) {
        context.read<ScFormCubit>().picImageChanged(data.picImageDetail!);
      }
    } catch (e) {
      print("⚠️ Gagal sync foto dari Hive: $e");
    }
  }

  Future<ValidationLoadResult> _loadValidationData(String transNo) async {
    try {
      final box =
      Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
      final statuses = <String, ValidationStatus>{};
      final List<ServiceCallValidationEntryModel> relevantEntries =
      box.values.where((e) => e.transNo == transNo).toList();

      for (final entry in relevantEntries) {
        final serial = entry.serialNo.trim().toUpperCase();
        statuses[serial] = entry.isCompleted
            ? ValidationStatus.completed
            : ValidationStatus.inProgress;
      }
      return ValidationLoadResult(statuses: statuses, entries: relevantEntries);
    } catch (e) {
      return ValidationLoadResult(statuses: {}, entries: []);
    }
  }

  void _refreshSerials() {
    final blocState = context.read<ServiceCallDetailBloc>().state;
    if (blocState is ServiceCallDetailLoaded) {
      final formCubit = context.read<ScFormCubit>();
      final List<ServiceCallUnitDetail> allUnits = blocState.data.detail;

      _loadValidationData(blocState.data.header.transNo).then((result) {
        if (mounted) {
          setState(() {
            _validationStatusFuture = Future.value(result.statuses);
          });
          formCubit.updateValidationProgress(allUnits, result.entries);
        }
      }).catchError((error) {
        if (mounted) {
          _showValidationSnackbar(
              context, "Gagal memuat status validasi unit.");
          setState(() {
            _validationStatusFuture = Future.value({});
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _validationStatusFuture = Future.value({});
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            return OtpBloc(repository: OtpRepository())
              ..add(CheckOtpStatus(widget.transNo));
          },
        ),
        BlocProvider(
          lazy: false, // ✅ Wajib False
          create: (context) {
            final detailState = context.read<ServiceCallDetailBloc>().state;
            double lat = 0;
            double long = 0;
            if (detailState is ServiceCallDetailLoaded) {
              lat = double.tryParse(detailState.data.header.storeLat) ?? 0;
              long = double.tryParse(detailState.data.header.storeLong) ?? 0;
            }

            return LocationValidationBloc(transactionBox: widget.transactionInfoBox)
              ..add(LoadLocationPhoto(widget.transNo, lat, long));
          },
        ),
      ],
      // 🔥 TAMBAHAN LISTENER UNTUK SYNC FOTO
      child: MultiBlocListener(
        listeners: [
          // 1. Sync Foto dari LocationBloc ke ScFormCubit
          BlocListener<LocationValidationBloc, LocationValidationState>(
            listener: (context, state) {
              if (state is LocationPhotoLoaded && state.photo != null) {
                print("🔄 [Sync] Foto baru diterima, update ScFormCubit!");
                context.read<ScFormCubit>().picImageChanged(state.photo!);
              }
            },
          ),

          // 2. Listener Form (Pindahkan logika lama kesini)
          BlocListener<ScFormCubit, ScFormState>(
            listenWhen: (prev, current) =>
            prev.picName != current.picName ||
                prev.picPhone != current.picPhone ||
                prev.picNik != current.picNik ||
                prev.picPosition != current.picPosition ||
                prev.technician1 != current.technician1 ||
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
              if (_technician1Controller.text != state.technician1) {
                _technician1Controller.text = state.technician1;
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
          ),
        ],
        child: BlocConsumer<ServiceCallDetailBloc, ServiceCallDetailState>(
          listener: (context, detailState) {
            if (detailState is ServiceCallDetailLoaded) {
              _refreshSerials();
            } else if (detailState is ServiceCallDetailError) {
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
              final detailList = detailState.data.detail;
              final sortedDetailList =
              List<ServiceCallUnitDetail>.from(detailList);

              sortedDetailList.sort((a, b) {
                bool isARemote =
                a.articleNameUnit.toUpperCase().contains('REMOTE');
                bool isBRemote =
                b.articleNameUnit.toUpperCase().contains('REMOTE');

                if (isARemote && !isBRemote) return 1;
                else if (!isARemote && isBRemote) return -1;
                else return a.serialNo.compareTo(b.serialNo);
              });

              final List<NoteOption> noteOptions =
                  detailState.data.noteIndoorAfterOptions;

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
                                "Error memuat status validasi: ${snapshot.error}"));
                      }

                      final validationStatuses = snapshot.data ?? {};
                      final header = detailState.data.header;
                      final problems = detailState.data.problems;

                      return BlocListener<ServiceCallSubmittedBloc,
                          ServiceCallSubmittedState>(
                        listener: (context, state) async {
                          if (state is ScFinalValidationLoading) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                  child: CircularProgressIndicator()),
                            );
                          } else if (state is ScProceedToAhoDialog) {
                            Navigator.of(context, rootNavigator: true).pop();
                            try {
                              await showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) {
                                  return AhoDialog(
                                    formState: state.formState,
                                    initialAho: state.initialAho,
                                    onSubmit: (String ahoNumber) {
                                      context
                                          .read<ServiceCallSubmittedBloc>()
                                          .add(
                                        AhoInputCompleted(
                                          formState: state.formState,
                                          ahoNumber: ahoNumber,
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            } catch (e, stacktrace) {
                              log("🔴 ERROR AhoDialog: $e",
                                  error: e, stackTrace: stacktrace);
                            }
                          } else if (state is ScProceedToOtpDialog) {
                            Navigator.of(context, rootNavigator: true).pop();
                            final formState = state.formState;
                            final double storeLat =
                                double.tryParse(header.storeLat) ?? 0.0;
                            final double storeLong =
                                double.tryParse(header.storeLong) ?? 0.0;

                            final otpBloc = context.read<OtpBloc>();
                            final locationBloc =
                            context.read<LocationValidationBloc>();

                            // 🔥 Logic Cek Foto Robust (Fallback Hive)
                            bool isPhotoReady = false;

                            final locState = locationBloc.state;
                            if (locState is LocationPhotoLoaded &&
                                locState.photo != null) {
                              isPhotoReady = true;
                              print("✅ SC: Foto ditemukan di BLoC State");
                            } else if (locState is LocationValidationFailure &&
                                locState.photo != null) {
                              isPhotoReady = true;
                              print("⚠️ SC: Foto ditemukan di BLoC Failure State");
                            }

                            if (!isPhotoReady) {
                              try {
                                final String hiveKey = _getHiveKey(widget.transNo);
                                final info = widget.transactionInfoBox.get(hiveKey);

                                if (info?.picImageDetail != null) {
                                  isPhotoReady = true;
                                  print("✅ SC: Foto ditemukan via Fallback Hive (Key: $hiveKey)");
                                  // Opsional: Refresh Bloc biar sinkron
                                  locationBloc.add(LoadLocationPhoto(widget.transNo, 0, 0));
                                } else {
                                  print("❌ SC: Foto TIDAK ditemukan di Hive. Key: $hiveKey");
                                }
                              } catch (e) {
                                print("❌ SC: Gagal cek Hive manual: $e");
                              }
                            }

                            OtpStorage.isOtpRequired().then((wajibOtp) {
                              showDialog<void>(
                                context: context,
                                builder: (_) {
                                  return MultiBlocProvider(
                                    providers: [
                                      BlocProvider.value(value: otpBloc),
                                      BlocProvider.value(value: locationBloc),
                                      BlocProvider.value(
                                          value: context
                                              .read<UploadProgressCubit>()),
                                    ],
                                    child: OtpDialog(
                                      transNo: widget.transNo,
                                      shipTo: header.storeId,
                                      email: header.storeEmail,
                                      storeLat: storeLat,
                                      storeLong: storeLong,
                                      isPhotoExisting: isPhotoReady,
                                      isOtpRequired: wajibOtp, // 🔥 OPER FLAG KE DIALOG
                                      onVerified: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => const Center(
                                              child: CircularProgressIndicator()),
                                        );

                                        final progressCubit =
                                        context.read<UploadProgressCubit>();
                                        context
                                            .read<ServiceCallSubmittedBloc>()
                                            .add(
                                          SubmitValidation(
                                            transNo: header.transNo,
                                            createdBy: maintenanceBy,
                                            createdByName:
                                            formState.technician1,
                                            createdByIP: maintenanceByIP,
                                            pathAttachment:
                                            header.pathAttachment,
                                            progressCubit: progressCubit,
                                            formState: formState,
                                            storeName: header.storeName,
                                            ahoNumber: state.ahoNumber,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            });
                          } else if (state is ValidationUploadPartial) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            if (state.failureCount > 0) {
                              showPartialUploadDialog(
                                context,
                                state.successCount,
                                state.failureCount,
                                state.failedFiles,
                              );
                            }
                          } else if (state is ValidationSuccess) {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            showSuccessDialog(
                              context,
                              "Data berhasil dikirim.",
                              onOk: () {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              },
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 65.0),
                              child: SingleChildScrollView(
                                padding:
                                const EdgeInsets.fromLTRB(16, 16, 16, 35),
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
                                          _buildScanQRButton(
                                              context, detailState),
                                          const SizedBox(height: 8),
                                          ...sortedDetailList.map((item) =>
                                              _buildDetailCard(header, item,
                                                  validationStatuses)),
                                        ],
                                      ),
                                    ),
                                    BlocBuilder<ScFormCubit, ScFormState>(
                                      buildWhen: (prev, current) {
                                        return prev.allUnitsValidated !=
                                            current.allUnitsValidated ||
                                            prev.isFinalTempSkipped !=
                                                current.isFinalTempSkipped ||
                                            prev.finalTempNote !=
                                                current.finalTempNote ||
                                            prev.finalTempInImage !=
                                                current.finalTempInImage ||
                                            prev.minFinalTempInLimit !=
                                                current.minFinalTempInLimit;
                                      },
                                      builder: (context, formStateForTemp) {
                                        final bool isEnabled =
                                            formStateForTemp.allUnitsValidated;
                                        return Padding(
                                          padding:
                                          const EdgeInsets.only(top: 16.0),
                                          child: Stack(
                                            children: [
                                              Opacity(
                                                opacity: isEnabled ? 1.0 : 0.5,
                                                child: AbsorbPointer(
                                                  absorbing: !isEnabled,
                                                  child: _buildFinalTempSection(
                                                      context,
                                                      formStateForTemp,
                                                      noteOptions),
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
                                                    BorderRadius.circular(
                                                        12),
                                                    child: Container(
                                                        color:
                                                        Colors.transparent),
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
                            _buildSubmitButton(
                                context, header, problems, formState),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }
            return const Center(child: Text("Data belum dimuat"));
          },
        ),
      ),
    );
  }

  // --- Widget Helper Tetap Sama ---
  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
        Text('Posted: ${header.postedDate.split('T')[0]}')
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
    context.read<ScFormCubit>();
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
                child: scPositionDropdown(context, formState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicianPanel(BuildContext context, ScFormState formState) {
    final formCubit = context.read<ScFormCubit>();
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
            onTap: () {},
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
              onTap: () {},
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
                onTap: () {},
                onChanged: (value) {
                  formCubit.technician3Changed(value);
                  formCubit.onFieldChanged();
                },
                iconBtn: IconButton(
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
        .where((t) => excludedName.isEmpty || t['technician_name'] != excludedName)
        .toList();

    // Jika nilai tersimpan tidak ada di daftar (mis. draft lama atau roster teknisi
    // berubah), sisipkan sebagai item agar tetap tampil & ikut ter-submit — bukan
    // hilang diam-diam dari tampilan sementara datanya masih dikirim.
    if (value.isNotEmpty && !filtered.any((t) => t['technician_name'] == value)) {
      filtered.insert(0, {'technician_id': '', 'technician_name': value});
    }
    final currentValue = filtered.any((t) => t['technician_name'] == value) ? value : null;

    final dropdown = DropdownButtonFormField2<String>(
      value: currentValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.engineering, color: Colors.grey.shade600, size: 20),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              hintText: 'Cari teknisi...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) =>
            item.value.toString().toLowerCase().contains(searchValue.toLowerCase()),
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
                  (e) => e.serialNo.trim().toUpperCase().startsWith(
                scannedSerialNo.trim().toUpperCase(),
              ),
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
                _refreshSerials();
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
    final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
    final existingEntry = box.values.firstWhereOrNull((e) =>
    e.serialNo.trim().toUpperCase() ==
        detail.serialNo.trim().toUpperCase() &&
        e.transNo == header.transNo);

    String displaySerial = detail.serialNo;
    bool isSwapped = false;

    if (existingEntry != null &&
        existingEntry.correctSerialNo != null &&
        existingEntry.correctSerialNo!.isNotEmpty) {
      displaySerial = existingEntry.correctSerialNo!;
      isSwapped = true;
    }

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
            Row(
              children: [
                Text('Serial No: ',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (isSwapped) ...[
                  Text(displaySerial,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange)),
                  const SizedBox(width: 4),
                  const Icon(Icons.swap_horiz,
                      size: 16, color: Colors.deepOrange),
                ] else
                  Text(displaySerial,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (isSwapped)
              const Text('(Unit Hasil Koreksi)',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.deepOrange,
                      fontStyle: FontStyle.italic)),
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
          final detailState = context.read<ServiceCallDetailBloc>().state;
          if (detailState is! ServiceCallDetailLoaded) return;

          final outdoorSerials =
          detailState.data.outdoor.map((unit) => unit.serialNo).toList();
          final problemSources = detailState.data.problems;

          String serialForDisplay = detail.serialNo;
          if (existingEntry != null &&
              existingEntry.correctSerialNo != null &&
              existingEntry.correctSerialNo!.isNotEmpty) {
            serialForDisplay = existingEntry.correctSerialNo!;
          }

          if (isRemote) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RemoteValidationScreen(
                  transNo: header.transNo,
                  uniqueId: detail.serialNo,
                  articleName: detail.articleNameUnit,
                  initialData: existingEntry,
                  complaintDetails: detail.complaintDetails,
                  imageFile: header.pathAttachment,
                  problemSources: problemSources,
                ),
              ),
            );

            if (mounted) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              _refreshSerials();
            }
          } else {
            final detailData = (context.read<ServiceCallDetailBloc>().state
            as ServiceCallDetailLoaded)
                .data;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceCallValidationScreen(
                  serialNo: detail.serialNo,
                  displaySerialNo: serialForDisplay,
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

            if (mounted) {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              _refreshSerials();
            }
          }
        },
      ),
    );
  }

  Widget _buildFinalTempSection(BuildContext context, ScFormState formState,
      List<NoteOption> noteOptions) {
    final formCubit = context.read<ScFormCubit>();
    final baseLimits = _scFinalTempBaseLimits;
    final String label = baseLimits.label;
    final finalTempLimits = MeasurementLimits(
      id: baseLimits.id,
      label: label,
      min: baseLimits.min,
      max: baseLimits.max,
      unit: baseLimits.unit,
      normalMin: baseLimits.normalMin,
      normalMax: baseLimits.normalMax,
    );

    return _buildSection(
      title: 'Suhu Dalam Ruangan Setelah Service (*Wajib)',
      child: Column(
        children: [
          MeasurementInputWidget(
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
            isSkipEnabled: true,
            isSkipped: formState.isFinalTempSkipped,
            onSkipChanged: (isSkipped) {
              // Panggil method baru di Cubit
              formCubit.finalTempSkippedChanged(isSkipped);
            },
          ),
          if (formState.isFinalTempSkipped)
            _buildNoteDropdown(
              context: context,
              options: noteOptions,
              selectedValue: formState.finalTempNote,
              searchController: _finalTempNoteSearchController,
              label: 'Alasan Skip Suhu Akhir',
              onChanged: (value) {
                formCubit.finalTempNoteChanged(value); // Panggil method baru
                formCubit.onFieldChanged();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ServiceCallHeader header,
      List<ProblemSourceModel> problems, ScFormState formState) {
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
              // Paksa sinkronisasi
              scFormCubit.picNameChanged(_picNameController.text);
              scFormCubit.picPhoneChanged(_picPhoneController.text);
              scFormCubit.picNikChanged(_picNikController.text);
              scFormCubit.technician1Changed(_technician1Controller.text);
              scFormCubit.technician2Changed(_technician2Controller.text);
              scFormCubit.technician3Changed(_technician3Controller.text);
              scFormCubit.finalTempInChanged(_finalTempController.text);
              scFormCubit.onFieldChanged();
              final latestFormState = scFormCubit.state;

              if (latestFormState.isFormReadyToSubmit) {
                context.read<ServiceCallSubmittedBloc>().add(
                  ScFinalValidationRequested(
                    transNo: widget.transNo,
                    formState: latestFormState,
                    problemSources: problems,
                  ),
                );
              } else {
                // Tampilkan pesan error spesifik
                if (!latestFormState.isPicStoreValid) {
                  _showValidationSnackbar(context, 'Lengkapi info PIC.');
                } else if (latestFormState.technician1.isEmpty) {
                  _showValidationSnackbar(context, 'Harap isi nama Teknisi 1.');
                } else if (!latestFormState.allUnitsValidated) {
                  _showValidationSnackbar(
                      context, 'Lengkapi validasi semua unit.');
                } else if (!latestFormState.isFinalTempValid) {
                  _showValidationSnackbar(
                      context, 'Lengkapi suhu dalam ruangan & fotonya.');
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

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    IconButton? iconBtn,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
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

  Widget _buildNoteDropdown({
    required BuildContext context,
    required List<NoteOption> options,
    required String? selectedValue,
    required TextEditingController searchController,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    final double maxDropdownHeight = MediaQuery.of(context).size.height * 0.4;

    final filteredOptions = options.where((opt) {
      return !opt.isSystemOnly || opt.label == selectedValue;
    }).toList();
    final selectedOptionObj =
        filteredOptions.where((opt) => opt.label == selectedValue).firstOrNull;
    final bool isReadOnlySystemValue = selectedOptionObj?.isSystemOnly ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16.0),
      // Sesuaikan padding
      child: DropdownButtonFormField2<String>(
        value: selectedValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: '$label (*Wajib)',
          border: const OutlineInputBorder(),
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
        hint: Text('Pilih Alasan', style: const TextStyle(fontSize: 14)),
        items: options
            .map((item) => DropdownMenuItem<String>(
          value: item.label,
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(item.label,
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        selectedItemBuilder: (context) {
          return options.map((item) {
            return Text(
              item.label,
              style: const TextStyle(
                  fontSize: 14, overflow: TextOverflow.ellipsis),
              maxLines: 1,
            );
          }).toList();
        },
        dropdownStyleData: DropdownStyleData(
          maxHeight: maxDropdownHeight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        ),
        menuItemStyleData: const MenuItemStyleData(
          padding: EdgeInsets.symmetric(horizontal: 14),
        ),
        dropdownSearchData: DropdownSearchData(
          searchController: searchController,
          searchInnerWidgetHeight: 50,
          searchInnerWidget: Container(
            height: 50,
            padding: const EdgeInsets.all(8),
            child: TextFormField(
              expands: true,
              maxLines: null,
              controller: searchController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText: 'Cari alasan...',
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
      ),
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
}