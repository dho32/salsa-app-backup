import 'package:flutter/material.dart';

import 'components/history_body_mobile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Screen ini tidak perlu lagi membuat BLoC
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: const SafeArea(child: HistoryBodyMobile()),
    );
  }
}