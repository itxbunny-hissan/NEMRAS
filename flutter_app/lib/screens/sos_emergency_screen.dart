import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';
import '../navigation/app_router.dart';

/// Informational copy of the Screen 13 reference.
///
/// Category selection stays on this page. Nothing is dispatched, called, or
/// located.
class SosEmergencyScreen extends StatefulWidget {
  const SosEmergencyScreen({super.key, required this.record});

  final PatientRecord record;

  @override
  State<SosEmergencyScreen> createState() => _SosEmergencyScreenState();
}

class _SosEmergencyScreenState extends State<SosEmergencyScreen> {
  int _category = 0;

  static const _categories = <(IconData, String, String)>[
    (Icons.monitor_heart_outlined, 'Medical / Cardiac', 'Not sent'),
    (Icons.car_crash_outlined, 'RTA / Trauma', 'Not sent'),
    (Icons.local_fire_department_outlined, 'Fire / Burns', 'Not sent'),
    (Icons.air, 'Respiratory', 'Not sent'),
  ];

  String get _incidentLabel => _category == 4
      ? 'Other / unspecified'
      : _categories[_category].$2;

  @override
  Widget build(BuildContext context) {
    final summary = widget.record.summary;
    final blood = summary.bloodType.trim().isEmpty
        ? 'Blood type not recorded'
        : 'Blood ${summary.bloodType}';
    final allergy = summary.allergy.trim().isEmpty
        ? 'No allergy recorded'
        : summary.allergy;

    return Scaffold(
      backgroundColor: _SosPalette.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'PROTOTYPE',
                      style: NemrasTextStyles.tag.copyWith(
                        color: _SosPalette.sos,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel / Exit'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Incident type',
                      style: NemrasTextStyles.fieldLabel.copyWith(
                        color: _SosPalette.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Not sent',
                    style: NemrasTextStyles.dataCaption.copyWith(
                      color: _SosPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: [
                  for (var i = 0; i < _categories.length; i++)
                    _CategoryButton(
                      icon: _categories[i].$1,
                      title: _categories[i].$2,
                      subtitle: _categories[i].$3,
                      selected: _category == i,
                      onTap: () => setState(() => _category = i),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _category = 4),
                icon: const Icon(Icons.emergency_outlined, size: 18),
                label: const Text('Other / unspecified'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _category == 4
                      ? _SosPalette.sos
                      : _SosPalette.text,
                  side: BorderSide(
                    color: _category == 4
                        ? _SosPalette.sos
                        : _SosPalette.border,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 168,
                  height: 168,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _SosPalette.sos,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Does not dispatch',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Holding this control does not start a timer or contact a service.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _SosPalette.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  AppRouter.emergencyDetails(
                    widget.record,
                    incident: _incidentLabel,
                  ),
                ),
                child: const Text('View emergency details'),
              ),
              Text(
                'Opening that page does not alert 1122.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _SosPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _SosPalette.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _SosPalette.border),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch channel: not connected',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _SosPalette.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This prototype does not contact Rescue 1122, send a location, or alert a hospital.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _SosPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _SosPalette.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _SosPalette.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'On this record, not transmitted',
                        style: NemrasTextStyles.listTitle.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _SosPalette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$blood · $allergy',
                        style: NemrasTextStyles.bodySmall.copyWith(
                          color: _SosPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: null,
                  child: Text('Call 1122 is not started here'),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('Location refresh is not available'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFDAD7) : _SosPalette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? _SosPalette.sos : _SosPalette.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _SosPalette.sos),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _SosPalette.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NemrasTextStyles.dataCaption.copyWith(
                        color: _SosPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _SosPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color sos = Color(0xFF9E1C23);
}
