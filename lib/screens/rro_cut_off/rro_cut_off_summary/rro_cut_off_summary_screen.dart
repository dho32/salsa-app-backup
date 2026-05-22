import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

// 🔥 SESUAIKAN IMPORT PATH INI
import '../../../../models/rro_cut_off/rro_cut_off_detail_model.dart';
import '../../../../blocs/upload_progress/upload_progress_cubit.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_submit/rro_cut_off_submit_bloc.dart';
import '../../../../blocs/rro_cut_off/rro_cut_off_submit/rro_cut_off_submit_repository.dart';
import '../../../../blocs/otp/otp_bloc.dart';
import '../../../../blocs/otp/otp_event.dart';
import '../../../../blocs/otp/otp_repository.dart';

// 🔥 TAMBAHAN UNTUK LOCATION
import '../../../../blocs/location_validation/location_validation_bloc.dart';
import '../../../../blocs/location_validation/location_validation_event.dart';
import '../../../../models/proof_of_service/pos_transaction_info_model.dart';
import '../../../../components/constants.dart';

import 'components/rro_cut_off_summary_body_mobile.dart';

class RROCutOffSummaryScreen extends StatefulWidget {
  final String transNo;
  final RROCutOffHeader header;

  const RROCutOffSummaryScreen({
    super.key,
    required this.transNo,
    required this.header,
  });

  @override
  State<RROCutOffSummaryScreen> createState() => _RROCutOffSummaryScreenState();
}

class _RROCutOffSummaryScreenState extends State<RROCutOffSummaryScreen> {
  Box<PosTransactionInfoModel>? _transactionInfoBox;

  @override
  void initState() {
    super.initState();
    _openHiveBox();
  }

  Future<void> _openHiveBox() async {
    final box = await Hive.openBox<PosTransactionInfoModel>(kPosTransactionInfoHiveBox);
    if (mounted) {
      setState(() {
        _transactionInfoBox = box;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_transactionInfoBox == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => UploadProgressCubit()),
        BlocProvider(create: (context) => RROCutOffSubmitBloc(repository: RROCutOffSubmitRepository())),
        BlocProvider(
          create: (context) => OtpBloc(repository: OtpRepository())
            ..add(CheckOtpStatus(widget.transNo)),
        ),

        BlocProvider(
          lazy: false,
          create: (context) {
            double lat = widget.header.latitude;
            double long = widget.header.longitude;

            return LocationValidationBloc(transactionBox: _transactionInfoBox!)
              ..add(LoadLocationPhoto(widget.transNo, lat, long));
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
            title: const Text("Summary Bongkar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.white),
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          body: SafeArea(
            child: RROCutOffSummaryBodyMobile(
              transNo: widget.transNo,
              header: widget.header,
            ),
          ),
        ),
      ),
    );
  }
}