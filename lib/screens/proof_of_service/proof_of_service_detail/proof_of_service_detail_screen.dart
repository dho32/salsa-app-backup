import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import '../../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../blocs/failed_uploads/failed_uploads_repository.dart';
import '../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../blocs/location_validation/location_validation_event.dart';
import '../../../blocs/location_validation/location_validation_state.dart';
import '../../../blocs/otp/otp_bloc.dart';
import '../../../blocs/otp/otp_event.dart';
import '../../../blocs/otp/otp_repository.dart';
import '../../../blocs/proof_of_service/pos_unserviceable/pos_unserviceable_bloc.dart';
import '../../../blocs/proof_of_service/pos_unserviceable/pos_unserviceable_event.dart';
import '../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_state.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/components/shared_widgets.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/models/service_call/validation_status.dart';
import '../../../components/shared_function.dart';
import '../../../components/widgets/otp.dart';
import '../../../models/common/note_option.dart';
import '../../common/services/confirmation_service.dart';
import '../proof_of_service_report_issue/pos_report_issue_screen.dart';
import 'components/proof_of_service_detail_body_mobile.dart';

class ProofOfServiceDetailScreen extends StatefulWidget {
  final String transNo;

  const ProofOfServiceDetailScreen({super.key, required this.transNo});

  @override
  State<ProofOfServiceDetailScreen> createState() =>
      _ProofOfServiceDetailScreenState();
}

class _ProofOfServiceDetailScreenState
    extends State<ProofOfServiceDetailScreen> {
  Box<PosTransactionInfoModel>? _transactionInfoBox;
  String? _technician1Name;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
    _loadTechnicianName();
  }

  Future<void> _loadTechnicianName() async {
    final user = await AuthStorage.getUser();
    if (mounted) {
      setState(() {
        _technician1Name = user['name'] ?? 'Nama Tidak Ditemukan';
      });
    }
  }

  Future<void> _openHiveBox() async {
    final box =
        await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    if (mounted) {
      setState(() {
        _transactionInfoBox = box;
      });
    }
  }

  String _getHiveKey(String transNo) {
    return transNo.trim().toUpperCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  @override
  Widget build(BuildContext context) {
    if (_transactionInfoBox == null || _technician1Name == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 🔥 2. BUNGKUS DENGAN REPOSITORY PROVIDER
    return RepositoryProvider(
      create: (context) => FailedUploadsRepository(), // Buat Repo di sini
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                ProofOfServiceDetailBloc(ProofOfServiceDetailRepository())
                  ..add(FetchProofOfServiceDetail(widget.transNo)),
          ),
          BlocProvider(
            create: (context) {
              final bloc =
                  PosSubmittedBloc(repository: PosSubmittedRepository());
              Hive.openBox<Map<dynamic, dynamic>>(kPosValidationPartialHiveBox)
                  .then((box) {
                if (box.containsKey(widget.transNo)) {
                  bloc.add(LoadPosValidationPartial(widget.transNo));
                }
              });
              return bloc;
            },
          ),
          BlocProvider(create: (context) => UploadProgressCubit()),

          // 🔥 3. UPDATE FAILED UPLOADS BLOC
          BlocProvider(
            create: (context) => FailedUploadsBloc(
              progressCubit: context.read<UploadProgressCubit>(),
              repository:
                  context.read<FailedUploadsRepository>(), // INJECT REPO
            )..add(LoadFailedUploads()),
          ),

          BlocProvider<PosFormCubit>(
            create: (context) {
              final detailState =
                  context.read<ProofOfServiceDetailBloc>().state;
              bool initialAllUnitsValidated = false;
              if (detailState is ProofOfServiceDetailLoaded) {
                initialAllUnitsValidated =
                    detailState.data.detail.every((detail) {
                  final mapKey = detail.isGeneric
                      ? '${detail.unitType}_${detail.unitIndex}'
                      : detail.serialNo.trim().toUpperCase();
                  return detailState.validationStatuses[mapKey] ==
                      ValidationStatus.completed;
                });
              }
              return PosFormCubit(
                transNo: widget.transNo,
                initialAllUnitsValidated: initialAllUnitsValidated,
              );
            },
          ),
          BlocProvider(
            create: (context) => PosUnserviceableBloc(transNo: widget.transNo)
              ..add(LoadUnserviceableDraft()),
          ),
          BlocProvider(
            create: (context) => OtpBloc(repository: OtpRepository())
              ..add(CheckOtpStatus(widget.transNo)),
          ),
          BlocProvider(
            lazy: false,
            create: (context) {
              final detailBloc = context.read<ProofOfServiceDetailBloc>();
              final detailState = detailBloc.state;
              double lat = 0;
              double long = 0;
              if (detailState is ProofOfServiceDetailLoaded) {
                lat = double.tryParse(detailState.data.header.latitude) ?? 0;
                long = double.tryParse(detailState.data.header.longitude) ?? 0;
              }
              return LocationValidationBloc(
                  transactionBox: _transactionInfoBox!)
                ..add(LoadLocationPhoto(widget.transNo, lat, long));
            },
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            BlocListener<LocationValidationBloc, LocationValidationState>(
              listener: (context, state) {
                if (state is LocationPhotoLoaded && state.photo != null) {
                  print(
                      "🔄 [POS Sync] Foto baru diterima, update PosFormCubit!");
                  context.read<PosFormCubit>().picImageChanged(state.photo!);
                }
              },
            ),
            BlocListener<PosSubmittedBloc, PosSubmittedState>(
              listener: (context, state) {
                if (state is PosValidationUploadInProgress) {
                  final uploadCubit = context.read<UploadProgressCubit>();
                  uploadCubit.reset();
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => BlocProvider.value(
                      value: uploadCubit,
                      child: const UploadProgressDialog(),
                    ),
                  );
                } else if (state is PosValidationUploadPartial) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  showPartialUploadDialog(context, state.successCount,
                      state.failureCount, state.failedFiles);
                } else if (state is PosValidationSuccess) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  ConfirmationService().processQueue();
                  showSuccessDialog(context, "Data berhasil dikirim.",
                      onOk: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  });
                } else if (state is PosValidationFailure) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  showFailureDialog(context, state.error);
                } else if (state is ShowCreateServiceCallDialog) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text("Unit Bermasalah Terdeteksi"),
                      content: const Text(kStringDialogUnitProblem),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("OK"))
                      ],
                    ),
                  );
                } else if (state is ProceedToOtpDialog) {
                  final detailState =
                      context.read<ProofOfServiceDetailBloc>().state;
                  if (detailState is ProofOfServiceDetailLoaded) {
                    final header = detailState.data.header;

                    bool isPhotoReady = false;
                    final locationBloc = context.read<LocationValidationBloc>();
                    final otpBloc = context.read<OtpBloc>();

                    final locState = locationBloc.state;
                    if (locState is LocationPhotoLoaded &&
                        locState.photo != null) {
                      isPhotoReady = true;
                    } else if (locState is LocationValidationFailure &&
                        locState.photo != null) {
                      isPhotoReady = true;
                    }

                    if (!isPhotoReady && _transactionInfoBox != null) {
                      try {
                        final key = _getHiveKey(widget.transNo);
                        final info = _transactionInfoBox!.get(key);
                        if (info?.picImageDetail != null) {
                          isPhotoReady = true;
                          locationBloc
                              .add(LoadLocationPhoto(widget.transNo, 0, 0));
                        }
                      } catch (e) {
                        print("Error check hive manual: $e");
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
                                  value: context.read<UploadProgressCubit>()),
                            ],
                            child: OtpDialog(
                              transNo: header.transNo,
                              shipTo: header.shipToCode,
                              email: header.storeEmail,
                              storeLat: double.tryParse(header.latitude) ?? 0.0,
                              storeLong: double.tryParse(header.longitude) ?? 0.0,
                              isPhotoExisting: isPhotoReady,
                              isOtpRequired: wajibOtp,
                              onVerified: () {
                                Navigator.pop(context);
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                      child: CircularProgressIndicator()),
                                );
                                AuthStorage.getUser().then((user) {
                                  getPublicIpAddress().then((ip) {
                                    if (!mounted) return; // SAFEGUARD
                                    context.read<PosSubmittedBloc>().add(
                                      SubmitPosValidation(
                                        transNo: header.transNo,
                                        createdBy: user['user_id'] ?? '',
                                        createdByName: user['name'] ?? '',
                                        createdByIP: ip,
                                        progressCubit: context
                                            .read<UploadProgressCubit>(),
                                      ),
                                    );
                                  });
                                });
                              },
                            ),
                          );
                        },
                      );
                    });
                  }
                }
              },
            ),
            BlocListener<ProofOfServiceDetailBloc, ProofOfServiceDetailState>(
              listener: (context, detailState) {
                if (detailState is ProofOfServiceDetailLoaded) {
                  final formCubit = context.read<PosFormCubit>();
                  final allUnitsValidated =
                      detailState.data.detail.every((detail) {
                    final mapKey = detail.isGeneric
                        ? '${detail.unitType}_${detail.unitIndex}'
                        : detail.serialNo.trim().toUpperCase();
                    return detailState.validationStatuses[mapKey] ==
                        ValidationStatus.completed;
                  });
                  formCubit.updateAllUnitsValidated(allUnitsValidated);
                  formCubit.recalculateFinalTempLimit();
                }
              },
            ),
          ],
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/bg_app.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: const Text(""),
                backgroundColor: Colors.transparent,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                actions: [
                  BlocBuilder<PosSubmittedBloc, PosSubmittedState>(
                    builder: (context, submitState) {
                      if (submitState is! PosValidationUploadPartial) {
                        return BlocBuilder<ProofOfServiceDetailBloc,
                            ProofOfServiceDetailState>(
                          builder: (context, detailState) {
                            if (detailState is ProofOfServiceDetailLoaded) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.warning_amber_rounded,
                                      size: 16),
                                  label: const Text(
                                      "Laporkan Masalah Jika Tidak Bisa Service"),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.orange.shade900,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.9),
                                    shape: const StadiumBorder(),
                                    elevation: 2,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: () {
                                    final List<NoteOption> rawReasons =
                                        detailState.data.unserviceableReasons ??
                                            [];
                                    final List<String> reasons =
                                        rawReasons.map((e) => e.label).toList();
                                    final String transNo =
                                        detailState.data.header.transNo;
                                    final posUnserviceableBloc =
                                        context.read<PosUnserviceableBloc>();
                                    final uploadProgressCubit =
                                        context.read<UploadProgressCubit>();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MultiBlocProvider(
                                          providers: [
                                            BlocProvider.value(
                                                value: posUnserviceableBloc),
                                            BlocProvider.value(
                                                value: uploadProgressCubit),
                                          ],
                                          child: PosReportIssueScreen(
                                            transNo: transNo,
                                            reasons: reasons,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: ProofOfServiceDetailBodyMobile(
                  transNo: widget.transNo,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
