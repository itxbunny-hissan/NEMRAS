import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/federation_models.dart';
import '../data/geography.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 5 — Federation.
///
/// Every value on this screen is simulated. NEMRAS has no node agents, no
/// synchronisation protocol, no event stream and no national index, so the
/// screen's job is to show the shape a federation view would take while
/// never once implying the shape is populated with observations. The DEMO
/// marker appears in the page notice, on the tally card, on each KPI and in
/// every table row, because a marker shown once at the top of a long page is
/// a marker a scrolling reader will miss.
class FederationScreen extends StatelessWidget {
  const FederationScreen({super.key});

  /// Technologies a real federation would need, listed so the architecture
  /// intent is on the record without any of it being built.
  static const List<({String requirement, String detail})> _futureWork =
      <({String requirement, String detail})>[
    (
      requirement: 'Node agent',
      detail: 'Software at each hospital that reports its own sync state. '
          'Nothing reports today, so there is nothing to read.',
    ),
    (
      requirement: 'Event stream',
      detail: 'A broker carrying record-change events between hospitals and '
          'the national index. Not implemented in this phase.',
    ),
    (
      requirement: 'National index',
      detail: 'A record locator so a national query can find which node '
          'holds a record without copying it. Not implemented.',
    ),
    (
      requirement: 'Sync telemetry',
      detail: 'Measured lag, throughput and failure counts. Without it, any '
          'latency figure on this page would be invented.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.federationState.isLoading) {
      return const NationalLoadingState(
        message: 'Loading simulated federation state',
      );
    }
    if (controller.federationState.hasFailed) {
      return NationalErrorState(
        title: 'Federation state unavailable',
        message: controller.federationError ??
            'The demo federation provider returned an error.',
        onRetry: controller.refreshFederation,
      );
    }

    final snapshot = controller.federation;
    if (snapshot == null || snapshot.nodes.isEmpty) {
      return const NationalEmptyState(
        title: 'No federated nodes',
        message: 'The demo federation provider reported no nodes. No real '
            'federation exists to fall back to.',
        icon: Icons.hub_outlined,
      );
    }

    final now = controller.now;
    final tally = snapshot.tally;
    final flagged = snapshot.nodesNeedingAttention(now);

    return NationalContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Every value on this page is simulated',
          message: 'NEMRAS operates no federated infrastructure. The nodes '
              'below are generated locally with fixed values and are not '
              'named after real hospitals. Node identifiers, synchronisation '
              'times, record counts and health states are all DEMO. None of '
              'them was measured, and no network was contacted to produce '
              'them.',
        ),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: controller.federationOnlineKpi,
              icon: Icons.hub_outlined,
            ),
            NationalKpiCard(
              metric: controller.federationRecordsKpi,
              icon: Icons.sync_outlined,
            ),
            NationalKpiCard(
              metric: controller.networkLatencyKpi,
              icon: Icons.speed_outlined,
            ),
            NationalKpiCard(
              metric: controller.geographicCoverageKpi,
              icon: Icons.public_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalSectionHeader(
          title: 'Node health summary',
          subtitle: 'Simulated state captured '
              '${formatUtcTimestamp(snapshot.capturedAt)}.',
          trailing: const DemoChip(),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          accent: tally.needingAttention > 0
              ? semantics.elevated.solid
              : semantics.stable.solid,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NationalWrapGrid(
                minTileWidth: 150,
                children: <Widget>[
                  _TallyFigure(
                    label: 'Online',
                    value: tally.online,
                    status: semantics.stable,
                  ),
                  _TallyFigure(
                    label: 'Degraded',
                    value: tally.degraded,
                    status: semantics.elevated,
                  ),
                  _TallyFigure(
                    label: 'Offline',
                    value: tally.offline,
                    status: semantics.critical,
                  ),
                  _TallyFigure(
                    label: 'Total nodes',
                    value: tally.total,
                    status: semantics.informational,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.huge),
              NationalProgressBar(
                fraction: tally.onlineFraction,
                color: semantics.stable.solid,
                height: 10,
              ),
              const SizedBox(height: NemrasSpacing.m),
              Text(
                '${tally.onlinePercentLabel} of simulated nodes reporting '
                'normally. ${formatCount(tally.recordsSynchronized)} '
                'simulated records synchronised in total.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (flagged.isNotEmpty) ...<Widget>[
          const SizedBox(height: NemrasSpacing.xl),
          NationalAlertPanel(
            alert: NationalAlert(
              title: '${flagged.length} simulated node'
                  '${flagged.length == 1 ? '' : 's'} would need attention',
              detail: 'In a real federation these nodes would be '
                  'investigated. Nothing is actually degraded, because '
                  'nothing is actually running.',
              severity: NationalAlertSeverity.warning,
              provenance: controller.federationOnlineKpi.provenance,
            ),
          ),
        ],
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Federated nodes',
          subtitle: 'Node ID, hospital ID, status, last synchronisation, '
              'records synchronised and health state.',
          trailing: DemoChip(),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Node ID', flex: 2),
              NationalColumn(label: 'Hospital ID', flex: 2),
              NationalColumn(label: 'Status', flex: 2),
              NationalColumn(label: 'Last sync', flex: 2, alignEnd: true),
              NationalColumn(label: 'Records', flex: 2, alignEnd: true),
              NationalColumn(label: 'Health state', flex: 5),
              NationalColumn(label: 'Source', flex: 2),
            ],
            rows: <List<Widget>>[
              for (final node in snapshot.nodes)
                <Widget>[
                  NationalMonoCell(node.nodeId, emphasise: true),
                  NationalMonoCell(node.hospitalId),
                  NationalStatusPill(
                    label: node.health.label,
                    status: _statusFor(node.health, semantics),
                  ),
                  NationalMonoCell(node.stalenessLabel(now)),
                  NationalMonoCell(formatCount(node.recordsSynchronized)),
                  NationalTextCell(node.health.meaning),
                  if (node.isDemo)
                    const DemoChip()
                  else
                    const NationalTextCell(kNotAvailable, maxLines: 1),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Last synchronisation times are relative to the dashboard clock '
          'and are generated, not observed. Node names are deliberately '
          'identifiers rather than hospital names, so no real facility is '
          'shown beside a simulated figure.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'What a real federation would require',
          subtitle: 'Recorded as architecture intent. None of it is built in '
              'this phase.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: 'No federated infrastructure is connected',
          explanation: 'The interface behind this screen is a repository '
              'boundary, so a future transport can supply the same model '
              'without any screen changing. Nothing is implemented behind it '
              'today beyond the local demo provider.',
          requirements: _futureWork,
          icon: Icons.hub_outlined,
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const UnavailablePanel(
          headline: GeographicAvailability.notice,
          explanation: 'The reference node table carries a province column. '
              'It is omitted here: no node, hospital or record in NEMRAS '
              'carries a location, so the column could only be filled by '
              'guessing.',
          icon: Icons.public_off_outlined,
        ),
      ],
    );
  }

  static NemrasStatusColor _statusFor(
    NodeHealth health,
    NemrasSemantics semantics,
  ) {
    switch (health) {
      case NodeHealth.online:
        return semantics.stable;
      case NodeHealth.degraded:
        return semantics.elevated;
      case NodeHealth.offline:
        return semantics.critical;
    }
  }
}

/// One count in the node health summary.
class _TallyFigure extends StatelessWidget {
  const _TallyFigure({
    required this.label,
    required this.value,
    required this.status,
  });

  final String label;
  final int value;
  final NemrasStatusColor status;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NationalLabel(label),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          '$value',
          style: NemrasTextStyles.metricValue.copyWith(color: status.onSoft),
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          'simulated',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
      ],
    );
  }
}
