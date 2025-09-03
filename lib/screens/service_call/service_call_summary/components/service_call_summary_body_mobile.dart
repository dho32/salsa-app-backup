import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../blocs/service_call/service_call_summary/service_call_summary_bloc.dart';
import '../../../../blocs/service_call/service_call_summary/service_call_summary_state.dart';
import '../../../../components/shared_widgets.dart';
import '../../components/widgets/service_call_widgets.dart';
import '../../service_call_list/service_call_list_screen.dart';

class ServiceCallSummaryBodyMobile extends StatefulWidget {
  final String maintenanceBy;
  const ServiceCallSummaryBodyMobile({
    super.key, required this.maintenanceBy,});

  @override
  State<ServiceCallSummaryBodyMobile> createState() =>
      _ServiceCallSummaryBodyMobileState();
}

class _ServiceCallSummaryBodyMobileState
    extends State<ServiceCallSummaryBodyMobile> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCallSummaryBloc, ServiceCallSummaryState>(
      builder: (context, state) {
        if (state is SummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is SummaryError) {
          return Center(child: Text("Error: ${state.message}"));
        } else if (state is SummaryLoaded) {
          final data = state.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeaderMain(
                    title: 'service call', period: data.period.toString()),
                const SizedBox(height: 12),
                FadeInSection(
                  child: buildSection(
                    title: 'Informasi',
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          buildInfoCard(
                            context: context,
                            title: 'Prioritas',
                            value: data.notDonePriority.toString(),
                            icon: FontAwesomeIcons.screwdriverWrench,
                            color: Colors.red,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceCallListScreen(
                                    initialStatus: 'not_done_priority',
                                    maintenanceBy: widget.maintenanceBy,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          buildInfoCard(
                            context: context,
                            title: 'Belum Selesai',
                            value: data.notDone.toString(),
                            icon: FontAwesomeIcons.screwdriverWrench,
                            color: Colors.orange,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceCallListScreen(
                                    initialStatus: 'not_done',
                                    maintenanceBy: widget.maintenanceBy,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          buildInfoCard(
                            context: context,
                            title: 'Selesai',
                            value: data.done.toString(),
                            icon: FontAwesomeIcons.screwdriverWrench,
                            color: Colors.green,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceCallListScreen(
                                    initialStatus: 'done',
                                    maintenanceBy: widget.maintenanceBy,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          buildInfoCard(
                            context: context,
                            title: 'Total',
                            value: data.total.toString(),
                            icon: FontAwesomeIcons.screwdriverWrench,
                            color: Colors.blue,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ServiceCallListScreen(
                                    initialStatus: '',
                                    maintenanceBy: widget.maintenanceBy,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInSection(
                  child: buildSection(
                    title: 'Service Call 30 Hari Terakhir',
                    child: buildPieChart(
                        data.done.toDouble(),
                        data.notDone.toDouble(),
                        data.notDonePriority.toDouble(),
                        data.total.toDouble()),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInSection(
                    child: buildSection(
                        child: TopIssueList(issues: data.topIssues),
                        title: 'Top 3 Issue')),
                const SizedBox(height: 24),
                FadeInSection(
                    child: buildSection(
                        child: WeeklyPerformanceChart(
                            data: data.weeklyPerformance),
                        title: 'Weekly Performance')),
              ],
            ),
          );
        }
        return const SizedBox.shrink(); // Initial state
      },
    );
  }
}
