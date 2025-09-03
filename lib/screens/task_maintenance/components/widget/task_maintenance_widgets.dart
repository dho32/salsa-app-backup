
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../blocs/timer/timer_bloc.dart';
import '../../../../blocs/timer/timer_state.dart';

Widget buildHeaderTaskMaintenance({
  required String title,
  required String user,
  required String company,
}) {
  return Center(
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: Image.asset('assets/images/salsa.png', width: 100, height: 100),
        ),
        Text(title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          company,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        Text(
          user,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        BlocProvider(
          // Menyediakan TimeBloc hanya untuk subtree ini.
          // Jika TimeBloc sudah disediakan di root (main.dart),
          // Anda bisa menghapus BlocProvider ini dan langsung menggunakan BlocBuilder.
          create: (context) => TimeBloc(),
          child: BlocBuilder<TimeBloc, TimeState>(
            builder: (context, state) {
              return Text(
                // Format tanggal dan waktu menggunakan package intl
                  DateFormat('EEEE, dd MMMM yyyy HH:mm:ss', 'id_ID').format(state.currentTime),
                  style: const TextStyle(fontSize: 14, color: Colors.black54)
              );
            },
          ),
        ),
      ]
    ),
  );
}

Widget _buildShimmerRow() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 28, height: 28, color: Colors.white), // Placeholder untuk Icon
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(width: 80, height: 16, color: Colors.white), // Placeholder untuk Judul (Service/Cuci)
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 14, color: Colors.white), // Placeholder untuk TextField hint
          ],
        ),
      ),
      const SizedBox(width: 12),
      Container(width: 24, height: 24, color: Colors.white), // Placeholder untuk Tombol Search
    ],
  );
}

Widget buildHeaderShimmer() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 24,
          color: Colors.white,
        ),
        const SizedBox(height: 10),
        Container(
          width: 150,
          height: 16,
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        Container(
          width: 120,
          height: 16,
          color: Colors.white,
        ),
        const SizedBox(height: 4),
        Container(
          width: 220,
          height: 14,
          color: Colors.white,
        ),
      ],
    ),
  );
}

Widget buildTaskMaintenanceShimmerBody() {
  return Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Shimmer untuk Header
        buildHeaderShimmer(),
        const SizedBox(height: 16), // Beri jarak seperti di UI asli
        // 2. Shimmer untuk Card Input
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white, // Warna ini penting untuk efek shimmer
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              children: [
                _buildShimmerRow(),
                const SizedBox(height: 20),
                _buildShimmerRow(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}