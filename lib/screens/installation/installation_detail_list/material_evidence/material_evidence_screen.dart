import 'package:flutter/material.dart';

import 'components/material_evidence_body_mobile.dart';

class MaterialEvidenceScreen extends StatelessWidget {
  final String transNo;

  const MaterialEvidenceScreen({super.key, required this.transNo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Foto Merk Material"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: MaterialEvidenceBodyMobile(transNo: transNo),
    );
  }
}