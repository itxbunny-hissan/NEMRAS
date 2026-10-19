import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';

/// Stitch Screen 26 — Bed and hospital capacity.
///
/// NEMRAS holds no bed, unit or capacity data for this hospital, so every
/// figure the reference draws is reported as not available and every
/// adjustment control is disabled. The only live figure is the demo queue's
/// open-case count, which is labelled as such.
class BedCapacityScreen extends StatelessWidget {
  const BedCapacityScreen({super.key});

  /// Opens the screen as a page above the clinical shell.
  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => const BedCapacityScreen(),
      );

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final semantics = NemrasSemantics.of(context);

    return Scaffold(
      backgroundColor: semantics.screenBackground,
      appBar: AppBar(
        title: const Text('Bed & hospital capacity'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ClinicalContentArea(
        maxWidth: 820,
        children: <Widget>[
          _HospitalHeader(controller: controller),
          const ProvenanceNotice(
            icon: Icons.bed_outlined,
            message:
                'NEMRAS records no bed, unit or capacity data for this '
                'hospital. Nothing on this page is read from, or sent to, a '
                'hospital information system or a dispatch centre.',
          ),
          const ClinicalCard(
            title: 'Capacity summary',
            child: ClinicalWrapGrid(
              minCellWidth: 140,
              children: <Widget>[
                ClinicalMetric(
                  label: 'Available ED beds',
                  value: kNotAvailable,
                  caption: 'Not recorded',
                ),
                ClinicalMetric(
                  label: 'Occupied ED',
                  value: kNotAvailable,
                  caption: 'Not recorded',
                ),
                ClinicalMetric(
                  label: 'Facility-wide',
                  value: kNotAvailable,
                  caption: 'Not recorded',
                ),
              ],
            ),
          ),
          _QueuePressureCard(controller: controller),
          ClinicalCard(
            title: 'Unit breakdown',
            child: Text(
              'No units or wards are recorded for '
              '${controller.hospital.hospitalId}.',
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ),
          _CapacityAdjustmentCard(controller: controller),
        ],
      ),
    );
  }
}

class _HospitalHeader extends StatelessWidget {
  const _HospitalHeader({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: NemrasSpacing.l,
          runSpacing: NemrasSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(
              controller.hospital.displayName,
              style: NemrasTextStyles.screenTitle.copyWith(
                color: semantics.textPrimary,
              ),
            ),
            const DemoChip(),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          '${controller.hospital.hospitalId}  ·  Congestion status not '
          'available',
          style: NemrasTextStyles.dataCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QueuePressureCard extends StatelessWidget {
  const _QueuePressureCard({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final ready = controller.queueState == LoadState.ready;
    final open = controller.openCases.length;
    return ClinicalCard(
      title: 'Incoming demand',
      trailing: const DemoChip(label: 'DEMO QUEUE'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            ready
                ? '$open open ${open == 1 ? 'case' : 'cases'} in the demo '
                    'queue'
                : 'The demo queue is not loaded.',
            style: NemrasTextStyles.listTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            'No bed is assigned to any case.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityAdjustmentCard extends StatelessWidget {
  const _CapacityAdjustmentCard({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final staff = controller.staff;
    return ClinicalCard(
      title: 'Capacity adjustment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Capacity changes cannot be recorded in this build, so these '
            'controls are disabled.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Clinical unit',
              hintText: 'No unit is recorded',
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Available beds',
                  style: NemrasTextStyles.listTitle.copyWith(
                    color: semantics.textPrimary,
                  ),
                ),
              ),
              const IconButton(
                tooltip: 'Decrease is not available',
                onPressed: null,
                icon: Icon(Icons.remove),
              ),
              Text(
                '—',
                style: NemrasTextStyles.metricValue.copyWith(
                  color: semantics.textPlaceholder,
                ),
              ),
              const IconButton(
                tooltip: 'Increase is not available',
                onPressed: null,
                icon: Icon(Icons.add),
              ),
            ],
          ),
          const SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: false,
            onChanged: null,
            title: Text('Declare surge protocol'),
            subtitle: Text('Not available. No diversion is sent.'),
          ),
          const SizedBox(height: NemrasSpacing.s),
          ClinicalDataField(
            label: 'Signed in as',
            value: staff == null
                ? 'No clinical session'
                : '${staff.displayLabel} · ${staff.staffId}',
          ),
          const SizedBox(height: NemrasSpacing.xl),
          const SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Text('Save & broadcast is not available'),
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: null,
              child: Text('No changes to discard'),
            ),
          ),
        ],
      ),
    );
  }
}
