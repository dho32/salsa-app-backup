// file: components/salsa_scaffold.dart

import 'package:flutter/material.dart';

class SalsaScaffold extends StatelessWidget {
  final Widget child;
  final bool useBackground;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;

  const SalsaScaffold({
    super.key,
    required this.child,
    this.useBackground = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      backgroundColor: backgroundColor ?? Colors.transparent,
      body: Stack(
        children: [
          if (useBackground) const _SalsaBackground(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _SalsaBackground extends StatelessWidget {
  const _SalsaBackground();
  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg_app.png"),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
