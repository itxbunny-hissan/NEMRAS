import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class RiskBadge extends StatelessWidget {
  final String risk;
  const RiskBadge(this.risk, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.riskColor(risk);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 9, color: c),
        const SizedBox(width: 7),
        Text(risk,
            style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

class AlertCard extends StatelessWidget {
  final Alert alert;
  const AlertCard(this.alert, {super.key});

  IconData _icon(String s) {
    switch (s) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.severityColor(alert.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: c, width: 4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(_icon(alert.severity), color: c, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert.title,
                style: TextStyle(fontWeight: FontWeight.w700, color: c, fontSize: 14)),
            const SizedBox(height: 3),
            Text(alert.detail,
                style: const TextStyle(color: AppTheme.ink, fontSize: 13, height: 1.35)),
          ]),
        ),
      ]),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const InfoTile(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAEC)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.muted, letterSpacing: 0.3)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.ink)),
      ]),
    );
  }
}
