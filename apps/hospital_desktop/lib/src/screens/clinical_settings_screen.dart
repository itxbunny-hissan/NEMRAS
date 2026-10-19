import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../data/clinical_api_client.dart';
import '../data/staff_identity.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Settings — the ninth sidebar destination.
///
/// Reports the session and build configuration a reviewer needs, and ends the
/// demo session. It exposes no secrets: only the configured API base URL and
/// non-sensitive demo identifiers.
class ClinicalSettingsScreen extends StatelessWidget {
  const ClinicalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final staff = controller.staff;

    return ClinicalContentArea(
      maxWidth: 860,
      children: <Widget>[
        ClinicalCard(
          title: 'Clinical session',
          trailing: const DemoChip(label: 'DEMO SESSION'),
          child: ClinicalWrapGrid(
            minCellWidth: 170,
            children: <Widget>[
              ClinicalDataField(
                label: 'Staff label',
                value: staff?.displayLabel ?? 'Not signed in',
              ),
              ClinicalDataField(
                label: 'Role',
                value: staff?.role.label ?? 'Not available',
              ),
              ClinicalDataField(
                label: 'Staff ID',
                value: staff?.staffId ?? 'Not available',
              ),
              ClinicalDataField(
                label: 'Firebase UID',
                value: staff?.firebaseUid ?? 'Not available',
              ),
              ClinicalDataField(
                label: 'Hospital ID',
                value: controller.hospital.hospitalId,
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Backend configuration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClinicalDataField(label: 'API base URL', value: kBaseUrl),
              const SizedBox(height: NemrasSpacing.l),
              ClinicalDataField(
                label: 'Reachability',
                value: switch (controller.backendReachable) {
                  null => 'Not checked',
                  true => 'Reachable',
                  false => 'Unreachable',
                },
                valueColor: controller.backendReachable == false
                    ? semantics.critical.onSoft
                    : null,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              Text(
                'Override per build with '
                '--dart-define=NEMRAS_API_URL=http://host:port.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: controller.probeBackend,
                  icon: const Icon(Icons.network_check, size: 16),
                  label: const Text('Re-check backend'),
                ),
              ),
            ],
          ),
        ),
        const ClinicalCard(
          title: 'Not implemented in this build',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ProvenanceNotice(
                icon: Icons.construction_outlined,
                message:
                    'Hospital operations and ministry dashboards, real-time '
                    'transports, real hospital or dispatch integration, '
                    'staff multi-factor authentication, bed management and '
                    'billing are out of scope for this phase. The '
                    'repository and provider interfaces are in place so they '
                    'can be added without reshaping these screens.',
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'End session',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ending the session clears the open record, the assistant '
                'transcript and the selected case, and records a DEMO audit '
                'event.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    controller.endSession();
                    Navigator.of(context).pushReplacementNamed(
                      NemrasRouteNames.hospitalLogin,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: semantics.critical.onSoft,
                    side: BorderSide(color: semantics.critical.solid),
                  ),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('End demo session'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
