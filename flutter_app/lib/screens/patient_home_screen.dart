import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';

class PatientHomeScreen extends StatelessWidget {
  final PatientRecord record;
  final void Function(int tab) onTabChange;

  const PatientHomeScreen({
    super.key,
    required this.record,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final s = record.summary;
    final riskColor = AppTheme.riskColor(s.riskScore);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header ─────────────────────────────────────
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('GOOD MORNING',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.muted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(s.patientName,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink)),
              ]),
              const Spacer(),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: const Color(0xFFE2EAEC)),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppTheme.ink, size: 22),
              ),
            ]),
            const SizedBox(height: 20),

            // ── Patient card ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF083A39), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.patientName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  _RiskPill(s.riskScore),
                ]),
                const SizedBox(height: 8),
                Text('CNIC · ${s.cnic}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 12)),
              ]),
            ),
            const SizedBox(height: 26),

            // ── Quick Actions ───────────────────────────────
            const _SectionHeader(title: 'QUICK ACTIONS', action: 'View all'),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickAction(
                    icon: Icons.timeline,
                    label: 'Timeline',
                    onTap: () => onTabChange(1)),
                _QuickAction(
                    icon: Icons.medication_outlined,
                    label: 'Meds',
                    onTap: () => onTabChange(1)),
                _QuickAction(
                    icon: Icons.smart_toy_outlined,
                    label: 'Chat AI',
                    onTap: () => onTabChange(2)),
                _QuickAction(
                    icon: Icons.shield_outlined,
                    label: 'Permits',
                    onTap: () => onTabChange(3)),
              ],
            ),
            const SizedBox(height: 26),

            // ── Risk alert (elevated / critical only) ───────
            if (s.riskScore == 'Critical' || s.riskScore == 'Elevated') ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.monitor_heart, color: riskColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.riskScore} Risk · ${s.medicalCondition}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: riskColor,
                                  fontSize: 13)),
                          Text('Triage Level: ${s.triageLevel}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.muted)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ],

            // ── Recent Activity ─────────────────────────────
            const _SectionHeader(title: 'RECENT ACTIVITY', action: 'See all'),
            const SizedBox(height: 14),
            _ActivityTile(
              icon: Icons.science_outlined,
              color: AppTheme.primary,
              title: 'Lab Results Available',
              subtitle: '${s.testResults} · ${s.hospital}',
              time: '2h',
            ),
            const SizedBox(height: 10),
            _ActivityTile(
              icon: Icons.person_outlined,
              color: AppTheme.accent,
              title: 'Dr. ${s.doctor} accessed record',
              subtitle: s.hospital,
              time: 'Yesterday\n14:22',
            ),
            const SizedBox(height: 10),
            _ActivityTile(
              icon: Icons.medication_outlined,
              color: AppTheme.high,
              title: '${s.medication} prescription active',
              subtitle: 'Current medication on record',
              time: 'Active',
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────

class _RiskPill extends StatelessWidget {
  final String risk;
  const _RiskPill(this.risk);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(risk.toUpperCase(),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title, action;
  const _SectionHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.muted,
                letterSpacing: 1)),
        const Spacer(),
        Text(action,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.primary,
                fontWeight: FontWeight.w600)),
      ]);
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 28),
          ),
          const SizedBox(height: 7),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle, time;
  const _ActivityTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.ink)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.muted)),
            ]),
          ),
          Text(time,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
        ]),
      );
}
