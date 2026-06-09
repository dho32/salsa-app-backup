import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../blocs/proof_of_service_freezer/posf_form/posf_form_cubit.dart';
import '../../../blocs/proof_of_service_freezer/posf_submitted/posf_submitted_bloc.dart';
import '../../../blocs/proof_of_service_freezer/posf_submitted/posf_submitted_repository.dart';
import '../../../blocs/proof_of_service_freezer/proof_of_service_freezer_detail/proof_of_service_freezer_detail_bloc.dart';
import '../../../blocs/proof_of_service_freezer/proof_of_service_freezer_detail/proof_of_service_freezer_detail_repository.dart';
import '../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../blocs/location_validation/location_validation_event.dart';
import '../../../blocs/location_validation/location_validation_state.dart';
import '../../../blocs/otp/otp_bloc.dart';
import '../../../blocs/otp/otp_event.dart';
import '../../../blocs/otp/otp_repository.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/constants.dart';
import '../../../components/shared_widgets.dart';
import '../../../models/proof_of_service_freezer/proof_of_service_freezer_info_model.dart';
import 'components/proof_of_service_freezer_detail_body_mobile.dart';

class ProofOfServiceFreezerDetailScreen extends StatelessWidget {
  final String transNo;

  const ProofOfServiceFreezerDetailScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              ProofOfServiceFreezerDetailBloc(repository: ProofOfServiceFreezerDetailRepository())
                ..add(FetchProofOfServiceFreezerDetail(transNo)),
        ),
        BlocProvider(create: (_) => PosfFormCubit(transNo: transNo)),
        BlocProvider(create: (_) => UploadProgressCubit()),
        BlocProvider(
            create: (_) => PosfSubmittedBloc(repository: PosfSubmittedRepository())),
        BlocProvider(
          create: (_) =>
              OtpBloc(repository: OtpRepository())..add(CheckOtpStatus(transNo)),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => LocationValidationBloc(
            transactionBox:
                Hive.box<ProofOfServiceFreezerInfoModel>(kProofOfServiceFreezerInfoBox),
          )..add(LoadLocationPhoto(transNo, 0, 0)),
        ),
      ],
      child: _ProofOfServiceFreezerDetailView(transNo: transNo),
    );
  }
}

class _ProofOfServiceFreezerDetailView extends StatelessWidget {
  final String transNo;

  const _ProofOfServiceFreezerDetailView({required this.transNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg_app.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text('Cuci Freezer'),
        ),
        body: MultiBlocListener(
          listeners: [
            // Status semua freezer tervalidasi -> aktif/nonaktifkan tombol Selesai.
            BlocListener<ProofOfServiceFreezerDetailBloc, ProofOfServiceFreezerDetailState>(
              listenWhen: (p, c) => c is ProofOfServiceFreezerDetailLoaded,
              listener: (context, state) {
                if (state is ProofOfServiceFreezerDetailLoaded) {
                  context
                      .read<PosfFormCubit>()
                      .updateAllUnitsValidated(state.allUnitsValidated);
                }
              },
            ),
            // Foto lokasi (diambil saat OTP) -> sync ke form sebagai foto PIC.
            BlocListener<LocationValidationBloc, LocationValidationState>(
              listener: (context, state) {
                if (state is LocationPhotoLoaded && state.photo != null) {
                  context.read<PosfFormCubit>().picImageChanged(state.photo!);
                }
              },
            ),
            // Hasil submit + upload.
            BlocListener<PosfSubmittedBloc, PosfSubmittedState>(
              listener: _onSubmittedStateChanged,
            ),
          ],
          child: ProofOfServiceFreezerDetailBodyMobile(transNo: transNo),
        ),
      ),
    );
  }

  void _onSubmittedStateChanged(BuildContext context, PosfSubmittedState state) {
    if (state is PosfUploadInProgress) {
      final uploadCubit = context.read<UploadProgressCubit>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => BlocProvider.value(
          value: uploadCubit,
          child: const UploadProgressDialog(),
        ),
      );
    } else if (state is PosfUploadPartial) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showPartialUploadDialog(
          context, state.successCount, state.failureCount, state.failedFiles);
    } else if (state is PosfSubmitSuccess) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showSuccessDialog(context, 'Data Cuci Freezer berhasil dikirim.',
          onOk: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } else if (state is PosfSubmitFailure) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      showFailureDialog(context, state.error);
    }
  }
}
