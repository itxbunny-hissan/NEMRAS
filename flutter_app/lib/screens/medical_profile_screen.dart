import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';
import '../dev/demo_auth.dart';

/// Read-only copy of the Screen 16 reference.
///
/// Values come from the signed-in record. Editing, contacts, and
/// synchronization are not available.
class MedicalProfileScreen extends StatelessWidget {
  const MedicalProfileScreen({super.key, required this.record});

  final PatientRecord record;

  @override
  Widget build(BuildContext context) {
    final summary = record.summary;
    final name = summary.patientName.trim().isEmpty
        ? 'Name not recorded'
        : summary.patientName.trim();
    final demo = isDemoPatientRecord(record);
    final allergy = _shown(summary.allergy);
    final medication = _shown(summary.medication);
    final condition = _shown(summary.medicalCondition);
    final chronic = summary.chronicCondition.trim();
    final blood = summary.bloodType.trim().isEmpty
        ? 'Not recorded'
        : summary.bloodType.trim();

    return Scaffold(
      backgroundColor: _ProfilePalette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Medical Profile',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: _ProfilePalette.text,
                      ),
                    ),
                  ),
                  const Text(
                    'Not verified',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _ProfilePalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Editing is not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: _ProfilePalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: NemrasTextStyles.screenTitle.copyWith(
                              color: _ProfilePalette.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CNIC ${summary.cnic.isEmpty ? 'not recorded' : summary.cnic}',
                            style: NemrasTextStyles.bodyCaption.copyWith(
                              color: _ProfilePalette.textSecondary,
                            ),
                          ),
                          Text(
                            '${summary.age} yrs · ${summary.gender.isEmpty ? 'Sex not recorded' : summary.gender}',
                            style: NemrasTextStyles.bodyCaption.copyWith(
                              color: _ProfilePalette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            demo ? 'Synthetic demo record' : 'Signed-in record',
                            style: NemrasTextStyles.dataCaption.copyWith(
                              color: demo
                                  ? const Color(0xFF92400E)
                                  : _ProfilePalette.teal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Blood type: $blood',
                            style: NemrasTextStyles.listTitle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: _ProfilePalette.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Critical health baseline',
                      style: NemrasTextStyles.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _ProfilePalette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Label('Allergy'),
                          Text(
                            allergy ?? 'No allergy recorded',
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: _ProfilePalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _Label('Medication'),
                          Text(
                            medication ?? 'No medication recorded',
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: _ProfilePalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _Label('Condition on record'),
                          Text(
                            condition ?? 'No condition recorded',
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: _ProfilePalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const _Label('Chronic condition'),
                          Text(
                            chronic.isEmpty || chronic.toLowerCase() == 'no'
                                ? 'No chronic condition recorded'
                                : chronic,
                            style: NemrasTextStyles.bodySmall.copyWith(
                              color: _ProfilePalette.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Guardians and emergency contacts',
                      style: NemrasTextStyles.listTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _ProfilePalette.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _Card(
                      child: Text(
                        'No emergency contact is stored on this record.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _ProfilePalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Add Emergency Contact / Proxy'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This screen does not save or synchronize a dossier.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: _ProfilePalette.textSecondary,
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
                        child: Text('Save & Synchronize Dossier'),
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

String? _shown(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') return null;
  return trimmed;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _ProfilePalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _ProfilePalette.border),
      ),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: NemrasTextStyles.dataCaption.copyWith(
          color: _ProfilePalette.textSecondary,
        ),
      ),
    );
  }
}

abstract final class _ProfilePalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}
