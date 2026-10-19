import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/governance_models.dart';
import '../data/metric_provenance.dart';
import '../screens/governance_screen.dart';
import '../screens/hospital_network_screen.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';
import 'admin_navigation.dart';

/// Stitch Screen 35 — national administration overview.
///
/// The reference shows a live verification queue, hospital census and fleet.
/// None of those registries exist. The figures that do exist are the session
/// audit trail and, when an endpoint supplies it, a facility record count.
class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key, this.onOpenSection});

  /// Switches the administration sidebar. Null when the screen is shown alone.
  final ValueChanged<int>? onOpenSection;

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final summary = controller.hospitalSummary;
    final hospitalsKnown = summary != null && summary.isAvailable;
    final events = controller.auditEvents.take(4).toList();

    return NationalContentArea(
      children: <Widget>[
        const _AdminBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'National administration',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Demonstration metrics. No identity registry, fleet or live '
          'security feed is connected.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Pending verification',
                basis: 'No verification queue is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: hospitalsKnown
                  ? NationalMetric.datasetAggregate(
                      label: 'Facilities in the aggregate',
                      value: summary.facilityCount,
                      basis: 'Rows from the hospital aggregate endpoint',
                      caption:
                          'Record counts. Not a count of hospitals online.',
                    )
                  : NationalMetric.unavailable(
                      label: 'Connected hospitals',
                      basis: 'No hospital aggregate endpoint is available',
                      caption: 'Not available.',
                    ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Registered responders',
                basis: 'No responder or fleet registry is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: controller.auditState.isReady
                  ? NationalMetric.demo(
                      label: 'Break-glass events in session audit',
                      value: controller.emergencyAccessCount,
                      basis: 'In-memory national audit trail',
                      caption:
                          'Demo events. Not a live security anomaly count.',
                    )
                  : NationalMetric.unavailable(
                      label: 'Break-glass events in session audit',
                      basis: 'The session audit has not loaded',
                    ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Pending verification queue'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No verification dossiers are recorded.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const Wrap(
                spacing: NemrasSpacing.s,
                runSpacing: NemrasSpacing.s,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: null,
                    child: Text('Filtering the queue is not available'),
                  ),
                  FilledButton(
                    onPressed: null,
                    child: Text('Batch verification is not available'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Expanded(child: NationalLabel('Administrative stream')),
                  DemoChip(),
                ],
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                events.isEmpty
                    ? 'No audit events are recorded for this session.'
                    : 'Session audit events. Not a live enclave ledger.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              for (final event in events) ...<Widget>[
                const SizedBox(height: NemrasSpacing.l),
                Text(
                  event.action.label,
                  style: NemrasTextStyles.listTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
                Text(
                  '${event.actorId}  ·  ${formatUtcTimestamp(event.timestamp)}',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Registries',
          subtitle: 'The reference offers four command centers here.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          minTileWidth: 220,
          children: <Widget>[
            _RegistryCard(
              title: 'User and role directory',
              detail: 'No account registry is connected.',
              action: 'Open user verification',
              onPressed: onOpenSection == null
                  ? null
                  : () => onOpenSection!(AdminNavigation.verificationIndex),
            ),
            _RegistryCard(
              title: 'Hospital accreditation',
              detail: 'No accreditation registry is connected. The national '
                  'hospital screen shows record counts only.',
              action: 'Open hospital network',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('Hospital network'),
                      leading: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    body: const HospitalNetworkScreen(),
                  ),
                ),
              ),
            ),
            const _RegistryCard(
              title: 'Fleet dispatch',
              detail: 'No responder or ambulance registry is connected.',
              action: 'Fleet registry is not available',
            ),
            _RegistryCard(
              title: 'Session audit',
              detail: 'The national audit trail is in memory for this '
                  'session. It is not a signed statutory archive.',
              action: 'Open national audit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      title: const Text('National audit'),
                      leading: IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    body: const GovernanceScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminBanner extends StatelessWidget {
  const _AdminBanner();

  @override
  Widget build(BuildContext context) {
    final elevated = NemrasSemantics.of(context).elevated;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: elevated.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border.all(color: elevated.solid),
      ),
      child: Text(
        'DEMO PROTOTYPE. Not a live administration console. No identity '
        'authority is connected.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RegistryCard extends StatelessWidget {
  const _RegistryCard({
    required this.title,
    required this.detail,
    required this.action,
    this.onPressed,
  });

  final String title;
  final String detail;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NationalLabel(title),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            detail,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: onPressed == null
                ? OutlinedButton(onPressed: null, child: Text(action))
                : TextButton(onPressed: onPressed, child: Text(action)),
          ),
        ],
      ),
    );
  }
}
