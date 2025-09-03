import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/screens/service_call/service_call_summary/components/service_call_summary_body_mobile.dart';

import '../../../blocs/auth/auth_storage.dart';
import '../../../blocs/service_call/service_call_summary/service_call_summary_bloc.dart';
import '../../../blocs/service_call/service_call_summary/service_call_summary_event.dart';
import '../../../blocs/service_call/service_call_summary/service_call_summary_repository.dart';
import '../../../components/salsa_scaffold.dart';

class ServiceCallSummaryScreen extends StatefulWidget {
  const ServiceCallSummaryScreen({super.key});

  @override
  State<ServiceCallSummaryScreen> createState() =>
      _ServiceCallSummaryScreenState();
}

class _ServiceCallSummaryScreenState extends State<ServiceCallSummaryScreen> {
  String? _maintenanceBy;

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
    if (_maintenanceBy == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return BlocProvider(
      create: (_) => ServiceCallSummaryBloc(
        repository: ServiceCallSummaryRepository(),
        maintenanceBy: _maintenanceBy!,
      )..add(FetchServiceCallSummary()),
      child: SalsaScaffold(
        child: ServiceCallSummaryBodyMobile(maintenanceBy: _maintenanceBy!,),
      ),
    );
  }
}
