import 'package:flutter/material.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';
import 'components/outdoor_input_form_body_mobile.dart';

class OutdoorInputFormScreen extends StatelessWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel? existingData;
  final String transNo;

  const OutdoorInputFormScreen({
    super.key,
    required this.target,
    this.existingData,
    required this.transNo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existingData == null ? "Input Outdoor Baru" : "Edit Outdoor"),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold
        ),
      ),
      backgroundColor: Colors.grey[50], // Background agak abu biar kontras
      body: OutdoorInputFormBodyMobile(
        target: target,
        existingData: existingData,
        transNo: transNo,
      ),
    );
  }
}