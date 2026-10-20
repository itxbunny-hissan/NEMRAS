import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 05 reference.
///
/// The identity field is a disabled placeholder. This screen does not read,
/// store, or submit a CNIC or phone number, and it does not send a code.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  void _signIn(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(NemrasRouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _RecoveryPalette.canvas,
      resizeToAvoidBottomInset: true,
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
                          onPressed: () => _signIn(context),
                          style: IconButton.styleFrom(
                            backgroundColor: _RecoveryPalette.card,
                            side: const BorderSide(
                              color: _RecoveryPalette.border,
                            ),
                            fixedSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                        ),
                        const Spacer(),
                        Text(
                          'RECOVERY',
                          style: NemrasTextStyles.tag.copyWith(
                            color: _RecoveryPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _RecoveryPalette.tealLight,
                          borderRadius: BorderRadius.all(Radius.circular(18)),
                        ),
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(
                            Icons.lock_outline,
                            color: _RecoveryPalette.teal,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Forgot Password',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 24,
                        color: _RecoveryPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Account recovery is not available in this prototype. '
                      'No verification code will be sent.',
                      style: NemrasTextStyles.body.copyWith(
                        fontSize: 13.5,
                        color: _RecoveryPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'CNIC or registered mobile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NemrasTextStyles.listTitle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _RecoveryPalette.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Not collected',
                          style: NemrasTextStyles.dataCaption.copyWith(
                            color: _RecoveryPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const TextField(
                      enabled: false,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        hintText: 'XXXXX-XXXXXXX-X',
                        filled: true,
                        fillColor: _RecoveryPalette.card,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(
                            color: _RecoveryPalette.border,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
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
                        child: Text('Send Verification Code'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        NemrasRouteNames.otpVerification,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _RecoveryPalette.teal,
                      ),
                      child: const Text('View verification layout'),
                    ),
                    Text(
                      'Opening that layout does not send a code.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _RecoveryPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const _RecoveryNotice(),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Remember your credentials? ',
                          style: NemrasTextStyles.bodySmall.copyWith(
                            color: _RecoveryPalette.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _signIn(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _RecoveryPalette.teal,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Back to Sign In'),
                        ),
                      ],
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

abstract final class _RecoveryPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color noticeBg = Color(0xFFEAF3FF);
  static const Color noticeBorder = Color(0xFFBFDBFE);
  static const Color noticeTitle = Color(0xFF1E40AF);
  static const Color noticeBody = Color(0xFF3B82F6);
}

class _RecoveryNotice extends StatelessWidget {
  const _RecoveryNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _RecoveryPalette.noticeBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _RecoveryPalette.noticeBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: _RecoveryPalette.noticeTitle),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recovery unavailable',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _RecoveryPalette.noticeTitle,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'This prototype does not send an SMS, reset a passcode, '
                    'or check whether an account exists.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: _RecoveryPalette.noticeBody,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
