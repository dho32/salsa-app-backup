import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_bloc.dart';
import '../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_repository.dart';
import '../../../blocs/proof_of_service/proof_of_service_detail/proof_of_service_detail_event.dart';
import '../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_bloc.dart';
import '../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_event.dart';
import '../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_repository.dart';
import '../../../blocs/proof_of_service/proof_of_service_submitted/pos_submitted_state.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/constants.dart';
import '../../../components/shared_widgets.dart';
import '../../../models/proof_of_service/pos_transaction_info_model.dart';
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

  @override
  void initState() {
    super.initState();
    _openHiveBox();
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
      body: _transactionInfoBox == null
          ? const Center(child: CircularProgressIndicator())
          : MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ProofOfServiceDetailBloc(ProofOfServiceDetailRepository())
              ..add(FetchProofOfServiceDetail(widget.transNo)),
          ),
          BlocProvider(
            create: (context) => PosSubmittedBloc(repository: PosSubmittedRepository()),
          ),
          BlocProvider(
            create: (context) => UploadProgressCubit(),
          ),
          BlocProvider(
            create: (context) {
              final bloc = PosSubmittedBloc(repository: PosSubmittedRepository());
              // --- TAMBAHKAN LOGIKA INI ---
              // Cek apakah ada data retry saat BLoC dibuat
              Hive.openBox(kPosValidationPartialHiveBox).then((box) {
                if (box.containsKey(widget.transNo)) {
                  bloc.add(LoadPosValidationPartial(widget.transNo));
                }
              });
              return bloc;
            },
          ),
        ],
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
                Navigator.pop(context); // Tutup loading dialog
              }
              showSuccessDialog(context, "Data berhasil dikirim.");
            } else if (state is PosValidationFailure) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Tutup loading dialog
              }
              showFailureDialog(context, state.error);
            }
          },
          child: ProofOfServiceDetailBodyMobile(
            transNo: widget.transNo,
            transactionInfoBox: _transactionInfoBox!,
          ),
        ),
      ),
    );
  }
}
