import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

class SecureBootScreen extends StatefulWidget {
  const SecureBootScreen({super.key});
  @override
  State<SecureBootScreen> createState() => _SecureBootScreenState();
}



class _SecureBootScreenState extends State<SecureBootScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _arcCtrl;
  int _count = 4;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arcCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _count--);
      if (_count <= 0) {
        t.cancel();
        _navigate();
      }
    });
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, NemrasRouteNames.onboarding);
  }

  @override
  void dispose() {
    _arcCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(children: [
            const Spacer(flex: 2),
            AnimatedBuilder(
              animation: _arcCtrl,
              builder: (_, __) => SizedBox(
                width: 168,
                height: 168,
                child: Stack(alignment: Alignment.center, children: [
                  SizedBox(
                    width: 168,
                    height: 168,
                    child: CircularProgressIndicator(
                      value: _arcCtrl.value,
                      strokeWidth: 5,
                      backgroundColor: NemrasColors.paper2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          NemrasColors.teal),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      _count.clamp(0, 9).toString().padLeft(2, '0'),
                      style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: NemrasColors.ink,
                          letterSpacing: -2),
                    ),
                    const Text(
                      'SECURE BOOT',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 2.5,
                          color: NemrasColors.muted,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 52),
            const Text(
              'Establishing Secure\nChannel',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: NemrasColors.ink,
                  height: 1.2),
            ),
            const SizedBox(height: 18),
            const Text(
              'TLS 1.3 · AES-256 · End-to-end\nencrypted connection to NEMRAS\nnational index',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: NemrasColors.muted, height: 1.65),
            ),
            const Spacer(flex: 3),
          ]),
        ),
      ),
    );
  }
}
