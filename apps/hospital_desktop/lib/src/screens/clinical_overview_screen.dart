import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';
import '../data/handover_models.dart';
import '../navigation/clinical_navigation.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';
import 'alerts_escalation_screen.dart';
import 'bed_capacity_screen.dart';

/// Screen 2 — Clinical overview (Stitch Screen 23, hospital staff dashboard).
///
/// Incoming-case figures come from the demo handover queue and population
/// figures from the NEMRAS dataset. It carries no bed occupancy, no live
/// vitals, no ETA and no arrival history, because the backend records none of
/// those, and it is not connected to a hospital information system.
class ClinicalOverviewScreen extends StatelessWidget {
  const ClinicalOverviewScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);

    void openQueue() =>
        onNavigate(HospitalClinicalNavigation.emergencyQueueIndex);

    void openCase(String emergencyId) {
      controller.selectCase(emergencyId);
      openQueue();
    }

    return ClinicalContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          icon: Icons.science_outlined,
          message:
              'Demo session. Incoming cases come from a demo queue and are '
              'not connected to a hospital information system. NEMRAS records '
              'no bed occupancy, vital signs or arrival times.',
        ),
        _PriorityIncomingBanner(
          controller: controller,
          onOpenQueue: openQueue,
          onOpenCase: openCase,
        ),
        _ClinicalOperations(controller: controller),
        _ClinicalModules(
          pendingCount: controller.pendingCaseCount,
          onOpenQueue: openQueue,
        ),
        _InboundCasesCard(controller: controller, onOpenCase: openCase),
        const _InflowTrendCard(),
        _DatasetSection(
          controller: controller,
          onOpenSearch: () =>
              onNavigate(HospitalClinicalNavigation.patientsIndex),
        ),
      ],
    );
  }
}

String _thousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

int _triageRank(String triage) {
  switch (triage.toLowerCase()) {
    case 'high':
      return 0;
    case 'medium':
      return 1;
    case 'low':
      return 2;
    default:
      return 3;
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Wrap(
      spacing: NemrasSpacing.l,
      runSpacing: NemrasSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _PriorityIncomingBanner extends StatelessWidget {
  const _PriorityIncomingBanner({
    required this.controller,
    required this.onOpenQueue,
    required this.onOpenCase,
  });

  final HospitalSessionController controller;
  final VoidCallback onOpenQueue;
  final ValueChanged<String> onOpenCase;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    switch (controller.queueState) {
      case LoadState.idle:
      case LoadState.loading:
        return ClinicalCard(
          child: Text(
            'Loading the demo emergency queue…',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        );
      case LoadState.failed:
        return ClinicalCard(
          borderColor: semantics.critical.solid,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                controller.queueError ??
                    'The emergency queue could not be loaded.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.critical.onSoft,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              OutlinedButton.icon(
                onPressed: controller.refreshQueue,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      case LoadState.ready:
        break;
    }

    final pending =
        controller.queue
            .where((c) => c.status == EmergencyCaseStatus.pending)
            .toList()
          ..sort(
            (a, b) => _triageRank(
              a.snapshot.triageLevel,
            ).compareTo(_triageRank(b.snapshot.triageLevel)),
          );

    if (pending.isEmpty) {
      return ClinicalCard(
        background: semantics.stable.soft,
        borderColor: semantics.stable.solid,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'No pending incoming case',
              style: NemrasTextStyles.alertTitle.copyWith(
                color: semantics.stable.onSoft,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xs),
            Text(
              'Nothing in the demo queue is waiting for acceptance.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final top = pending.first;
    final count = pending.length;
    final snapshot = top.snapshot;
    return ClinicalCard(
      background: semantics.critical.soft,
      borderColor: semantics.critical.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: NemrasSpacing.l,
            runSpacing: NemrasSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                '$count pending incoming '
                '${count == 1 ? 'case' : 'cases'}',
                style: NemrasTextStyles.alertTitle.copyWith(
                  color: semantics.critical.onSoft,
                ),
              ),
              if (top.isDemo) const DemoChip(),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            '${top.emergencyId} · ${top.ambulanceId}',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            '${snapshot.patientLabel}, ${snapshot.ageLabel} · '
            '${snapshot.medicalCondition}',
            style: NemrasTextStyles.listTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.xs,
            children: <Widget>[
              ClinicalTag(
                label: 'TRIAGE ${snapshot.triageLevel}',
                status: semantics.triage(snapshot.triageLevel),
              ),
              ClinicalTag(
                label: 'ETA NOT AVAILABLE',
                status: semantics.informational,
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Wrap(
            spacing: NemrasSpacing.l,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => onOpenCase(top.emergencyId),
                icon: const Icon(Icons.assignment_outlined, size: 16),
                label: const Text('Review case'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenQueue,
                icon: const Icon(Icons.emergency_outlined, size: 16),
                label: const Text('Open emergency queue'),
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No bay is reserved from this dashboard.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalOperations extends StatelessWidget {
  const _ClinicalOperations({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final ready = controller.queueState == LoadState.ready;
    final queue = controller.queue;
    String count(bool Function(EmergencyHandover) test) =>
        ready ? '${queue.where(test).length}' : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          title: 'Clinical operations',
          trailing: DemoChip(label: 'DEMO QUEUE'),
        ),
        const SizedBox(height: NemrasSpacing.l),
        ClinicalWrapGrid(
          minCellWidth: 150,
          children: <Widget>[
            ClinicalMetric(
              label: 'Incoming',
              value: count((c) => c.status == EmergencyCaseStatus.pending),
              caption: 'Pending acceptance',
              valueColor: semantics.critical.onSoft,
            ),
            ClinicalMetric(
              label: 'Open ER cases',
              value: count((c) => c.status != EmergencyCaseStatus.completed),
              caption: 'Not yet completed',
            ),
            ClinicalMetric(
              label: 'Bed occupancy',
              value: kNotAvailable,
              caption: 'NEMRAS records no beds',
              valueColor: semantics.textPlaceholder,
            ),
            ClinicalMetric(
              label: 'Handoffs',
              value: count(
                (c) =>
                    c.status == EmergencyCaseStatus.accepted ||
                    c.status == EmergencyCaseStatus.inProgress,
              ),
              caption: 'Accepted or in treatment',
            ),
          ],
        ),
      ],
    );
  }
}

class _ClinicalModules extends StatelessWidget {
  const _ClinicalModules({
    required this.pendingCount,
    required this.onOpenQueue,
  });

  final int pendingCount;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(title: 'Clinical modules'),
        const SizedBox(height: NemrasSpacing.l),
        _ModuleTile(
          icon: Icons.format_list_numbered,
          title: 'Incoming triage queue',
          subtitle: 'Review demo cases announced to this hospital',
          trailing: pendingCount > 0
              ? ClinicalTag(
                  label: '$pendingCount PENDING',
                  status: semantics.critical,
                )
              : null,
          onTap: onOpenQueue,
        ),
        const SizedBox(height: NemrasSpacing.s),
        _ModuleTile(
          icon: Icons.bed_outlined,
          title: 'Bed & capacity manager',
          subtitle: 'Not available. NEMRAS records no bed or capacity data.',
          onTap: () => Navigator.of(context).push(BedCapacityScreen.route()),
        ),
        const SizedBox(height: NemrasSpacing.s),
        _ModuleTile(
          icon: Icons.notifications_active_outlined,
          title: 'Alerts & escalations',
          subtitle: 'Not available. No escalation feed is connected.',
          onTap: () => Navigator.of(context).push(
            AlertsEscalationScreen.route(
              onOpenCase: (id) {
                HospitalSessionScope.read(context).selectCase(id);
                onOpenQueue();
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final enabled = onTap != null;
    final foreground = enabled
        ? semantics.textPrimary
        : semantics.textPlaceholder;
    return Material(
      color: semantics.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: NemrasRadii.cardBorder,
        side: BorderSide(color: semantics.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(NemrasSpacing.xl),
          child: Row(
            children: <Widget>[
              Icon(
                icon,
                size: 20,
                color: enabled ? semantics.accent : foreground,
              ),
              const SizedBox(width: NemrasSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: NemrasTextStyles.listTitle.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: NemrasSpacing.xxs),
                    Text(
                      subtitle,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: semantics.textSecondary,
                      ),
                    ),
                    if (trailing != null) ...<Widget>[
                      const SizedBox(height: NemrasSpacing.xs),
                      trailing!,
                    ],
                  ],
                ),
              ),
              if (enabled)
                Icon(Icons.chevron_right, color: semantics.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboundCasesCard extends StatelessWidget {
  const _InboundCasesCard({required this.controller, required this.onOpenCase});

  final HospitalSessionController controller;
  final ValueChanged<String> onOpenCase;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final open = controller.queueState == LoadState.ready
        ? controller.openCases
        : const <EmergencyHandover>[];

    return ClinicalCard(
      title: 'Inbound cases',
      trailing: const DemoChip(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Vital signs and arrival times are not recorded for these cases.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          if (open.isEmpty)
            Text(
              'No open emergency cases have been announced to this hospital.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            )
          else
            for (final handover in open) ...<Widget>[
              _InboundCaseRow(
                handover: handover,
                onTap: () => onOpenCase(handover.emergencyId),
              ),
              const SizedBox(height: NemrasSpacing.s),
            ],
        ],
      ),
    );
  }
}

class _InboundCaseRow extends StatelessWidget {
  const _InboundCaseRow({required this.handover, required this.onTap});

  final EmergencyHandover handover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;
    final triage = semantics.triage(snapshot.triageLevel);

    return Material(
      color: semantics.controlBackground,
      shape: RoundedRectangleBorder(borderRadius: NemrasRadii.controlBorder),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: triage.solid, width: 3)),
          ),
          padding: const EdgeInsets.all(NemrasSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: NemrasSpacing.s,
                runSpacing: NemrasSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    handover.emergencyId,
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                  ClinicalTag(label: handover.status.label, status: triage),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xs),
              Text(
                '${snapshot.patientLabel} (${snapshot.ageLabel}'
                '${snapshot.gender.isEmpty ? '' : ', ${snapshot.gender}'})',
                style: NemrasTextStyles.listTitle.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xxs),
              Text(
                '${snapshot.medicalCondition} · ${handover.ambulanceId}',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              Wrap(
                spacing: NemrasSpacing.s,
                runSpacing: NemrasSpacing.xs,
                children: <Widget>[
                  ClinicalTag(
                    label: 'TRIAGE ${snapshot.triageLevel}',
                    status: triage,
                  ),
                  ClinicalStatusPill(
                    label: snapshot.riskCategory,
                    status: semantics.risk(snapshot.riskCategory),
                  ),
                  if (snapshot.hasRecordedAllergy)
                    ClinicalTag(
                      label: 'ALLERGY ${snapshot.allergy}',
                      status: semantics.critical,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InflowTrendCard extends StatelessWidget {
  const _InflowTrendCard();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ClinicalCard(
      title: 'Inflow trend',
      child: Text(
        'Not available. NEMRAS stores no arrival history, so no trend is '
        'drawn.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: semantics.textSecondary,
        ),
      ),
    );
  }
}

class _DatasetSection extends StatelessWidget {
  const _DatasetSection({required this.controller, required this.onOpenSearch});

  final HospitalSessionController controller;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final children = <Widget>[];

    switch (controller.overviewState) {
      case LoadState.idle:
      case LoadState.loading:
        children.add(
          Text(
            'Loading clinical overview…',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        );
      case LoadState.failed:
        children.add(
          ClinicalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  controller.overviewError ??
                      'The clinical overview could not be loaded.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.critical.onSoft,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                OutlinedButton.icon(
                  onPressed: controller.refreshOverview,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case LoadState.ready:
        final stats = controller.stats;
        if (stats == null) {
          children.add(
            ClinicalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'The NEMRAS backend returned no dataset statistics.',
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                  const SizedBox(height: NemrasSpacing.l),
                  OutlinedButton.icon(
                    onPressed: controller.refreshOverview,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reload'),
                  ),
                ],
              ),
            ),
          );
        } else {
          children.addAll(<Widget>[
            const ProvenanceNotice(
              icon: Icons.dataset_outlined,
              message:
                  'These counts describe the NEMRAS dataset served by the '
                  'backend. They are not live hospital telemetry: NEMRAS '
                  'records no bed occupancy, vital signs or laboratory '
                  'values.',
            ),
            ClinicalWrapGrid(
              minCellWidth: 150,
              children: <Widget>[
                ClinicalMetric(
                  label: 'Records in dataset',
                  value: _thousands(stats.totalPatients),
                  caption: 'Total patient rows',
                ),
                ClinicalMetric(
                  label: 'Critical risk tier',
                  value: _thousands(
                    stats.countFor(stats.riskScore, 'Critical'),
                  ),
                  caption: 'Risk_Score = Critical',
                  valueColor: semantics.critical.onSoft,
                ),
                ClinicalMetric(
                  label: 'High triage',
                  value: _thousands(stats.countFor(stats.triageLevel, 'High')),
                  caption: 'Triage_Level = High',
                  valueColor: semantics.elevated.onSoft,
                ),
                ClinicalMetric(
                  label: 'Average age',
                  value: stats.averageAgeLabel,
                  caption: 'Years, dataset mean',
                ),
              ],
            ),
            ClinicalSplitPanels(
              primary: _RiskDistributionCard(stats: stats),
              secondary: _ConditionBreakdownCard(stats: stats),
            ),
            _HighestRiskCard(
              rows: controller.highestRisk,
              onOpenSearch: onOpenSearch,
            ),
          ]);
        }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionHeading(
          title: 'NEMRAS dataset',
          trailing: DemoChip(label: 'SYNTHETIC DATASET'),
        ),
        for (final child in children) ...<Widget>[
          const SizedBox(height: NemrasSpacing.l),
          child,
        ],
      ],
    );
  }
}

class _RiskDistributionCard extends StatelessWidget {
  const _RiskDistributionCard({required this.stats});

  final ClinicalPopulationStats stats;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    const tiers = <String>['Critical', 'Elevated', 'Stable'];
    final total = stats.totalPatients;

    return ClinicalCard(
      title: 'Risk tier distribution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Risk_Score is a categorical label carried in the dataset. It is '
            'not a model probability and must not be read as one.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          for (final tier in tiers) ...<Widget>[
            _ProportionRow(
              label: tier,
              count: stats.countFor(stats.riskScore, tier),
              total: total,
              status: semantics.risk(tier),
            ),
            const SizedBox(height: NemrasSpacing.l),
          ],
        ],
      ),
    );
  }
}

class _ConditionBreakdownCard extends StatelessWidget {
  const _ConditionBreakdownCard({required this.stats});

  final ClinicalPopulationStats stats;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final conditions = stats.topConditions();

    return ClinicalCard(
      title: 'Recorded conditions',
      child: conditions.isEmpty
          ? Text(
              kNotAvailable,
              style: NemrasTextStyles.dataValue.copyWith(
                color: semantics.textPlaceholder,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (final entry in conditions) ...<Widget>[
                  _ProportionRow(
                    label: entry.label,
                    count: entry.count,
                    total: stats.totalPatients,
                    status: semantics.informational,
                  ),
                  const SizedBox(height: NemrasSpacing.l),
                ],
              ],
            ),
    );
  }
}

class _ProportionRow extends StatelessWidget {
  const _ProportionRow({
    required this.label,
    required this.count,
    required this.total,
    required this.status,
  });

  final String label;
  final int count;
  final int total;
  final NemrasStatusColor status;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final fraction = total <= 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: NemrasTextStyles.listTitle.copyWith(
                  color: semantics.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _thousands(count),
              style: NemrasTextStyles.dataCaption.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xs),
        ClipRRect(
          borderRadius: NemrasRadii.tagBorder,
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: semantics.controlBackground,
            valueColor: AlwaysStoppedAnimation<Color>(status.solid),
          ),
        ),
      ],
    );
  }
}

class _HighestRiskCard extends StatelessWidget {
  const _HighestRiskCard({required this.rows, required this.onOpenSearch});

  final List<CriticalPatientRow> rows;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return ClinicalCard(
      title: 'Highest risk-tier records',
      trailing: TextButton.icon(
        onPressed: onOpenSearch,
        icon: const Icon(Icons.search, size: 14),
        label: const Text('Patient search'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'An ordering of dataset records by risk tier. This is not a live '
            'admissions list and no arrival time is implied.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          if (rows.isEmpty)
            Text(
              'No records returned.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            )
          else
            for (final row in rows) ...<Widget>[
              _RiskRow(row: row),
              const SizedBox(height: NemrasSpacing.s),
            ],
        ],
      ),
    );
  }
}

class _RiskRow extends StatelessWidget {
  const _RiskRow({required this.row});

  final CriticalPatientRow row;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.xl,
        vertical: NemrasSpacing.l,
      ),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        borderRadius: NemrasRadii.controlBorder,
      ),
      child: Wrap(
        spacing: NemrasSpacing.xl,
        runSpacing: NemrasSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
            child: Text(
              row.medicalCondition,
              style: NemrasTextStyles.listTitle.copyWith(
                color: semantics.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'AGE ${row.ageLabel}',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          ClinicalTag(
            label: 'TRIAGE ${row.triageLevel}',
            status: semantics.triage(row.triageLevel),
          ),
          ClinicalStatusPill(
            label: row.riskScore,
            status: semantics.risk(row.riskScore),
          ),
          Text(
            row.admissionType,
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
