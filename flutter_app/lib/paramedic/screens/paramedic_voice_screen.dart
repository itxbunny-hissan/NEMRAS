import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';

class ParamedicVoiceScreen extends StatefulWidget {
  const ParamedicVoiceScreen({
    super.key,
    required this.controller,
    required this.onOpenScan,
  });

  final ParamedicSessionController controller;
  final VoidCallback onOpenScan;

  @override
  State<ParamedicVoiceScreen> createState() => _ParamedicVoiceScreenState();
}

class _ParamedicVoiceScreenState extends State<ParamedicVoiceScreen> {
  late final TextEditingController _notes = TextEditingController(
    text: widget.controller.emergencySession?.handoverNotes ?? '',
  );
  bool _demoListening = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final record = widget.controller.patientRecord;
    return ParamedicPage(
      title: 'Voice & Notes',
      subtitle: 'Local demo interface · no speech service',
      controller: widget.controller,
      child: record == null
          ? EmptyEmergencyCard(
              message: 'Start an emergency session before recording notes.',
              onOpenScan: widget.onOpenScan,
            )
          : ListView(
              padding: const EdgeInsets.all(NemrasSpacing.xxl),
              children: <Widget>[
                FieldCard(
                  child: Column(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          setState(() => _demoListening = !_demoListening);
                        },
                        child: Semantics(
                          button: true,
                          label: _demoListening
                              ? 'Stop demo voice visualization'
                              : 'Start demo voice visualization',
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: semantics.accent.withValues(
                                alpha: _demoListening ? 0.24 : 0.12,
                              ),
                              border: Border.all(
                                color: semantics.accent,
                                width: _demoListening ? 4 : 2,
                              ),
                            ),
                            child: Icon(
                              _demoListening ? Icons.graphic_eq : Icons.mic,
                              size: 46,
                              color: semantics.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: NemrasSpacing.xl),
                      Text(
                        _demoListening
                            ? 'DEMO LISTENING VISUALIZATION'
                            : 'TAP FOR DEMO VOICE STATE',
                        style: NemrasTextStyles.fieldLabel.copyWith(
                          color: semantics.accent,
                        ),
                      ),
                      const SizedBox(height: NemrasSpacing.s),
                      Text(
                        'No audio is recorded, transmitted, transcribed, '
                        'or stored in Phase 2A.',
                        textAlign: TextAlign.center,
                        style: NemrasTextStyles.bodyCaption.copyWith(
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
                      const FieldSectionLabel('Handover notes'),
                      const SizedBox(height: NemrasSpacing.m),
                      TextField(
                        key: const Key('paramedic-handover-notes'),
                        controller: _notes,
                        maxLines: 5,
                        onChanged: widget.controller.updateHandoverNotes,
                        style: NemrasTextStyles.body,
                        decoration: InputDecoration(
                          hintText: 'Type observed handover notes…',
                          hintStyle: NemrasTextStyles.inputPlaceholder.copyWith(
                            color: semantics.textPlaceholder,
                          ),
                          filled: true,
                          fillColor: semantics.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: NemrasRadii.controlBorder,
                            borderSide:
                                BorderSide(color: semantics.inputBorder),
                          ),
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
                      const FieldSectionLabel('Record quick reference'),
                      const SizedBox(height: NemrasSpacing.m),
                      _ReferenceLine(
                        label: 'ALLERGY',
                        value: record.summary.allergy,
                      ),
                      _ReferenceLine(
                        label: 'MEDICATION',
                        value: record.summary.medication,
                      ),
                      _ReferenceLine(
                        label: 'CONDITION',
                        value: record.summary.medicalCondition,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReferenceLine extends StatelessWidget {
  const _ReferenceLine({required this.label, required this.value});

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
            width: 92,
            child: Text(
              label,
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
