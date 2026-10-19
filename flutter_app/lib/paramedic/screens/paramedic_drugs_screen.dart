import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';

class ParamedicDrugsScreen extends StatelessWidget {
  const ParamedicDrugsScreen({
    super.key,
    required this.controller,
    required this.onOpenScan,
  });

  final ParamedicSessionController controller;
  final VoidCallback onOpenScan;

  @override
  Widget build(BuildContext context) {
    final record = controller.patientRecord;
    final semantics = NemrasSemantics.of(context);
    if (record == null) {
      return ParamedicPage(
        title: 'Medication Safety',
        subtitle: 'Record fields only',
        controller: controller,
        child: EmptyEmergencyCard(
          message: 'Scan a patient to view recorded medication safety fields.',
          onOpenScan: onOpenScan,
        ),
      );
    }

    final summary = record.summary;
    final interactionPresent =
        summary.drugInteractionRisk.toLowerCase() == 'yes';
    final interaction = semantics.drugInteraction(
      present: interactionPresent,
    );

    return ParamedicPage(
      title: 'Medication Safety',
      subtitle: 'Dataset record · no prescribing',
      controller: controller,
      child: ListView(
        padding: const EdgeInsets.all(NemrasSpacing.xxl),
        children: <Widget>[
          FieldCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.medication_outlined,
                      color: semantics.medication.solid,
                    ),
                    const SizedBox(width: NemrasSpacing.s),
                    const Expanded(
                      child: FieldSectionLabel('Recorded medication'),
                    ),
                  ],
                ),
                const SizedBox(height: NemrasSpacing.xl),
                Text(
                  summary.medication.isEmpty
                      ? 'Not recorded'
                      : summary.medication,
                  style: NemrasTextStyles.summaryName,
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            borderColor: semantics.allergy.solid,
            color: semantics.allergy.solid.withValues(alpha: 0.12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FieldSectionLabel(
                  'Recorded allergy',
                  color: semantics.allergy.onSolid,
                ),
                const SizedBox(height: NemrasSpacing.s),
                Text(
                  summary.allergy.isEmpty ? 'Not recorded' : summary.allergy,
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            borderColor: interaction.solid,
            child: Row(
              children: <Widget>[
                Icon(
                  interactionPresent
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: interaction.solid,
                ),
                const SizedBox(width: NemrasSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const FieldSectionLabel('Drug interaction flag'),
                      const SizedBox(height: NemrasSpacing.xs),
                      Text(
                        summary.drugInteractionRisk.isEmpty
                            ? 'Not recorded'
                            : summary.drugInteractionRisk,
                        style: NemrasTextStyles.body.copyWith(
                          color: interaction.solid,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          FieldCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.info_outline,
                  color: semantics.informational.solid,
                ),
                const SizedBox(width: NemrasSpacing.m),
                Expanded(
                  child: Text(
                    'This screen only displays existing dataset fields. It '
                    'does not contain a drug database, calculate interactions, '
                    'recommend medication, diagnose, or prescribe.',
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
    );
  }
}
