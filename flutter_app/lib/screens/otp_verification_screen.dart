import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 06 reference.
///
/// The boxes stay empty. This screen does not receive, check, or resend a code.
class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(NemrasRouteNames.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _OtpPalette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 32
                      ? constraints.maxHeight - 32
                      : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => _back(context),
                          style: IconButton.styleFrom(
                            backgroundColor: _OtpPalette.card,
                            side: const BorderSide(color: _OtpPalette.border),
                            fixedSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          'PROTOTYPE',
                          style: NemrasTextStyles.tag.copyWith(
                            color: _OtpPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Verify Your Identity',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 24,
                        color: _OtpPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Identity verification is not available in this prototype. '
                      'No code was sent to a phone number.',
                      style: NemrasTextStyles.body.copyWith(
                        fontSize: 13.5,
                        color: _OtpPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        Expanded(child: _OtpBox()),
                        SizedBox(width: 8),
                        Expanded(child: _OtpBox()),
                        SizedBox(width: 8),
                        Expanded(child: _OtpBox()),
                        SizedBox(width: 8),
                        Expanded(child: _OtpBox()),
                        SizedBox(width: 8),
                        Expanded(child: _OtpBox()),
                        SizedBox(width: 8),
                        Expanded(child: _OtpBox()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _OtpNotice(),
                    const SizedBox(height: 16),
                    const SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Color(0xFF94A3B8),
                          ),
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                          elevation: WidgetStatePropertyAll(0),
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        child: Text('Verify Code'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Resend code'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        NemrasRouteNames.resetPassword,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _OtpPalette.teal,
                      ),
                      child: const Text('View reset layout'),
                    ),
                    Text(
                      'Opening that layout does not change a passcode.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _OtpPalette.textSecondary,
                      ),
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

class _OtpBox extends StatelessWidget {
  const _OtpBox();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _OtpPalette.card,
          borderRadius: BorderRadius.all(Radius.circular(12)),
          border: Border.fromBorderSide(
            BorderSide(color: _OtpPalette.border, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _OtpNotice extends StatelessWidget {
  const _OtpNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'The boxes stay empty. This screen does not check a code, '
          'start a timer, or contact a mobile network.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Color(0xFF1E40AF),
          ),
        ),
      ),
    );
  }
}

abstract final class _OtpPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
