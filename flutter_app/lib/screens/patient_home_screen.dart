import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';
import '../dev/demo_auth.dart';
import '../navigation/app_router.dart';
import 'sos_emergency_screen.dart';

/// Signed-in patient home. Visual layout follows the Screen 12 reference.
///
/// Record fields come from the signed-in [PatientRecord]. Dispatch, GPS,
/// NADRA, and emergency contacts are not available and are labeled as such.
class PatientHomeScreen extends StatelessWidget {
  final PatientRecord record;
  final void Function(int tab) onTabChange;

  const PatientHomeScreen({
    super.key,
    required this.record,
    required this.onTabChange,
  });

  void _unavailable(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openSos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SosEmergencyScreen(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = record.summary;
    final demo = isDemoPatientRecord(record);
    final allergy = _present(s.allergy);
    final medication = _present(s.medication);
    final blood = _present(s.bloodType);
    final hospital = _present(s.hospital);
    final notes = record.alerts.length;

    return Scaffold(
      backgroundColor: _HomePalette.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                onNotifications: () => _unavailable(
                  context,
                  'Notifications',
                  'Notifications are not available in this prototype.',
                ),
                onProfile: () => onTabChange(3),
              ),
              const SizedBox(height: 14),
              _IdentityCard(
                name: s.patientName.isEmpty ? 'Name not recorded' : s.patientName,
                cnic: s.cnic.isEmpty ? 'CNIC not recorded' : s.cnic,
                triage: s.triageLevel.isEmpty
                    ? 'Triage not recorded'
                    : 'Triage ${s.triageLevel}',
                synthetic: demo,
              ),
              if (s.riskScore == 'Critical' || s.riskScore == 'Elevated') ...[
                const SizedBox(height: 12),
                _RiskBanner(
                  risk: s.riskScore,
                  condition: s.medicalCondition,
                  triage: s.triageLevel,
                ),
              ],
              const SizedBox(height: 12),
              _DispatchCard(onPressed: () => _openSos(context)),
              const SizedBox(height: 12),
              _LocationCard(
                onChange: () => _unavailable(
                  context,
                  'Location',
                  'This screen does not read or change a GPS location.',
                ),
              ),
              const SizedBox(height: 12),
              const _StatusCard(
                title: 'No dispatch has been sent',
                body: 'Emergency dispatch is not connected from this app.',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.medical_information_outlined,
                      title: 'Medical profile',
                      onTap: () => Navigator.of(context).push(
                        AppRouter.medicalProfile(record),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _Chip(
                                label: blood ?? 'Blood type not recorded',
                                filled: blood != null,
                              ),
                              _Chip(
                                label: allergy ?? 'No allergy recorded',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            medication ?? 'No medication on record',
                            style: NemrasTextStyles.bodyCaption.copyWith(
                              color: _HomePalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.contact_phone_outlined,
                      title: 'Emergency contacts',
                      onTap: () => Navigator.of(context).push(
                        AppRouter.medicalProfile(record),
                      ),
                      child: Text(
                        'Not on file',
                        style: NemrasTextStyles.bodyCaption.copyWith(
                          color: _HomePalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.history,
                      title: 'Record notes',
                      onTap: () => onTabChange(1),
                      child: Text(
                        notes == 0
                            ? 'No notes on file'
                            : '$notes note${notes == 1 ? '' : 's'} on file',
                        style: NemrasTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _HomePalette.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoCard(
                      icon: Icons.local_hospital_outlined,
                      title: 'Hospital on record',
                      onTap: () => _unavailable(
                        context,
                        'Hospital distance',
                        'Distance to a hospital is not calculated.',
                      ),
                      child: Text(
                        hospital == null
                            ? 'No hospital on record'
                            : '$hospital\nDistance not calculated',
                        style: NemrasTextStyles.bodyCaption.copyWith(
                          color: _HomePalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _PrivacyNote(),
            ],
          ),
        ),
      ),
    );
  }
}

String? _present(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toLowerCase() == 'none') return null;
  return trimmed;
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotifications, required this.onProfile});

  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            color: _HomePalette.teal,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.emergency, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'NEMRAS',
                    style: NemrasTextStyles.screenTitle.copyWith(
                      color: _HomePalette.text,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _HomePalette.tealLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        'CITIZEN',
                        style: NemrasTextStyles.dataCaption.copyWith(
                          color: _HomePalette.teal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Signed in',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _HomePalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: onNotifications,
          icon: const Icon(Icons.notifications_none),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfile,
          style: IconButton.styleFrom(
            backgroundColor: _HomePalette.teal,
            foregroundColor: Colors.white,
            fixedSize: const Size(36, 36),
          ),
          icon: const Icon(Icons.person, size: 18),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.cnic,
    required this.triage,
    required this.synthetic,
  });

  final String name;
  final String cnic;
  final String triage;
  final bool synthetic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomePalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: _HomePalette.tealLight,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.person, color: _HomePalette.teal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NemrasTextStyles.screenTitle.copyWith(
                      color: _HomePalette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CNIC $cnic',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: _HomePalette.textSecondary,
                    ),
                  ),
                  Text(
                    triage,
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: _HomePalette.teal,
                    ),
                  ),
                  if (synthetic)
                    Text(
                      'Synthetic demo record',
                      style: NemrasTextStyles.dataCaption.copyWith(
                        color: const Color(0xFF92400E),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomePalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'EMERGENCY',
                    style: NemrasTextStyles.fieldLabel.copyWith(
                      color: _HomePalette.sos,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    child: Text(
                      'Not connected',
                      style: NemrasTextStyles.dataCaption.copyWith(
                        color: _HomePalette.sos,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 120,
              height: 120,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: _HomePalette.sos,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emergency, size: 28),
                    Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Emergency dispatch is not available',
              textAlign: TextAlign.center,
              style: NemrasTextStyles.listTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: _HomePalette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This button does not contact an ambulance or a hospital.',
              textAlign: TextAlign.center,
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _HomePalette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: _HomePalette.canvas,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 18, color: _HomePalette.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hold does not send a silent alert.',
                        style: NemrasTextStyles.bodyCaption.copyWith(
                          color: _HomePalette.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onPressed,
                      style: TextButton.styleFrom(
                        backgroundColor: _HomePalette.sos,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Hold to SOS'),
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.onChange});

  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomePalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_off_outlined, size: 18, color: _HomePalette.teal),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Location not available',
                    style: NemrasTextStyles.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _HomePalette.text,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onChange,
                  child: const Text('Change'),
                ),
              ],
            ),
            Text(
              'No GPS fix is shown. Coordinates are not read on this screen.',
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _HomePalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomePalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _HomePalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: _HomePalette.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: NemrasTextStyles.listTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _HomePalette.text,
                    ),
                  ),
                  Text(
                    body,
                    style: NemrasTextStyles.bodyCaption.copyWith(
                      color: _HomePalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomePalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _HomePalette.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: _HomePalette.teal),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, size: 16, color: _HomePalette.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: NemrasTextStyles.listTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _HomePalette.text,
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: NemrasTextStyles.dataCaption.copyWith(
            color: filled ? _HomePalette.sos : _HomePalette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({
    required this.risk,
    required this.condition,
    required this.triage,
  });

  final String risk;
  final String condition;
  final String triage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.monitor_heart_outlined, color: _HomePalette.sos),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$risk risk'
                '${condition.isEmpty ? '' : ' · $condition'}'
                '${triage.isEmpty ? '' : ' · Triage $triage'}',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: _HomePalette.sos,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _HomePalette.tealLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 18, color: _HomePalette.teal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'This screen does not share a location. Medical details shown '
                'here come from the signed-in record and are not sent to a '
                'dispatch service.',
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _HomePalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _HomePalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color tealLight = Color(0xFFE8F6F3);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color sos = Color(0xFF9E1C23);
}
