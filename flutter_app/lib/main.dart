import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NemrasApp());
}

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