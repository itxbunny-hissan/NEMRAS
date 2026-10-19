import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'auth/auth_service.dart';
import 'navigation/app_router.dart';
import 'paramedic/screens/paramedic_shell.dart';
import 'screens/splash_screen.dart';

/// Explicit demo-only entry selector. It is not a role claim and grants no
/// backend authorization. The default remains the frozen Patient startup.
const String _demoRole = String.fromEnvironment('NEMRAS_DEMO_ROLE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Optional development sign-in. Starts only when SUPABASE_URL and
  // SUPABASE_PUBLISHABLE_KEY are supplied with --dart-define; otherwise the
  // developer sign-in screen explains what is missing. Never throws.
  await initializeSupabase();

  runApp(const NemrasApp());
}

class NemrasApp extends StatelessWidget {
  const NemrasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMRAS',
      debugShowCheckedModeBanner: false,
      theme: nemrasClinicalLightTheme(),
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: _demoRole == 'paramedic'
          ? const ParamedicShell()
          : const SplashScreen(),
    );
  }
}
