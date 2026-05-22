import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salsa/screens/installation/installation_detail_list/indoor_list/components/indoor_list_body_mobile.dart';

class IndoorListScreen extends StatelessWidget {
  final String transNo; // 1. Tambah variabel ini

  const IndoorListScreen({
    super.key,
    required this.transNo, // 2. Wajib diisi saat dipanggil
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          title: const Text(
            "Daftar Unit Indoor",
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

        body: SafeArea(
          // 3. Kirim transNo ke Body
          // (Pasti error merah disini karena Body-nya belum kita update,
          // abaikan dulu, nanti kita fix di file Body)
          child: IndoorListBodyMobile(transNo: transNo),
        ),
      ),
    );
  }
}