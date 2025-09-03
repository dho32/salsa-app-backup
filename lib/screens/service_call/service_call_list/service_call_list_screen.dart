import 'package:flutter/material.dart';
import 'package:salsa/screens/service_call/service_call_list/components/service_call_list_body_mobile.dart';

class ServiceCallListScreen extends StatelessWidget {
  final String initialStatus;
  final String maintenanceBy;

  const ServiceCallListScreen(
      {super.key,
        required this.initialStatus, required this.maintenanceBy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Call')),
      body: SafeArea(
        child: Center(
          child: SizedBox(
              child: ServiceCallListBodyMobile(
            initialStatus: initialStatus,
                maintenanceBy: maintenanceBy,
          )),
        ),
      ),
    );
  }
}
