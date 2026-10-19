import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';
import '../data/handover_models.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

const String _kNotRecorded = 'Not recorded';

/// Stitch Screen 27 — Clinical handoff and admission for one case.
///
/// The SBAR is assembled from the handover snapshot. NEMRAS records no
/// verification checklist, admission destination, signature or receiving
/// acknowledgement, so those are shown as not recorded and their controls are
/// disabled. The one enabled action is the existing local demo status step.
class ClinicalHandoffScreen extends StatelessWidget {
  const ClinicalHandoffScreen({super.key, required this.emergencyId});

  final String emergencyId;

  static Route<void> route(String emergencyId) => MaterialPageRoute<void>(
        builder: (_) => ClinicalHandoffScreen(emergencyId: emergencyId),
      );

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);

    EmergencyHandover? handover;
    for (final c in controller.queue) {
      if (c.emergencyId == emergencyId) handover = c;
    }

    return Scaffold(
      backgroundColor: semantics.screenBackground,
      appBar: AppBar(
        title: const Text('Clinical handoff & admission'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: handover == null
          ? const ClinicalEmptyState(
              icon: Icons.assignment_late_outlined,
              title: 'Case not found',
              message: 'This case is no longer in the emergency queue.',
            )
          : _HandoffBody(handover: handover),
    );
  }
}

class _HandoffBody extends StatelessWidget {
  const _HandoffBody({required this.handover});

  final EmergencyHandover handover;

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;
    final staff = controller.staff;
    final nextLabel = handover.status.advanceActionLabel;

    return ClinicalContentArea(
      maxWidth: 820,
      children: <Widget>[
        if (handover.isDemo)
          const ProvenanceNotice(
            icon: Icons.science_outlined,
            message:
                'DEMO case. No handoff has been accepted, no patient has been '
                'admitted and no hospital or dispatch centre has been '
                'notified. Nothing on this page is sent anywhere.',
          ),
        ClinicalCard(
          title: 'Custody transfer',
          trailing: handover.isDemo ? const DemoChip() : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${handover.emergencyId}  ·  ${handover.ambulanceId}',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.xs),
              Text(
                '${snapshot.patientLabel} (${snapshot.ageLabel}'
                '${snapshot.gender.isEmpty ? '' : ', ${snapshot.gender}'})',
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              ClinicalWrapGrid(
                minCellWidth: 140,
                children: <Widget>[
                  ClinicalDataField(
                    label: 'Handed over by',
                    value: handover.paramedicId,
                  ),
                  ClinicalDataField(
                    label: 'Receiving clinician',
                    value: handover.acceptedByStaffId ?? _kNotRecorded,
                  ),
                  const ClinicalDataField(
                    label: 'Assigned bed',
                    value: kNotAvailable,
                  ),
                  ClinicalDataField(
                    label: 'Case status',
                    value: handover.status.label,
                  ),
                ],
              ),
            ],
          ),
        ),
        _SbarCard(handover: handover),
        const _ChecklistCard(),
        const _DispositionCard(),
        ClinicalCard(
          title: 'Dual sign-off',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClinicalWrapGrid(
                minCellWidth: 160,
                children: <Widget>[
                  ClinicalDataField(
                    label: 'Paramedic · ${handover.paramedicId}',
                    value: 'Signature not recorded',
                  ),
                  ClinicalDataField(
                    label: staff == null
                        ? 'Receiving clinician'
                        : 'Receiving · ${staff.staffId}',
                    value: 'Signature not available',
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'Electronic signatures are not supported in this build.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ClinicalCard(
          title: 'Actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (nextLabel != null) ...<Widget>[
                FilledButton.icon(
                  onPressed: () =>
                      controller.advanceCase(handover.emergencyId),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text('Demo status step: $nextLabel'),
                ),
                const SizedBox(height: NemrasSpacing.xs),
                Text(
                  'Changes the local demo case status and session audit log '
                  'only. It does not admit the patient or notify anyone.',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ] else
                Text(
                  'The demo encounter is closed. No admission is recorded.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              const SizedBox(height: NemrasSpacing.l),
              const OutlinedButton(
                onPressed: null,
                child: Text('Confirming handoff & admission is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Flagging a discrepancy is not available'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SbarCard extends StatelessWidget {
  const _SbarCard({required this.handover});

  final EmergencyHandover handover;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final snapshot = handover.snapshot;

    return ClinicalCard(
      title: 'Structured SBAR',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Assembled from the handover snapshot. It is not a '
            'clinician-authored SBAR.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          _SbarSection(
            letter: 'S',
            title: 'Situation',
            status: semantics.informational,
            children: <Widget>[
              _line(context, 'Condition: ${snapshot.medicalCondition}'),
              _line(
                context,
                handover.hasHandoverNotes
                    ? handover.handoverNotes
                    : 'No handover note was recorded for this case.',
                muted: !handover.hasHandoverNotes,
              ),
            ],
          ),
          _SbarSection(
            letter: 'B',
            title: 'Background & allergies',
            status: semantics.elevated,
            children: <Widget>[
              _line(context, 'Chronic condition: ${snapshot.chronicCondition}'),
              _line(context, 'Medication: ${snapshot.medication}'),
              _line(context, 'Allergy: ${snapshot.allergy}'),
              if (snapshot.hasRecordedAllergy) ...<Widget>[
                const SizedBox(height: NemrasSpacing.s),
                ClinicalAlertBox(
                  title: 'Recorded allergy: ${snapshot.allergy}',
                  detail: 'Rule-based flag from the recorded allergy field.',
                  status: semantics.allergy,
                ),
              ],
            ],
          ),
          _SbarSection(
            letter: 'A',
            title: 'Assessment & vitals',
            status: semantics.stable,
            children: const <Widget>[
              ClinicalWrapGrid(
                minCellWidth: 110,
                children: <Widget>[
                  ClinicalDataField(label: 'BP', value: kNotAvailable),
                  ClinicalDataField(label: 'HR', value: kNotAvailable),
                  ClinicalDataField(label: 'SpO₂', value: kNotAvailable),
                ],
              ),
            ],
          ),
          _SbarSection(
            letter: 'R',
            title: 'Recommendation & orders',
            status: semantics.critical,
            children: <Widget>[
              _line(context, 'No orders are recorded.', muted: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String text, {bool muted = false}) {
    final semantics = NemrasSemantics.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.xxs),
      child: Text(
        text,
        style: NemrasTextStyles.bodySmall.copyWith(
          color: muted ? semantics.textPlaceholder : semantics.textPrimary,
          fontStyle: muted ? FontStyle.italic : null,
        ),
      ),
    );
  }
}

class _SbarSection extends StatelessWidget {
  const _SbarSection({
    required this.letter,
    required this.title,
    required this.status,
    required this.children,
  });

  final String letter;
  final String title;
  final NemrasStatusColor status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: NemrasSpacing.l),
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        borderRadius: NemrasRadii.controlBorder,
        border: Border(left: BorderSide(color: status.solid, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.soft,
              borderRadius: NemrasRadii.tagBorder,
            ),
            child: Text(
              letter,
              style: NemrasTextStyles.badge.copyWith(color: status.onSoft),
            ),
          ),
          const SizedBox(width: NemrasSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: NemrasTextStyles.listTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.xs),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard();

  static const List<String> _items = <String>[
    'SBAR briefing received and verified',
    'Physical custody transferred',
    'Field assessment notes received',
    'Belongings and valuables logged',
  ];

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ClinicalCard(
      title: 'Joint verification checklist',
      trailing: ClinicalTag(
        label: '0/${_items.length} RECORDED',
        status: semantics.informational,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Checklist sign-off is not recorded in this build.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          for (final item in _items)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: false,
              onChanged: null,
              title: Text(item),
              dense: true,
            ),
        ],
      ),
    );
  }
}

class _DispositionCard extends StatelessWidget {
  const _DispositionCard();

  static const List<String> _options = <String>[
    'Admit to emergency observation',
    'Direct transfer to a specialist unit',
    'Discharge after evaluation',
  ];

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ClinicalCard(
      title: 'Admission & transfer disposition',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'No admission destination is recorded. Disposition cannot be set '
            'in this build.',
            style: NemrasTextStyles.bodyCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          RadioGroup<String>(
            groupValue: null,
            onChanged: (_) {},
            child: Column(
              children: <Widget>[
                for (final option in _options)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: option,
                    enabled: false,
                    title: Text(option),
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const TextField(
            enabled: false,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Admission clinical note',
              hintText: 'Not recorded',
            ),
          ),
        ],
      ),
    );
  }
}
