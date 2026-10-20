import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/audit_models.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Screen 10 — Access audit.
///
/// Lists what this session recorded. Entries carry a staff ID, an action, a
/// time, a pseudonymous subject reference and — for break-glass — the reason
/// the clinician typed. They never carry a CNIC, a patient name, a medical
/// field or a token.
///
/// This is session-scoped and in memory. It is not a durable, append-only or
/// tamper-evident audit trail, and the screen states that.
class ClinicalAuditScreen extends StatelessWidget {
  const ClinicalAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final events = controller.auditEvents;

    return ClinicalContentArea(
      maxWidth: 900,
      children: <Widget>[
        const ProvenanceNotice(
          icon: Icons.history_toggle_off_outlined,
          message:
              'DEMO audit. These events live in memory for the current '
              'session only. A production audit trail has to be written '
              'append-only by the backend, with identifiers reduced to a '
              'keyed HMAC server-side.',
        ),
        ClinicalWrapGrid(
          minCellWidth: 220,
          children: <Widget>[
            ClinicalMetric(
              label: 'Recorded events',
              value: '${events.length}',
              caption: 'This session',
            ),
            ClinicalMetric(
              label: 'Break-glass events',
              value: '${controller.breakGlassEventCount}',
              caption: 'Emergency overrides',
              valueColor: controller.breakGlassEventCount > 0
                  ? semantics.critical.onSoft
                  : null,
            ),
          ],
        ),
        ClinicalCard(
          title: 'Access audit',
          trailing: const DemoChip(),
          child: events.isEmpty
              ? Text(
                  'No access events have been recorded in this session.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var i = 0; i < events.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: NemrasSpacing.l),
                      _AuditRow(event: events[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.event});

  final ClinicalAuditEvent event;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final emergency = event.action.isEmergencyAccess;
    final status = emergency ? semantics.critical : semantics.informational;

    return Container(
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: emergency ? status.soft : semantics.controlBackground,
        borderRadius: NemrasRadii.controlBorder,
        border: emergency
            ? Border.all(color: status.solid)
            : Border.all(color: semantics.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                emergency ? Icons.lock_open : Icons.check_circle_outline,
                size: 14,
                color: emergency ? status.onSoft : semantics.textSecondary,
              ),
              const SizedBox(width: NemrasSpacing.s),
              Expanded(
                child: Text(
                  event.action.label,
                  style: NemrasTextStyles.listTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
              ),
              if (event.isDemo) const DemoChip(),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Wrap(
            spacing: NemrasSpacing.xl,
            runSpacing: NemrasSpacing.xxs,
            children: <Widget>[
              _AuditField(label: 'STAFF', value: event.staffId),
              _AuditField(label: 'HOSPITAL', value: event.hospitalId),
              _AuditField(
                label: 'TIME (UTC)',
                value: _formatTimestamp(event.timestamp),
              ),
              if (event.subjectReference != null)
                _AuditField(label: 'SUBJECT', value: event.subjectReference!),
              if (event.emergencyId != null)
                _AuditField(label: 'EMERGENCY', value: event.emergencyId!),
            ],
          ),
          if (event.reason != null && event.reason!.isNotEmpty) ...<Widget>[
            const SizedBox(height: NemrasSpacing.m),
            ClinicalDataField(
              label: 'Recorded reason',
              value: event.reason!,
              emphasise: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditField extends StatelessWidget {
  const _AuditField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$label ',
          style: NemrasTextStyles.metricLabel.copyWith(
            color: semantics.textPlaceholder,
          ),
        ),
        Text(
          value,
          style: NemrasTextStyles.dataCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
      ],
    );
  }
}

String _formatTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}Z';
}
