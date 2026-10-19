import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/analyst_identity.dart';
import '../data/geography.dart';
import '../data/metric_provenance.dart';
import '../data/national_api_client.dart';
import '../data/national_models.dart';
import '../admin/admin_shell.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 8 — Settings.
///
/// A disclosure screen rather than a preferences screen. It states the demo
/// identity in use, which endpoints the dashboard reads, which figures are
/// simulated, and what this build does not enforce. There are no toggles: a
/// setting that changed nothing would be worse than no setting.
class NationalSettingsScreen extends StatelessWidget {
  const NationalSettingsScreen({super.key});

  /// Endpoints this surface reads, and what it takes from each.
  static const List<({String route, String use, String privacy})> _endpoints =
      <({String route, String use, String privacy})>[
    (
      route: 'GET /api/stats',
      use: 'Every dataset-derived count and the dataset mean age.',
      privacy: 'Aggregate only. Returns no patient field of any kind.',
    ),
    (
      route: 'GET /api/dashboard/critical',
      use: 'The highest-risk slice, used for the two sample distributions.',
      privacy: 'Patient-level. Reduced to age and categorical clinical '
          'fields at the parse boundary; CNIC and name are never read into '
          'this app.',
    ),
    (
      route: 'GET /health',
      use: 'The data-source status indicator in the status strip.',
      privacy: 'Returns service state only.',
    ),
  ];

  /// What this build deliberately does not do.
  static const List<({String requirement, String detail})> _notEnforced =
      <({String requirement, String detail})>[
    (
      requirement: 'Production authentication',
      detail: 'The analyst identity below is a demo profile. It is not a '
          'credential, it authorises nothing, and no sign-in occurred.',
    ),
    (
      requirement: 'Backend authorisation',
      detail: 'A production national surface must have the backend decide '
          'and audit every read. UI scoping is not a security boundary.',
    ),
    (
      requirement: 'Persistent audit',
      detail: 'The national audit trail is in memory for this session and is '
          'lost on reload.',
    ),
    (
      requirement: 'Federated infrastructure',
      detail: 'No node agents, event stream, cache, national index or FHIR '
          'store exists. Federation figures are generated locally.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final analyst = controller.analyst;

    return NationalContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'This is a disclosure screen',
          message: 'It records what this build reads, what it simulates and '
              'what it does not enforce, so none of that has to be inferred '
              'from the dashboard itself.',
        ),
        NationalSplitPanels(
          primary: NationalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                NationalSectionHeader(
                  title: 'Analyst identity',
                  subtitle: analyst.role.dataScope,
                  trailing: analyst.isDemo ? const DemoChip() : null,
                ),
                const SizedBox(height: NemrasSpacing.xxl),
                NationalField(label: 'Display name', value: analyst.displayLabel),
                NationalField(label: 'Role', value: analyst.role.label),
                NationalField(
                  label: 'Analyst ID',
                  value: analyst.analystId,
                  mono: true,
                ),
                NationalField(
                  label: 'Organisation ID',
                  value: analyst.organizationId,
                  mono: true,
                ),
                NationalField(
                  label: 'Firebase UID',
                  value: analyst.firebaseUid,
                  mono: true,
                ),
                Text(
                  'Firebase UID remains the identity identifier across '
                  'NEMRAS. CNIC is a patient identifier and is never used as '
                  'an identity, and never appears on this surface at all.',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          secondary: NationalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const NationalSectionHeader(
                  title: 'Build and data source',
                  subtitle: 'Where this dashboard reads from.',
                ),
                const SizedBox(height: NemrasSpacing.xxl),
                NationalField(
                  label: 'Environment',
                  value: controller.environment.label,
                ),
                NationalField(
                  label: 'Aggregate API',
                  value: kBaseUrl,
                  mono: true,
                ),
                NationalField(
                  label: 'Data source status',
                  value: controller.dataSourceStatus.label,
                ),
                NationalField(
                  label: 'Reporting period',
                  value: controller.reportingPeriod.label,
                ),
                NationalField(
                  label: 'Data as of',
                  value: controller.snapshot == null
                      ? kNotAvailable
                      : formatUtcTimestamp(controller.snapshot!.capturedAt),
                  mono: true,
                ),
                Text(
                  controller.reportingPeriod.detail,
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Endpoints read by this surface',
          subtitle: 'No new backend route was added for this phase.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Endpoint', flex: 3),
              NationalColumn(label: 'What it supplies', flex: 4),
              NationalColumn(label: 'Privacy position', flex: 5),
            ],
            rows: <List<Widget>>[
              for (final endpoint in _endpoints)
                <Widget>[
                  NationalMonoCell(endpoint.route, emphasise: true),
                  NationalTextCell(endpoint.use),
                  NationalTextCell(endpoint.privacy),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Provenance vocabulary',
          subtitle: 'What each badge on this dashboard means.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Badge', flex: 2),
              NationalColumn(label: 'Meaning', flex: 7),
            ],
            rows: <List<Widget>>[
              for (final provenance in MetricProvenance.values)
                <Widget>[
                  ProvenanceBadge(provenance),
                  NationalTextCell(provenance.explanation),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Not enforced by this build',
          subtitle: 'Stated here so it is on the record.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: 'This is a final-year demonstration build',
          explanation: 'It is not a production national health system. The '
              'items below would all have to be in place before anything on '
              'this dashboard could inform a real decision.',
          requirements: _notEnforced,
          icon: Icons.policy_outlined,
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const UnavailablePanel(
          headline: GeographicAvailability.notice,
          explanation: GeographicAvailability.explanation,
          requirements: GeographicAvailability.requirements,
          icon: Icons.public_off_outlined,
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Administration console'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'A separate demonstration console. It does not replace this '
                'dashboard and it does not authorise any account.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.of(context).push(AdminShell.route()),
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 16),
                  label: const Text('Open administration console'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
