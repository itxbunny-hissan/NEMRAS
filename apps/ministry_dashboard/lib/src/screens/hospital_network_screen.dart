import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/geography.dart';
import '../data/hospital_aggregate_models.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 4 — Hospital Network.
///
/// In Phase 5A this screen's honest state is "no endpoint". `Hospital` is a
/// dataset column, but nothing aggregates by it, and the only way to build
/// the view client-side would be to read every patient record into the
/// browser. So the screen states the exact required phrase, names the
/// endpoint that would resolve it, and renders a real table the moment a
/// repository supplies one — which is why the table is written even though
/// the shipped repository never returns rows.
class HospitalNetworkScreen extends StatelessWidget {
  const HospitalNetworkScreen({super.key, this.onNavigate});

  /// Switches the shell sidebar. Null when the screen is shown on its own.
  final ValueChanged<int>? onNavigate;

  static const List<({String requirement, String detail})> _requirements =
      <({String requirement, String detail})>[
    (
      requirement: 'GET /api/aggregate/hospitals',
      detail: 'Returns one row per facility with record, emergency and '
          'risk-tier counts. No patient fields of any kind.',
    ),
    (
      requirement: 'Server-side grouping',
      detail: 'The grouping must happen in the backend, so the client never '
          'holds the rows the counts were derived from.',
    ),
    (
      requirement: 'Small-cell suppression',
      detail: 'A facility contributing very few records could be '
          're-identifying, so low counts need suppressing before release.',
    ),
    (
      requirement: 'Facility registry',
      detail: 'Hospital is free text in the dataset, so two spellings of one '
          'facility would currently count as two facilities.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.hospitalState.isLoading) {
      return const NationalLoadingState(
        message: 'Requesting hospital aggregation',
      );
    }
    if (controller.hospitalState.hasFailed) {
      return NationalErrorState(
        title: 'Hospital aggregation failed',
        message: controller.hospitalError ??
            'The hospital aggregate source returned an error.',
        onRetry: controller.refreshHospitalNetwork,
      );
    }

    final summary = controller.hospitalSummary;
    if (summary == null) {
      return const NationalEmptyState(
        title: 'Hospital network not loaded',
        message: 'The hospital aggregate source has not been queried.',
        icon: Icons.local_hospital_outlined,
      );
    }

    return NationalContentArea(
      children: <Widget>[
        const _CapacityBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        _NetworkHeader(onNavigate: onNavigate),
        const SizedBox(height: NemrasSpacing.section),
        NationalSectionHeader(
          title: 'Network capacity',
          subtitle: 'Bed, occupancy and diversion figures. Record counts, '
              'where an aggregate endpoint supplies them, are separate.',
          trailing: const ProvenanceBadge(MetricProvenance.unavailable),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (final metric in controller.networkCapacityKpis)
              NationalKpiCard(metric: metric),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const ProvenanceNotice(
          title: 'Aggregate only',
          message: 'This screen shows facility-level counts and nothing '
              'else. It does not list patients, does not expose CNICs or '
              'names, and does not read patient records to build its '
              'figures.',
        ),
        if (summary.hasNoEndpoint) ...<Widget>[
          const NationalSectionHeader(
            title: 'Hospital-level national aggregation',
            subtitle: 'The state of this view against the current backend.',
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          const UnavailablePanel(
            headline: kHospitalAggregationUnavailable,
            explanation: 'Hospital is a populated column in '
                'NEMRAS_Dataset.csv, so the facility breakdown exists in the '
                'data. What is missing is a route that groups by it. The '
                'only alternative would be to page every patient record into '
                'the browser and group there, which this dashboard is not '
                'permitted to do and which would expose far more than the '
                'counts it needs.',
            requirements: _requirements,
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          const UnavailablePanel(
            headline: GeographicAvailability.notice,
            explanation: 'Even with a facility breakdown, no facility could '
                'be placed on a map or attributed to a province. The '
                'dataset records no location for any hospital, and hospital '
                'names are not a safe substitute for one.',
            requirements: GeographicAvailability.requirements,
            icon: Icons.public_off_outlined,
          ),
          const SizedBox(height: NemrasSpacing.xl),
          const _RefusedInferences(),
        ] else if (summary.hospitals.isEmpty) ...<Widget>[
          const NationalEmptyState(
            title: 'No facilities reported',
            message: 'The hospital aggregate endpoint answered but returned '
                'no facilities.',
            icon: Icons.local_hospital_outlined,
          ),
        ] else ...<Widget>[
          NationalWrapGrid(
            children: <Widget>[
              NationalKpiCard(
                metric: NationalMetric.datasetAggregate(
                  label: 'Facilities reporting',
                  value: summary.facilityCount,
                  basis: 'Rows returned by the hospital aggregate endpoint.',
                ),
                icon: Icons.local_hospital_outlined,
              ),
              NationalKpiCard(
                metric: NationalMetric.datasetAggregate(
                  label: 'Records covered',
                  value: summary.totalRecords,
                  basis: 'Sum of per-facility record counts.',
                ),
                icon: Icons.storage_outlined,
              ),
              NationalKpiCard(
                metric: controller.geographicCoverageKpi,
                icon: Icons.public_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.section),
          NationalSectionHeader(
            title: 'Facility contribution',
            subtitle: summary.reason,
            trailing: const ProvenanceBadge(
              MetricProvenance.datasetAggregate,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          NationalCard(
            child: NationalTable(
              columns: const <NationalColumn>[
                NationalColumn(label: 'Facility', flex: 4),
                NationalColumn(label: 'Records', flex: 2, alignEnd: true),
                NationalColumn(label: 'Emergency', flex: 2, alignEnd: true),
                NationalColumn(label: 'Critical risk', flex: 2, alignEnd: true),
                NationalColumn(label: 'Emergency share', flex: 3),
                NationalColumn(label: 'Region', flex: 2),
              ],
              rows: <List<Widget>>[
                for (final hospital in summary.hospitals)
                  <Widget>[
                    NationalTextCell(hospital.hospitalName, maxLines: 1),
                    NationalMonoCell(
                      formatCount(hospital.recordCount),
                      emphasise: true,
                    ),
                    NationalMonoCell(formatCount(hospital.emergencyRecords)),
                    NationalMonoCell(
                      formatCount(hospital.criticalRiskRecords),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: NemrasSpacing.l),
                      child: NationalProgressBar(
                        fraction: hospital.emergencyFraction,
                        color: semantics.critical.solid,
                      ),
                    ),
                    // Held empty on purpose: the column appears in the
                    // reference layout and there is no value for it.
                    const NationalTextCell(kNotAvailable, maxLines: 1),
                  ],
              ],
            ),
          ),
        ],
        const SizedBox(height: NemrasSpacing.section),
        const _FacilityDossier(),
        const SizedBox(height: NemrasSpacing.xl),
        const _DispatchOverrides(),
      ],
    );
  }
}

class _CapacityBanner extends StatelessWidget {
  const _CapacityBanner();

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
        'SIMULATED VIEW. No live bed board is connected. Capacity figures '
        'below are not hospital census counts.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NetworkHeader extends StatelessWidget {
  const _NetworkHeader({required this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final back = onNavigate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (back != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => back(NationalNavigation.overviewIndex),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to command'),
            ),
          ),
        Text(
          'Hospital network',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Facility record counts only, and only when an aggregate endpoint '
          'supplies them. Search and the reference filters need a facility '
          'registry, which NEMRAS does not have.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
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
              label: Text('Province filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Designation filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Capability filter not available'),
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
      ],
    );
  }
}

class _FacilityDossier extends StatelessWidget {
  const _FacilityDossier();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: NationalLabel('Facility dossier')),
              ProvenanceBadge(MetricProvenance.unavailable),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No facility is selected. Beds, units, staffing and blood stock '
            'are not recorded.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const NationalWrapGrid(
            minTileWidth: 160,
            children: <Widget>[
              NationalField(label: 'Medical director', value: 'Not recorded'),
              NationalField(label: 'Departmental load', value: kNotAvailable),
              NationalField(label: 'Critical assets', value: kNotAvailable),
              NationalField(label: 'Diversion target', value: 'Not recorded'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DispatchOverrides extends StatelessWidget {
  const _DispatchOverrides();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const NationalLabel('Dispatch overrides'),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No surge protocol, transfer channel or CAD override is '
            'connected.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const FilledButton(
            onPressed: null,
            child: Text('Declaring a trauma surge is not available'),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const OutlinedButton(
            onPressed: null,
            child: Text('Transmitting a transfer dossier is not available'),
          ),
          const SizedBox(height: NemrasSpacing.s),
          const OutlinedButton(
            onPressed: null,
            child: Text('Broadcasting an override is not available'),
          ),
        ],
      ),
    );
  }
}

/// The inferences this dashboard refuses to make, stated for the reader.
///
/// Rendered from [GeographicAvailability.refusedInferences] so the list the
/// UI shows and the list the implementation is held to are the same list.
class _RefusedInferences extends StatelessWidget {
  const _RefusedInferences();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return NationalCard(
      accent: semantics.elevated.solid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NationalSectionHeader(
            title: 'Location inferences NEMRAS refuses to make',
            subtitle: 'Each of these could produce a plausible-looking map. '
                'None of them would be true.',
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Available field', flex: 3),
              NationalColumn(label: 'Why it is not a location', flex: 7),
            ],
            rows: <List<Widget>>[
              for (final entry in GeographicAvailability.refusedInferences)
                <Widget>[
                  NationalMonoCell(entry.source, emphasise: true),
                  NationalTextCell(entry.reason),
                ],
            ],
          ),
        ],
      ),
    );
  }
}
