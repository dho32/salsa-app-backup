import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../models/service_call/service_call_summary_model.dart';

class PieChartSummary extends StatelessWidget {
  final int done;
  final int notDone;

  const PieChartSummary({
    super.key,
    required this.done,
    required this.notDone,
  });

  @override
  Widget build(BuildContext context) {
    final total = done + notDone;
    final donePercent = total > 0 ? (done / total) * 100 : 0;
    final notDonePercent = total > 0 ? (notDone / total) * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Completion",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: done.toDouble(),
                  color: Colors.green,
                  title: "${donePercent.toStringAsFixed(1)}%",
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  radius: 60,
                ),
                PieChartSectionData(
                  value: notDone.toDouble(),
                  color: Colors.red,
                  title: "${notDonePercent.toStringAsFixed(1)}%",
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  radius: 60,
                ),
              ],
              sectionsSpace: 4,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(Colors.green, "Done"),
            const SizedBox(width: 16),
            _buildLegend(Colors.red, "Not Done"),
          ],
        )
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class TopIssueList extends StatelessWidget {
  final List<TopIssue> issues;

  const TopIssueList({super.key, required this.issues});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: issues.map((issue) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  issue.issue,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${issue.count}x',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class WeeklyPerformanceChart extends StatelessWidget {
  final Map<String, int> data;

  const WeeklyPerformanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final labelMap = {
      'mon': 'Sen',
      'tue': 'Sel',
      'wed': 'Rab',
      'thu': 'Kam',
      'fri': 'Jum',
      'sat': 'Sab',
      'sun': 'Min',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (data.values.isEmpty ? 1 : (data.values.reduce((a, b) => a > b ? a : b)).toDouble()) + 1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      int index = value.toInt();
                      if (index >= 0 && index < dayLabels.length) {
                        return Text(labelMap[dayLabels[index]] ?? '');
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(dayLabels.length, (index) {
                final count = data[dayLabels[index]] ?? 0;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: count.toDouble(),
                      width: 18,
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

Widget buildPieChart(double done, double notDone, double notDonePriority, double total) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
      ],
    ),
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 20,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    color: Colors.green,
                    value: done,
                    title: '${(done / total * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    color: Colors.orange,
                    value: notDone,
                    title: '${(notDone / total * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    color: Colors.red,
                    value: notDonePriority,
                    title: '${(notDonePriority / total * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.red),
                  SizedBox(width: 6),
                  Text("Prioritas : ${int.parse(notDonePriority.toStringAsFixed(0))}"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.orange),
                  SizedBox(width: 6),
                  Text("Belum selesai : ${int.parse(notDone.toStringAsFixed(0))}"),
                ],
              ),
              const SizedBox(height: 12),Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.green),
                  SizedBox(width: 6),
                  Text("Sudah selesai : ${int.parse(done.toStringAsFixed(0))}"),
                ],
              ),
              const SizedBox(height: 12),
              Text("Total: ${int.parse(total.toStringAsFixed(0))}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    ),
  );
}