import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import Body (Nanti kita buat di bawah)
import 'components/material_list_body_mobile.dart';

class MaterialListScreen extends StatelessWidget {
  final String transNo;

  const MaterialListScreen({
    super.key,
    required this.transNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Background Image (Konsisten)
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
            "Penggunaan Material",
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

        // Body Safe Area
        body: SafeArea(
          child: MaterialListBodyMobile(transNo: transNo),
        ),
      ),
    );
  }
}