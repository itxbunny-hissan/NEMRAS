import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 07 reference.
///
/// Both fields stay empty and disabled. Nothing is saved or checked.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

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
      backgroundColor: _ResetPalette.canvas,
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
                            backgroundColor: _ResetPalette.card,
                            side: const BorderSide(color: _ResetPalette.border),
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
                            color: _ResetPalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reset Password',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 24,
                        color: _ResetPalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Password reset is not available in this prototype. '
                      'Nothing entered here is saved.',
                      style: NemrasTextStyles.body.copyWith(
                        fontSize: 13.5,
                        color: _ResetPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _DisabledSecretField(label: 'New password'),
                    const SizedBox(height: 12),
                    const _DisabledSecretField(label: 'Confirm password'),
                    const SizedBox(height: 16),
                    const _RuleRow(label: 'Minimum 8 characters'),
                    const _RuleRow(label: 'A number and a special character'),
                    const _RuleRow(label: 'The two fields match'),
                    const SizedBox(height: 8),
                    Text(
                      'These checks are not running. No password is stored.',
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _ResetPalette.textSecondary,
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
                        child: Text('Save & Sign In'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A support contact is not available in this prototype.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _ResetPalette.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _signIn(context),
                      style: TextButton.styleFrom(
                        foregroundColor: _ResetPalette.teal,
                      ),
                      child: const Text('Back to Sign In'),
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

class _DisabledSecretField extends StatelessWidget {
  const _DisabledSecretField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: NemrasTextStyles.listTitle.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _ResetPalette.text,
          ),
        ),
        const SizedBox(height: 6),
        const TextField(
          enabled: false,
          obscureText: true,
          enableInteractiveSelection: false,
          decoration: InputDecoration(
            hintText: 'Not collected',
            filled: true,
            fillColor: _ResetPalette.card,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: _ResetPalette.border, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked,
            size: 16,
            color: _ResetPalette.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: _ResetPalette.textSecondary,
              ),
            ),
          ),
          Text(
            'Not checked',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: _ResetPalette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _ResetPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
