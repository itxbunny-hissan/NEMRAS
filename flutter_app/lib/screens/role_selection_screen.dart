import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 08 reference.
///
/// The cards do not grant a role. Continue stays disabled.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

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
      backgroundColor: _RolePalette.canvas,
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
                            backgroundColor: _RolePalette.card,
                            side: const BorderSide(color: _RolePalette.border),
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
                            color: _RolePalette.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Select Access Role',
                      style: NemrasTextStyles.summaryName.copyWith(
                        fontSize: 24,
                        color: _RolePalette.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Choosing a card does not grant access. '
                      'Role provisioning is not available in this prototype.',
                      style: NemrasTextStyles.body.copyWith(
                        fontSize: 13.5,
                        color: _RolePalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _RoleCard(
                      icon: Icons.person_outline,
                      iconColor: _RolePalette.teal,
                      iconBackground: _RolePalette.tealLight,
                      name: 'Patient / Citizen',
                      badge: 'Not open',
                      body:
                          'Citizen sign-in already uses a CNIC and demo passcode. '
                          'Self-registration is not available here.',
                    ),
                    const _RoleCard(
                      icon: Icons.emergency_outlined,
                      iconColor: Color(0xFFE11D48),
                      iconBackground: Color(0xFFFFF1F2),
                      name: 'Emergency Responder',
                      badge: 'Not verified',
                      body:
                          'Paramedic tools are a separate demo entry. '
                          'This screen does not verify a service badge.',
                    ),
                    const _RoleCard(
                      icon: Icons.local_hospital_outlined,
                      iconColor: Color(0xFF2563EB),
                      iconBackground: Color(0xFFEFF6FF),
                      name: 'Hospital Staff / Clinician',
                      badge: 'Not granted',
                      body:
                          'Hospital sign-in is a separate desktop app. '
                          'This screen does not confirm a hospital affiliation.',
                    ),
                    const _RoleCard(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: Color(0xFF4B5563),
                      iconBackground: Color(0xFFF3F4F6),
                      name: 'System Administrator',
                      badge: 'Not provisioned',
                      body:
                          'Administrator access is not available in this prototype.',
                    ),
                    const SizedBox(height: 4),
                    const _RoleNotice(),
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
                        child: Text('Continue to Profile Setup'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        NemrasRouteNames.profileSetup,
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: _RolePalette.teal,
                      ),
                      child: const Text('View profile layout'),
                    ),
                    Text(
                      'Opening that layout does not save a profile.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _RolePalette.textSecondary,
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.name,
    required this.badge,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String name;
  final String badge;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _RolePalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _RolePalette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: NemrasTextStyles.listTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _RolePalette.text,
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              badge,
                              style: NemrasTextStyles.dataCaption.copyWith(
                                color: _RolePalette.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _RolePalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleNotice extends StatelessWidget {
  const _RoleNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Paramedic, hospital, and administrator access are not started '
          'from this screen.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Color(0xFF92400E),
          ),
        ),
      ),
    );
  }
}

abstract final class _RolePalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
