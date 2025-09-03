import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salsa/screens/dashboard/components/widget/dashboard_body_mobile_loading.dart';
import 'package:salsa/screens/dashboard/components/widget/dashboard_widgets.dart';
import '../../../blocs/auth/auth_storage.dart';
import '../../../blocs/dashboard/dashboard_bloc.dart';
import '../../../blocs/dashboard/dashboard_state.dart';
import '../../../components/shared_widgets.dart';
import '../../../models/dashboard/dashboard_data_model.dart';

class DashboardBodyMobile extends StatefulWidget {
  const DashboardBodyMobile({super.key});

  @override
  State<DashboardBodyMobile> createState() => _DashboardBodyMobileState();
}

class _DashboardBodyMobileState extends State<DashboardBodyMobile> {
  String userName = "";
  String maintenanceByName = "";


  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthStorage.getUser();
    setState(() {
      userName = user['name'] ?? '';
      maintenanceByName = user['maintenance_by_name'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const DashboardBodyMobileLoading();
        }
        if (state is DashboardError) {
          return Center(child: Text("Error: ${state.message}"));
        }
        if (state is DashboardLoaded) {
          return _buildContent(state.data);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(DashboardDataModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSection(
            child: buildHeader(
                title: "Welcome to SALSA",
                user: userName,
                company: maintenanceByName,),
          ),
          const SizedBox(height: 24),
          FadeInSection(
            child: buildSection(
              title: 'Informasi',
              child: Row(
                children: [
                  buildInfoCard(
                    context: context,
                    title: 'Service Call Aktif',
                    value: data.information.serviceCall.toString(),
                    icon: FontAwesomeIcons.screwdriverWrench,
                    color: Colors.red,
                    onTap: () => Navigator.pushNamed(context, '/service-call'),
                  ),
                  const SizedBox(width: 12),
                  buildInfoCard(
                    context: context,
                    title: 'Jadwal Hari Ini',
                    value: data.information.amSchedule.toString(),
                    icon: FontAwesomeIcons.calendarDays,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(context, '/proof-of-service'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInSection(
            child: buildSection(
              title: 'Service Call 3 Bulan Terakhir',
              child: buildPieChart(
                  data.lastServiceCall
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInSection(
            child: buildSection(
              title: 'Jadwal Service Bulan Ini',
              child: Column(
                children: [
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      buildGridCard(
                          title: 'Sudah',
                          value: data.amScheduleMonthly.done.toString(),
                          icon: FontAwesomeIcons.checkDouble,
                          color: Colors.green),
                      buildGridCard(
                          title: 'Belum',
                          value: data.amScheduleMonthly.notDone.toString(),
                          icon: Icons.pending_actions,
                          color: Colors.red),
                      buildGridCard(
                          title: 'Total',
                          value: data.amScheduleMonthly.total.toString(),
                          icon: Icons.event,
                          color: Colors.blue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildWeeklyBarChart(data.posWeekly),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

