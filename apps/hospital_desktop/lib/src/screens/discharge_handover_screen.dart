import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';
import '../data/handover_models.dart';
import '../navigation/clinical_navigation.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Screen 9 — Discharge and handover.
///
/// Summarises what this hospital received from the field and what it holds
/// about discharge. Nothing is transmitted anywhere: there is no hospital
/// network integration in this build, so the screen reports continuity
/// information rather than claiming to send it.
class DischargeHandoverScreen extends StatelessWidget {
  const DischargeHandoverScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final record = controller.record;
    final cases = controller.queue;

    return ClinicalContentArea(
      maxWidth: 900,
      children: <Widget>[
        const ProvenanceNotice(
          icon: Icons.sync_disabled_outlined,
          message:
              'This screen reads local state only. No handover is pushed to '
              'another hospital, ambulance service or registry: NEMRAS '
              'implements no hospital network integration yet.',
        ),
        ClinicalCard(
          title: 'Inbound field handovers',
          trailing: const DemoChip(),
          child: cases.isEmpty
              ? Text(
                  'No field handover has been announced to this hospital.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var i = 0; i < cases.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: NemrasSpacing.l),
                      _HandoverRow(
                        handover: cases[i],
                        onOpen: () {
                          controller.selectCase(cases[i].emergencyId);
                          onNavigate(
                            HospitalClinicalNavigation.emergencyQueueIndex,
                          );
                        },
                      ),
                    ],
                  ],
                ),
        ),
        if (record == null)
          ClinicalCard(
            title: 'Discharge summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Open a patient record to see the discharge fields NEMRAS '
                  'holds for it.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => onNavigate(
                      HospitalClinicalNavigation.patientsIndex,
                    ),
                    icon: const Icon(Icons.search, size: 16),
                    label: const Text('Patient search'),
                  ),
                ),
              ],
            ),
          )
        else
          ClinicalCard(
            title: 'Discharge summary from the record',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClinicalWrapGrid(
                  minCellWidth: 170,
                  children: <Widget>[
                    ClinicalDataField(
                      label: 'Admission type',
                      value: record.summary.admissionType,
                    ),
                    ClinicalDataField(
                      label: 'Admitted',
                      value: record.summary.admissionDate,
                    ),
                    ClinicalDataField(
                      label: 'Discharged',
                      value: record.summary.dischargeDate,
                    ),
                    ClinicalDataField(
                      label: 'Attending doctor',
                      value: record.summary.doctor,
                    ),
                    ClinicalDataField(
                      label: 'Hospital of record',
                      value: record.summary.hospital,
                    ),
                    ClinicalDataField(
                      label: 'Continuing medication',
                      value: record.summary.medication,
                    ),
                  ],
                ),
                const SizedBox(height: NemrasSpacing.xl),
                const ClinicalWrapGrid(
                  minCellWidth: 170,
                  children: <Widget>[
                    ClinicalDataField(
                      label: 'Follow-up appointment',
                      value: kNotAvailable,
                    ),
                    ClinicalDataField(
                      label: 'Discharge destination',
                      value: kNotAvailable,
                    ),
                    ClinicalDataField(
                      label: 'Discharge instructions',
                      value: kNotAvailable,
                    ),
                  ],
                ),
                const SizedBox(height: NemrasSpacing.l),
                Text(
                  'NEMRAS records no follow-up plan, discharge destination '
                  'or written instructions, so these are reported as '
                  'unavailable.',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HandoverRow extends StatelessWidget {
  const _HandoverRow({required this.handover, required this.onOpen});

  final EmergencyHandover handover;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Container(
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        borderRadius: NemrasRadii.controlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: NemrasSpacing.l,
            runSpacing: NemrasSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                handover.emergencyId,
                style: NemrasTextStyles.dataValue.copyWith(
                  color: semantics.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ClinicalTag(
                label: handover.status.label,
                status: semantics.informational,
              ),
              Text(
                '${handover.ambulanceId}  ·  ${handover.paramedicId}',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.m),
          if (handover.hasHandoverNotes)
            Text(
              handover.handoverNotes,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textPrimary,
              ),
            )
          else
            Text(
              'No handover note recorded.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textPlaceholder,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: NemrasSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('Open encounter'),
            ),
          ),
        ],
      ),
    );
  }
}
