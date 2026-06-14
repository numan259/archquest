import 'package:flutter/material.dart';

import '../constants/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/chip_logo.dart';
import 'subjects_screen.dart';

/// Brief branded splash shown at launch, then replaced by the Subjects screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Hand off to the app after a short beat.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondary) =>
              const SubjectsScreen(),
          transitionsBuilder: (context, anim, secondary, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _controller,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ChipLogo(size: 120),
                const SizedBox(height: 20),
                Text(Strings.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Computer Architecture',
                    style: TextStyle(color: AppColors.onSurfaceMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
