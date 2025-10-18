import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'main.dart'; // We’ll import your existing HomePage from main.dart

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnimationCompleted = false;

  void _goToHome() {
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const HomePage(), // from your main.dart
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 800),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/lottie/Capsule.json',
          width: 220,
          height: 220,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            Future.delayed(composition.duration, () {
              if (mounted && !_isAnimationCompleted) {
                _isAnimationCompleted = true;
                _goToHome();
              }
            });
          },
        ),
      ),
    );
  }
}
