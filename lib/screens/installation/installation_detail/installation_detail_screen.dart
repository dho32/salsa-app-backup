import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/blocs/installation/installation_bloc.dart';
import 'package:salsa/blocs/installation/installation_event.dart';
import 'package:salsa/blocs/installation/installation_repository.dart';
import 'components/installation_detail_body_mobile.dart';

class InstallationDetailScreen extends StatelessWidget {
  final String transNo;
  final String vendorId;

  const InstallationDetailScreen({
    super.key,
    required this.transNo,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => InstallationBloc(
        repository: InstallationRepository(),
      )..add(LoadInstallationData(transNo)),

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
            title: const Text("Detail Instalasi"),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // BODY CONTENT
          body: const SafeArea(
            child: InstallationDetailBodyMobile(),
          ),
        ),
      ),
    );
  }
}