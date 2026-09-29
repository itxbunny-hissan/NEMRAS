import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class AuditLogScreen extends StatelessWidget {
  final PatientRecord record;
  const AuditLogScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final s = record.summary;

    final entries = [
      _Entry(
        dot: const Color.fromARGB(255, 0, 0, 0),
        name: 'Dr. ${s.doctor}',
        institution: s.hospital,
        badge: 'CLINICAL',
        badgeColor: AppTheme.primary,
        action: 'VIEW · CRITICAL SUMMARY',
        date: '16 MAY 14:32',
      ),
      const _Entry(
        dot: Color(0xFFF57C00),
        name: 'Paramedic ID 4421',
        institution: 'Rescue 1122',
        badge: 'FIELD',
        badgeColor: Color(0xFFF57C00),
        action: 'VOICE QUERY',
        date: '12 MAY 09:14',
      ),
      _Entry(
        dot: AppTheme.critical,
        name: 'Emergency Override',
        institution: s.hospital,
        badge: 'OVERRIDE',
        badgeColor: AppTheme.critical,
        action: 'DUAL-AUTH · DR. F. ALAN + DR. G. RAZA',
        date: '09 MAY',
      ),
      const _Entry(
        dot: AppTheme.accent,
        name: 'You · Self-Access',
        institution: '',
        badge: 'SELF',
        badgeColor: AppTheme.accent,
        action: 'VIEW · LAB RESULTS',
        date: '02 MAY 18:45',
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Audit Log',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
              icon: const Icon(Icons.check_circle_outline), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: const Text('PAST 7 DAYS · 12 ACCESSES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.muted,
                    letterSpacing: 0.8)),
          ),
          const SizedBox(height: 14),
          ...entries.map((e) => _LogTile(entry: e)),
        ],
      ),
    );
  }
}

class _Entry {
  final Color dot, badgeColor;
  final String name, institution, badge, action, date;
  const _Entry({
    required this.dot,
    required this.name,
    required this.institution,
    required this.badge,
    required this.badgeColor,
    required this.action,
    required this.date,
  });
}

class _LogTile extends StatelessWidget {
  final _Entry entry;
  const _LogTile({required this.entry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: entry.dot, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                  child: Text(entry.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.ink)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(entry.badge,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: entry.badgeColor)),
                ),
              ]),
              if (entry.institution.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(entry.institution,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.muted)),
              ],
              const SizedBox(height: 5),
              Text(entry.action,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2)),
              const SizedBox(height: 2),
              Text(entry.date,
                  style:
                      const TextStyle(fontSize: 11, color: AppTheme.muted)),
            ]),
          ),
        ]),
      );
}
