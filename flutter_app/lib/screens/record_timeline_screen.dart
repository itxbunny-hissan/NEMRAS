import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class RecordTimelineScreen extends StatelessWidget {
  final PatientRecord record;
  const RecordTimelineScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final s = record.summary;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Medical Record',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VisitCard(
            hospital: s.hospital,
            admissionType: s.admissionType,
            admissionDate: s.admissionDate,
            dischargeDate: s.dischargeDate,
            condition: s.medicalCondition,
          ),
          const SizedBox(height: 12),
          _LabCard(
            result: s.testResults,
            hospital: s.hospital,
            date: s.admissionDate,
          ),
          const SizedBox(height: 12),
          _MedicationCard(
            name: s.medication,
            doctor: s.doctor,
            date: s.admissionDate,
          ),
          const SizedBox(height: 12),
          if (s.allergy.toLowerCase() != 'none') ...[
            _AllergyCard(allergy: s.allergy),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Card widgets
// ─────────────────────────────────────────────────────────────

class _VisitCard extends StatelessWidget {
  final String hospital, admissionType, admissionDate, dischargeDate, condition;
  const _VisitCard({
    required this.hospital,
    required this.admissionType,
    required this.admissionDate,
    required this.dischargeDate,
    required this.condition,
  });

  String _icdFor(String c) {
    const map = {
      'Diabetes': '5A10',
      'Cancer': '2A00',
      'Obesity': '5B81',
      'Asthma': 'CA23',
      'Arthritis': 'FA22',
      'Hypertension': 'BA00',
    };
    return map[c] ?? 'M12.0';
  }

  @override
  Widget build(BuildContext context) {
    final discharged = dischargeDate.isNotEmpty;
    return _TimelineCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(hospital,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.ink)),
          ),
          _Badge(
            discharged ? 'DISCHARGED' : 'ADMITTED',
            discharged ? AppTheme.primary : AppTheme.high,
          ),
        ]),
        const SizedBox(height: 3),
        Text('$admissionType Visit',
            style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
        const SizedBox(height: 8),
        Text(admissionDate,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _InfoChip('ICD-11 · ${_icdFor(condition)}'),
          const _InfoChip('3 NOTES'),
          const _InfoChip('2 LABS'),
        ]),
      ]),
    );
  }
}

class _LabCard extends StatelessWidget {
  final String result, hospital, date;
  const _LabCard(
      {required this.result, required this.hospital, required this.date});

  @override
  Widget build(BuildContext context) {
    final isNormal = result.toLowerCase() == 'normal';
    final color = isNormal ? AppTheme.stable : AppTheme.high;
    return _TimelineCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('CBC · Complete Blood Count',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.ink)),
          ),
          _Badge(result.toUpperCase(), color),
        ]),
        const SizedBox(height: 4),
        Text('$date · $hospital',
            style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
        const SizedBox(height: 14),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _LabValue(label: 'HB', value: '13.2', unit: 'g/dL'),
            _LabValue(label: 'WBC', value: '7.4 ×10³', unit: ''),
            _LabValue(label: 'PLT', value: '208', unit: 'K'),
          ],
        ),
      ]),
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final String name, doctor, date;
  const _MedicationCard(
      {required this.name, required this.doctor, required this.date});

  @override
  Widget build(BuildContext context) => _TimelineCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_outlined,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('$name 500mg',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.ink)),
                ),
                const _Badge('ACTIVE', AppTheme.primary),
              ]),
              const SizedBox(height: 4),
              Text('PRESCRIBED · DR. ${doctor.toUpperCase()}',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.muted,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(date,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.muted)),
            ]),
          ),
        ]),
      );
}

class _AllergyCard extends StatelessWidget {
  final String allergy;
  const _AllergyCard({required this.allergy});

  @override
  Widget build(BuildContext context) => _TimelineCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.critical.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dangerous_outlined,
                color: AppTheme.critical, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text('Allergy: $allergy',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.ink)),
                ),
                const _Badge('ALERT', AppTheme.critical),
              ]),
              const SizedBox(height: 4),
              const Text('Documented in patient record',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted)),
            ]),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final Widget child;
  const _TimelineCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: child,
      );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.muted,
                fontWeight: FontWeight.w500)),
      );
}

class _LabValue extends StatelessWidget {
  final String label, value, unit;
  const _LabValue(
      {required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.muted, letterSpacing: 0.5)),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink),
              children: unit.isNotEmpty
                  ? [
                      TextSpan(
                          text: '  $unit',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.muted))
                    ]
                  : [],
            ),
          ),
        ],
      );
}
