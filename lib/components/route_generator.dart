import 'package:flutter/material.dart';
import '../screens/common/login/login_screen.dart';
import '../screens/common/main_navigation/main_navigation.dart';
import 'auth_guard_page.dart';
import 'constants.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case kPathLanding:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case kPathMain:
        return MaterialPageRoute(
            builder: (_) => const AuthGuardPage(
                  child: MainNavigationScreen(),
                ));
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Error Page")),
      );
    });
  }
}
