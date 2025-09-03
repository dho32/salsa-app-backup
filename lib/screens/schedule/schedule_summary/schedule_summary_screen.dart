// lib/screens/schedule_summary/schedule_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/components/salsa_scaffold.dart';

import '../../../blocs/auth/auth_storage.dart';
import '../../../blocs/schedule/schedule_summary/schedule_summary_bloc.dart';
import '../../../blocs/schedule/schedule_summary/schedule_summary_repository.dart';
import 'components/schedule_summary_body_mobile.dart';

class ScheduleSummaryScreen extends StatefulWidget {
  const ScheduleSummaryScreen({super.key});

  @override
  State<ScheduleSummaryScreen> createState() => _ScheduleSummaryScreenState();
}

class _ScheduleSummaryScreenState extends State<ScheduleSummaryScreen> {
  String _maintenanceBy = '';

  @override
  void initState() {
    super.initState();
    _loadMaintenanceBy();
  }

  Future<void> _loadMaintenanceBy() async {
    final user = await AuthStorage.getUser();
    setState(() {
      _maintenanceBy = user['maintenance_by'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_maintenanceBy.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create: (context) => ScheduleSummaryBloc(
        repository: ScheduleSummaryRepository(),
        maintenanceBy: _maintenanceBy,
      )..add(FetchScheduleSummaryData()),
      child: SalsaScaffold(
        // Asumsi SalsaScaffold sudah punya AppBar
        child: ScheduleSummaryBodyMobile(maintenanceBy: _maintenanceBy,),
      ),
    );
  }
}
