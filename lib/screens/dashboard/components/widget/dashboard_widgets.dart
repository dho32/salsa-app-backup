import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../models/dashboard/dashboard_data_model.dart';

Widget buildHeader({
  required String title,
  required String user,
  required String company,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "$user / $company",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      const SizedBox(width: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset('assets/images/salsa.png', width: 60, height: 60),
      ),
    ],
  );
}

Widget buildPieChart(LastServiceCall data) {
  final done = data.done;
  final notDone = data.notDone;
  final total = data.total;

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
                    color: Colors.blue,
                    value: done.toDouble(),
                    title: '${(done / total * 100).toStringAsFixed(0)}%',
                    radius: 40,
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    color: Colors.grey[300],
                    value: notDone.toDouble(),
                    title: '${(notDone / total * 100).toStringAsFixed(0)}%',
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
                  Icon(Icons.circle, size: 12, color: Colors.blue),
                  SizedBox(width: 6),
                  Text("Sudah selesai : $done"),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.circle, size: 12, color: Colors.grey),
                  SizedBox(width: 6),
                  Text("Belum selesai : $notDone"),
                ],
              ),
              const SizedBox(height: 12),
              Text("Total: $total",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        )
      ],
    ),
  );
}

Widget buildWeeklyBarChart(PosWeekly data) {
  final values = [
    data.sen,
    data.sel,
    data.rab,
    data.kam,
    data.jum,
    data.sab,
    data.min
  ];

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Service Minggu ini",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem('${rod.toY.toInt()} AC',
                          const TextStyle(color: Colors.white)),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(labels[value.toInt()],
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                7,
                    (index) => BarChartGroupData(x: index, barRods: [
                  BarChartRodData(
                    toY: values[index].toDouble(),
                    color: Colors.blue,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


