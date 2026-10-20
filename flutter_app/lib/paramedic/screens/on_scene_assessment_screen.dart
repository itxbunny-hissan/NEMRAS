import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';

/// Field-mode copy of the Screen 21 reference.
///
/// No vital signs are stored or transmitted.
class OnSceneAssessmentScreen extends StatelessWidget {
  const OnSceneAssessmentScreen({super.key, required this.controller});

  final ParamedicSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final name = controller.patientRecord?.summary.patientName.trim() ?? '';
    return Material(
      type: MaterialType.transparency,
      child: ParamedicPage(
        title: 'On-scene assessment',
        subtitle: 'Vitals not recorded',
        controller: controller,
        actions: <Widget>[
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(NemrasSpacing.xxl),
          children: <Widget>[
            Text(
              name.isEmpty ? 'No patient is open' : name,
              style: NemrasTextStyles.summaryName,
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              'Blood pressure, heart rate, oxygen saturation, and consciousness '
              'are not recorded. Nothing on this page is saved or sent.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            const _VitalField(label: 'Blood pressure'),
            const _VitalField(label: 'Heart rate'),
            const _VitalField(label: 'SpO2 saturation'),
            const _VitalField(label: 'Consciousness'),
            const SizedBox(height: NemrasSpacing.m),
            const TextField(
              enabled: false,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Observation',
                hintText: 'Not collected',
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            const SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: null,
                child: Text('Save & transmit vitals'),
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            const SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                child: Text('Save local draft is not available'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  const _VitalField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.m),
      child: TextField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Not recorded',
        ),
      ),
    );
  }
}
