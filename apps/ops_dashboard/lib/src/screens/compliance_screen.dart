import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/admin_identity.dart';
import '../data/audit_models.dart';
import '../data/metric_provenance.dart';
import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 8a — Compliance.
///
/// Summarises the access events a compliance reviewer has to answer for:
/// how much emergency access was granted, whether each grant carries a
/// recorded justification, and which staff performed it. The full log lives
/// on the Audit Trail screen.
///
/// No patient identifier appears here. Entries carry a masked reference only,
/// which is all a compliance count needs.
class ComplianceScreen extends StatelessWidget {
  const ComplianceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.auditState.isLoading) {
      return const OpsLoadingState(message: 'Reading audit trail');
    }

    final events = controller.auditEvents;
    final emergencyEvents =
        events.where((e) => e.action.isEmergencyAccess).toList();
    final patientEvents =
        events.where((e) => e.action.touchesPatientData).toList();
    final unjustified =
        emergencyEvents.where((e) => !e.hasReason).toList();

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Demo audit trail',
          message: 'These events are seeded by a local demo provider and '
              'record nothing that actually happened. A production NEMRAS '
              'must persist the audit trail server-side: a log the client '
              'owns is a log the client can edit. Patient references are '
              'masked here, and a real store must derive them with a '
              'server-side keyed HMAC so an entry cannot be reversed to an '
              'identity by anyone holding the log.',
        ),
        OpsWrapGrid(
          children: <Widget>[
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Audited Events',
                value: events.length,
                basis: 'Events in the current audit scope',
                caption: 'Demo audit trail.',
              ),
              icon: Icons.fact_check_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Emergency Access',
                value: emergencyEvents.length,
                basis: 'Break-glass grants requiring review',
                caption: 'Demo audit trail.',
              ),
              icon: Icons.lock_open_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Patient Record Access',
                value: patientEvents.length,
                basis: 'Events that touched a patient record',
                caption: 'Demo audit trail.',
              ),
              icon: Icons.folder_shared_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.demo(
                label: 'Grants Without Reason',
                value: unjustified.length,
                basis: 'Break-glass grants with no recorded justification',
                caption: 'Should be zero. Demo audit trail.',
              ),
              icon: Icons.report_problem_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Emergency access review',
          subtitle: 'Break-glass access bypasses normal authorisation and '
              'every grant requires a recorded justification.',
          trailing: ProvenanceBadge(MetricProvenance.demo),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          accent: emergencyEvents.isEmpty
              ? semantics.stable.solid
              : semantics.critical.solid,
          child: emergencyEvents.isEmpty
              ? const OpsEmptyState(
                  title: 'No emergency access to review',
                  message: 'No break-glass grant appears in the current '
                      'audit scope.',
                  icon: Icons.verified_user_outlined,
                )
              : OpsTable(
                  columns: const <OpsColumn>[
                    OpsColumn(label: 'Timestamp', flex: 3),
                    OpsColumn(label: 'Staff ID', flex: 2),
                    OpsColumn(label: 'Emergency ID', flex: 3),
                    OpsColumn(label: 'Patient reference', flex: 3),
                    OpsColumn(label: 'Recorded reason', flex: 5),
                  ],
                  rows: <List<Widget>>[
                    for (final event in emergencyEvents)
                      <Widget>[
                        OpsMonoCell(formatUtcTimestamp(event.timestamp)),
                        OpsMonoCell(event.staffId, emphasise: true),
                        OpsMonoCell(event.emergencyId ?? kNotAvailable),
                        OpsMonoCell(event.subjectLabel),
                        OpsTextCell(event.reasonLabel),
                      ],
                  ],
                ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Activity by staff member',
          subtitle: 'Event counts per staff identifier in the current scope.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: OpsTable(
            columns: const <OpsColumn>[
              OpsColumn(label: 'Staff ID', flex: 2),
              OpsColumn(label: 'Events', flex: 1, alignEnd: true),
              OpsColumn(label: 'Patient access', flex: 1, alignEnd: true),
              OpsColumn(label: 'Emergency access', flex: 1, alignEnd: true),
            ],
            rows: <List<Widget>>[
              for (final staffId in _staffIds(events))
                <Widget>[
                  OpsMonoCell(staffId, emphasise: true),
                  OpsMonoCell(
                    '${events.where((e) => e.staffId == staffId).length}',
                  ),
                  OpsMonoCell(
                    '${patientEvents.where((e) => e.staffId == staffId).length}',
                  ),
                  OpsMonoCell(
                    '${emergencyEvents.where((e) => e.staffId == staffId).length}',
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Hospital scope',
          subtitle: 'Every event shown is scoped to this hospital.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OpsField(
                label: 'Hospital ID',
                value: controller.hospital.hospitalId,
                mono: true,
              ),
              OpsField(
                label: 'Reviewing administrator',
                value: '${controller.administrator.staffId} '
                    '(${controller.administrator.role.label})',
              ),
              OpsField(
                label: 'Audit scope filter',
                value: controller.auditFilter.label,
              ),
              Text(
                'The backend remains the security boundary. This dashboard '
                'enforces no authorisation and the filter above is a '
                'presentation control only.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Distinct staff identifiers, in first-seen order so the table is stable.
  static List<String> _staffIds(List<OpsAuditEvent> events) {
    final seen = <String>[];
    for (final event in events) {
      if (!seen.contains(event.staffId)) seen.add(event.staffId);
    }
    return seen;
  }
}
