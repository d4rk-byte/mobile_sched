import 'package:flutter/material.dart';

class AppOpeningLoadingScreen extends StatelessWidget {
  const AppOpeningLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/ic_logo.png',
          width: 120,
          height: 120,
          gaplessPlayback: true,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.calendar_month_rounded,
              size: 80,
              color: Color(0xFF465FFF),
            );
          },
        ),
      ),
    );
  }
}
