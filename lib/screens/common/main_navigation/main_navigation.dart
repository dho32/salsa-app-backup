import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:salsa/screens/task_maintenance/task_maintenance_screen.dart';

import '../../../blocs/history/history_bloc.dart';
import '../../../blocs/history/history_event.dart';
import '../../../blocs/history/history_repository.dart';
import '../../history/history_list/history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final HistoryBloc _historyBloc = HistoryBloc(HistoryRepository());


  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _requestLocationPermissionAndService();
    _pages = [
      const TaskMaintenanceScreen(),
      BlocProvider.value(
        value: _historyBloc,
        child: const HistoryScreen(),
      ),
    ];
  }

  // BARU: Fungsi untuk meminta izin lokasi dan memeriksa layanan lokasi
  Future<void> _requestLocationPermissionAndService() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan lokasi di perangkat aktif (GPS, Wi-Fi, dll.)
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) { // Pastikan widget masih ada sebelum menampilkan SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Layanan lokasi (GPS) tidak aktif. Mohon aktifkan.'),
            action: SnackBarAction(
              label: 'Buka Pengaturan',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // 2. Cek status izin lokasi aplikasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Izin ditolak, coba minta izin kepada pengguna
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin masih ditolak setelah permintaan.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Aplikasi tidak dapat mengambil koordinat.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Izin ditolak secara permanen. Pengguna harus mengaktifkannya secara manual dari pengaturan aplikasi.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Izin lokasi ditolak permanen. Mohon aktifkan di Pengaturan Aplikasi.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Buka Pengaturan',
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
            ),
          ),
        );
      }
      return;
    }
  }

  void _onItemTapped(int index) {
    // --- 3. TAMBAHKAN LOGIKA REFRESH DI SINI ---
    // Jika pengguna mengetuk tab 'Riwayat' (index 1) dan tab itu SUDAH aktif
    if (index == 1) {
      // Panggil fungsi refresh melalui GlobalKey
      _historyBloc.add(const HistoryRefreshed());
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey,
        elevation: 1,
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onItemTapped(index);
        },
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.white,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.house), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
        ],
      ),
    );
  }
}
