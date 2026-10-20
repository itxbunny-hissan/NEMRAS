import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../state/paramedic_session_controller.dart';
import '../widgets/paramedic_ui.dart';

/// Field-mode copy of the Screen 22 reference.
///
/// No hospital is notified and no incident is completed.
class HospitalHandoffScreen extends StatefulWidget {
  const HospitalHandoffScreen({super.key, required this.controller});

  final ParamedicSessionController controller;

  @override
  State<HospitalHandoffScreen> createState() => _HospitalHandoffScreenState();
}

class _HospitalHandoffScreenState extends State<HospitalHandoffScreen> {
  bool _sceneDischarge = false;

  static const _steps = <String>[
    'Accepted',
    'En route',
    'Arrived',
    'Assessed',
    'Transit',
    'Handoff',
    'Complete',
  ];

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final hospital =
        widget.controller.patientRecord?.summary.hospital.trim() ?? '';
    return Material(
      type: MaterialType.transparency,
      child: ParamedicPage(
        title: 'Hospital handoff',
        subtitle: 'No live handoff',
        controller: widget.controller,
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
            FieldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const FieldSectionLabel('Offline buffer'),
                  const SizedBox(height: NemrasSpacing.s),
                  Text(
                    'No offline buffer is queued. Nothing will sync.',
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                  const SizedBox(height: NemrasSpacing.m),
                  const SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: null,
                      child: Text('Sync now is not available'),
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
                  const FieldSectionLabel('Mission pipeline'),
                  const SizedBox(height: NemrasSpacing.s),
                  Text(
                    'No mission stage is recorded.',
                    style: NemrasTextStyles.bodySmall.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                  const SizedBox(height: NemrasSpacing.m),
                  Wrap(
                    spacing: NemrasSpacing.s,
                    runSpacing: NemrasSpacing.s,
                    children: <Widget>[
                      for (final step in _steps)
                        Chip(
                          label: Text('$step · not started'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ModeButton(
                    label: 'Hospital transfer',
                    selected: !_sceneDischarge,
                    onPressed: () => setState(() => _sceneDischarge = false),
                  ),
                ),
                const SizedBox(width: NemrasSpacing.s),
                Expanded(
                  child: _ModeButton(
                    label: 'Scene discharge',
                    selected: _sceneDischarge,
                    onPressed: () => setState(() => _sceneDischarge = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              'This choice is not saved or sent.',
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: semantics.textSecondary,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            if (_sceneDischarge)
              const _SceneDischargeCard()
            else
              _HospitalTransferCard(
                hospital: hospital.isEmpty ? 'Not on file' : hospital,
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Text(label, textAlign: TextAlign.center);
    if (selected) {
      return FilledButton(onPressed: onPressed, child: child);
    }
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}

class _HospitalTransferCard extends StatelessWidget {
  const _HospitalTransferCard({required this.hospital});

  final String hospital;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return FieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(hospital, style: NemrasTextStyles.summaryName),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No receiving bay is assigned. No live link is open.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const _Line(label: 'ETA', value: 'Not calculated'),
          const _Line(label: 'Distance', value: 'Not calculated'),
          const SizedBox(height: NemrasSpacing.s),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('Call receiving desk is not available'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('Alternate hospitals are not available'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          const SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              child: Text('Confirm hospital handoff'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneDischargeCard extends StatelessWidget {
  const _SceneDischargeCard();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return FieldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'No witness, signature, or scene discharge is recorded.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Witness',
              hintText: 'Not collected',
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          Text(
            'Signature is not available.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.m),
          const SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              child: Text('Complete scene discharge'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.s),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 88,
            child: Text(
              label.toUpperCase(),
              style: NemrasTextStyles.dataCaption.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ),
          Expanded(child: Text(value, style: NemrasTextStyles.bodySmall)),
        ],
      ),
    );
  }
}
