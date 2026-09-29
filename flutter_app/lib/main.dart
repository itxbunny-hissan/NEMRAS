import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const NemrasApp());

class NemrasApp extends StatelessWidget {
  const NemrasApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMRAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: const SplashScreen(),
    );
  }
}
