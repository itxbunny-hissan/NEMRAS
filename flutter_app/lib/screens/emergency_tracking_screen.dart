import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../api.dart';

/// Informational copy of the Screen 15 reference.
///
/// No unit, route, ETA, or responder is shown as assigned.
class EmergencyTrackingScreen extends StatelessWidget {
  const EmergencyTrackingScreen({super.key, required this.record});

  final PatientRecord record;

  @override
  Widget build(BuildContext context) {
    final hospital = record.summary.hospital.trim();
    return Scaffold(
      backgroundColor: _TrackPalette.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      'Active Emergency Dispatch',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NemrasTextStyles.screenTitle.copyWith(
                        color: _TrackPalette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _Notice(
                      title: 'No incident is active',
                      body:
                          'No unit has been dispatched. This page does not track a vehicle or share a location.',
                    ),
                    const SizedBox(height: 12),
                    const _Card(
                      title: 'Arrival time',
                      body: 'Not calculated. No remaining distance is available.',
                    ),
                    const SizedBox(height: 10),
                    _Card(
                      title: 'Route',
                      body: hospital.isEmpty
                          ? 'No hospital is on this record, and no route is drawn.'
                          : 'Hospital on record: $hospital. No route is drawn.',
                    ),
                    const SizedBox(height: 10),
                    const _Card(
                      title: 'Incident steps',
                      body:
                          'Submitted, assigned, en route, arrived, and handover are not started.',
                    ),
                    const SizedBox(height: 10),
                    const _Card(
                      title: 'Responder',
                      body:
                          'No responder is assigned. A health summary has not been sent.',
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: null,
                        child: Text('Call crew is not available'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Audio note is not available'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Back to details'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There is no emergency request to cancel.',
                      textAlign: TextAlign.center,
                      style: NemrasTextStyles.bodyCaption.copyWith(
                        color: _TrackPalette.textSecondary,
                      ),
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

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
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
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _TrackPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _TrackPalette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _TrackPalette.border),
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
                color: _TrackPalette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: _TrackPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class _TrackPalette {
  static const Color canvas = Color(0xFFF7FAFC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF243746);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}
