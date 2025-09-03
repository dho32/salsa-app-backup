import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salsa/screens/common/login/login_screen.dart';
import 'package:salsa/screens/common/main_navigation/main_navigation.dart';
import 'package:upgrader/upgrader.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return UpgradeAlert(
      upgrader: Upgrader(
          countryCode: 'ID',
          minAppVersion: '1.0.2',
          debugLogging: false,
          storeController: UpgraderStoreController(
            onAndroid: () => UpgraderAppcastStore(
                appcastURL:
                'https://raw.githubusercontent.com/RomyITCM/salsa/main/appcast.xml'),
            oniOS: () => UpgraderAppcastStore(
                appcastURL:
                'https://raw.githubusercontent.com/RomyITCM/salsa/main/appcast.xml'),
          )),
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const MainNavigationScreen();
          }

          if (state is AuthFirstLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFFEAF3FB),
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
