import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Body Mobile Outdoor (Nanti kita buat/sesuaikan di bawah)
import 'components/outdoor_list_body_mobile.dart';

class OutdoorListScreen extends StatelessWidget {
  final String transNo; // Kita butuh transNo untuk dilempar ke Body -> Form

  const OutdoorListScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return Container(
      // 1. BACKGROUND IMAGE (Samakan dengan Indoor)
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_app.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Transparan
        extendBodyBehindAppBar: true, // Body naik ke belakang AppBar

        appBar: AppBar(
          title: const Text(
            "Daftar Unit Outdoor", // Judul disesuaikan
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),

        // 2. BODY SAFE AREA
        body: SafeArea(
          // Panggil Body Outdoor (Passing transNo)
          child: OutdoorListBodyMobile(
            transNo: transNo,
          ),
        ),
      ),
    );
  }
}
