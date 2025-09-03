import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../components/shared_widgets.dart';

class DashboardBodyMobileLoading extends StatelessWidget {
  const DashboardBodyMobileLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSection(child: _buildHeaderShimmer()),
          const SizedBox(height: 24),
          FadeInSection(child: _buildInfoCardRowShimmer()),
          const SizedBox(height: 16),
          FadeInSection(child: _buildPieChartShimmer()),
          const SizedBox(height: 16),
          FadeInSection(child: _buildGridAndBarChartShimmer()),
        ],
      ),
    );
  }

  Widget _buildHeaderShimmer() {
    return _shimmerContainer(height: 80, width: double.infinity, radius: 12);
  }

  Widget _buildInfoCardRowShimmer() {
    return Row(
      children: [
        Expanded(child: _shimmerContainer(height: 100, radius: 12)),
        const SizedBox(width: 12),
        Expanded(child: _shimmerContainer(height: 100, radius: 12)),
      ],
    );
  }

  Widget _buildPieChartShimmer() {
    return _shimmerContainer(height: 200, width: double.infinity, radius: 12);
  }

  Widget _buildGridAndBarChartShimmer() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: List.generate(3, (_) => _shimmerContainer(height: 80, radius: 12)),
        ),
        const SizedBox(height: 16),
        _buildWeeklyBarChartShimmer(),
      ],
    );
  }

  Widget _buildWeeklyBarChartShimmer() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final dummyHeights = [35, 50, 45, 65, 70, 30, 75];

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          height: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 16,
                    height: dummyHeights[index].toDouble(),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black38,
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _shimmerContainer({double height = 100, double width = double.infinity, double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
