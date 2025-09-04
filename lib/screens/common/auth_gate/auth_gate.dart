// auth_gate.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/screens/common/login/login_screen.dart';
import 'package:salsa/screens/common/main_navigation/main_navigation.dart';
// Hapus 'package:upgrader/upgrader.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahkan ini

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Hapus widget UpgradeAlert. Kita ganti dengan BlocConsumer.
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Listener akan bereaksi sekali terhadap state baru, cocok untuk dialog/snackbar
        if (state is AuthUpdateRequired) {
          showDialog(
            context: context,
            barrierDismissible: false, // Wajibkan pengguna berinteraksi
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Versi Aplikasi Usang'),
                content: const Text(
                  'Anda harus memperbarui aplikasi ke versi terbaru untuk dapat melanjutkan.',
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('UPDATE SEKARANG'),
                    onPressed: () {
                      // Buka URL Play Store / App Store
                      launchUrl(
                        Uri.parse(state.newVersionUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, state) {
        // Builder akan membangun ulang UI setiap kali state berubah
        if (state is AuthAuthenticated) {
          return const MainNavigationScreen();
        }

        if (state is AuthFirstLoading || state is AuthInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFFEAF3FB),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Untuk state: AuthUnauthenticated, AuthFailure, AuthUpdateRequired
        // kita tetap tampilkan LoginScreen.
        // Dialog untuk AuthUpdateRequired akan muncul di atasnya karena di-handle oleh listener.
        return const LoginScreen();
      },
    );
  }
}