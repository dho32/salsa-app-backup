import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/dashboard/dashboard_event.dart';
import '../../blocs/dashboard/dashboard_repository.dart';
import '../../components/salsa_scaffold.dart';
import 'components/dashboard_body_mobile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          DashboardBloc(DashboardRepository(authBloc: context.read<AuthBloc>())
          )..add(FetchDashboardData()),
      child: SalsaScaffold(
        child: const DashboardBodyMobile(),
      ),
    );
  }
}
