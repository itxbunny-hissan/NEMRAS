import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../navigation/clinical_navigation.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Screen 6 — AI clinical assistant.
///
/// Reuses the NEMRAS backend's existing `POST /api/chat` responder, scoped to
/// the record currently open.
///
/// What it actually is: a deterministic, keyword-matched responder that reads
/// only the loaded patient's own row. It is not a trained model, not an LLM
/// and not RAG, it has no clinical validation, and it cannot answer anything
/// outside that record. The screen says so rather than implying otherwise.
class AiClinicalAssistantScreen extends StatefulWidget {
  const AiClinicalAssistantScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<AiClinicalAssistantScreen> createState() =>
      _AiClinicalAssistantScreenState();
}

class _AiClinicalAssistantScreenState
    extends State<AiClinicalAssistantScreen> {
  final TextEditingController _question = TextEditingController();

  /// The topics the backend responder actually branches on. Offering anything
  /// else would suggest a capability it does not have.
  static const List<String> _supportedPrompts = <String>[
    'What allergies are recorded?',
    'What medication is on record?',
    'What is the blood type?',
    'What condition is recorded?',
    'What is the recorded risk tier?',
  ];

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _ask(HospitalSessionController controller, String text) async {
    if (text.trim().isEmpty) return;
    _question.clear();
    await controller.askAssistant(text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final record = controller.record;

    if (record == null) {
      return ClinicalEmptyState(
        icon: Icons.forum_outlined,
        title: 'No record in context',
        message:
            'The assistant only answers from one open patient record. Open a '
            'record first.',
        action: FilledButton.icon(
          onPressed: () =>
              widget.onNavigate(HospitalClinicalNavigation.patientsIndex),
          icon: const Icon(Icons.search, size: 16),
          label: const Text('Patient search'),
        ),
      );
    }

    final transcript = controller.assistantTranscript;

    return Column(
      children: <Widget>[
        Expanded(
          child: ClinicalContentArea(
            maxWidth: 860,
            children: <Widget>[
              const ProvenanceNotice(
                icon: Icons.psychology_outlined,
                message:
                    'Implemented behaviour: a rule-based responder on the '
                    'NEMRAS backend that matches keywords and quotes this '
                    'patient\'s own recorded fields. It is not a trained '
                    'model, not an LLM and not retrieval-augmented '
                    'generation, and it is not clinically validated. Do not '
                    'use it for diagnosis or prescribing.',
              ),
              ClinicalCard(
                title: 'Record in context',
                trailing: controller.isBreakGlassAccess
                    ? const DemoChip(label: 'BREAK-GLASS')
                    : null,
                child: ClinicalWrapGrid(
                  minCellWidth: 170,
                  children: <Widget>[
                    ClinicalDataField(
                      label: 'Condition',
                      value: record.summary.medicalCondition,
                    ),
                    ClinicalDataField(
                      label: 'Medication',
                      value: record.summary.medication,
                    ),
                    ClinicalDataField(
                      label: 'Allergy',
                      value: record.summary.allergy,
                    ),
                  ],
                ),
              ),
              if (transcript.isEmpty)
                ClinicalCard(
                  title: 'Questions this responder handles',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Anything outside these topics returns a generic '
                        'reply, because the responder has no other branches.',
                        style: NemrasTextStyles.bodyCaption.copyWith(
                          color: semantics.textSecondary,
                        ),
                      ),
                      const SizedBox(height: NemrasSpacing.xl),
                      Wrap(
                        spacing: NemrasSpacing.s,
                        runSpacing: NemrasSpacing.s,
                        children: <Widget>[
                          for (final prompt in _supportedPrompts)
                            OutlinedButton(
                              onPressed: controller.assistantBusy
                                  ? null
                                  : () => _ask(controller, prompt),
                              child: Text(prompt),
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              else
                ClinicalCard(
                  title: 'Transcript',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (var i = 0; i < transcript.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: NemrasSpacing.l),
                        _TranscriptTurn(turn: transcript[i]),
                      ],
                    ],
                  ),
                ),
              if (controller.assistantBusy)
                const ClinicalLoadingState(message: 'Querying responder…'),
            ],
          ),
        ),
        _Composer(
          controller: _question,
          enabled: !controller.assistantBusy,
          onSubmit: (text) => _ask(controller, text),
        ),
      ],
    );
  }
}

class _TranscriptTurn extends StatelessWidget {
  const _TranscriptTurn({required this.turn});

  final AssistantTurn turn;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    final (String label, NemrasStatusColor status) = switch (turn.kind) {
      AssistantTurnKind.question => ('CLINICIAN', semantics.informational),
      AssistantTurnKind.answer => (
          'RULE-BASED RESPONDER',
          semantics.advisory
        ),
      AssistantTurnKind.failure => ('REQUEST FAILED', semantics.critical),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: turn.kind == AssistantTurnKind.question
            ? semantics.controlBackground
            : status.soft,
        borderRadius: NemrasRadii.controlBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: NemrasTextStyles.fieldLabel.copyWith(
              color: status.onSoft,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xs),
          Text(
            turn.text,
            style: NemrasTextStyles.body.copyWith(
              color: semantics.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onSubmit;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Container(
      padding: const EdgeInsets.all(NemrasSpacing.xxl),
      decoration: BoxDecoration(
        color: semantics.barBackground,
        border: Border(top: BorderSide(color: semantics.cardBorder)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              onSubmitted: widget.enabled ? widget.onSubmit : null,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ask about this record…',
                hintStyle: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textPlaceholder,
                ),
                filled: true,
                fillColor: semantics.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: NemrasRadii.controlBorder,
                  borderSide: BorderSide(color: semantics.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: NemrasRadii.controlBorder,
                  borderSide: BorderSide(color: semantics.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: NemrasRadii.controlBorder,
                  borderSide: BorderSide(color: semantics.inputBorderActive),
                ),
              ),
            ),
          ),
          const SizedBox(width: NemrasSpacing.l),
          FilledButton.icon(
            onPressed: widget.enabled &&
                    widget.controller.text.trim().isNotEmpty
                ? () => widget.onSubmit(widget.controller.text)
                : null,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Ask'),
          ),
        ],
      ),
    );
  }
}
