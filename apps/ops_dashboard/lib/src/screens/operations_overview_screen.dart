import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/admin_identity.dart';
import '../data/metric_provenance.dart';
import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 1 — Hospital Operations Overview.
///
/// Answers "what is happening across this hospital right now?" as honestly as
/// NEMRAS can. Three of the six KPIs are dataset record counts, two are
/// simulated, and one has no source at all and says so. Each card carries its
/// own provenance badge, so the panel cannot be read as six live figures.
class OperationsOverviewScreen extends StatelessWidget {
  const OperationsOverviewScreen({super.key});

  static const List<IconData> _kpiIcons = <IconData>[
    Icons.emergency_outlined,
    Icons.login_outlined,
    Icons.bed_outlined,
    Icons.meeting_room_outlined,
    Icons.local_shipping_outlined,
    Icons.priority_high_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final kpis = controller.overviewKpis;
    final alerts = controller.alerts;

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'How to read this page',
          message: 'NEMRAS holds a corpus of patient records, not a feed of '
              'hospital telemetry. Figures marked DATASET-DERIVED are counts '
              'of records in NEMRAS_Dataset.csv and are not current hospital '
              'statistics. Figures marked DEMO are simulated by a local '
              'provider and no hospital system is connected.',
        ),
        if (controller.snapshotState.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: NemrasSpacing.xxl),
            child: OpsLoadingState(message: 'Reading dataset aggregates'),
          ),
        if (controller.snapshotState.hasFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: NemrasSpacing.xxl),
            child: OpsCard(
              accent: semantics.critical.solid,
              child: OpsErrorState(
                title: 'Dataset figures unavailable',
                message: controller.snapshotError ??
                    'The NEMRAS backend could not be reached.',
                onRetry: controller.refreshSnapshot,
              ),
            ),
          ),
        OpsSectionHeader(
          title: 'Operational indicators',
          subtitle: 'Six indicators, each labelled with its data source.',
          trailing: controller.environment.isDemo ? const DemoChip() : null,
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsWrapGrid(
          children: <Widget>[
            for (var i = 0; i < kpis.length; i++)
              OpsKpiCard(
                metric: kpis[i],
                icon: i < _kpiIcons.length ? _kpiIcons[i] : null,
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        OpsSplitPanels(
          primary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const OpsSectionHeader(
                title: 'Operational alerts',
                subtitle: 'Raised by fixed threshold rules, not by a model.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              if (alerts.isEmpty)
                const OpsCard(
                  child: OpsEmptyState(
                    title: 'No operational alerts',
                    message: 'No ward is above the occupancy threshold, no '
                        'handover is awaiting acceptance, and no '
                        'break-glass access is pending review.',
                    icon: Icons.check_circle_outline,
                  ),
                )
              else
                for (final alert in alerts) OpsAlertPanel(alert: alert),
            ],
          ),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const OpsSectionHeader(
                title: 'Handover workflow',
                subtitle: 'Demo provider. No live paramedic link exists.',
              ),
              const SizedBox(height: NemrasSpacing.xxl),
              _HandoverTallyCard(controller: controller),
              const SizedBox(height: NemrasSpacing.xl),
              _DatasetScaleCard(controller: controller),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        OpsSectionHeader(
          title: 'Dataset composition',
          subtitle: 'Population breakdowns from GET /api/stats.',
          trailing: const ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.triageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.riskDistribution,
            order: const <String>['Critical', 'Elevated', 'Stable'],
            color: semantics.elevated.solid,
          ),
        ),
      ],
    );
  }
}

/// The four handover workflow counts.
class _HandoverTallyCard extends StatelessWidget {
  const _HandoverTallyCard({required this.controller});

  final OpsConsoleController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    if (controller.handoverState.isLoading) {
      return const OpsCard(child: OpsLoadingState());
    }
    if (controller.handoverState.hasFailed) {
      return OpsCard(
        accent: semantics.critical.solid,
        child: OpsErrorState(
          title: 'Handover state unavailable',
          message: controller.handoverError ??
              'The demo handover provider returned an error.',
          onRetry: controller.refreshHandovers,
        ),
      );
    }

    final tally = controller.handoverTally;

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: OpsLabel('Handover states')),
              const DemoChip(),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          _TallyRow(
            label: 'Incoming',
            value: tally.incoming,
            color: semantics.critical.solid,
          ),
          _TallyRow(
            label: 'Accepted',
            value: tally.accepted,
            color: semantics.elevated.solid,
          ),
          _TallyRow(
            label: 'In progress',
            value: tally.inProgress,
            color: semantics.informational.solid,
          ),
          _TallyRow(
            label: 'Completed',
            value: tally.completed,
            color: semantics.stable.solid,
          ),
          Divider(color: semantics.divider),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            '${tally.total} demo cases, ${tally.active} consuming clinical '
            'capacity.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TallyRow extends StatelessWidget {
  const _TallyRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.l),
      child: Row(
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: NemrasSpacing.m),
          Expanded(
            child: Text(
              label,
              style: NemrasTextStyles.body.copyWith(
                color: semantics.textPrimary,
              ),
            ),
          ),
          Text(
            '$value',
            style: NemrasTextStyles.dataValue.copyWith(
              color: semantics.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The dataset size, stated as a record count.
class _DatasetScaleCard extends StatelessWidget {
  const _DatasetScaleCard({required this.controller});

  final OpsConsoleController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final metric = controller.datasetSizeKpi;

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: OpsLabel('Dataset scale')),
              ProvenanceBadge(metric.provenance),
            ],
          ),
          const SizedBox(height: NemrasSpacing.m),
          Text(
            metric.isAvailable
                ? '${metric.displayValue} dataset records'
                : kNotAvailable,
            style: NemrasTextStyles.summaryName.copyWith(
              color: metric.isAvailable
                  ? semantics.textPrimary
                  : semantics.textPlaceholder,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            'Rows in NEMRAS_Dataset.csv. This is not a count of patients '
            'currently in this hospital.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          OpsField(
            label: 'Average recorded age',
            value: controller.stats?.averageAgeLabel ?? kNotAvailable,
            mono: true,
          ),
        ],
      ),
    );
  }
}
