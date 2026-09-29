import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class SummaryScreen extends StatelessWidget {
  final PatientRecord record;
  const SummaryScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final s = record.summary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Critical Health Summary',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Patient header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white24,
                  child: Text(s.patientName.isNotEmpty ? s.patientName[0] : '?',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(s.patientName,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${s.age} yrs · ${s.gender} · ${s.cnic}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                _chip(Icons.bloodtype, s.bloodType),
                const SizedBox(width: 8),
                _chip(Icons.local_fire_department, 'Triage ${s.triageLevel}'),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Risk score banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.riskColor(s.riskScore).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.riskColor(s.riskScore).withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Icon(Icons.monitor_heart, color: AppTheme.riskColor(s.riskScore), size: 30),
              const SizedBox(width: 14),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI RISK SCORE',
                    style: TextStyle(fontSize: 11, color: AppTheme.muted, letterSpacing: 0.5)),
              ]),
              const Spacer(),
              RiskBadge(s.riskScore),
            ]),
          ),
          const SizedBox(height: 20),

          _sectionTitle('AI Decision Support · Alerts'),
          const SizedBox(height: 10),
          ...record.alerts.map((a) => AlertCard(a)),
          const SizedBox(height: 16),

          _sectionTitle('Clinical Snapshot'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              InfoTile(Icons.coronavirus, 'Condition', s.medicalCondition),
              InfoTile(Icons.medication, 'Medication', s.medication),
              InfoTile(Icons.dangerous, 'Allergy', s.allergy),
              InfoTile(Icons.repeat, 'Chronic', s.chronicCondition),
              InfoTile(Icons.science, 'Test Result', s.testResults),
              InfoTile(Icons.emergency, 'Admission', s.admissionType),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(cnic: s.cnic, name: s.patientName))),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ask the NEMRAS Health Assistant',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Access logged · Patient notified · Audit trail active',
                style: TextStyle(fontSize: 11, color: AppTheme.muted)),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _chip(IconData i, String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white24, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink));
}
