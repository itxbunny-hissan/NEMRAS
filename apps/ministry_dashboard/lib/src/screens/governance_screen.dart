import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/governance_models.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 7 — Audit / Governance.
///
/// Shows that oversight activity happened, in what category, by which actor
/// identifier and when. It shows nothing about who was looked at. The audit
/// model carries no patient reference at all, so there is no masked column
/// here to accidentally widen later.
class GovernanceScreen extends StatelessWidget {
  const GovernanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.auditState.isLoading) {
      return const NationalLoadingState(message: 'Loading national audit');
    }
    if (controller.auditState.hasFailed) {
      return NationalErrorState(
        title: 'Audit trail unavailable',
        message: controller.auditError ??
            'The national audit source returned an error.',
        onRetry: controller.refreshAudit,
      );
    }

    final events = controller.auditEvents;
    final counts = controller.auditCategoryCounts;

    return NationalContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'What this log does and does not contain',
          message: 'Each entry records that an action of a given category '
              'occurred, by which staff or analyst identifier, at which '
              'facility, and when. No entry carries a patient name, a CNIC, '
              'a phone number, an email address or any clinical content: the '
              'national audit model has no field for them. Break-glass '
              'reasons are recorded at the facility that granted the access '
              'and are not replicated nationally. This trail is DEMO and is '
              'held in memory for the session.',
        ),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: NationalMetric.demo(
                label: 'Audit events',
                value: events.length,
                basis: 'Entries in the in-memory demo trail for this '
                    'session.',
              ),
              icon: Icons.receipt_long_outlined,
            ),
            NationalKpiCard(
              metric: NationalMetric.demo(
                label: 'Break-glass grants',
                value: controller.emergencyAccessCount,
                basis: 'Emergency-access entries in the demo trail.',
                caption: 'Each one would require a recorded justification at '
                    'the granting facility.',
              ),
              icon: Icons.lock_open_outlined,
            ),
            NationalKpiCard(
              metric: NationalMetric.demo(
                label: 'Record accesses',
                value: controller.patientAccessCount,
                basis: 'Patient-access entries in the demo trail, counted '
                    'without content.',
              ),
              icon: Icons.visibility_outlined,
            ),
            _GovernanceStatusCard(
              needsReview: controller.emergencyAccessCount > 0,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Access categories',
          subtitle: 'How the session trail breaks down by category.',
          trailing: DemoChip(),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final category in NationalAuditCategory.values)
                NationalDistributionRow(
                  entry: DistributionEntry(
                    label: category.label,
                    count: counts[category] ?? 0,
                    total: events.isEmpty ? 0 : events.length,
                  ),
                  color: category == NationalAuditCategory.emergencyAccess
                      ? semantics.critical.solid
                      : category == NationalAuditCategory.patientAccess
                          ? semantics.elevated.solid
                          : semantics.informational.solid,
                ),
              Text(
                'Counts of demo events. Not a measure of real access across '
                'any hospital.',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalSectionHeader(
          title: 'Audit trail',
          subtitle: 'Newest first. Timestamps in UTC.',
          trailing: _FilterSelector(
            selected: controller.governanceFilter,
            onChanged: controller.setGovernanceFilter,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        if (events.isEmpty)
          NationalCard(
            child: NationalEmptyState(
              title: 'No events for this filter',
              message: controller.governanceFilter == GovernanceFilter.all
                  ? 'The demo audit trail is empty.'
                  : 'No ${controller.governanceFilter.label.toLowerCase()} '
                      'events in the session trail.',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          NationalCard(
            child: NationalTable(
              columns: const <NationalColumn>[
                NationalColumn(label: 'Timestamp', flex: 3),
                NationalColumn(label: 'Category', flex: 2),
                NationalColumn(label: 'Action', flex: 4),
                NationalColumn(label: 'Actor', flex: 2),
                NationalColumn(label: 'Facility', flex: 2),
                NationalColumn(label: 'Node', flex: 2),
                NationalColumn(label: 'Note', flex: 5),
                NationalColumn(label: 'Source', flex: 2),
              ],
              rows: <List<Widget>>[
                for (final event in events)
                  <Widget>[
                    NationalMonoCell(formatUtcTimestamp(event.timestamp)),
                    NationalStatusPill(
                      label: event.category.shortLabel,
                      status: _categoryStatus(event.category, semantics),
                    ),
                    NationalTextCell(event.action.label),
                    NationalMonoCell(event.actorId, emphasise: true),
                    NationalMonoCell(event.hospitalLabel),
                    NationalMonoCell(event.nodeLabel),
                    NationalTextCell(event.noteLabel),
                    if (event.isDemo)
                      const DemoChip()
                    else
                      const NationalTextCell(kNotAvailable, maxLines: 1),
                  ],
              ],
            ),
          ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Governance posture',
          subtitle: 'What this build does and does not enforce.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: 'National audit is not yet a system of record',
          explanation: 'This trail is held in memory for the duration of the '
              'session, so it is lost on reload and cannot be relied on for '
              'oversight. A production NEMRAS must persist audit entries '
              'server-side, make them append-only, and aggregate them before '
              'they reach a national surface.',
          requirements: <({String requirement, String detail})>[
            (
              requirement: 'Server-side persistence',
              detail: 'Append-only storage the client cannot rewrite, so an '
                  'entry survives the session that created it.',
            ),
            (
              requirement: 'Aggregate-only national read',
              detail: 'National queries should receive counts by category, '
                  'not individual entries, so oversight does not become a '
                  'second route to patient data.',
            ),
            (
              requirement: 'Backend-enforced authorisation',
              detail: 'Access decisions must be made and audited by the '
                  'backend. A UI restriction is not a security boundary.',
            ),
          ],
          icon: Icons.gavel_outlined,
        ),
      ],
    );
  }

  static NemrasStatusColor _categoryStatus(
    NationalAuditCategory category,
    NemrasSemantics semantics,
  ) {
    switch (category) {
      case NationalAuditCategory.emergencyAccess:
        return semantics.critical;
      case NationalAuditCategory.patientAccess:
        return semantics.elevated;
      case NationalAuditCategory.governance:
        return semantics.informational;
      case NationalAuditCategory.federation:
        return semantics.advisory;
      case NationalAuditCategory.analystActivity:
        return semantics.stable;
    }
  }
}

/// Governance status, which is a state rather than a number, so it is a card
/// of its own instead of a KPI with a word where the figure goes.
class _GovernanceStatusCard extends StatelessWidget {
  const _GovernanceStatusCard({required this.needsReview});

  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.gavel_outlined,
                size: 16,
                color: semantics.textSecondary,
              ),
              const SizedBox(width: NemrasSpacing.xs),
              const Expanded(child: NationalLabel('Governance status')),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          const ProvenanceBadge(MetricProvenance.demo),
          const SizedBox(height: NemrasSpacing.m),
          NationalStatusPill(
            label: needsReview ? 'Review due' : 'Clear',
            status: needsReview ? semantics.elevated : semantics.stable,
            solid: true,
          ),
          const SizedBox(height: NemrasSpacing.m),
          Text(
            'A fixed rule over the demo trail: any break-glass grant raises '
            'a review. It is not a compliance determination.',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The category filter above the audit table.
class _FilterSelector extends StatelessWidget {
  const _FilterSelector({required this.selected, required this.onChanged});

  final GovernanceFilter selected;
  final ValueChanged<GovernanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NemrasSpacing.s,
      runSpacing: NemrasSpacing.s,
      children: <Widget>[
        for (final filter in GovernanceFilter.values)
          ChoiceChip(
            label: Text(filter.label),
            selected: filter == selected,
            onSelected: (_) => onChanged(filter),
          ),
      ],
    );
  }
}
