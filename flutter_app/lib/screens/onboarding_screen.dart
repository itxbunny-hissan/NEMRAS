import 'package:flutter/material.dart';
import '../theme.dart';
import 'scan_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      bg: Color(0xFFEFF5F5),
      iconBg: Color(0xFFD6EDEC),
      icon: Icons.grid_view_rounded,
      iconColor: AppTheme.primary,
      title: 'One Record.\nEvery Hospital.',
      body:
          'Your complete medical history follows you anywhere in Pakistan — '
          'accessible the moment your CNIC is scanned in any onboarded hospital.',
    ),
    _Slide(
      bg: Color(0xFFF3F0FA),
      iconBg: Color(0xFFE8E0F5),
      icon: Icons.verified_user_outlined,
      iconColor: Color(0xFF7B1FA2),
      title: 'Federated\n& Private',
      body:
          'Your raw records stay at the hospital that generated them. '
          'Only encrypted summaries travel — and every access is logged '
          'on an immutable audit trail.',
    ),
  ];

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_page];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: slide.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (_, i) => _slides[i].buildContent(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? slide.iconColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: slide.iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Continue',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Slide {
  final Color bg, iconBg, iconColor;
  final IconData icon;
  final String title, body;

  const _Slide({
    required this.bg,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  Widget buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Spacer(),
        Center(
          child: Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 66, color: iconColor),
          ),
        ),
        const Spacer(),
        Text(title,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
                height: 1.2)),
        const SizedBox(height: 16),
        Text(body,
            style: const TextStyle(
                fontSize: 15, color: AppTheme.muted, height: 1.65)),
        const Spacer(flex: 2),
      ]),
    );
  }
}
