import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/staff_identity.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Screen 1 — Hospital login / demo staff entry.
///
/// This performs no authentication. It selects which clearly labelled demo
/// clinical role the desktop renders for. Production sign-in must use the
/// Firebase Authentication identity layer already established for NEMRAS,
/// with the backend enforcing authorisation; no second authentication
/// architecture is introduced here.
class HospitalLoginScreen extends StatefulWidget {
  const HospitalLoginScreen({super.key, required this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<HospitalLoginScreen> createState() => _HospitalLoginScreenState();
}

class _HospitalLoginScreenState extends State<HospitalLoginScreen> {
  ClinicalRole _role = ClinicalRole.emergencyPhysician;
  bool _busy = false;

  Future<void> _enter(HospitalSessionController controller) async {
    setState(() => _busy = true);
    await controller.startDemoSession(_role);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[NemrasColors.ink, NemrasColors.ink2],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NemrasSpacing.section),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                padding: const EdgeInsets.all(NemrasSpacing.section),
                decoration: BoxDecoration(
                  color: NemrasColors.white,
                  borderRadius: NemrasRadii.cardBorder,
                  boxShadow: NemrasShadows.large,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.local_hospital,
                          size: 22,
                          color: semantics.accent,
                        ),
                        const SizedBox(width: NemrasSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'NEMRAS Clinical Desktop',
                                style: NemrasTextStyles.summaryName.copyWith(
                                  color: semantics.textPrimary,
                                ),
                              ),
                              Text(
                                controller.hospital.displayName.toUpperCase(),
                                style:
                                    NemrasTextStyles.screenSubtitle.copyWith(
                                  color: semantics.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const DemoChip(),
                      ],
                    ),
                    const SizedBox(height: NemrasSpacing.huge),
                    const ProvenanceNotice(
                      icon: Icons.shield_outlined,
                      message:
                          'This entry point does not authenticate anyone. It '
                          'selects a demo clinical role so the desktop can be '
                          'reviewed. Production sign-in uses Firebase '
                          'Authentication, and the NEMRAS backend remains the '
                          'authorization boundary.',
                    ),
                    const SizedBox(height: NemrasSpacing.huge),
                    const ClinicalSectionLabel('Demo clinical role'),
                    const SizedBox(height: NemrasSpacing.s),
                    for (final role in ClinicalRole.values) ...<Widget>[
                      _RoleOption(
                        role: role,
                        selected: role == _role,
                        onTap: _busy
                            ? null
                            : () => setState(() => _role = role),
                      ),
                      const SizedBox(height: NemrasSpacing.s),
                    ],
                    const SizedBox(height: NemrasSpacing.xs),
                    Container(
                      padding: const EdgeInsets.all(NemrasSpacing.xl),
                      decoration: BoxDecoration(
                        color: semantics.controlBackground,
                        borderRadius: NemrasRadii.controlBorder,
                      ),
                      child: ClinicalWrapGrid(
                        minCellWidth: 150,
                        spacing: NemrasSpacing.l,
                        children: <Widget>[
                          ClinicalDataField(
                            label: 'Staff ID',
                            value: DemoHospitalIdentity.forRole(_role).staffId,
                          ),
                          ClinicalDataField(
                            label: 'Hospital ID',
                            value: controller.hospital.hospitalId,
                          ),
                          ClinicalDataField(
                            label: 'Firebase UID',
                            value:
                                DemoHospitalIdentity.forRole(_role).firebaseUid,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.huge),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _enter(controller),
                        icon: _busy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.login, size: 16),
                        label: Text(
                          _busy
                              ? 'Starting demo session…'
                              : 'Enter clinical desktop',
                        ),
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.l),
                    Text(
                      'These demo identifiers authorise nothing and are not '
                      'production credentials.',
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: semantics.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final ClinicalRole role;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: role.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: NemrasRadii.controlBorder,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: NemrasTouchTargets.minimum,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NemrasSpacing.xl,
            vertical: NemrasSpacing.m,
          ),
          decoration: BoxDecoration(
            color: selected
                ? semantics.informational.soft
                : semantics.inputBackground,
            borderRadius: NemrasRadii.controlBorder,
            border: Border.all(
              color: selected ? semantics.accent : semantics.inputBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 16,
                color: selected ? semantics.accent : semantics.textPlaceholder,
              ),
              const SizedBox(width: NemrasSpacing.m),
              Expanded(
                child: Text(
                  role.label,
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
