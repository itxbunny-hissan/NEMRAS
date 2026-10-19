import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';
import '../data/handover_models.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';
import 'bed_capacity_screen.dart';
import 'clinical_handoff_screen.dart';

/// Screen 8 — Emergency encounter.
///
/// The detail panel for one case from the queue. It shows the paramedic
/// handover context and drives the four status transitions.
///
/// There is no ambulance position, ETA or bed assignment here. NEMRAS has no
/// GPS, dispatch or bed-management source, so none is drawn.
class EmergencyEncounterScreen extends StatelessWidget {
  const EmergencyEncounterScreen({super.key, required this.handover});

  final EmergencyHandover handover;

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;

    return ClinicalContentArea(
      maxWidth: 820,
      children: <Widget>[
        _EncounterHeader(handover: handover),
        if (handover.isDemo)
          const ProvenanceNotice(
            icon: Icons.science_outlined,
            message:
                'DEMO emergency case. There is no live connection to an '
                'ambulance or a hospital network in this build; the handover '
                'is supplied by a local demo repository.',
          ),
        _IdentityStrip(handover: handover),
        _StatusCard(
          handover: handover,
          onAdvance: () => controller.advanceCase(handover.emergencyId),
        ),
        _SafetyFlagsCard(snapshot: snapshot),
        ClinicalCard(
          title: 'Field assessment & vitals',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'No field vitals are recorded for this case. NEMRAS holds no '
                'vital-sign, glucose or consciousness observations.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const ClinicalWrapGrid(
                minCellWidth: 140,
                children: <Widget>[
                  ClinicalDataField(label: 'Heart rate', value: kNotAvailable),
                  ClinicalDataField(
                    label: 'Blood pressure',
                    value: kNotAvailable,
                  ),
                  ClinicalDataField(label: 'SpO₂', value: kNotAvailable),
                  ClinicalDataField(
                    label: 'Blood glucose',
                    value: kNotAvailable,
                  ),
                  ClinicalDataField(
                    label: 'Consciousness (AVPU)',
                    value: kNotAvailable,
                  ),
                  ClinicalDataField(
                    label: 'Glasgow Coma Scale',
                    value: kNotAvailable,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const ClinicalSectionLabel('Paramedic handover note'),
              const SizedBox(height: NemrasSpacing.s),
              if (handover.hasHandoverNotes)
                Text(
                  handover.handoverNotes,
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                  ),
                )
              else
                Text(
                  'No handover note was recorded for this case.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textPlaceholder,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Record baseline',
          trailing: handover.isDemo ? const DemoChip() : null,
          child: ClinicalWrapGrid(
            minCellWidth: 160,
            children: <Widget>[
              ClinicalDataField(
                label: 'Medication',
                value: snapshot.medication,
              ),
              ClinicalDataField(
                label: 'Medical condition',
                value: snapshot.medicalCondition,
              ),
              ClinicalDataField(
                label: 'Chronic condition',
                value: snapshot.chronicCondition,
              ),
              ClinicalDataField(label: 'Allergy', value: snapshot.allergy),
              ClinicalDataField(
                label: 'Drug interaction risk',
                value: snapshot.drugInteractionRisk,
              ),
              const ClinicalDataField(
                label: 'Emergency contact',
                value: _kNotRecorded,
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Field handover context',
          child: ClinicalWrapGrid(
            minCellWidth: 180,
            children: <Widget>[
              ClinicalDataField(
                label: 'Emergency ID',
                value: handover.emergencyId,
              ),
              ClinicalDataField(
                label: 'Patient reference',
                value: handover.patientId,
              ),
              ClinicalDataField(
                label: 'Paramedic ID',
                value: handover.paramedicId,
              ),
              ClinicalDataField(
                label: 'Ambulance ID',
                value: handover.ambulanceId,
              ),
              ClinicalDataField(
                label: 'Destination hospital',
                value: handover.destinationHospitalId,
              ),
              ClinicalDataField(
                label: 'Announced at (UTC)',
                value: _formatTimestamp(handover.announcedAt),
              ),
              ClinicalDataField(
                label: 'Accepted by',
                value: handover.acceptedByStaffId ?? kNotAvailable,
              ),
              const ClinicalDataField(
                label: 'Ambulance ETA',
                value: kNotAvailable,
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Pending diagnostics',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'No diagnostic orders or results are recorded for this case.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const ClinicalDataField(
                label: 'Laboratory panel',
                value: kNotAvailable,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              const OutlinedButton(
                onPressed: null,
                child: Text('Ordering diagnostics is not available'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Identity and placement facts carried by the handover, beside what NEMRAS
/// does not hold.
class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({required this.handover});

  final EmergencyHandover handover;

  @override
  Widget build(BuildContext context) {
    final snapshot = handover.snapshot;
    return ClinicalCard(
      title: 'Patient identity',
      trailing: handover.isDemo ? const DemoChip(label: 'SYNTHETIC') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _identityGrid(snapshot),
          const SizedBox(height: NemrasSpacing.s),
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).push(BedCapacityScreen.route()),
            icon: const Icon(Icons.bed_outlined, size: 16),
            label: const Text('View bed & capacity'),
          ),
        ],
      ),
    );
  }

  Widget _identityGrid(HandoverClinicalSnapshot snapshot) {
    final gender = snapshot.gender.trim().isEmpty
        ? _kNotRecorded
        : snapshot.gender;
    return ClinicalWrapGrid(
      minCellWidth: 140,
      children: <Widget>[
        ClinicalDataField(
          label: 'Patient label',
          value: snapshot.patientLabel,
          emphasise: true,
        ),
        ClinicalDataField(
          label: 'Demographics',
          value: '${snapshot.ageLabel} y · $gender',
        ),
        ClinicalDataField(
          label: 'Blood type (as handed over)',
          value: snapshot.bloodType,
        ),
        ClinicalDataField(
          label: 'Patient reference',
          value: handover.patientId,
        ),
        const ClinicalDataField(label: 'Assigned bed', value: kNotAvailable),
      ],
    );
  }
}

const String _kNotRecorded = 'Not recorded';

String _formatTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)}Z';
}

class _EncounterHeader extends StatelessWidget {
  const _EncounterHeader({required this.handover});

  final EmergencyHandover handover;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;
    final critical = snapshot.riskCategory == 'Critical';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.section),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: critical
              ? semantics.criticalSummaryGradient
              : semantics.summaryGradient,
        ),
        borderRadius: NemrasRadii.cardBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  snapshot.patientLabel,
                  style: NemrasTextStyles.summaryName.copyWith(
                    color: NemrasColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (handover.isDemo) const DemoChip(),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            '${handover.emergencyId}  ·  ${snapshot.gender}  ·  '
            'AGE ${snapshot.ageLabel}  ·  ${snapshot.bloodType}',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: NemrasColors.fieldTextSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              ClinicalStatusPill(
                label: 'RISK ${snapshot.riskCategory}',
                status: semantics.risk(snapshot.riskCategory),
              ),
              ClinicalStatusPill(
                label: 'TRIAGE ${snapshot.triageLevel}',
                status: semantics.triage(snapshot.triageLevel),
              ),
              ClinicalStatusPill(
                label: handover.status.label,
                status: semantics.informational,
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            'Risk category is a dataset label, not a clinically validated '
            'probability.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: NemrasColors.fieldTextTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.handover, required this.onAdvance});

  final EmergencyHandover handover;
  final Future<bool> Function() onAdvance;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final actionLabel = handover.status.advanceActionLabel;

    return ClinicalCard(
      title: 'Encounter status',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              for (final status in EmergencyCaseStatus.values)
                ClinicalTag(
                  label: status.label,
                  status: status == handover.status
                      ? semantics.informational
                      : semantics.stable,
                  icon: status == handover.status
                      ? Icons.radio_button_checked
                      : (status.index < handover.status.index
                          ? Icons.check
                          : Icons.radio_button_unchecked),
                ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Text(
            handover.status.description,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          if (actionLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => onAdvance(),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(actionLabel),
              ),
            )
          else
            ClinicalTag(
              label: 'Encounter closed',
              status: semantics.stable,
              icon: Icons.check_circle_outline,
            ),
          const SizedBox(height: NemrasSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                ClinicalHandoffScreen.route(handover.emergencyId),
              ),
              icon: const Icon(Icons.assignment_ind_outlined, size: 16),
              label: const Text('Open handoff & admission'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyFlagsCard extends StatelessWidget {
  const _SafetyFlagsCard({required this.snapshot});

  final HandoverClinicalSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final flags = <Widget>[];

    if (snapshot.hasRecordedAllergy) {
      flags.add(
        ClinicalAlertBox(
          title: 'Allergy: ${snapshot.allergy}',
          detail:
              'A ${snapshot.allergy} allergy is recorded. Confirm before '
              'administering anything.',
          status: semantics.allergy,
        ),
      );
    }
    if (snapshot.hasDrugInteractionFlag) {
      flags.add(
        ClinicalAlertBox(
          title: 'Drug interaction flagged',
          detail:
              'The record flags Drug_Interaction_Risk = Yes for '
              '${snapshot.medication}. NEMRAS records no severity grading, '
              'so verify against a pharmacy source.',
          status: semantics.drugInteraction(present: true),
        ),
      );
    }
    if (snapshot.hasChronicCondition) {
      flags.add(
        ClinicalAlertBox(
          title: 'Chronic condition recorded',
          detail:
              '${snapshot.medicalCondition} is recorded as chronic. Factor '
              'into treatment and discharge planning.',
          status: semantics.chronicCondition(present: true),
        ),
      );
    }

    return ClinicalCard(
      title: 'Point-of-care safety flags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Derived from the recorded fields with explicit rules. This is '
            'rule-based decision support, not a trained model.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          if (flags.isEmpty)
            ClinicalAlertBox(
              title: 'No safety flags on record',
              detail:
                  'No recorded allergy, interaction flag or chronic '
                  'condition for this case.',
              status: semantics.stable,
            )
          else
            for (var i = 0; i < flags.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: NemrasSpacing.l),
              flags[i],
            ],
        ],
      ),
    );
  }
}
