import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_bloc.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_event.dart';
import 'package:salsa/blocs/service_call/service_call_detail/service_call_detail_repository.dart';

import '../../../blocs/otp/otp_bloc.dart';
import '../../../blocs/otp/otp_repository.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_bloc.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_event.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_repository.dart';
import '../../../blocs/service_call/service_call_submitted/service_call_submitted_state.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/constants.dart';
import '../../../components/shared_widgets.dart';
import '../../../models/service_call/transaction_info_model.dart';
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

  // Fungsi untuk membuka box
  Future<void> _openHiveBox() async {
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Detail Service Call")),
      body: !_isBoxReady
          ? const Center(child: CircularProgressIndicator())
          : MultiBlocProvider(
              providers: [
                BlocProvider(
                    create: (_) => OtpBloc(repository: OtpRepository())),
                BlocProvider(
                  create: (_) =>
                      ServiceCallDetailBloc(ServiceCallDetailRepository())
                        ..add(FetchServiceCallDetail(
                            widget.transNo, widget.maintenanceBy)),
                ),
                BlocProvider(
                  create: (_) {
                    final bloc = ServiceCallSubmittedBloc(
                      repository: ServiceCallSubmittedRepository(),
                    );

                    Hive.openBox(kServiceCallValidationPartialHiveBox)
                        .then((box) {
                      final data = box.get(widget.transNo);
                      if (data != null) {
                        bloc.add(LoadValidationPartial(widget.transNo));
                      }
                    });

                    return bloc;
                  },
                ),
                BlocProvider(create: (_) => UploadProgressCubit()),
              ],
              child: BlocListener<ServiceCallSubmittedBloc,
                  ServiceCallSubmittedState>(
                listenWhen: (previous, current) {
                  if (current is ValidationUploadPartial &&
                      previous is ValidationInitial) {
                    return false; // Jangan lakukan apa-apa
                  }
                  // Untuk semua kasus lain, jalankan listener seperti biasa.
                  return true;
                },
                listener: (context, state) async {
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
                      await showSuccessDialog(
                          context, "Data berhasil dikirim.");
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
                child: ServiceCallDetailBodyMobile(
                  transNo: widget.transNo,
                  transactionInfoBox: _transactionInfoBox,
                ),
              ),
            ),
    );
  }
}
