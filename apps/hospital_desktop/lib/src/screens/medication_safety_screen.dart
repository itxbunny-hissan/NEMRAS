import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../navigation/clinical_navigation.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Screen 7 — Medication and drug safety.
///
/// A record-only view. NEMRAS holds one `Medication` value and a binary
/// `Drug_Interaction_Risk` flag per record, with no dose, route, frequency,
/// start date or severity grading, and there is no interaction database
/// behind this screen. It reports exactly those fields and names what is
/// missing instead of inventing a pharmacology engine.
class MedicationSafetyScreen extends StatelessWidget {
  const MedicationSafetyScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final record = controller.record;

    if (record == null) {
      return ClinicalEmptyState(
        icon: Icons.medication_outlined,
        title: 'No record open',
        message:
            'Medication safety reads the open patient record. Open a record '
            'to review it.',
        action: FilledButton.icon(
          onPressed: () =>
              onNavigate(HospitalClinicalNavigation.patientsIndex),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('Patient search'),
        ),
      );
    }

    final summary = record.summary;

    return ClinicalContentArea(
      maxWidth: 860,
      children: <Widget>[
        const ProvenanceNotice(
          icon: Icons.inventory_2_outlined,
          message:
              'Record-only view. NEMRAS stores a single medication name and '
              'a Yes/No interaction flag per record. No interaction '
              'database, dose calculator or severity grading is implemented, '
              'so none is shown.',
        ),
        ClinicalCard(
          title: 'Recorded medication',
          child: ClinicalWrapGrid(
            minCellWidth: 170,
            children: <Widget>[
              ClinicalDataField(
                label: 'Medication',
                value: summary.medication,
              ),
              ClinicalDataField(
                label: 'Interaction flag',
                value: summary.drugInteractionRisk,
                valueColor: summary.hasDrugInteractionFlag
                    ? semantics.critical.onSoft
                    : semantics.stable.onSoft,
              ),
              ClinicalDataField(label: 'Allergy', value: summary.allergy),
              ClinicalDataField(
                label: 'Chronic condition',
                value: summary.chronicCondition,
              ),
            ],
          ),
        ),
        _ContraindicationCard(
          allergy: summary.allergy,
          hasAllergy: summary.hasRecordedAllergy,
          medication: summary.medication,
          hasInteraction: summary.hasDrugInteractionFlag,
        ),
        const ClinicalCard(
          title: 'Not recorded by NEMRAS',
          child: ClinicalWrapGrid(
            minCellWidth: 150,
            children: <Widget>[
              ClinicalDataField(label: 'Dose', value: 'Not available'),
              ClinicalDataField(label: 'Route', value: 'Not available'),
              ClinicalDataField(label: 'Frequency', value: 'Not available'),
              ClinicalDataField(label: 'Start date', value: 'Not available'),
              ClinicalDataField(
                label: 'Interaction severity',
                value: 'Not available',
              ),
              ClinicalDataField(
                label: 'Prescribing clinician',
                value: 'Not available',
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Record the review',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Marking the review writes a DEMO audit event with your '
                'staff ID and a pseudonymous patient reference. No clinical '
                'content is written to the audit.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: controller.recordMedicationReview,
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text('Mark medication safety reviewed'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContraindicationCard extends StatelessWidget {
  const _ContraindicationCard({
    required this.allergy,
    required this.hasAllergy,
    required this.medication,
    required this.hasInteraction,
  });

  final String allergy;
  final bool hasAllergy;
  final String medication;
  final bool hasInteraction;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final boxes = <Widget>[];

    if (hasAllergy) {
      boxes.add(
        ClinicalAlertBox(
          title: 'Hard contraindication: $allergy',
          detail:
              'A recorded allergy is a contraindication regardless of '
              'allergen. Avoid $allergy and cross-reactive agents.',
          status: semantics.allergy,
        ),
      );
    }
    if (hasInteraction) {
      boxes.add(
        ClinicalAlertBox(
          title: 'Interaction flag set',
          detail:
              'Drug_Interaction_Risk is Yes for $medication. NEMRAS records '
              'no severity, so confirm against a pharmacy reference before '
              'adding anything.',
          status: semantics.drugInteraction(present: true),
        ),
      );
    }

    return ClinicalCard(
      title: 'Safety checks from the record',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'These checks are explicit rules over two recorded fields. They '
            'are not a pharmacological interaction screen.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          if (boxes.isEmpty)
            ClinicalAlertBox(
              title: 'No contraindication on record',
              detail:
                  'No allergy and no interaction flag is recorded. This is '
                  'the absence of a record, not a clearance to prescribe.',
              status: semantics.stable,
            )
          else
            for (var i = 0; i < boxes.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: NemrasSpacing.l),
              boxes[i],
            ],
        ],
      ),
    );
  }
}
