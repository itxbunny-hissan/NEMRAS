import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/handover_models.dart';
import '../data/metric_provenance.dart';
import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screens 2 and 6 — Emergency Operations and the Handover Monitor.
///
/// The two live behind one sidebar destination because the sidebar is fixed at
/// nine items and both views answer the same operational question. They are
/// kept as separate tabs rather than merged because their provenance differs
/// completely: emergency case data is dataset-derived, while arrival and
/// handover state exists only in the demo provider.
class EmergencyOperationsScreen extends StatefulWidget {
  const EmergencyOperationsScreen({super.key});

  @override
  State<EmergencyOperationsScreen> createState() =>
      _EmergencyOperationsScreenState();
}

class _EmergencyOperationsScreenState extends State<EmergencyOperationsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NemrasSpacing.section,
            vertical: NemrasSpacing.m,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: semantics.divider)),
          ),
          child: Row(
            children: <Widget>[
              _TabButton(
                label: 'Active emergency cases',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: NemrasSpacing.s),
              _TabButton(
                label: 'Handover monitor',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: _tab == 0
              ? const _EmergencyCasesView()
              : const _HandoverMonitorView(),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: NemrasRadii.controlBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NemrasSpacing.xl,
          vertical: NemrasSpacing.m,
        ),
        decoration: BoxDecoration(
          color: selected ? semantics.accent : Colors.transparent,
          borderRadius: NemrasRadii.controlBorder,
        ),
        child: Text(
          label,
          style: NemrasTextStyles.button.copyWith(
            color: selected ? semantics.onAccent : semantics.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Emergency cases drawn from the dataset.
class _EmergencyCasesView extends StatelessWidget {
  const _EmergencyCasesView();

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const OpsLoadingState(message: 'Reading emergency case data');
    }
    if (controller.snapshotState.hasFailed) {
      return OpsErrorState(
        title: 'Emergency case data unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }

    final feed = controller.riskFeed;
    final stats = controller.stats;
    if (feed == null || stats == null) {
      return const OpsEmptyState(
        title: 'No emergency case data',
        message: 'The dataset aggregates have not been loaded.',
      );
    }

    // The highest-risk feed is the only per-case data the backend exposes.
    // Narrowing it to emergency admissions keeps the table on topic, and the
    // count below states plainly that this is a slice.
    final emergencyRows = feed.rows
        .where((row) => row.admissionType == 'Emergency')
        .toList();

    return OpsContentArea(
      children: <Widget>[
        ProvenanceNotice(
          title: 'Scope of this page',
          message: 'The population figure below counts every record in the '
              'dataset with Admission_Type = Emergency. The case table shows '
              'only the ${feed.length} highest-risk records the backend '
              'returns, which is a bounded sample skewed towards severe cases '
              'by construction. Arrival time, ambulance destination and '
              'handover state are not recorded in the dataset; those appear '
              'on the Handover monitor tab, where they are simulated.',
        ),
        OpsWrapGrid(
          children: <Widget>[
            OpsKpiCard(
              metric: controller.emergencyCasesKpi,
              icon: Icons.emergency_outlined,
            ),
            OpsKpiCard(
              metric: controller.criticalCasesKpi,
              icon: Icons.priority_high_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.datasetSample(
                label: 'Emergency in Risk Slice',
                value: emergencyRows.length,
                basis: 'Of ${feed.length} highest-risk records',
                sampleSize: feed.length,
                caption: 'A bounded sample, not a hospital count.',
              ),
              icon: Icons.filter_alt_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Mean Arrival-to-Triage',
                basis: 'No arrival or triage timestamps in NEMRAS',
                caption: 'Requires an emergency department timing source.',
              ),
              icon: Icons.timer_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        OpsSectionHeader(
          title: 'Highest-risk emergency records',
          subtitle: 'Sorted by risk tier by the backend. Patient identifiers '
              'are masked to a case reference.',
          trailing: const ProvenanceBadge(MetricProvenance.datasetSample),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: emergencyRows.isEmpty
              ? const OpsEmptyState(
                  title: 'No emergency records in this slice',
                  message: 'None of the highest-risk records returned by the '
                      'backend has Admission_Type = Emergency.',
                )
              : OpsTable(
                  columns: const <OpsColumn>[
                    OpsColumn(label: 'Case reference', flex: 3),
                    OpsColumn(label: 'Condition', flex: 3),
                    OpsColumn(label: 'Age', flex: 1),
                    OpsColumn(label: 'Triage', flex: 2),
                    OpsColumn(label: 'Risk category', flex: 2),
                    OpsColumn(label: 'Handover status', flex: 2),
                    OpsColumn(label: 'Destination', flex: 2),
                  ],
                  rows: <List<Widget>>[
                    for (final row in emergencyRows)
                      <Widget>[
                        OpsMonoCell(row.caseReference, emphasise: true),
                        OpsTextCell(row.medicalCondition),
                        OpsMonoCell(row.ageLabel),
                        OpsStatusPill(
                          label: row.triageLevel,
                          status: semantics.triage(row.triageLevel),
                        ),
                        OpsStatusPill(
                          label: row.riskScore,
                          status: semantics.risk(row.riskScore),
                        ),
                        // The dataset records neither of these. Leaving the
                        // columns in place and empty states the gap, where
                        // dropping them would hide it.
                        const OpsTextCell(kNotAvailable),
                        const OpsTextCell(kNotAvailable),
                      ],
                  ],
                ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.riskFeedTriageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.admissionTypeDistribution,
            color: semantics.informational.solid,
          ),
        ),
      ],
    );
  }
}

/// The demo handover monitor.
class _HandoverMonitorView extends StatelessWidget {
  const _HandoverMonitorView();

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.handoverState.isLoading) {
      return const OpsLoadingState(message: 'Reading handover state');
    }
    if (controller.handoverState.hasFailed) {
      return OpsErrorState(
        title: 'Handover state unavailable',
        message: controller.handoverError ??
            'The demo handover provider returned an error.',
        onRetry: controller.refreshHandovers,
      );
    }

    final entries = controller.handoverEntries;
    final tally = controller.handoverTally;
    final now = controller.now;

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Demo handover state',
          message: 'Every case below is produced by a local demo provider. '
              'This dashboard is not connected to the Hospital Clinical '
              'Desktop or to any paramedic application through an event bus, '
              'a queue or a shared store. Identifiers match the format those '
              'applications use so a later integration maps onto the same '
              'fields, which is not the same as an existing link. Ambulance '
              'position, ETA and GPS are not modelled at all.',
        ),
        OpsWrapGrid(
          children: <Widget>[
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Incoming',
                value: tally.incoming,
                basis: 'Awaiting clinical acceptance',
                caption: 'Simulated handover state.',
              ),
              icon: Icons.call_received_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Accepted',
                value: tally.accepted,
                basis: 'Accepted, awaiting assessment',
                caption: 'Simulated handover state.',
              ),
              icon: Icons.assignment_turned_in_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'In Progress',
                value: tally.inProgress,
                basis: 'Under active treatment',
                caption: 'Simulated handover state.',
              ),
              icon: Icons.medical_services_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Completed',
                value: tally.completed,
                basis: 'Encounter closed',
                caption: 'Simulated handover state.',
              ),
              icon: Icons.task_alt_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Handover queue',
          subtitle: 'Newest first. Read-only: case transitions are performed '
              'in the clinical application, not here.',
          trailing: DemoChip(),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: entries.isEmpty
              ? const OpsEmptyState(
                  title: 'No handovers',
                  message: 'The demo provider is reporting an empty queue.',
                  icon: Icons.inbox_outlined,
                )
              : OpsTable(
                  columns: const <OpsColumn>[
                    OpsColumn(label: 'Emergency ID', flex: 3),
                    OpsColumn(label: 'Case reference', flex: 3),
                    OpsColumn(label: 'Triage', flex: 2),
                    OpsColumn(label: 'Risk category', flex: 2),
                    OpsColumn(label: 'Destination', flex: 3),
                    OpsColumn(label: 'Status', flex: 2),
                    OpsColumn(label: 'Accepted by', flex: 2),
                    OpsColumn(label: 'Open for', flex: 2, alignEnd: true),
                  ],
                  rows: <List<Widget>>[
                    for (final entry in entries)
                      <Widget>[
                        OpsMonoCell(entry.emergencyId, emphasise: true),
                        OpsMonoCell(entry.caseReference),
                        OpsStatusPill(
                          label: entry.triageLevel,
                          status: semantics.triage(entry.triageLevel),
                        ),
                        OpsStatusPill(
                          label: entry.riskCategory,
                          status: semantics.risk(entry.riskCategory),
                        ),
                        OpsTextCell(entry.destinationWard),
                        OpsStatusPill(
                          label: entry.status.label,
                          status: _statusColour(entry.status, semantics),
                          solid: entry.status.isPending,
                        ),
                        OpsMonoCell(entry.acceptedByLabel),
                        OpsMonoCell(entry.waitingLabel(now)),
                      ],
                  ],
                ),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const OpsLabel('What each status means'),
              const SizedBox(height: NemrasSpacing.l),
              for (final status in HandoverStatus.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: NemrasSpacing.m),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        child: OpsStatusPill(
                          label: status.label,
                          status: _statusColour(status, semantics),
                        ),
                      ),
                      const SizedBox(width: NemrasSpacing.l),
                      Expanded(
                        child: Text(
                          status.operationalMeaning,
                          style: NemrasTextStyles.bodySmall.copyWith(
                            color: semantics.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static NemrasStatusColor _statusColour(
    HandoverStatus status,
    NemrasSemantics semantics,
  ) {
    switch (status) {
      case HandoverStatus.incoming:
        return semantics.critical;
      case HandoverStatus.accepted:
        return semantics.elevated;
      case HandoverStatus.inProgress:
        return semantics.informational;
      case HandoverStatus.completed:
        return semantics.stable;
    }
  }
}
