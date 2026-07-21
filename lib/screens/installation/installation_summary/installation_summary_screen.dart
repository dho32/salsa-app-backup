import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart';
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/otp/otp_bloc.dart';
import 'package:salsa/blocs/otp/otp_event.dart';
import 'package:salsa/blocs/otp/otp_repository.dart';
import 'package:salsa/blocs/location_validation/location_validation_bloc.dart';
import 'package:salsa/blocs/location_validation/location_validation_event.dart';
import 'package:salsa/components/constants.dart';
import 'package:salsa/models/proof_of_service/pos_transaction_info_model.dart';
import 'package:salsa/screens/installation/installation_summary/components/installation_summary_body_mobile.dart';

class InstallationSummaryScreen extends StatefulWidget {
  final String transNo;

  const InstallationSummaryScreen({super.key, required this.transNo});

  @override
  State<InstallationSummaryScreen> createState() =>
      _InstallationSummaryScreenState();
}

class _InstallationSummaryScreenState extends State<InstallationSummaryScreen> {
  // Box ini dibutuhkan LocationValidationBloc (fallback validasi lokasi PIC).
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
      setState(() => _transactionInfoBox = box);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_transactionInfoBox == null) {
      return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()));
    }

    // InstallationBloc sudah di-provide via BlocProvider.value saat navigasi
    // dari halaman detail, jadi header (lat/long) bisa dibaca di sini.
    final header = context.read<InstallationBloc>().state.taskDetail?.header;
    final double lat = header?.latitude ?? 0.0;
    final double long = header?.longitude ?? 0.0;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => UploadProgressCubit()),
        BlocProvider(
          create: (context) => OtpBloc(repository: OtpRepository())
            ..add(CheckOtpStatus(widget.transNo)),
        ),
        BlocProvider(
          lazy: false,
          create: (context) =>
              LocationValidationBloc(transactionBox: _transactionInfoBox!)
                ..add(LoadLocationPhoto(widget.transNo, lat, long)),
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
            title: const Column(
              children: [
                Text("Verifikasi Akhir",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Review & Submit Data",
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            foregroundColor: const Color(0xFFFFFFFF),
            iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
          ),
          body: SafeArea(
              child: InstallationSummaryBodyMobile(transNo: widget.transNo)),
        ),
      ),
    );
  }
}
