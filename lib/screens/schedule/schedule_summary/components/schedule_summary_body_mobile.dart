// lib/screens/schedule_summary/components/schedule_summary_body_mobile.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../blocs/schedule/schedule_summary/schedule_summary_bloc.dart';
import '../../../../components/shared_widgets.dart';
import '../../../../components/widgets/default_card_list.dart';
import '../../proof_of_service/proof_of_service_screen.dart';
import '../../schedule_list/schedule_list_screen.dart';

class ScheduleSummaryBodyMobile extends StatelessWidget {
  final String maintenanceBy;
  const ScheduleSummaryBodyMobile({super.key, required this.maintenanceBy,});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleSummaryBloc, ScheduleSummaryState>(
      builder: (context, state) {
        if (state is ScheduleSummaryError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        if (state is ScheduleSummaryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ScheduleSummaryLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeaderMain(
                    title: 'Jadwal Pekerjaan',
                    period:
                        '${state.monthlyChartData.first.periode} - ${state.monthlyChartData.last.periode}'), // Contoh
                const SizedBox(height: 12),
                buildSection(
                    title: 'Informasi Umum',
                    child: _buildStatsSection(context, state)),
                const SizedBox(height: 24),
                buildSection(
                    title: 'Pekerjaan Prioritas',
                    child: _buildPriorityJobsSection(context, state)),
                const SizedBox(height: 24),
                buildSection(
                    title: 'Beban Kerja Bulanan',
                    child: _buildMonthlyChartSection(context, state)),
              ],
            ),
          );
        }

        return const SizedBox.shrink(); // Untuk Initial state
      },
    );
  }

  Widget _buildStatsSection(BuildContext context, ScheduleSummaryLoaded state) {
    // GridView untuk membuat layout 2x2 secara otomatis
    return GridView.count(
      crossAxisCount: 2,
      // 2 kartu per baris
      shrinkWrap: true,
      // Penting agar GridView tidak mengambil ruang tak terbatas
      physics: const NeverScrollableScrollPhysics(),
      // Nonaktifkan scroll internal GridView
      mainAxisSpacing: 12,
      // Jarak vertikal antar kartu
      crossAxisSpacing: 12,
      // Jarak horizontal antar kartu
      childAspectRatio: 2,
      // Rasio lebar-tinggi kartu, sesuaikan jika perlu
      children: [
        _buildStatCard(
          context: context,
          title: 'Selesai',
          value: state.jobsDoneCount,
          icon: FontAwesomeIcons.check,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleListScreen(
                  initialStatus: 'done',
                  maintenanceBy: maintenanceBy,
                ),
              ),
            );
          },
        ),
        _buildStatCard(
          context: context,
          title: 'Terjadwal',
          value: state.jobsScheduledCount,
          icon: FontAwesomeIcons.solidCalendarDays,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleListScreen(
                  initialStatus: 'scheduled',
                  maintenanceBy: maintenanceBy,
                ),
              ),
            );
          },
        ),
        _buildStatCard(
          context: context,
          title: 'Terlambat',
          value: state.jobsOverdueCount,
          icon: FontAwesomeIcons.triangleExclamation,
          color: Colors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleListScreen(
                  initialStatus: 'overdue',
                  maintenanceBy: maintenanceBy,
                ),
              ),
            );
          },
        ),
        _buildStatCard(
          context: context,
          title: 'Hari Ini',
          value: state.jobsTodayCount,
          icon: FontAwesomeIcons.star,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScheduleListScreen(
                  initialStatus: 'today',
                  maintenanceBy: maintenanceBy,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: FaIcon(icon, color: color, size: 18),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityJobsSection(
      BuildContext context, ScheduleSummaryLoaded state) {
    // Ambil maksimal 3 item pertama untuk ditampilkan
    final itemsToShow = state.priorityJobs.take(3).toList();
    // Cek apakah ada lebih dari 3 item untuk menampilkan tombol "Lihat Semua"
    final hasMoreItems = state.priorityJobs.length > 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tampilkan pesan jika tidak ada pekerjaan sama sekali
        if (itemsToShow.isEmpty)
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Tidak ada pekerjaan prioritas.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        // Tampilkan daftar pekerjaan jika ada
        else
          Column(
            // Gunakan Column biasa karena jumlah item terbatas, tidak perlu ListView.builder
            children: itemsToShow
                .map((job) => _buildPriorityJobCard(context, job))
                .toList(),
          ),

        // Tampilkan tombol "Lihat Semua" jika ada item lebih dari 3
        if (hasMoreItems)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleListScreen(
                      initialStatus: 'priority',
                      maintenanceBy: maintenanceBy,
                    ),
                  ),
                );
              },
              child: const Text('Lihat Semua >>'),
            ),
          ),
      ],
    );
  }

  Widget _buildPriorityJobCard(BuildContext context, PriorityJob job) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isOverdue = job.scheduleDate.isBefore(today);

    final Color statusColor = isOverdue ? Colors.red : Colors.orange;
    final IconData statusIcon = isOverdue
        ? FontAwesomeIcons.triangleExclamation
        : FontAwesomeIcons.clock;

    Widget child = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                FaIcon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.transNo,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      // Format tanggal agar mudah dibaca
                      DateFormat('d MMM yyyy').format(job.scheduleDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              job.type,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          job.customerName,
          style: const TextStyle(fontSize: 16),
          softWrap: true,
        ),
      ],
    );
    return cardList(
        statusColor: statusColor,
        child: child,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProofOfServiceScreen(
                transNo: job.transNo, // Gunakan transNo dari objek job
              ),
            ),
          );
        });
  }

  Widget _buildMonthlyChartSection(
      BuildContext context, ScheduleSummaryLoaded state) {
    final double maxY = (state.monthlyChartData
                .map((d) => d.posJobCount)
                .reduce((a, b) => a > b ? a : b) *
            1.2)
        .toDouble();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false, // Sembunyikan garis vertikal
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Colors.black12, // Warna garis sangat samar
                    strokeWidth: 1,
                    dashArray: [8, 4], // Buat garis menjadi putus-putus
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.grey,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month =
                        state.monthlyChartData[group.x.toInt()].monthName;
                    return BarTooltipItem(
                      '$month\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: "${rod.toY.round()} PO",
                          style: TextStyle(
                            color: Colors.cyan[100],
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value == 0 || value == meta.max) {
                        return const Text('');
                      }
                      return Text(value.toInt().toString(),
                          style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        _getMonthlyTitles(value, meta, state),
                    reservedSize: 24,
                  ),
                ),
              ),
              // Ambil data dari state BLoC
              barGroups:
                  _generateMonthlyBarGroups(context, state.monthlyChartData),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateMonthlyBarGroups(
      BuildContext context, List<MonthlyJobChartData> data) {
    return List.generate(data.length, (index) {
      final chartItem = data[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: chartItem.posJobCount.toDouble(),
            color: Theme.of(context).primaryColor,
            width: 45,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ],
      );
    });
  }

  Widget _getMonthlyTitles(
      double value, TitleMeta meta, ScheduleSummaryLoaded state) {
    const style = TextStyle(
      color: Colors.grey,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    // Ambil nama bulan dari data state berdasarkan index
    if (state.monthlyChartData.asMap().containsKey(value.toInt())) {
      text = state.monthlyChartData[value.toInt()].monthName;
    } else {
      text = '';
    }

    return SideTitleWidget(
      space: 8,
      meta: meta, // <-- TAMBAHKAN BARIS INI
      child: Text(text, style: style),
    );
  }
}
