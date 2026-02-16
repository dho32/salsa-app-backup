import 'package:flutter/material.dart';
import 'package:salsa/models/installation/installation_detail_model.dart';
import 'package:salsa/models/installation/installation_model.dart';

// Import Body Mobile
import 'components/material_input_form_body_mobile.dart';

class MaterialInputFormScreen extends StatelessWidget {
  final InstallationTargetUnitModel target;
  final InstallationUnitModel existingData; // Data Outdoor Unit (Wajib ada krn sdh dilock di list)
  final String transNo;

  const MaterialInputFormScreen({
    super.key,
    required this.target,
    required this.existingData,
    required this.transNo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input Material Unit ${target.unitIndex}"),
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
      backgroundColor: Colors.grey[50],
      body: MaterialInputFormBodyMobile(
        target: target,
        existingData: existingData,
        transNo: transNo,
      ),
    );
  }
}