import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash 1.5s then go to login
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FF), // soft blue background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App logo (use your asset)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.water_drop_outlined, color: Colors.white, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              'Will It Rain?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
