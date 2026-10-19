import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';
import '../dev/demo_auth.dart';
import '../navigation/app_router.dart';

/// Informational copy of the Screen 14 reference.
///
/// Fields come from the signed-in record. Severity and symptom taps stay on
/// this page. Nothing is submitted or sent to a dispatch service.
class EmergencyDetailsScreen extends StatefulWidget {
  const EmergencyDetailsScreen({
    super.key,
    required this.record,
    required this.incident,
  });

  final PatientRecord record;
  final String incident;

  @override
  State<EmergencyDetailsScreen> createState() => _EmergencyDetailsScreenState();
}

class _EmergencyDetailsScreenState extends State<EmergencyDetailsScreen> {
  int? _tier;
  final Set<String> _symptoms = <String>{};

  static const _tiers = <(String, String)>[
    ('Critical', 'Unconscious'),
    ('Severe', 'Acute pain'),
    ('Moderate', 'Conscious'),
  ];

  static const _symptomLabels = <String>[
    'Chest pain / pressure',
    'Shortness of breath',
    'Dizziness / cold sweats',
    'Slurred speech',
    'Severe bleeding',
  ];

  @override
  Widget build(BuildContext context) {
    final summary = widget.record.summary;
    final name = summary.patientName.trim().isEmpty
        ? 'Name not recorded'
        : summary.patientName.trim();
    final blood = summary.bloodType.trim().isEmpty
        ? 'Not recorded'
        : summary.bloodType.trim();
    final allergy = summary.allergy.trim().isEmpty
        ? 'No allergy recorded'
        : summary.allergy.trim();
    final medication = summary.medication.trim().isEmpty
        ? 'No medication recorded'
        : summary.medication.trim();
    final condition = summary.medicalCondition.trim().isEmpty
        ? 'No condition recorded'
        : summary.medicalCondition.trim();
    final demo = isDemoPatientRecord(widget.record);

    return Scaffold(
      backgroundColor: _DetailsPalette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Active Emergency Dispatch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: _DetailsPalette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'No dispatch is active',
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: _DetailsPalette.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          'GPS unavailable',
                          style: NemrasTextStyles.dataCaption.copyWith(
                            color: _DetailsPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _DetailsPalette.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _DetailsPalette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.monitor_heart_outlined,
                              color: _DetailsPalette.sos,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Incident category',
                                    style: NemrasTextStyles.dataCaption.copyWith(
                                      color: _DetailsPalette.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    widget.incident,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: NemrasTextStyles.listTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _DetailsPalette.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              child: const Text('Change'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Triage severity tier',
                      style: NemrasTextStyles.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _DetailsPalette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'On record: ${summary.riskScore.isEmpty ? 'not recorded' : summary.riskScore}'
                      '${summary.triageLevel.isEmpty ? '' : ' · triage ${summary.triageLevel}'}'
                      '. A tap here is not saved.',
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _DetailsPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _tiers.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _TierButton(
                              title: _tiers[i].$1,
                              subtitle: _tiers[i].$2,
                              selected: _tier == i,
                              onTap: () => setState(() => _tier = i),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Observed symptoms',
                            style: NemrasTextStyles.listTitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _DetailsPalette.text,
                            ),
                          ),
                        ),
                        Text(
                          '${_symptoms.length} selected · not sent',
                          style: NemrasTextStyles.dataCaption.copyWith(
                            color: _DetailsPalette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final label in _symptomLabels)
                          FilterChip(
                            label: Text(label),
                            selected: _symptoms.contains(label),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _symptoms.add(label);
                                } else {
                                  _symptoms.remove(label);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _Panel(
                      title: 'Pickup location',
                      trailing: 'Not available',
                      body:
                          'No GPS fix or landmark is collected. Edit is unavailable.',
                    ),
                    const SizedBox(height: 10),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _DetailsPalette.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _DetailsPalette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Patient dossier',
                                    style: NemrasTextStyles.listTitle.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _DetailsPalette.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  demo ? 'Synthetic demo' : 'Signed-in record',
                                  style: NemrasTextStyles.dataCaption.copyWith(
                                    color: demo
                                        ? const Color(0xFF92400E)
                                        : _DetailsPalette.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: NemrasTextStyles.screenTitle.copyWith(
                                color: _DetailsPalette.text,
                              ),
                            ),
                            Text(
                              '${summary.age} yrs · ${summary.gender.isEmpty ? 'Sex not recorded' : summary.gender}',
                              style: NemrasTextStyles.bodyCaption.copyWith(
                                color: _DetailsPalette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _Flag(label: 'Blood $blood'),
                                _Flag(label: allergy),
                                _Flag(label: medication),
                                _Flag(label: condition),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const TextField(
                      enabled: false,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Optional notes',
                        hintText: 'Not collected',
                        filled: true,
                        fillColor: _DetailsPalette.card,
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: _DetailsPalette.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Notes are not transmitted.',
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _DetailsPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Panel(
                      title: 'Dispatch link',
                      body:
                          'This screen does not contact Rescue 1122 or place an ambulance in a queue.',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        AppRouter.emergencyTracking(widget.record),
                      ),
                      child: const Text('View tracking layout'),
                    ),
                    Text(
                      'Opening that page does not start tracking.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _DetailsPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Color(0xFF94A3B8),
                          ),
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                          elevation: WidgetStatePropertyAll(0),
                        ),
                        child: Text('Submit Request & Alert 1122'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierButton extends StatelessWidget {
  const _TierButton({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _DetailsPalette.tealLight : _DetailsPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _DetailsPalette.teal : _DetailsPalette.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: NemrasTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _DetailsPalette.text,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: NemrasTextStyles.dataCaption.copyWith(
                  color: _DetailsPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.body, this.trailing});

  final String title;
  final String body;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _DetailsPalette.tealLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: NemrasTextStyles.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _DetailsPalette.text,
                    ),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: _DetailsPalette.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _DetailsPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flag extends StatelessWidget {
  const _Flag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: NemrasTextStyles.dataCaption.copyWith(
            color: _DetailsPalette.text,
          ),
        ),
      ),
    );
  }
}

abstract final class _DetailsPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color sos = Color(0xFF9E1C23);
}
