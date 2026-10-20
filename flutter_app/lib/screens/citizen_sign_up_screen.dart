import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 04 reference.
///
/// The fields are disabled placeholders. This screen does not read, store,
/// or submit a name, CNIC, phone number, or passcode.
class CitizenSignUpScreen extends StatelessWidget {
  const CitizenSignUpScreen({super.key});

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(NemrasRouteNames.signIn);
  }

  void _signIn(BuildContext context) {
    Navigator.pushNamed(context, NemrasRouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SignUpPalette.canvas,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight > 28
                      ? constraints.maxHeight - 28
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
                            backgroundColor: _SignUpPalette.card,
                            side: const BorderSide(color: _SignUpPalette.border),
                            fixedSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 18),
                        ),
                        const Spacer(),
                        Flexible(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _SignUpPalette.tealLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              child: Text(
                                'STEP 1 OF 3 · CITIZEN',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NemrasTextStyles.tag.copyWith(
                                  color: _SignUpPalette.teal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Emergency Profile',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 22,
                        color: _SignUpPalette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This is a visual prototype. Later registration steps '
                      'are not implemented.',
                      style: NemrasTextStyles.bodySmall.copyWith(
                        fontSize: 12.5,
                        color: _SignUpPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _UnavailableNotice(),
                    const SizedBox(height: 12),
                    const _PlaceholderField(
                      label: 'Full legal name',
                      hint: 'Not collected',
                      note: 'Placeholder',
                    ),
                    const _PlaceholderField(
                      label: 'CNIC',
                      hint: 'XXXXX-XXXXXXX-X',
                      note: 'Not collected',
                      mono: true,
                    ),
                    const _PlaceholderField(
                      label: 'Mobile phone number',
                      hint: 'Not collected',
                      note: 'No SMS',
                    ),
                    const _PlaceholderField(
                      label: 'Security passcode',
                      hint: 'Not collected',
                      note: 'Not saved',
                      obscure: true,
                    ),
                    const SizedBox(height: 4),
                    const _InactiveMeter(),
                    const SizedBox(height: 10),
                    const _UnavailableTerms(),
                    const SizedBox(height: 12),
                    const _DisabledContinue(),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        NemrasRouteNames.roleSelection,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _SignUpPalette.teal,
                      ),
                      child: const Text('View role layout'),
                    ),
                    Text(
                      'Opening that layout does not create an account.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _SignUpPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Already registered on NEMRAS? ',
                          style: NemrasTextStyles.bodySmall.copyWith(
                            color: _SignUpPalette.textSecondary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _signIn(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _SignUpPalette.teal,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Sign In Here'),
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

abstract final class _SignUpPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color alertBg = Color(0xFFFEF2F2);
  static const Color alertBorder = Color(0xFFFECACA);
  static const Color alertText = Color(0xFF991B1B);
}

class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _SignUpPalette.alertBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SignUpPalette.alertBorder),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Citizen registration is not available in this prototype yet.',
          style: TextStyle(
            color: _SignUpPalette.alertText,
            fontSize: 13,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderField extends StatelessWidget {
  const _PlaceholderField({
    required this.label,
    required this.hint,
    required this.note,
    this.mono = false,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final String note;
  final bool mono;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NemrasTextStyles.listTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _SignUpPalette.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                note,
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: _SignUpPalette.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            enabled: false,
            obscureText: obscure,
            enableInteractiveSelection: false,
            style: TextStyle(
              fontFamily: mono ? NemrasFonts.mono : NemrasFonts.ui,
              package: NemrasFonts.package,
              fontSize: 13,
              color: _SignUpPalette.textMuted,
            ),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: _SignUpPalette.card,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              disabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: _SignUpPalette.border, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveMeter extends StatelessWidget {
  const _InactiveMeter();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          const Expanded(
            child: SizedBox(
              height: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _SignUpPalette.border,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(width: 8),
        Text(
          'NOT CALCULATED',
          style: NemrasTextStyles.badge.copyWith(
            color: _SignUpPalette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _UnavailableTerms extends StatelessWidget {
  const _UnavailableTerms();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Checkbox(
          value: false,
          onChanged: null,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'A privacy policy and terms of care are not available '
              'in this prototype. This box cannot be accepted.',
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _SignUpPalette.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisabledContinue extends StatelessWidget {
  const _DisabledContinue();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 46,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(Color(0xFF94A3B8)),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          elevation: WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        child: Text('Continue to Verification'),
      ),
    );
  }
}
