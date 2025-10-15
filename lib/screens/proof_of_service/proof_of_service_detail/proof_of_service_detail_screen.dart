import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import '../../../blocs/failed_uploads/failed_uploads_bloc.dart';
import '../../../blocs/failed_uploads/failed_uploads_event.dart';
import '../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../blocs/otp/otp_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika data awal (nama teknisi, dll) belum siap
    if (_transactionInfoBox == null || _technician1Name == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // --- MultiBlocProvider SEKARANG MEMBUNGKUS SEMUANYA ---
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ProofOfServiceDetailBloc(ProofOfServiceDetailRepository())
                ..add(FetchProofOfServiceDetail(widget.transNo)),
        ),
        BlocProvider(
          create: (context) {
            final bloc = PosSubmittedBloc(repository: PosSubmittedRepository());
            Hive.openBox(kPosValidationPartialHiveBox).then((box) {
              if (box.containsKey(widget.transNo)) {
                bloc.add(LoadPosValidationPartial(widget.transNo));
              }
            });
            return bloc;
          },
        ),
        BlocProvider(
          create: (context) => UploadProgressCubit(),
        ),
        BlocProvider(
          create: (context) => FailedUploadsBloc(
            progressCubit: context.read<UploadProgressCubit>(),
          )..add(LoadFailedUploads()),
        ),
        BlocProvider<PosFormCubit>(
          create: (context) {
            final detailState = context.read<ProofOfServiceDetailBloc>().state;
            bool initialAllUnitsValidated = false;
            if (detailState is ProofOfServiceDetailLoaded) {
              initialAllUnitsValidated =
                  detailState.data.detail.every((detail) {
                final serialKey = detail.serialNo.trim().toUpperCase();
                return detailState.validationStatuses[serialKey] ==
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
      ],
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_app.png"),
            // <-- Ganti dengan path gambar Anda
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
                  // Tombol hanya muncul jika tidak ada antrian retry
                  if (submitState is! PosValidationUploadPartial) {
                    return BlocBuilder<ProofOfServiceDetailBloc,
                        ProofOfServiceDetailState>(
                      builder: (context, detailState) {
                        // Dan hanya jika data detail sudah berhasil dimuat
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
                                backgroundColor: Colors.white.withOpacity(0.9),
                                shape: const StadiumBorder(),
                                elevation: 2,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                final List<String> reasons =
                                    detailState.data.unserviceableReasons ?? [];
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
                        return const SizedBox
                            .shrink(); // Sembunyikan jika data belum siap
                      },
                    );
                  }
                  return const SizedBox
                      .shrink(); // Sembunyikan jika ada antrian retry
                },
              ),
            ],
          ),
          body: BlocListener<PosSubmittedBloc, PosSubmittedState>(
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
                // 1. Tutup dialog progress yang sedang berjalan
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                // 2. Tampilkan dialog informasi kegagalan parsial
                showPartialUploadDialog(
                  context,
                  state.successCount,
                  state.failureCount,
                  state.failedFiles,
                );
              } else if (state is PosValidationSuccess) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                ConfirmationService().processQueue();
                showSuccessDialog(
                  context,
                  "Data berhasil dikirim.",
                  onOk: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                );
              } else if (state is PosValidationFailure) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                showFailureDialog(context, state.error);
              } else if (state is ShowCreateServiceCallDialog) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Unit Bermasalah Terdeteksi"),
                    content: const Text("""
Ditemukan unit AC bermasalah yang belum memiliki tiket Service Call aktif pada toko ini.

Mohon koordinasikan dengan PIC toko untuk membuat transaksi Service Call terpisah terlebih dahulu, 
kemudian lanjutkan penyelesaian DO setelah transaksi tersebut dibuat."""),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("OK"),
                      ),
                    ],
                  ),
                );
              } else if (state is ProceedToOtpDialog) {
                // Jika BLoC memberi izin, BARU tampilkan dialog OTP
                final detailState = context.read<ProofOfServiceDetailBloc>().state;
                if (detailState is ProofOfServiceDetailLoaded) {
                  final header = detailState.data.header;
                  // Kode untuk menampilkan OtpDialog (yang kita pindahkan dari tombol 'Selesai')
                  showDialog<void>(
                    context: context,
                    builder: (_) {
                      return MultiBlocProvider(
                        providers: [
                          BlocProvider(create: (_) => OtpBloc(repository: OtpRepository())),
                          BlocProvider(create: (_) => LocationValidationBloc()),
                          BlocProvider.value(value: context.read<UploadProgressCubit>()),
                        ],
                        child: OtpDialog(
                          transNo: header.transNo,
                          shipTo: header.shipToCode,
                          email: header.storeEmail,
                          storeLat: double.tryParse(header.latitude ?? '0') ?? 0.0,
                          storeLong: double.tryParse(header.longitude ?? '0') ?? 0.0,
                          onVerified: () {
                            // Ambil data user di sini, tepat sebelum submit
                            AuthStorage.getUser().then((user) {
                              getPublicIpAddress().then((ip) {
                                context.read<PosSubmittedBloc>().add(
                                  SubmitPosValidation(
                                    transNo: header.transNo,
                                    createdBy: user['user_id'] ?? '',
                                    createdByName: user['name'] ?? '',
                                    createdByIP: ip,
                                    progressCubit: context.read<UploadProgressCubit>(),
                                  ),
                                );
                              });
                            });
                          },
                        ),
                      );
                    },
                  );
                }
              }
            },
            child: BlocListener<ProofOfServiceDetailBloc,
                ProofOfServiceDetailState>(
              listener: (context, detailState) {
                if (detailState is ProofOfServiceDetailLoaded) {
                  final allUnitsValidated =
                      detailState.data.detail.every((detail) {
                    final serialKey = detail.serialNo.trim().toUpperCase();
                    return detailState.validationStatuses[serialKey] ==
                        ValidationStatus.completed;
                  });
                  context
                      .read<PosFormCubit>()
                      .updateAllUnitsValidated(allUnitsValidated);
                }
              },
              child: SafeArea(
                child: ProofOfServiceDetailBodyMobile(
                  transNo: widget.transNo,
                  technician1Name: _technician1Name!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
