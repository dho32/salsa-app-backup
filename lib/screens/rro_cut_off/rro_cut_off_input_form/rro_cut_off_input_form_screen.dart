import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/rro_cut_off/rro_cut_off_detail_model.dart';
import 'components/rro_cut_off_input_form_body_mobile.dart';

class RROCutOffInputFormScreen extends StatelessWidget {
  final String transNo;
  final RROCutOffDetailItem unitData;
  final List<RROCutOffSerialNumber> availableSerialNumbers;

  const RROCutOffInputFormScreen({
    super.key,
    required this.transNo,
    required this.unitData,
    required this.availableSerialNumbers,
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
          title: Text(
            "Input Unit ${unitData.unitType}DOOR: ${unitData.unitIndex}",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: RROCutOffInputFormBodyMobile(
            transNo: transNo,
            unitData: unitData,
            availableSerialNumbers: availableSerialNumbers,
          ),
        ),
      ),
    );
  }
}