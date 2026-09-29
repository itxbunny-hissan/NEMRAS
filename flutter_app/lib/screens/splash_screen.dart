import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'secure_boot_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Force status bar icons white over the dark background
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Timer(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SecureBootScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF083A39),
      // extendBodyBehindAppBar ensures gradient covers the status bar area too
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF052E2D),
                Color(0xFF0A5A58),
                Color(0xFF0E7C7B),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Column(children: [
                const Spacer(flex: 3),

                // ── Logo icon ──────────────────────────────
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 1.5),
                    ),
                    child: const Icon(Icons.add,
                        color: Colors.white, size: 52),
                  ),
                ),
                const SizedBox(height: 30),

                // ── Brand name ─────────────────────────────
                const Text('NEMRAS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6)),
                const SizedBox(height: 10),
                Text(
                  'YOUR HEALTH  ·  YOUR RECORD  ·  ANYWHERE',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.50),
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(flex: 2),

                // ── Loading indicator ──────────────────────
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.60)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'INITIALIZING  ·  B2.4s',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500),
                ),
                const Spacer(flex: 2),

                // ── Footer ─────────────────────────────────
                Text('EMERSON UNIVERSITY MULTAN',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.30),
                        fontSize: 9,
                        letterSpacing: 2.2)),
                const SizedBox(height: 5),
                Text('v1.0.0  ·  BUILD 2026.05',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.24),
                        fontSize: 9,
                        letterSpacing: 1.5)),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
