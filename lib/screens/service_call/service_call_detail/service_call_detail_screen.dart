import 'package:collection/collection.dart'; // <-- Tambahkan import collection
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_event.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_repository.dart';
import 'package:salsa/blocs/service_call/service_call_unserviceable/sc_unserviceable_event.dart';

import '../../../blocs/otp/otp_bloc.dart';
import '../../../blocs/otp/otp_repository.dart';
import '../../../blocs/service_call/sc_form/sc_form_cubit.dart'; // <-- Impor Cubit baru
import '../../../blocs/service_call/service_call_detail/service_call_detail_state.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_bloc.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_repository.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import '../../../blocs/service_call/service_call_unserviceable/sc_unserviceable_bloc.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/constants.dart';
import '../../../components/shared_widgets.dart';
import '../../../models/service_call/service_call_validation_entry_model.dart';
import '../../../models/service_call/transaction_info_model.dart';
import '../service_call_report_issue/service_call_report_issue_screen.dart';
import 'components/service_call_detail_body_mobile.dart';


class ServiceCallDetailScreen extends StatefulWidget {
  final String transNo;
  final String maintenanceBy;

  const ServiceCallDetailScreen({
    super.key,
    required this.transNo,
    required this.maintenanceBy,
  });

  @override
  State<ServiceCallDetailScreen> createState() =>
      _ServiceCallDetailScreenState();
}

class _ServiceCallDetailScreenState extends State<ServiceCallDetailScreen> {
  late final Box<TransactionInfoModel> _transactionInfoBox;
  bool _isBoxReady = false;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    // Pastikan box SC Info dibuka
    _transactionInfoBox =
    await Hive.openBox<TransactionInfoModel>(kTransactionInfoHiveBox);
    if (mounted) {
      setState(() {
        _isBoxReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading jika box belum siap
    if (!_isBoxReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Pindahkan MultiBlocProvider ke level tertinggi setelah cek _isBoxReady
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SCUnserviceableBloc(transNo: widget.transNo)
            ..add(LoadUnserviceableDraft()),
        ),
        BlocProvider(create: (_) => OtpBloc(repository: OtpRepository())),
        BlocProvider(
          create: (_) => ServiceCallDetailBloc(ServiceCallDetailRepository())
            ..add(FetchServiceCallDetail(widget.transNo, widget.maintenanceBy)),
        ),
        BlocProvider(
          create: (_) {
            final bloc = ServiceCallSubmittedBloc(
              repository: ServiceCallSubmittedRepository(),
            );
            // Muat data partial (tidak berubah)
            Hive.openBox(kServiceCallValidationPartialHiveBox).then((box) {
              final data = box.get(widget.transNo);
              if (data != null) {
                bloc.add(LoadValidationPartial(widget.transNo));
              }
            });
            return bloc;
          },
        ),
        BlocProvider(create: (_) => UploadProgressCubit()),
        BlocProvider(
          create: (context) => ScFormCubit(transNo: widget.transNo),
        ),
      ],
      // Child utama adalah Container background
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_app.png"),
            fit: BoxFit.cover,
          ),
        ),
        // Di dalam Container ada Scaffold
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text("Close Complaint"),
            backgroundColor: Colors.transparent,
            // actions: [
            //   // Tombol Laporkan Masalah (tidak berubah)
            //   BlocBuilder<ServiceCallDetailBloc, ServiceCallDetailState>(
            //     builder: (context, detailState) {
            //       if (detailState is ServiceCallDetailLoaded) {
            //         return BlocBuilder<ServiceCallSubmittedBloc, ServiceCallSubmittedState>(
            //             builder: (context, submittedState){
            //               final bool shouldShowButton = submittedState is! ValidationUploadPartial ||
            //                   (submittedState.transNo != widget.transNo);
            //
            //               if (shouldShowButton){
            //                 return Padding(
            //                   padding: const EdgeInsets.only(right: 16.0),
            //                   child: ElevatedButton.icon(
            //                     icon: const Icon(Icons.warning_amber_rounded,
            //                         size: 16),
            //                     label: const Text("Laporkan Masalah Kunjungan"),
            //                     style: ElevatedButton.styleFrom(
            //                       foregroundColor: Colors.orange.shade900,
            //                       backgroundColor: Colors.white.withOpacity(0.9),
            //                       shape: const StadiumBorder(),
            //                       elevation: 2,
            //                       visualDensity: VisualDensity.compact,
            //                     ),
            //                     onPressed: () {
            //                       final List<String> reasons = detailState.data.unserviceableReasons ?? [];
            //                       final String transNo = widget.transNo;
            //                       final String pathAttachment = detailState.data.header.pathAttachment;
            //
            //                       // final List<String> reasons =
            //                       //     detailState.data.unserviceableReasons ?? [];
            //                       // final String transNo =
            //                       //     detailState.data.header.transNo;
            //
            //                       final scUnserviceableBloc =
            //                       context.read<SCUnserviceableBloc>();
            //                       final uploadProgressCubit =
            //                       context.read<UploadProgressCubit>();
            //
            //                       Navigator.push(
            //                         context,
            //                         MaterialPageRoute(
            //                           builder: (_) => MultiBlocProvider(
            //                             providers: [
            //                               BlocProvider.value(
            //                                   value: scUnserviceableBloc),
            //                               BlocProvider.value(
            //                                   value: uploadProgressCubit),
            //                             ],
            //                             child: SCReportIssueScreen(
            //                               transNo: transNo,
            //                               pathAttachment: pathAttachment,
            //                               reasons: reasons,
            //                             ),
            //                           ),
            //                         ),
            //                       );
            //                     },
            //                   ),
            //                 );
            //               } else {
            //                 return const SizedBox.shrink();
            //               }
            //             }
            //         );
            //       }
            //       return const SizedBox.shrink();
            //     },
            //   ),
            // ],
          ),
          // Body sekarang dibungkus oleh Listener-listener
          body: BlocListener<ServiceCallDetailBloc, ServiceCallDetailState>(
            listener: (context, detailState) {
              // --- LISTENER PENGHUBUNG ---
              if (detailState is ServiceCallDetailLoaded) {
                // Gunakan Hive.box() karena sudah dibuka di main.dart
                final box = Hive.box<ServiceCallValidationEntryModel>(kServiceCallHiveBox);
                final entries = box.values.where((e) => e.transNo == widget.transNo);

                // Hitung allUnitsValidated
                final allUnitsValidated = detailState.data.detail.every((unitDetail) {
                  final serialKey = unitDetail.serialNo.trim().toUpperCase();
                  // Cari entry yang cocok berdasarkan serial number
                  final entry = entries.firstWhereOrNull((e) => e.serialNo.trim().toUpperCase() == serialKey);
                  // Dianggap selesai jika entry ada DAN isCompleted true
                  return entry?.isCompleted ?? false;
                });

                // Update ScFormCubit
                context.read<ScFormCubit>().updateAllUnitsValidated(allUnitsValidated);
                print("🔄 ScFormCubit updated: allUnitsValidated = $allUnitsValidated");
              }
            },
            // Child-nya adalah Listener untuk submit
            child: BlocListener<ServiceCallSubmittedBloc, ServiceCallSubmittedState>(
              listenWhen: (previous, current) {
                if (current is ValidationUploadPartial &&
                    previous is ValidationInitial) {
                  return false; // Jangan lakukan apa-apa
                }
                // Untuk semua kasus lain, jalankan listener seperti biasa.
                return true;
              },
              listener: (context, state) async {
                print("==============debug============");
                print(state);
                if (state is ValidationUploadInProgress) {
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
                } else if (state is ValidationSuccess) {
                  // Tugasnya hanya menutup dialog loading & menampilkan dialog sukses
                  if (context.mounted) {
                    Navigator.pop(context); // Tutup loading dialog
                  }
                  if (context.mounted) {
                    await showSuccessDialog(context, "Data berhasil dikirim.");
                  }
                  // Mungkin bisa ditambahkan pop halaman ini setelah sukses
                  // if (context.mounted) Navigator.of(context).pop();
                } else if (state is ValidationUploadPartial) {
                  // Tugasnya hanya menutup dialog loading & menampilkan dialog gagal sebagian
                  if (context.mounted) {
                    Navigator.pop(context); // Tutup loading dialog
                  }
                  if (context.mounted) {
                    await showPartialUploadDialog(
                      context,
                      state.successCount,
                      state.failureCount,
                      state.failedFiles,
                    );
                  }
                } else if (state is ValidationFailure) {
                  // if (context.mounted) {
                  //   Navigator.pop(context); // Tutup loading dialog
                  // }
                  if (context.mounted) {
                    await showFailureDialog(context,
                        "Gagal mengirimkan data, silahkan coba lagi nanti atau hubungi customer service.");
                  }
                }
              },
              // Child terakhir adalah UI Body
              child: SafeArea(
                child: ServiceCallDetailBodyMobile(
                  transNo: widget.transNo,
                  transactionInfoBox: _transactionInfoBox, // Box sudah dibuka di initState
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
