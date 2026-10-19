import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 10 reference.
///
/// Location is not requested, stored, or shared.
class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  void _signIn(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(NemrasRouteNames.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _LocationPalette.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => _signIn(context),
                    style: IconButton.styleFrom(
                      backgroundColor: _LocationPalette.card,
                      side: const BorderSide(color: _LocationPalette.border),
                      fixedSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.chevron_left, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    'PROTOTYPE',
                    style: NemrasTextStyles.tag.copyWith(
                      color: _LocationPalette.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(
                Icons.my_location_outlined,
                size: 48,
                color: _LocationPalette.teal,
              ),
              const SizedBox(height: 16),
              Text(
                'Enable Emergency Location',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.summaryName.copyWith(
                  fontSize: 22,
                  color: _LocationPalette.text,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Location permission is not requested in this prototype. '
                'No coordinates are read or shared.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.body.copyWith(
                  fontSize: 13.5,
                  color: _LocationPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(Color(0xFF94A3B8)),
                    foregroundColor: WidgetStatePropertyAll(Colors.white),
                    elevation: WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  child: Text('Allow Precise Location'),
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _LocationPalette.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _LocationPalette.border),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manual emergency location',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _LocationPalette.text,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'No district is saved.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _LocationPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: null,
                  child: Text('Set Default'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  NemrasRouteNames.notificationPermission,
                ),
                style: TextButton.styleFrom(
                  foregroundColor: _LocationPalette.teal,
                ),
                child: const Text('View notification layout'),
              ),
              Text(
                'Opening that layout does not enable alerts.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _LocationPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _LocationPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
