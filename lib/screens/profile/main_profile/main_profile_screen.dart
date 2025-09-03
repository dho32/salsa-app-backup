import 'package:flutter/material.dart';

import 'components/main_profile_body_mobile.dart';

class MainProfileScreen extends StatelessWidget {
  const MainProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MainProfileBodyMobile(),
    );
  }
}
