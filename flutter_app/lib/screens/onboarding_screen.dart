import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Daylight colours from `assets/02_welcome_onboarding/code.html`.
///
/// Kept local so the shared [NemrasColors] palette, used by every other
/// surface, stays unchanged.
abstract final class _WelcomePalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color dot = Color(0xFFCBD5E1);
  static const Color emergency = Color(0xFFD94848);
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _signIn(BuildContext context) {
    Navigator.pushReplacementNamed(context, NemrasRouteNames.signIn);
  }

  void _openSignUp(BuildContext context) {
    Navigator.pushNamed(context, NemrasRouteNames.signUp);
  }

  void _nfcUnavailable(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('NFC badge'),
        content: const Text(
          'NFC badge sign-in is not available in this build. '
          'Paramedic access is not started from this screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WelcomePalette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _HeroCard(),
                    const _WelcomeCopy(),
                    const _RolePreview(),
                    _WelcomeActions(
                      onSignIn: () => _signIn(context),
                      onCreateAccount: () => _openSignUp(context),
                      onNfc: () => _nfcUnavailable(context),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_WelcomePalette.card, _WelcomePalette.tealLight],
        ),
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.fromBorderSide(
          BorderSide(color: _WelcomePalette.border),
        ),
      ),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(top: 14, left: 14, child: _TraumaBadge()),
            Center(
              child: SizedBox(
                width: 230,
                height: 168,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(child: _NetworkMark()),
                    Positioned(
                      top: 8,
                      right: 0,
                      child: _OrbitTag('Rescue 1122 Synced'),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      child: _OrbitTag('NADRA Enclave'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraumaBadge extends StatelessWidget {
  const _TraumaBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _WelcomePalette.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _WelcomePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule, size: 12, color: _WelcomePalette.teal),
            const SizedBox(width: 5),
            Text(
              'SUB-90s TRAUMA INTEL',
              style: NemrasTextStyles.tag.copyWith(color: _WelcomePalette.teal),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkMark extends StatelessWidget {
  const _NetworkMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 130,
      height: 130,
      child: CustomPaint(
        painter: _DashedRingPainter(),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _WelcomePalette.teal,
              borderRadius: BorderRadius.all(Radius.circular(18)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x400F766E),
                  offset: Offset(0, 8),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(painter: _DossierMarkPainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x590F766E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 1;
    const dash = 5.0;
    const gap = 4.0;
    const step = dash + gap;
    final turns = (2 * 3.141592653589793 * radius / step).floor();
    for (var i = 0; i < turns; i++) {
      final start = i * step / radius;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dash / radius,
        false,
        paint,
      );
    }
    canvas.drawCircle(
      center,
      radius - 8,
      Paint()..color = const Color(0x99FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) => false;
}

class _DossierMarkPainter extends CustomPainter {
  const _DossierMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.shortestSide / 24;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5 * unit;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center.translate(0, -10 * unit),
      center.translate(0, 10 * unit),
      paint,
    );
    canvas.drawLine(
      center.translate(-10 * unit, 0),
      center.translate(10 * unit, 0),
      paint,
    );
    canvas.drawCircle(center, 4 * unit, paint);
  }

  @override
  bool shouldRepaint(covariant _DossierMarkPainter oldDelegate) => false;
}

class _OrbitTag extends StatelessWidget {
  const _OrbitTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _WelcomePalette.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _WelcomePalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          style: NemrasTextStyles.badge.copyWith(
            fontSize: 9,
            color: _WelcomePalette.text,
          ),
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        children: [
          Text(
            'One Emergency Dossier.\nNationwide Access.',
            textAlign: TextAlign.center,
            style: NemrasTextStyles.summaryName.copyWith(
              fontSize: 24,
              height: 1.2,
              letterSpacing: -0.24,
              color: _WelcomePalette.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting citizens, 1122 ambulances, and ER '
            'resuscitation bays through cryptographically '
            'verified emergency records.',
            textAlign: TextAlign.center,
            style: NemrasTextStyles.body.copyWith(
              fontSize: 13.5,
              color: _WelcomePalette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PageDot(active: true),
              SizedBox(width: 6),
              _PageDot(active: false),
              SizedBox(width: 6),
              _PageDot(active: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 22 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? _WelcomePalette.teal : _WelcomePalette.dot,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _RolePreview extends StatelessWidget {
  const _RolePreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _WelcomePalette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _WelcomePalette.border),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            Expanded(child: _RoleMini(icon: Icons.person_outline, label: 'Patient')),
            Expanded(child: _RoleMini(icon: Icons.airport_shuttle_outlined, label: 'Responder')),
            Expanded(child: _RoleMini(icon: Icons.domain_outlined, label: 'Clinician')),
            Expanded(child: _RoleMini(icon: Icons.lock_outline, label: 'Admin')),
          ],
        ),
      ),
    );
  }
}

class _RoleMini extends StatelessWidget {
  const _RoleMini({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: _WelcomePalette.tealLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, size: 15, color: _WelcomePalette.teal),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: NemrasTextStyles.navLabel.copyWith(
            color: _WelcomePalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _WelcomeActions extends StatelessWidget {
  const _WelcomeActions({
    required this.onSignIn,
    required this.onCreateAccount,
    required this.onNfc,
  });

  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onNfc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: _WelcomePalette.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shadowColor: const Color(0x330F766E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign In to Account  →',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NemrasTextStyles.button.copyWith(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onCreateAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: _WelcomePalette.text,
                backgroundColor: _WelcomePalette.card,
                side: const BorderSide(color: _WelcomePalette.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Citizen Account',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NemrasTextStyles.button.copyWith(
                  fontSize: 14,
                  color: _WelcomePalette.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Field Paramedic on Active Shift? ',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _WelcomePalette.textSecondary,
                ),
              ),
              TextButton(
                onPressed: onNfc,
                style: TextButton.styleFrom(
                  foregroundColor: _WelcomePalette.emergency,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(48, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'NFC Badge Rapid Tap →',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _WelcomePalette.emergency,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
