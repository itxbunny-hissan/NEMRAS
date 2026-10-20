import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/handover_models.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Stitch Screen 28 — Hospital alerts and escalation.
///
/// NEMRAS has no escalation feed, paging channel or surge protocol, so this
/// page lists rule-based flags computed from the open cases in the handover
/// queue. They are not live alerts: nothing is acknowledged, escalated or
/// broadcast from here.
class AlertsEscalationScreen extends StatelessWidget {
  const AlertsEscalationScreen({super.key, this.onOpenCase});

  /// Called after this page closes, with the case to show in the queue.
  final ValueChanged<String>? onOpenCase;

  static Route<void> route({ValueChanged<String>? onOpenCase}) =>
      MaterialPageRoute<void>(
        builder: (_) => AlertsEscalationScreen(onOpenCase: onOpenCase),
      );

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final openCases = controller.queue
        .where((c) => c.status != EmergencyCaseStatus.completed)
        .toList();
    final flags = <_RuleFlag>[
      for (final c in openCases) ..._flagsFor(c, semantics),
    ];

    return Scaffold(
      backgroundColor: semantics.screenBackground,
      appBar: AppBar(
        title: const Text('Alerts & escalations'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ClinicalContentArea(
        maxWidth: 820,
        children: <Widget>[
          const ProvenanceNotice(
            icon: Icons.notifications_off_outlined,
            message:
                'No escalation feed, paging channel or surge protocol is '
                'connected. The flags below are rule-based checks over the '
                'demo handover queue. They are not live alerts and nobody is '
                'notified.',
          ),
          ClinicalCard(
            title: 'Surge protocol',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ClinicalDataField(
                  label: 'Surge status',
                  value: 'Not available',
                ),
                const SizedBox(height: NemrasSpacing.l),
                const FilledButton(
                  onPressed: null,
                  child: Text('Broadcasting a surge alert is not available'),
                ),
                const SizedBox(height: NemrasSpacing.xs),
                Text(
                  'NEMRAS records no capacity or surge data and has no '
                  'broadcast channel.',
                  style: NemrasTextStyles.bodyCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ClinicalCard(
            title: 'Rule-based case flags',
            trailing: const DemoChip(label: 'DEMO QUEUE'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${flags.length} '
                  '${flags.length == 1 ? 'flag' : 'flags'} from '
                  '${openCases.length} open '
                  '${openCases.length == 1 ? 'case' : 'cases'}',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                if (flags.isEmpty)
                  Text(
                    'No rule-based flags for open cases.',
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textPlaceholder,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  for (final flag in flags)
                    _FlagTile(
                      flag: flag,
                      onOpen: onOpenCase == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onOpenCase!(flag.handover.emergencyId);
                            },
                    ),
              ],
            ),
          ),
          ClinicalCard(
            title: 'Direct escalation triggers',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'No escalation contacts or on-call rotas are configured.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.l),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Paging a team is not available'),
                ),
              ],
            ),
          ),
          const ClinicalCard(
            title: 'Alert delivery',
            child: ClinicalWrapGrid(
              minCellWidth: 160,
              children: <Widget>[
                ClinicalDataField(label: 'Live channel', value: 'Not connected'),
                ClinicalDataField(label: 'Last delivery', value: 'Not available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static List<_RuleFlag> _flagsFor(
    EmergencyHandover c,
    NemrasSemantics semantics,
  ) {
    final s = c.snapshot;
    return <_RuleFlag>[
      if (c.status == EmergencyCaseStatus.pending)
        _RuleFlag(
          c,
          'Awaiting acceptance',
          'Case status is PENDING.',
          semantics.informational,
        ),
      if (s.triageLevel.toLowerCase() == 'high')
        _RuleFlag(
          c,
          'High triage label',
          'Triage level carried in the handover snapshot is High.',
          semantics.critical,
        ),
      if (s.hasRecordedAllergy)
        _RuleFlag(
          c,
          'Recorded allergy: ${s.allergy}',
          'Allergy field in the handover snapshot is not None.',
          semantics.allergy,
        ),
      if (s.hasDrugInteractionFlag)
        _RuleFlag(
          c,
          'Drug interaction risk recorded',
          'Drug interaction risk field is Yes.',
          semantics.elevated,
        ),
    ];
  }
}

class _RuleFlag {
  const _RuleFlag(this.handover, this.title, this.rule, this.status);

  final EmergencyHandover handover;
  final String title;
  final String rule;
  final NemrasStatusColor status;
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({required this.flag, required this.onOpen});

  final _RuleFlag flag;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final h = flag.handover;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: NemrasSpacing.l),
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        borderRadius: NemrasRadii.controlBorder,
        border: Border(left: BorderSide(color: flag.status.solid, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ClinicalTag(label: 'RULE-BASED', status: flag.status),
              Text(
                '${h.emergencyId}  ·  ${h.ambulanceId}',
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            flag.title,
            style: NemrasTextStyles.listTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
          Text(
            '${h.snapshot.patientLabel}  ·  ${flag.rule}',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.xs,
            children: <Widget>[
              if (onOpen != null)
                TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Open case'),
                ),
              const TextButton(
                onPressed: null,
                child: Text('Acknowledge is not available'),
              ),
              const TextButton(
                onPressed: null,
                child: Text('Escalate is not available'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
