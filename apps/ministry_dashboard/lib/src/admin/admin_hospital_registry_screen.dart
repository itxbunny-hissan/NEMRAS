import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/hospital_aggregate_models.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../screens/hospital_network_screen.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Stitch Screen 38 — hospital network management.
///
/// Facility record counts appear only when an aggregate endpoint supplies
/// them. Beds, telemetry, coordinates and diversion state are not recorded,
/// and no facility can be onboarded or diverted from here.
class AdminHospitalRegistryScreen extends StatelessWidget {
  const AdminHospitalRegistryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.hospitalState.isLoading) {
      return const NationalLoadingState(message: 'Reading the facility list');
    }
    if (controller.hospitalState.hasFailed) {
      return NationalErrorState(
        title: 'Facility list unavailable',
        message: controller.hospitalError ??
            'The hospital aggregate source returned an error.',
        onRetry: controller.refreshHospitalNetwork,
      );
    }

    final summary = controller.hospitalSummary;
    final facilities = summary != null && summary.isAvailable
        ? summary.hospitals
        : const <HospitalAggregate>[];

    return NationalContentArea(
      children: <Widget>[
        const _RegistryBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Hospital network',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'No live capacity, telemetry or diversion feed is connected.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: facilities.isEmpty
                  ? NationalMetric.unavailable(
                      label: 'Facilities connected',
                      basis: summary?.hasNoEndpoint == true
                          ? kHospitalAggregationUnavailable
                          : 'No facilities were returned',
                      caption: 'Not available.',
                    )
                  : NationalMetric.datasetAggregate(
                      label: 'Facilities in the aggregate',
                      value: facilities.length,
                      basis: 'Rows from the hospital aggregate endpoint',
                      caption: 'Record counts. Not hospitals online.',
                    ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Telemetry synchronised',
                basis: 'No facility telemetry is connected',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'High-latency nodes',
                basis: 'No gateway latency is measured',
                caption: 'Not available.',
              ),
            ),
            NationalKpiCard(
              metric: NationalMetric.unavailable(
                label: 'Surge diversions',
                basis: 'No diversion feed is connected',
                caption: 'Not available.',
              ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Search facilities',
            hintText: 'Not available',
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: Text('Territory filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Tier filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Status filter not available'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const NationalLabel('Facility directory'),
              const SizedBox(height: NemrasSpacing.s),
              if (facilities.isEmpty)
                Text(
                  'No facility directory is recorded.',
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                )
              else
                for (final facility in facilities) ...<Widget>[
                  const SizedBox(height: NemrasSpacing.l),
                  Text(
                    facility.hospitalName,
                    style: NemrasTextStyles.listTitle.copyWith(
                      color: semantics.textPrimary,
                    ),
                  ),
                  Text(
                    '${facility.recordCount} dataset records · '
                    'beds $kNotAvailable · location $kNotAvailable',
                    style: NemrasTextStyles.bodyCaption.copyWith(
                      color: semantics.textSecondary,
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NationalLabel('Selected facility'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No facility is selected.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const NationalWrapGrid(
                minTileWidth: 150,
                children: <Widget>[
                  NationalField(label: 'Administrator', value: 'Not recorded'),
                  NationalField(label: 'Licensed beds', value: kNotAvailable),
                  NationalField(label: 'Telemetry', value: kNotAvailable),
                  NationalField(label: 'Coordinates', value: kNotAvailable),
                ],
              ),
              const SizedBox(height: NemrasSpacing.l),
              const FilledButton(
                onPressed: null,
                child: Text('Updating facility credentials is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Initiating a surge diversion is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Onboarding a facility is not available'),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text('Decommissioning a facility is not available'),
              ),
              const SizedBox(height: NemrasSpacing.l),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Hospital network'),
                          leading: IconButton(
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        body: const HospitalNetworkScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.local_hospital_outlined, size: 16),
                  label: const Text('Open national hospital network'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RegistryBanner extends StatelessWidget {
  const _RegistryBanner();

  @override
  Widget build(BuildContext context) {
    final elevated = NemrasSemantics.of(context).elevated;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: elevated.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border.all(color: elevated.solid),
      ),
      child: Text(
        'NO LIVE FACILITY DIRECTORY. Capacity numbers on the reference are '
        'not used. Nothing here contacts a hospital.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
