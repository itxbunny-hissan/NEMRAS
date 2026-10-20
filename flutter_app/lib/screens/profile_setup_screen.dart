import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 09 reference.
///
/// Every field is empty and disabled. No name, phone, allergy, or blood
/// group is collected or presented as verified.
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  void _back(BuildContext context) {
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
      backgroundColor: _ProfilePalette.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _back(context),
                    style: IconButton.styleFrom(
                      backgroundColor: _ProfilePalette.card,
                      side: const BorderSide(color: _ProfilePalette.border),
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
                      color: _ProfilePalette.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Profile',
                style: NemrasTextStyles.summaryName.copyWith(
                  fontSize: 24,
                  color: _ProfilePalette.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Profile setup is not available in this prototype. '
                'No identity or medical details are collected.',
                style: NemrasTextStyles.body.copyWith(
                  fontSize: 13.5,
                  color: _ProfilePalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RoleChip(label: 'Patient / Citizen', enabled: false),
                  _RoleChip(label: 'Responder', enabled: false),
                  _RoleChip(label: 'Hospital Staff', enabled: false),
                  _RoleChip(label: 'Admin', enabled: false),
                ],
              ),
              const SizedBox(height: 14),
              const _DisabledField(label: 'Full legal name'),
              const SizedBox(height: 10),
              const _DisabledField(label: 'Emergency mobile'),
              const SizedBox(height: 10),
              const _DisabledField(label: 'Next of kin name'),
              const SizedBox(height: 10),
              const _DisabledField(label: 'Next of kin phone'),
              const SizedBox(height: 10),
              const _DisabledField(label: 'Known allergies'),
              const SizedBox(height: 10),
              const _DisabledField(label: 'Pre-existing conditions'),
              const SizedBox(height: 14),
              Text(
                'Blood group',
                style: NemrasTextStyles.listTitle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _ProfilePalette.text,
                ),
              ),
              const SizedBox(height: 6),
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _BloodChip(label: 'O+'),
                  _BloodChip(label: 'A+'),
                  _BloodChip(label: 'B+'),
                  _BloodChip(label: 'AB+'),
                  _BloodChip(label: 'O-'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'No blood group is selected.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _ProfilePalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              const SizedBox(
                height: 48,
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
                  child: Text('Save & Proceed to Permissions'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  NemrasRouteNames.locationPermission,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _ProfilePalette.teal,
                ),
                child: const Text('View location layout'),
              ),
              Text(
                'Opening that layout does not request location.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _ProfilePalette.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => _back(context),
                style: TextButton.styleFrom(
                  foregroundColor: _ProfilePalette.teal,
                ),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.label});

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
            color: _ProfilePalette.text,
          ),
        ),
        const SizedBox(height: 6),
        const TextField(
          enabled: false,
          enableInteractiveSelection: false,
          decoration: InputDecoration(
            hintText: 'Not collected',
            filled: true,
            fillColor: _ProfilePalette.card,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: _ProfilePalette.border,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProfilePalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: NemrasTextStyles.chip.copyWith(
            color: enabled ? Colors.white : _ProfilePalette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BloodChip extends StatelessWidget {
  const _BloodChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProfilePalette.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: NemrasTextStyles.dataValue.copyWith(
            color: _ProfilePalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

abstract final class _ProfilePalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
