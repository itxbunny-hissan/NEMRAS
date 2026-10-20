import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Daylight splash colours from `assets/01_splash_screen/code.html`.
///
/// These stay local. The shared [NemrasColors] tokens are the earlier ink and
/// teal palette, and changing them would restyle every other surface.
abstract final class _SplashPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealDeep = Color(0xFF115E59);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color track = Color(0xFFEDF2F7);
  static const Color success = Color(0xFF16A34A);
}

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
  late Animation<double> _progress;
  Timer? _navTimer;

  static const Duration _splashDuration = Duration(milliseconds: 2800);

  /// The reference freezes the boot bar at this fraction. It is a graphic,
  /// not a measurement of a TLS session or a live gateway.
  static const double _referenceProgress = 0.68;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fade = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 0.7, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _progress = Tween<double>(begin: 0, end: _referenceProgress).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _navTimer = Timer(_splashDuration, _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, NemrasRouteNames.secureBoot);
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SplashPalette.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashWash(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NemrasSpacing.section,
                ),
                child: Column(
                  children: [
                    Expanded(child: _SplashIdentity(scale: _scale)),
                    _BootCard(progress: _progress),
                    const SizedBox(height: NemrasSpacing.section),
                    Text(
                      'Govt of Pakistan · Health Informatics v1.4',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.dataCaption.copyWith(
                        fontSize: 11,
                        color: _SplashPalette.textMuted,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.huge),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWash extends StatelessWidget {
  const _SplashWash();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.44),
          radius: 0.85,
          colors: [
            Color(0x140F766E),
            Color(0x00F7FAFC),
          ],
          stops: [0, 0.65],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.7, 0.7),
            radius: 0.7,
            colors: [
              Color(0xB3E8F6F3),
              Color(0x00F7FAFC),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashIdentity extends StatelessWidget {
  const _SplashIdentity({required this.scale});

  final Animation<double> scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(scale: scale, child: const _Emblem()),
        const SizedBox(height: NemrasSpacing.section),
        Text(
          'NEMRAS',
          style: NemrasTextStyles.pageTitle.copyWith(
            fontSize: 32,
            letterSpacing: -0.64,
            color: _SplashPalette.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'NATIONAL EMERGENCY MEDICAL SYSTEM',
          style: NemrasTextStyles.fieldLabel.copyWith(
            fontSize: 11,
            letterSpacing: 1.54,
            color: _SplashPalette.teal,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Text(
          'Instant, federated critical health data delivery '
          'during life-threatening emergency response.',
          textAlign: TextAlign.center,
          style: NemrasTextStyles.body.copyWith(
            fontSize: 13.5,
            color: _SplashPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x1F0F766E),
                borderRadius: BorderRadius.all(Radius.circular(28)),
                border: Border.fromBorderSide(
                  BorderSide(color: Color(0x330F766E)),
                ),
              ),
              child: SizedBox(width: 112, height: 112),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_SplashPalette.teal, _SplashPalette.tealDeep],
              ),
              borderRadius: BorderRadius.all(Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x590F766E),
                  offset: Offset(0, 12),
                  blurRadius: 24,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(painter: _EmblemMarkPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmblemMarkPainter extends CustomPainter {
  const _EmblemMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 * unit;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center.translate(0, -9 * unit),
      center.translate(0, 9 * unit),
      paint,
    );
    canvas.drawLine(
      center.translate(-9 * unit, 0),
      center.translate(9 * unit, 0),
      paint,
    );
    paint.strokeWidth = 2.2 * unit;
    canvas.drawCircle(center, 5 * unit, paint);
  }

  @override
  bool shouldRepaint(covariant _EmblemMarkPainter oldDelegate) => false;
}

class _BootCard extends StatelessWidget {
  const _BootCard({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    final caption = NemrasTextStyles.bodyCaption.copyWith(
      color: _SplashPalette.textSecondary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SplashPalette.card,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: _SplashPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D243746),
            offset: Offset(0, 4),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          children: [
            Row(
              children: [
                const _StatusDot(),
                const SizedBox(width: 6),
                Text(
                  'Secure Enclave Init',
                  style: NemrasTextStyles.fieldLabel.copyWith(
                    fontSize: 11,
                    letterSpacing: 0,
                    color: _SplashPalette.teal,
                  ),
                ),
                const Spacer(),
                Text(
                  'TLS 1.3 · 68%',
                  style: NemrasTextStyles.fieldLabel.copyWith(
                    fontSize: 11,
                    letterSpacing: 0,
                    color: _SplashPalette.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NemrasSpacing.m),
            AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: NemrasRadii.pillBorder,
                  child: SizedBox(
                    height: 6,
                    width: double.infinity,
                    child: ColoredBox(
                      color: _SplashPalette.track,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress.value,
                        child: const ColoredBox(color: _SplashPalette.teal),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: NemrasSpacing.m),
            Row(
              children: [
                Text('PK-NDHA Federated Gateway', style: caption),
                const Spacer(),
                Text(
                  'Multan Node #001',
                  style: NemrasTextStyles.dataCaption.copyWith(
                    fontSize: 11,
                    color: _SplashPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 7,
      height: 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _SplashPalette.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
