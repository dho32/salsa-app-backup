// lib/screens/schedule_list/schedule_list_screen.dart

import 'package:flutter/material.dart';
import 'components/schedule_list_body_mobile.dart';

class ScheduleListScreen extends StatelessWidget {
  final String initialStatus;
  final String maintenanceBy;

  const ScheduleListScreen(
      {super.key, required this.initialStatus, required this.maintenanceBy});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List Pekerjaan"),
        elevation: 0,
      ),
      body: ScheduleListBodyMobile(
        initialStatus: initialStatus,
        maintenanceBy: maintenanceBy,
      ),
    );
  }
}
