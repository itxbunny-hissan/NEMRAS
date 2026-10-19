import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// Informational copy of the Screen 11 reference.
///
/// Notifications are not requested or scheduled.
class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

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
      backgroundColor: _AlertPalette.canvas,
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
                      backgroundColor: _AlertPalette.card,
                      side: const BorderSide(color: _AlertPalette.border),
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
                      color: _AlertPalette.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.notifications_none,
                size: 48,
                color: _AlertPalette.teal,
              ),
              const SizedBox(height: 12),
              Text(
                'Emergency Alerts & Updates',
                style: NemrasTextStyles.summaryName.copyWith(
                  fontSize: 24,
                  color: _AlertPalette.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Notification permission is not requested in this prototype. '
                'No alert will be sent.',
                style: NemrasTextStyles.body.copyWith(
                  fontSize: 13.5,
                  color: _AlertPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const _AlertCard(
                title: 'Record-access alerts',
                body: 'This prototype does not send a message when a record is opened.',
              ),
              const _AlertCard(
                title: 'Arrival and queue updates',
                body: 'Live arrival times and bed reservations are not shown here.',
              ),
              const _AlertCard(
                title: 'Family access requests',
                body: 'Guardian approval is not available on this screen.',
              ),
              const SizedBox(height: 8),
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
                  child: Text('Enable Urgent Notifications'),
                ),
              ),
              TextButton(
                onPressed: () => _signIn(context),
                style: TextButton.styleFrom(
                  foregroundColor: _AlertPalette.textSecondary,
                ),
                child: const Text('Remind Me Later'),
              ),
              Text(
                'This does not schedule a reminder. Sign-in is required '
                'before the patient home.',
                textAlign: TextAlign.center,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _AlertPalette.textSecondary,
                ),
              ),
              TextButton(
                onPressed: () => _signIn(context),
                style: TextButton.styleFrom(
                  foregroundColor: _AlertPalette.teal,
                ),
                child: const Text('Continue to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _AlertPalette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AlertPalette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: NemrasTextStyles.listTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _AlertPalette.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: NemrasTextStyles.bodyCaption.copyWith(
                  color: _AlertPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

abstract final class _AlertPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color teal = Color(0xFF0F766E);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
}
