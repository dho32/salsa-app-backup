import 'package:flutter/material.dart';

import '../blocs/auth/auth_storage.dart';
import '../screens/common/login/login_screen.dart';

class AuthGuardPage extends StatelessWidget {
  final Widget child;

  const AuthGuardPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthStorage.hasToken(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          return child;
        } else {
          return const LoginScreen(); // redirect kalau belum login
        }
      },
    );
  }
}
