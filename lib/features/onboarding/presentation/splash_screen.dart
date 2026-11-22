import 'dart:async';

import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class BrandedLaunchScreen extends StatefulWidget {
  const BrandedLaunchScreen({required this.destination, super.key});

  static bool hasShown = false;

  final Widget destination;

  @override
  State<BrandedLaunchScreen> createState() => _BrandedLaunchScreenState();
}

class _BrandedLaunchScreenState extends State<BrandedLaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _showDestination = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    if (BrandedLaunchScreen.hasShown) {
      _showDestination = true;
      return;
    }
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      BrandedLaunchScreen.hasShown = true;
      if (mounted) setState(() => _showDestination = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showDestination) return widget.destination;

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/branding/splash_logo.png',
                width: 340,
                semanticLabel: 'Trace logo',
              ),
              const SizedBox(height: 18),
              const Text(
                'Leave no expense untraced.',
                style: TextStyle(color: AppColors.mutedText, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
