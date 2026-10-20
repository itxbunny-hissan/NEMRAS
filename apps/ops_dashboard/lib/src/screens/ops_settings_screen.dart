import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/admin_identity.dart';
import '../data/operations_models.dart';
import '../data/ops_api_client.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 9 — Settings.
///
/// Reports what this build actually is: which hospital it is scoped to, which
/// backend it reads, whether the session is demo, and which data sources are
/// connected. Configuration placeholders are listed as not configurable
/// rather than rendered as controls that do nothing.
class OpsSettingsScreen extends StatelessWidget {
  const OpsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final administrator = controller.administrator;
    final hospital = controller.hospital;
    final status = controller.backendStatus;

    return OpsContentArea(
      maxWidth: 1000,
      children: <Widget>[
        if (controller.environment.isDemo)
          const ProvenanceNotice(
            title: 'Demo build',
            message: 'This build runs with a demo administrator session and '
                'demo providers for occupancy, handover state and the audit '
                'trail. It is not a production deployment, the session is not '
                'a credential, and it authorises nothing.',
          ),
        const OpsSectionHeader(
          title: 'Hospital',
          subtitle: 'The scope every figure on this dashboard is filtered to.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OpsField(
                label: 'Hospital ID',
                value: hospital.hospitalId,
                mono: true,
              ),
              OpsField(label: 'Hospital name', value: hospital.displayName),
              OpsField(label: 'Region', value: hospital.region),
              Row(
                children: <Widget>[
                  const OpsLabel('Identity source'),
                  const SizedBox(width: NemrasSpacing.m),
                  if (hospital.isDemo) const DemoChip(),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xxs),
              Text(
                'The dataset Hospital column holds a free-text name, not an '
                'identifier, so the hospital ID is a NEMRAS-side value and is '
                'labelled demo.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Environment',
          subtitle: 'Which build this is and what it is reading.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const OpsLabel('Environment'),
                  const SizedBox(width: NemrasSpacing.m),
                  OpsStatusPill(
                    label: controller.environment.label,
                    status: controller.environment.isDemo
                        ? semantics.elevated
                        : semantics.stable,
                    solid: true,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xl),
              OpsField(
                label: 'API base URL',
                value: kBaseUrl,
                mono: true,
              ),
              OpsField(
                label: 'API override',
                value: kBaseUrl == kDefaultApiUrl
                    ? 'Not set (using development default)'
                    : 'Set via --dart-define=NEMRAS_API_URL',
              ),
              Row(
                children: <Widget>[
                  const OpsLabel('Data source status'),
                  const SizedBox(width: NemrasSpacing.m),
                  OpsStatusPill(
                    label: status.label,
                    status: status == OpsBackendStatus.reachable
                        ? semantics.stable
                        : status == OpsBackendStatus.unknown
                            ? semantics.informational
                            : semantics.critical,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xxs),
              Text(
                status.detail,
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Administrator session',
          subtitle: 'Identifiers only. No credential is held by this build.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OpsField(label: 'Name', value: administrator.displayLabel),
              OpsField(label: 'Role', value: administrator.role.label),
              OpsField(
                label: 'Staff ID',
                value: administrator.staffId,
                mono: true,
              ),
              OpsField(
                label: 'Firebase UID',
                value: administrator.firebaseUid,
                mono: true,
              ),
              Text(
                'Firebase Authentication is the NEMRAS identity layer and the '
                'Firebase UID remains the identity identifier. This phase '
                'adds no second authentication system: the demo session above '
                'is a label, and the backend remains the security boundary.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Data sources',
          subtitle: 'What each part of this dashboard reads from.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: OpsTable(
            columns: const <OpsColumn>[
              OpsColumn(label: 'Area', flex: 3),
              OpsColumn(label: 'Source', flex: 5),
              OpsColumn(label: 'Kind', flex: 2, alignEnd: true),
            ],
            rows: <List<Widget>>[
              <Widget>[
                const OpsTextCell('Population aggregates'),
                const OpsMonoCell('GET /api/stats'),
                OpsStatusPill(
                  label: 'DATASET',
                  status: semantics.informational,
                ),
              ],
              <Widget>[
                const OpsTextCell('Highest-risk slice'),
                const OpsMonoCell('GET /api/dashboard/critical'),
                OpsStatusPill(label: 'SAMPLE', status: semantics.advisory),
              ],
              <Widget>[
                const OpsTextCell('Data source health'),
                const OpsMonoCell('GET /health'),
                OpsStatusPill(
                  label: 'DATASET',
                  status: semantics.informational,
                ),
              ],
              <Widget>[
                const OpsTextCell('Room occupancy'),
                const OpsTextCell('DemoOccupancyRepository'),
                OpsStatusPill(label: 'DEMO', status: semantics.elevated),
              ],
              <Widget>[
                const OpsTextCell('Handover state'),
                const OpsTextCell('DemoHandoverRepository'),
                OpsStatusPill(label: 'DEMO', status: semantics.elevated),
              ],
              <Widget>[
                const OpsTextCell('Audit trail'),
                const OpsTextCell('InMemoryAuditRepository'),
                OpsStatusPill(label: 'DEMO', status: semantics.elevated),
              ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Configuration placeholders',
          subtitle: 'Listed so the gap is documented. None is settable in '
              'this phase.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: OpsTable(
            columns: const <OpsColumn>[
              OpsColumn(label: 'Setting', flex: 3),
              OpsColumn(label: 'Would require', flex: 4),
              OpsColumn(label: 'Status', flex: 2),
            ],
            rows: const <List<Widget>>[
              <Widget>[
                OpsTextCell('Occupancy pressure threshold'),
                OpsTextCell('Server-side hospital configuration'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Alert recipients'),
                OpsTextCell('A notification service'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Report schedule'),
                OpsTextCell('A reporting backend'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Ward and bed registry'),
                OpsTextCell('A bed-management or ADT system'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Real-time event subscription'),
                OpsTextCell('SSE, WebSocket or a message broker'),
                OpsTextCell(kNotAvailable),
              ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Available roles',
          subtitle: 'Presentation scope only. These grant no authorisation.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final role in OpsRole.values)
                OpsField(
                  label: role.shortLabel,
                  value: DemoOpsIdentity.forRole(role).staffId,
                  mono: true,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
