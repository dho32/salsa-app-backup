import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/auth/auth_storage.dart';
import 'package:salsa/blocs/proof_of_service/pos_form/pos_form_cubit.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import 'package:salsa/blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
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
import '../../common/services/confirmation_service.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Proof of Service"),
      ),
      // --- KOREKSI LOGIKA LOADING ---
      // Gunakan || (ATAU) bukan && (DAN)
      body: _transactionInfoBox == null || _technician1Name == null
          ? const Center(child: CircularProgressIndicator())
          : MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) =>
                      ProofOfServiceDetailBloc(ProofOfServiceDetailRepository())
                        ..add(FetchProofOfServiceDetail(widget.transNo)),
                ),
                // --- GABUNGKAN MENJADI SATU BLOCPROVIDER UNTUK PosSubmittedBloc ---
                BlocProvider(
                  create: (context) {
                    final bloc =
                        PosSubmittedBloc(repository: PosSubmittedRepository());
                    // Cek apakah ada data retry saat BLoC dibuat
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
                BlocProvider<PosFormCubit>(
                  create: (context) {
                    final detailState =
                        context.read<ProofOfServiceDetailBloc>().state;
                    bool initialAllUnitsValidated = false;
                    if (detailState is ProofOfServiceDetailLoaded) {
                      initialAllUnitsValidated =
                          detailState.data.detail.every((detail) {
                        final serialKey = detail.serialNo.trim().toUpperCase();
                        return detailState.validationStatuses[serialKey] ==
                            ValidationStatus.completed;
                      });
                    }
                    // --- UBAH NAMA PARAMETER SESUAI PERUBAHAN DI CUBIT ---
                    return PosFormCubit(
                      transNo: widget.transNo,
                      initialAllUnitsValidated: initialAllUnitsValidated,
                    );
                  },
                ),
              ],
              // *** BAGIAN TERPENTING: TAMBAHKAN BLOCLISTENER UNTUK SINKRONISASI ***
              child: BlocListener<ProofOfServiceDetailBloc,
                  ProofOfServiceDetailState>(
                listener: (context, detailState) {
                  if (detailState is ProofOfServiceDetailLoaded) {
                    // Setiap kali status unit berubah, hitung ulang status validasinya
                    final allUnitsValidated =
                        detailState.data.detail.every((detail) {
                      final serialKey = detail.serialNo.trim().toUpperCase();
                      return detailState.validationStatuses[serialKey] ==
                          ValidationStatus.completed;
                    });
                    // Kemudian, beri tahu PosFormCubit tentang status terbaru
                    context
                        .read<PosFormCubit>()
                        .updateAllUnitsValidated(allUnitsValidated);
                  }
                },
                child: BlocListener<PosSubmittedBloc, PosSubmittedState>(
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
                    } else if (state is PosValidationSuccess) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      ConfirmationService().processQueue();
                      showSuccessDialog(
                        context,
                        "Data berhasil dikirim.",
                        onOk: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      );
                    } else if (state is PosValidationFailure) {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      showFailureDialog(context, state.error);
                    }
                  },
                  child: ProofOfServiceDetailBodyMobile(
                    transNo: widget.transNo,
                    technician1Name: _technician1Name!,
                  ),
                ),
              ),
            ),
    );
  }
}
