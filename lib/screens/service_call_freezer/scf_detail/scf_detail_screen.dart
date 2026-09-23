import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../blocs/location_validation/location_validation_event.dart';
import '../../../blocs/location_validation/location_validation_state.dart';
import '../../../blocs/otp/otp_bloc.dart';
import '../../../blocs/otp/otp_event.dart';
import '../../../blocs/otp/otp_repository.dart';
import '../../../blocs/service_call_freezer/scf_detail/scf_detail_bloc.dart';
import '../../../blocs/service_call_freezer/scf_detail/scf_detail_repository.dart';
import '../../../blocs/service_call_freezer/scf_form/scf_form_cubit.dart';
import '../../../blocs/service_call_freezer/scf_submitted/scf_submitted_bloc.dart';
import '../../../blocs/service_call_freezer/scf_submitted/scf_submitted_repository.dart';
import '../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../components/constants.dart';
import '../../../models/service_call_freezer/scf_info_model.dart';
import 'components/scf_detail_body_mobile.dart';

/// Layar detail tugas **Service Call Freezer**: daftar freezer + form PIC/teknisi
/// + peluncuran wizard validasi (scan/tap). Submit lewat gate AHO→OTP + geofence
/// foto PIC (LocationValidationBloc atas [ScfInfoModel]).
class ScfDetailScreen extends StatelessWidget {
  final String transNo;

  /// Vendor teknisi (`userData['maintenance_by']`), diteruskan ke query detail
  /// sebagai `vendor_id` — pola sama dengan ServiceCallDetailScreen.
  final String vendorId;

  const ScfDetailScreen({
    super.key,
    required this.transNo,
    this.vendorId = '',
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ScfDetailBloc(
            repository: ScfDetailRepository(),
            vendorId: vendorId,
          )..add(FetchScfDetail(transNo)),
        ),
        BlocProvider(create: (_) => ScfFormCubit(transNo: transNo)),
        BlocProvider(create: (_) => UploadProgressCubit()),
        BlocProvider(
            create: (_) =>
                ScfSubmittedBloc(repository: ScfSubmittedRepository())),
        BlocProvider(
          create: (_) =>
              OtpBloc(repository: OtpRepository())..add(CheckOtpStatus(transNo)),
        ),
        BlocProvider(
          lazy: false,
          create: (_) => LocationValidationBloc(
            transactionBox:
                Hive.box<ScfInfoModel>(kServiceCallFreezerInfoBox),
          )..add(LoadLocationPhoto(transNo, 0, 0)),
        ),
      ],
      child: _ScfDetailView(transNo: transNo),
    );
  }
}

class _ScfDetailView extends StatelessWidget {
  final String transNo;

  const _ScfDetailView({required this.transNo});

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
          title: const Text('Service Call Freezer'),
        ),
        body: MultiBlocListener(
          listeners: [
            // Status semua freezer tervalidasi -> aktif/nonaktifkan tombol Selesai.
            BlocListener<ScfDetailBloc, ScfDetailState>(
              listenWhen: (p, c) => c is ScfDetailLoaded,
              listener: (context, state) {
                if (state is ScfDetailLoaded) {
                  context
                      .read<ScfFormCubit>()
                      .updateAllUnitsValidated(state.allUnitsValidated);
                }
              },
            ),
            // Foto lokasi (diambil saat OTP) -> sync ke form sebagai foto PIC.
            BlocListener<LocationValidationBloc, LocationValidationState>(
              listener: (context, state) {
                if (state is LocationPhotoLoaded && state.photo != null) {
                  context.read<ScfFormCubit>().picImageChanged(state.photo!);
                }
              },
            ),
          ],
          child: ScfDetailBodyMobile(transNo: transNo),
        ),
      ),
    );
  }
}
