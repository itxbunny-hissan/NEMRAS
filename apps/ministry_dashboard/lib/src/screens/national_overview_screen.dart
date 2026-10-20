import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/analyst_identity.dart';
import '../data/geography.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';
import 'emergency_map_screen.dart';

/// Screen 1 — National Overview.
///
/// Answers "what is happening across the NEMRAS national data ecosystem?" as
/// honestly as the data allows. Every indicator declares its provenance, and
/// the panel where the reference dashboard draws a regional burden map
/// instead states that no geographic breakdown is possible.
class NationalOverviewScreen extends StatelessWidget {
  const NationalOverviewScreen({super.key, this.onNavigate});

  /// Switches the shell's sidebar destination. Null when the screen is shown
  /// outside the shell, in which case the cross-links are not drawn.
  final ValueChanged<int>? onNavigate;

  static const List<IconData> _operationsIcons = <IconData>[
    Icons.emergency_share_outlined,
    Icons.call_received_outlined,
    Icons.bed_outlined,
    Icons.timer_outlined,
  ];

  static const List<IconData> _kpiIcons = <IconData>[
    Icons.storage_outlined,
    Icons.emergency_outlined,
    Icons.priority_high_outlined,
    Icons.local_hospital_outlined,
    Icons.monitor_heart_outlined,
    Icons.category_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final kpis = controller.overviewKpis;
    final alerts = controller.alerts;

    final criticalAlerts = alerts
        .where((a) => a.severity == NationalAlertSeverity.critical)
        .length;

    return NationalContentArea(
      children: <Widget>[
        const _SimulationBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        _CommandHeader(criticalAlerts: criticalAlerts),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalSectionHeader(
          title: 'Operations headline',
          subtitle: 'The live figures a national command centre would lead '
              'with. NEMRAS receives no dispatch, CAD or bed feed, so none '
              'can be shown.',
          trailing: const ProvenanceBadge(MetricProvenance.unavailable),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (var i = 0; i < controller.operationsKpis.length; i++)
              NationalKpiCard(
                metric: controller.operationsKpis[i],
                icon: _operationsIcons[i],
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const ProvenanceNotice(
          title: 'How to read this page',
          message: 'NEMRAS holds a corpus of patient records, not a national '
              'health register. Figures marked DATASET-DERIVED are counts of '
              'records in NEMRAS_Dataset.csv and are not national population '
              'statistics: a condition count is not a prevalence, and a '
              'record total is not a count of people in Pakistan. Figures '
              'marked DEMO are simulated locally and no national '
              'infrastructure is connected.',
        ),
        if (controller.snapshotState.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: NemrasSpacing.xxl),
            child: NationalLoadingState(
              message: 'Reading national aggregates',
            ),
          ),
        if (controller.snapshotState.hasFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: NemrasSpacing.xxl),
            child: NationalCard(
              accent: semantics.critical.solid,
              child: NationalErrorState(
                title: 'National aggregates unavailable',
                message: controller.snapshotError ??
                    'The NEMRAS backend could not be reached.',
                onRetry: controller.refreshSnapshot,
              ),
            ),
          ),
        NationalSectionHeader(
          title: 'National indicators',
          subtitle: 'Six aggregate indicators, each labelled with its data '
              'source.',
          trailing: controller.environment.isDemo ? const DemoChip() : null,
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (var i = 0; i < kpis.length; i++)
              NationalKpiCard(
                metric: kpis[i],
                icon: i < _kpiIcons.length ? _kpiIcons[i] : null,
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: controller.emergencyShareKpi,
              icon: Icons.percent_outlined,
              unitSuffix: '%',
            ),
            NationalKpiCard(
              metric: controller.averageAgeKpi,
              icon: Icons.cake_outlined,
              unitSuffix: ' yrs',
            ),
            NationalKpiCard(
              metric: controller.networkLatencyKpi,
              icon: Icons.speed_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalSplitPanels(
          primary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalSectionHeader(
                title: 'Incident inflow',
                subtitle: 'The reference charts arrivals over 24 hours here.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              _LinkedUnavailableCard(
                message: 'Not available. No endpoint groups emergency '
                    'records by time, so no inflow curve or peak is drawn.',
                linkLabel: 'Open emergency trends',
                onTap: onNavigate == null
                    ? null
                    : () => onNavigate!(
                          NationalNavigation.emergencyTrendsIndex,
                        ),
              ),
              const SizedBox(height: NemrasSpacing.section),
              // Where the reference draws "Regional Disease Burden". The
              // dataset supports no such view, so the slot states that
              // plainly rather than rendering a map of invented numbers.
              const NationalSectionHeader(
                title: 'Regional distribution',
                subtitle: 'The reference dashboard shows a regional burden '
                    'map here.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              const UnavailablePanel(
                headline: GeographicAvailability.notice,
                explanation: GeographicAvailability.explanation,
                requirements: GeographicAvailability.requirements,
                icon: Icons.public_off_outlined,
              ),
              const SizedBox(height: NemrasSpacing.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    EmergencyMapScreen.route(),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Open emergency map'),
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const NationalSectionHeader(
                title: 'Governance and data-quality alerts',
                subtitle: 'Raised by fixed threshold rules, not by a model.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              for (final alert in alerts) NationalAlertPanel(alert: alert),
              const _EscalationActions(),
            ],
          ),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LinkedUnavailableCard(
                title: 'Audit ledger',
                message: 'No cryptographic or consensus ledger exists. '
                    'Governance events are held in the NEMRAS audit '
                    'repository.',
                linkLabel: 'Open audit / governance',
                onTap: onNavigate == null
                    ? null
                    : () => onNavigate!(NationalNavigation.governanceIndex),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const NationalSectionHeader(
                title: 'Most frequent conditions',
                subtitle: 'Free-text condition names, not ICD-coded '
                    'categories.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              NationalDistributionCard(
                distribution: controller.conditionDistribution,
                limit: 8,
                color: semantics.informational.solid,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              _FederationSummaryCard(controller: controller),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Dataset composition',
          subtitle: 'Population breakdowns from GET /api/stats.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.triageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.riskDistribution,
            order: const <String>['Critical', 'Elevated', 'Stable'],
            color: semantics.elevated.solid,
          ),
        ),
      ],
    );
  }
}

/// The persistent prototype banner the reference places above every
/// national dashboard.
class _SimulationBanner extends StatelessWidget {
  const _SimulationBanner();

  @override
  Widget build(BuildContext context) {
    final critical = NemrasSemantics.of(context).critical;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: critical.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border.all(color: critical.solid),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.warning_amber_outlined, size: 18, color: critical.solid),
          const SizedBox(width: NemrasSpacing.m),
          Expanded(
            child: Text(
              'PROTOTYPE DATA. Not live Pakistan emergency statistics. '
              'Figures are dataset-derived or simulated for demonstration.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: critical.onSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Title, period and scope. Only the full-dataset period exists, so the
/// reference's rolling windows are drawn disabled.
class _CommandHeader extends StatelessWidget {
  const _CommandHeader({required this.criticalAlerts});

  final int criticalAlerts;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const NationalLabel('Federated command centre'),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'National Emergency Operations Command',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Aggregates from NEMRAS_Dataset.csv. No live dispatch, CAD or '
          'hospital feed is connected.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Full dataset'),
              selected: true,
              onSelected: (_) {},
            ),
            for (final window in const <String>[
              'Past 24 hours',
              'Past 7 days',
              'Past 30 days',
            ])
              ChoiceChip(
                label: Text(window),
                selected: false,
                onSelected: null,
              ),
            const ChoiceChip(
              label: Text('Nationwide · no regional filter'),
              selected: false,
              onSelected: null,
            ),
            NationalStatusPill(
              label: '$criticalAlerts CRITICAL RULE '
                  '${criticalAlerts == 1 ? 'ALERT' : 'ALERTS'}',
              status: criticalAlerts > 0
                  ? semantics.critical
                  : semantics.informational,
              icon: Icons.rule,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Rolling windows are not available: no endpoint groups records by '
          'date. A regional filter is not available: the dataset has no '
          'location field.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// An unavailable panel with an optional link to the related destination.
class _LinkedUnavailableCard extends StatelessWidget {
  const _LinkedUnavailableCard({
    this.title,
    required this.message,
    required this.linkLabel,
    required this.onTap,
  });

  final String? title;
  final String message;
  final String linkLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: NationalLabel(title!)),
                const ProvenanceBadge(MetricProvenance.unavailable),
              ],
            ),
            const SizedBox(height: NemrasSpacing.l),
          ],
          Text(
            message,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(height: NemrasSpacing.l),
            TextButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: Text(linkLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Where the reference offers diversion and ICU coordination buttons.
class _EscalationActions extends StatelessWidget {
  const _EscalationActions();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NationalLabel('Inter-hospital escalations'),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No dispatch, diversion or ICU coordination feed is connected, '
            'so no incident escalation is listed.',
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
                child: Text('Coordinating a diversion is not available'),
              ),
              OutlinedButton(
                onPressed: null,
                child: Text('Confirming ICU beds is not available'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact federation summary, flagged demo throughout.
class _FederationSummaryCard extends StatelessWidget {
  const _FederationSummaryCard({required this.controller});

  final NationalConsoleController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    if (controller.federationState.isLoading) {
      return const NationalCard(child: NationalLoadingState());
    }
    if (controller.federationState.hasFailed) {
      return NationalCard(
        accent: semantics.critical.solid,
        child: NationalErrorState(
          title: 'Federation state unavailable',
          message: controller.federationError ??
              'The demo federation provider returned an error.',
          onRetry: controller.refreshFederation,
        ),
      );
    }

    final tally = controller.federationTally;
    if (tally == null || tally.total == 0) {
      return const NationalCard(
        child: NationalEmptyState(
          title: 'No federation nodes',
          message: 'The demo federation provider reported no nodes.',
          icon: Icons.hub_outlined,
        ),
      );
    }

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: NationalLabel('Federated nodes')),
              const DemoChip(),
            ],
          ),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            '${tally.online} / ${tally.total}',
            style: NemrasTextStyles.metricValue.copyWith(
              color: semantics.textPrimary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            'Simulated nodes reporting normally '
            '(${tally.onlinePercentLabel}).',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          NationalProgressBar(
            fraction: tally.onlineFraction,
            color: semantics.stable.solid,
            height: 10,
          ),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            '${tally.degraded} degraded · ${tally.offline} offline',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No federated infrastructure exists. These values are '
            'simulated.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
