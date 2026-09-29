import 'package:flutter/material.dart';
import '../api.dart';
import '../theme.dart';
import 'audit_log_screen.dart';

class ProfileScreen extends StatefulWidget {
  final PatientRecord record;
  const ProfileScreen({super.key, required this.record});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _fatherAccess = true;
  bool _sisterAccess = false;
  bool _emergencyOverride = true;

  @override
  Widget build(BuildContext context) {
    final s = widget.record.summary;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Permissions',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Patient info card ──────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                child: Text(
                  s.patientName.isNotEmpty ? s.patientName[0] : '?',
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(s.patientName,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink)),
                  const SizedBox(height: 3),
                  Text('${s.cnic} · ${s.gender} · ${s.age} yrs',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.muted)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // ── Family Access ──────────────────────────────
          const _SectionLabel('FAMILY ACCESS'),
          const SizedBox(height: 10),
          _AccessTile(
            name: 'Sajjad Ahmed',
            role: 'FATHER',
            level: 'FULL ACCESS',
            value: _fatherAccess,
            onChanged: (v) => setState(() => _fatherAccess = v),
          ),
          const SizedBox(height: 8),
          _AccessTile(
            name: 'Ayasha Sajjad',
            role: 'SISTER',
            level: 'VIEW ONLY',
            value: _sisterAccess,
            onChanged: (v) => setState(() => _sisterAccess = v),
          ),
          const SizedBox(height: 22),

          // ── Emergency Override ─────────────────────────
          const _SectionLabel('EMERGENCY OVERRIDE'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.high.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.high, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Allow Emergency Override',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.ink)),
                ),
                Switch(
                  value: _emergencyOverride,
                  onChanged: (v) => setState(() => _emergencyOverride = v),
                  activeThumbColor: AppTheme.primary,
                ),
              ]),
              const SizedBox(height: 8),
              const Text('Two-doctor authorization required',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text(
                'When enabled, ER staff can access your full record without '
                'consent in life-threatening situations. You will be notified instantly.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.muted, height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 22),

          // ── Audit log link ─────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        AuditLogScreen(record: widget.record))),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EAEC)),
              ),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history, color: AppTheme.accent, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Access Audit Log',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.ink)),
                    SizedBox(height: 2),
                    Text('Who saw what · when',
                        style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                  ]),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.muted),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.muted,
          letterSpacing: 1));
}

class _AccessTile extends StatelessWidget {
  final String name, role, level;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessTile({
    required this.name,
    required this.role,
    required this.level,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2EAEC)),
        ),
        child: Row(children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFF0F4F4),
            child: Icon(Icons.person_outline, color: AppTheme.muted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.ink)),
              const SizedBox(height: 2),
              Text('$role · $level',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.muted)),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
          ),
        ]),
      );
}
