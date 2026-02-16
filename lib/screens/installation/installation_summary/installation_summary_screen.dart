import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // [WAJIB IMPORT]
import 'package:salsa/blocs/upload_progress/upload_progress_cubit.dart'; // [WAJIB IMPORT]
import 'package:salsa/screens/installation/installation_summary/components/installation_summary_body_mobile.dart';

class InstallationSummaryScreen extends StatelessWidget {
  final String transNo;

  const InstallationSummaryScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    // [FIX] Bungkus dengan BlocProvider agar child (body) bisa akses Cubit ini
    return BlocProvider(
      create: (context) => UploadProgressCubit(),
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
                Text("Verifikasi Akhir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Review & Submit Data", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            foregroundColor: const Color(0xFFFFFFFF),
            iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
          ),
          body: SafeArea(
              child: InstallationSummaryBodyMobile(transNo: transNo)
          ),
        ),
      ),
    );
  }
}