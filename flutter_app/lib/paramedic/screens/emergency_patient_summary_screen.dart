import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../../api.dart';
import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';
import 'on_scene_assessment_screen.dart';

class EmergencyPatientSummaryScreen extends StatefulWidget {
  const EmergencyPatientSummaryScreen({
    super.key,
    required this.controller,
    required this.onOpenRoute,
    required this.onNewScan,
  });

  final ParamedicSessionController controller;
  final VoidCallback onOpenRoute;
  final VoidCallback onNewScan;

  @override
  State<EmergencyPatientSummaryScreen> createState() =>
      _EmergencyPatientSummaryScreenState();
}

class _EmergencyPatientSummaryScreenState
    extends State<EmergencyPatientSummaryScreen> {
  static const Duration _demoResponseWindow = Duration(seconds: 90);
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _remaining() {
    final created = widget.controller.emergencySession?.createdAt;
    if (created == null) return '00:00';
    final elapsed = DateTime.now().toUtc().difference(created);
    final remaining = _demoResponseWindow - elapsed;
    final safe = remaining.isNegative ? Duration.zero : remaining;
    return '${safe.inMinutes.toString().padLeft(2, '0')}:'
        '${(safe.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.controller.patientRecord;
    final session = widget.controller.emergencySession;
    if (record == null || session == null) {
      return ParamedicPage(
        title: 'Emergency Summary',
        subtitle: 'No active emergency',
        controller: widget.controller,
        child: EmptyEmergencyCard(
          message: 'Scan a patient to start a DEMO emergency session.',
          onOpenScan: widget.onNewScan,
        ),
      );
    }

    final semantics = NemrasSemantics.of(context);
    final summary = record.summary;
    final risk = semantics.risk(summary.riskScore);
    final critical = summary.riskScore == 'Critical';

    return ParamedicPage(
      title: 'Incident Assessment',
      subtitle: session.isDemo
          ? 'Demo lookup · not a live dispatch'
          : '${session.emergencyId} · ${session.status.name}',
      controller: widget.controller,
      child: ListView(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        children: <Widget>[
          Semantics(
            label: 'Demo response timer ${_remaining()}',
            child: FieldCard(
              color: critical
                  ? semantics.critical.solid
                  : semantics.cardBackground,
              borderColor:
                  critical ? semantics.critical.solid : semantics.cardBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              summary.patientName,
                              style: NemrasTextStyles.summaryName,
                            ),
                            const SizedBox(height: NemrasSpacing.xs),
                            Text(
                              '${summary.age} · ${summary.gender} · '
                              '${session.patientId}',
                              style: NemrasTextStyles.dataCaption.copyWith(
                                color: critical
                                    ? NemrasColors.white.withValues(alpha: 0.75)
                                    : semantics.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FieldStatusTag(label: summary.riskScore, status: risk),
                    ],
                  ),
                  const SizedBox(height: NemrasSpacing.xxl),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _SummaryMetric(
                          label: 'BLOOD',
                          value: summary.bloodType,
                        ),
                      ),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'TRIAGE',
                          value: summary.triageLevel,
                        ),
                      ),
                      Expanded(
                        child: _SummaryMetric(
                          label: 'DEMO TIMER',
                          value: _remaining(),
                          valueColor: NemrasColors.fieldAlert,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          _ClinicalField(
            label: 'Allergy',
            value: summary.allergy,
            status: semantics.allergy,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          _ClinicalField(
            label: 'Medication',
            value: summary.medication,
            status: semantics.medication,
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          _ClinicalField(
            label: 'Medical condition',
            value: summary.medicalCondition,
            status: semantics.informational,
            icon: Icons.medical_information_outlined,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          _ClinicalField(
            label: 'Chronic condition',
            value: summary.chronicCondition,
            status: semantics.chronicCondition(
              present: summary.chronicCondition.toLowerCase() == 'yes',
            ),
            icon: Icons.monitor_heart_outlined,
          ),
          if (record.alerts.isNotEmpty) ...<Widget>[
            const SizedBox(height: NemrasSpacing.xl),
            FieldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const FieldSectionLabel('Rule-based record alerts'),
                  const SizedBox(height: NemrasSpacing.m),
                  for (final Alert alert in record.alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: NemrasSpacing.m),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.circle,
                            size: 9,
                            color: semantics.severity(alert.severity).solid,
                          ),
                          const SizedBox(width: NemrasSpacing.s),
                          Expanded(
                            child: Text(
                              alert.title,
                              style: NemrasTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FieldSectionLabel('Pickup location'),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  'No pickup location is on this record.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const FieldSectionLabel('Emergency contact'),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  'No emergency contact is stored on this record.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.m),
                const SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null,
                    child: Text('Call contact is not available'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          OutlinedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Theme(
                  data: nemrasFieldDarkTheme(),
                  child: OnSceneAssessmentScreen(
                    controller: widget.controller,
                  ),
                ),
              ),
            ),
            child: const Text('View on-scene vitals'),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'Opening that page does not record or transmit vitals.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          FilledButton.icon(
            onPressed: widget.onOpenRoute,
            icon: const Icon(Icons.alt_route),
            label: const Text('Prepare Route & Handover'),
          ),
          const SizedBox(height: NemrasSpacing.m),
          OutlinedButton.icon(
            onPressed: () {
              widget.controller.clearEmergency();
              widget.onNewScan();
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('End Demo Session / New Scan'),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: NemrasTextStyles.metricLabel.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          value.isEmpty ? '—' : value,
          style: NemrasTextStyles.dataValue.copyWith(
            color: valueColor ?? semantics.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ClinicalField extends StatelessWidget {
  const _ClinicalField({
    required this.label,
    required this.value,
    required this.status,
    required this.icon,
  });

  final String label;
  final String value;
  final NemrasStatusColor status;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return FieldCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: status.solid.withValues(alpha: 0.16),
              borderRadius: NemrasRadii.smallBorder,
            ),
            child: Icon(icon, color: status.solid),
          ),
          const SizedBox(width: NemrasSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FieldSectionLabel(label, color: status.solid),
                const SizedBox(height: NemrasSpacing.xs),
                Text(
                  value.isEmpty ? 'Not recorded' : value,
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
