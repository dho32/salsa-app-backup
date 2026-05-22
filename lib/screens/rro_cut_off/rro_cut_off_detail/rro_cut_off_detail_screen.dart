import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/rro_cut_off/rro_cut_off_detail_bloc.dart';
import '../../../blocs/rro_cut_off/rro_cut_off_detail_event.dart';
import '../../../blocs/rro_cut_off/rro_cut_off_form/rro_form_cubit.dart';
import '../../../blocs/rro_cut_off/rro_cut_off_repository.dart';
import 'components/rro_cut_off_detail_body_mobile.dart';

class RROCutOffDetailScreen extends StatelessWidget {
  final String transNo;
  final String vendorId;

  const RROCutOffDetailScreen({
    super.key,
    required this.transNo,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 1. Suntik BLoC untuk narik data detail (dari API/Hive)
        BlocProvider<RROCutOffDetailBloc>(
          create: (context) => RROCutOffDetailBloc(RROCutOffDetailRepository())
            ..add(FetchRROCutOffDetail(transNo, vendorId)),
        ),
        // 2. Suntik Cubit untuk nampung inputan form PIC & Teknisi
        BlocProvider<RROFormCubit>(
          create: (context) => RROFormCubit(),
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
            title: const Text("Detail Cut Off"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(child: RROCutOffDetailBodyMobile(transNo: transNo)),
        ),
      ),
    );
  }
}