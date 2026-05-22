import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'components/indoor_input_form_body_mobile.dart';

class IndoorInputFormScreen extends StatelessWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel? existingData;
  final String transNo; // 1. Tambah variabel ini

  const IndoorInputFormScreen({
    super.key,
    required this.transNo, // 2. Wajib diisi via Constructor
    required this.target,
    this.existingData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. BACKGROUND IMAGE (Sama dengan Halaman Detail)
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_app.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan agar background terlihat
        extendBodyBehindAppBar: true,      // Body naik ke belakang AppBar

        appBar: AppBar(
          // Judul Putih & Bold
          title: Text(
              target.description,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white
              )
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          // Icon Back Putih
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        // 2. BODY DIBUNGKUS SAFE AREA
        body: SafeArea(
          child: IndoorInputFormBodyMobile(
            transNo: transNo, // 3. Kirim transNo ke Body
            target: target,
            existingData: existingData,
          ),
        ),
      ),
    );
  }
}