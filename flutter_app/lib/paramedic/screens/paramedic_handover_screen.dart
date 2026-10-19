import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../models/paramedic_models.dart';
import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';
import 'hospital_handoff_screen.dart';

class ParamedicHandoverScreen extends StatelessWidget {
  const ParamedicHandoverScreen({
    super.key,
    required this.controller,
    required this.onOpenScan,
  });

  final ParamedicSessionController controller;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    final session = controller.emergencySession;
    final record = controller.patientRecord;
    final semantics = NemrasSemantics.of(context);
    if (session == null || record == null) {
      return ParamedicPage(
        title: 'Route & Handover',
        subtitle: 'No active emergency',
        controller: controller,
        child: EmptyEmergencyCard(
          message: 'Start an emergency session before preparing handover.',
          onOpenScan: onOpenScan,
        ),
      );
    }

    final summary = record.summary;
    final name = summary.patientName.trim().isEmpty
        ? 'Name not recorded'
        : summary.patientName.trim();
    return ParamedicPage(
      title: 'Route & Handover',
      subtitle: '${session.emergencyId} · local demo',
      controller: controller,
      child: ListView(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        children: <Widget>[
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: NemrasTextStyles.summaryName),
                const SizedBox(height: NemrasSpacing.xs),
                Text(
                  '${summary.age} yrs · '
                  '${summary.gender.isEmpty ? 'Sex not recorded' : summary.gender}',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                _HandoverLine(
                  label: 'Blood',
                  value: summary.bloodType,
                ),
                _HandoverLine(label: 'Allergy', value: summary.allergy),
                _HandoverLine(
                  label: 'Condition',
                  value: summary.medicalCondition,
                ),
                _HandoverLine(
                  label: 'Hospital on record',
                  value: summary.hospital,
                ),
                const _HandoverLine(
                  label: 'Contact',
                  value: 'Not on file',
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.near_me_outlined, color: semantics.accent),
                    const SizedBox(width: NemrasSpacing.s),
                    const Expanded(
                      child: FieldSectionLabel('Navigation'),
                    ),
                    FieldStatusTag(
                      label: session.status.name,
                      status: _statusColor(semantics, session.status),
                    ),
                  ],
                ),
                const SizedBox(height: NemrasSpacing.l),
                Text(
                  'Turn-by-turn navigation is not available.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                const _HandoverLine(
                  label: 'Remaining ETA',
                  value: 'Not calculated',
                ),
                const _HandoverLine(
                  label: 'Distance',
                  value: 'Not calculated',
                ),
                _HandoverLine(
                  label: 'Hospital ID',
                  value: session.destinationHospitalId,
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FieldSectionLabel('Future hospital payload preview'),
                const SizedBox(height: NemrasSpacing.xl),
                _HandoverLine(
                  label: 'Emergency',
                  value: session.emergencyId,
                ),
                _HandoverLine(
                  label: 'Patient',
                  value: session.patientId,
                ),
                _HandoverLine(
                  label: 'Paramedic',
                  value: session.paramedicId,
                ),
                _HandoverLine(
                  label: 'Ambulance',
                  value: session.ambulanceId,
                ),
                _HandoverLine(
                  label: 'Risk / triage',
                  value: '${summary.riskScore} / ${summary.triageLevel}',
                ),
                _HandoverLine(
                  label: 'Medication',
                  value: summary.medication,
                ),
                _HandoverLine(
                  label: 'Chronic',
                  value: summary.chronicCondition,
                ),
                _HandoverLine(
                  label: 'Notes',
                  value: session.handoverNotes.isEmpty
                      ? 'No handover notes entered'
                      : session.handoverNotes,
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            color: semantics.informational.solid.withValues(alpha: 0.1),
            child: Text(
              'No hospital has been notified. No route, GPS, ETA, dispatch, '
              'WebSocket, or network handover exists in Phase 2A. This card '
              'only demonstrates the future interface contract.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          if (session.status == EmergencyStatus.active)
            FilledButton.icon(
              key: const Key('prepare-handover-button'),
              onPressed: controller.prepareHandover,
              icon: const Icon(Icons.assignment_turned_in_outlined),
              label: const Text('Prepare Demo Handover'),
            )
          else if (session.status == EmergencyStatus.handoverPreparing)
            FilledButton.icon(
              key: const Key('ready-transport-button'),
              onPressed: controller.markReadyForTransport,
              icon: const Icon(Icons.emergency_share_outlined),
              label: const Text('Mark Demo Ready for Transport'),
            )
          else
            Text(
              'Demo handover is marked ready on this device. '
              'No hospital has been notified.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          const SizedBox(height: NemrasSpacing.m),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('Open in external GPS is not available'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('Quick-dial is not available'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Theme(
                  data: nemrasFieldDarkTheme(),
                  child: HospitalHandoffScreen(controller: controller),
                ),
              ),
            ),
            child: const Text('View hospital handoff'),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'Opening that page does not notify a hospital or complete the incident.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          OutlinedButton.icon(
            onPressed: onOpenScan,
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Return to incident assessment'),
          ),
        ],
      ),
    );
  }

  NemrasStatusColor _statusColor(
    NemrasSemantics semantics,
    EmergencyStatus status,
  ) {
    switch (status) {
      case EmergencyStatus.active:
        return semantics.critical;
      case EmergencyStatus.handoverPreparing:
        return semantics.elevated;
      case EmergencyStatus.readyForTransport:
        return semantics.stable;
      case EmergencyStatus.closed:
        return semantics.informational;
    }
  }
}

class _HandoverLine extends StatelessWidget {
  const _HandoverLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.m),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 112,
            child: Text(
              label.toUpperCase(),
              style: NemrasTextStyles.dataCaption.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not recorded' : value,
              style: NemrasTextStyles.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
