import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/audit_models.dart';
import '../data/metric_provenance.dart';
import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 8b — Audit Trail.
///
/// The full event log, newest first, narrowable by scope. Filtering happens
/// in the repository rather than in the widget, so the same narrowing a
/// server-side store would perform is what the UI exercises.
class AuditTrailScreen extends StatelessWidget {
  const AuditTrailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final events = controller.auditEvents;

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Demo audit trail',
          message: 'Timestamps are stored and displayed in UTC so a log read '
              'in another timezone is unambiguous. Patient references are '
              'masked to their last four digits and no CNIC appears anywhere '
              'on this page.',
        ),
        OpsSectionHeader(
          title: 'Audit events',
          subtitle: '${events.length} event'
              '${events.length == 1 ? '' : 's'} in the '
              '${controller.auditFilter.label.toLowerCase()} scope.',
          trailing: const ProvenanceBadge(MetricProvenance.demo),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            for (final filter in AuditFilter.values)
              _FilterChip(
                label: filter.label,
                selected: controller.auditFilter == filter,
                onTap: () => controller.setAuditFilter(filter),
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        if (controller.auditState.isLoading)
          const OpsLoadingState()
        else
          OpsCard(
            child: events.isEmpty
                ? const OpsEmptyState(
                    title: 'No audit events',
                    message: 'No event in this hospital matches the '
                        'selected scope.',
                    icon: Icons.history_outlined,
                  )
                : OpsTable(
                    columns: const <OpsColumn>[
                      OpsColumn(label: 'Timestamp', flex: 3),
                      OpsColumn(label: 'Action', flex: 4),
                      OpsColumn(label: 'Staff ID', flex: 2),
                      OpsColumn(label: 'Hospital', flex: 2),
                      OpsColumn(label: 'Patient reference', flex: 3),
                      OpsColumn(label: 'Emergency ID', flex: 3),
                      OpsColumn(label: 'Scope', flex: 2),
                    ],
                    rows: <List<Widget>>[
                      for (final event in events)
                        <Widget>[
                          OpsMonoCell(formatUtcTimestamp(event.timestamp)),
                          OpsTextCell(event.action.label),
                          OpsMonoCell(event.staffId, emphasise: true),
                          OpsMonoCell(event.hospitalId),
                          OpsMonoCell(event.subjectLabel),
                          OpsMonoCell(event.emergencyId ?? kNotAvailable),
                          OpsStatusPill(
                            label: event.action.isEmergencyAccess
                                ? 'EMERGENCY'
                                : event.action.touchesPatientData
                                    ? 'PATIENT'
                                    : 'OPERATIONAL',
                            status: event.action.isEmergencyAccess
                                ? semantics.critical
                                : event.action.touchesPatientData
                                    ? semantics.elevated
                                    : semantics.informational,
                          ),
                        ],
                    ],
                  ),
          ),
        const SizedBox(height: NemrasSpacing.section),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const OpsLabel('Recorded justifications'),
              const SizedBox(height: NemrasSpacing.l),
              if (events.where((e) => e.hasReason).isEmpty)
                Text(
                  'No event in this scope carries a recorded reason.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                )
              else
                for (final event in events.where((e) => e.hasReason))
                  Padding(
                    padding: const EdgeInsets.only(bottom: NemrasSpacing.l),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 180,
                          child: OpsMonoCell(
                            formatUtcTimestamp(event.timestamp),
                          ),
                        ),
                        const SizedBox(width: NemrasSpacing.l),
                        Expanded(
                          child: Text(
                            '${event.action.label}: ${event.reasonLabel}',
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: semantics.textPrimary,
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
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      borderRadius: NemrasRadii.pillBorder,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NemrasSpacing.xl,
          vertical: NemrasSpacing.s,
        ),
        decoration: BoxDecoration(
          color: selected ? semantics.accent : semantics.controlBackground,
          borderRadius: NemrasRadii.pillBorder,
          border: Border.all(
            color: selected ? semantics.accent : semantics.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: NemrasTextStyles.chip.copyWith(
            color: selected ? semantics.onAccent : semantics.textSecondary,
          ),
        ),
      ),
    );
  }
}
