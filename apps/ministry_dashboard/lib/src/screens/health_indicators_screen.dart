import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 3 — Health Indicators.
///
/// Walks the eight dataset fields the phase names, and for each one states
/// either the aggregate NEMRAS can produce or the reason it cannot. Two of
/// the eight (Gender, Age bands) are present in the dataset but absent from
/// the aggregate API, and the screen says so rather than leaving a blank.
///
/// The screen also carries the standing caveat about `Risk_Score`: it is a
/// categorical dataset label, not a validated clinical probability, so no
/// percentage is ever attached to it.
class HealthIndicatorsScreen extends StatelessWidget {
  const HealthIndicatorsScreen({super.key, this.onNavigate});

  /// Switches the shell sidebar. Null when the screen is shown on its own.
  final ValueChanged<int>? onNavigate;

  /// The eight fields the phase asks about, and their status here.
  static const List<({String field, String aggregate, String note})>
      _fieldCoverage = <({String field, String aggregate, String note})>[
    (
      field: 'Medical_Condition',
      aggregate: 'Available',
      note: 'Free-text condition names counted by the backend. Not coded to '
          'ICD-11 or any other classification.',
    ),
    (
      field: 'Triage_Level',
      aggregate: 'Available',
      note: 'Categorical: High, Medium, Low. An ordinal label, not a score.',
    ),
    (
      field: 'Risk_Score',
      aggregate: 'Available',
      note: 'Categorical: Critical, Elevated, Stable. Despite the column '
          'name it holds no number and no probability.',
    ),
    (
      field: 'Chronic_Condition',
      aggregate: 'Available',
      note: 'Categorical yes/no flag per record.',
    ),
    (
      field: 'Drug_Interaction_Risk',
      aggregate: 'Available',
      note: 'Categorical yes/no flag per record. A dataset flag, not the '
          'output of an interaction checker.',
    ),
    (
      field: 'Admission_Type',
      aggregate: 'Available',
      note: 'Categorical: Emergency, Urgent, Elective.',
    ),
    (
      field: 'Gender',
      aggregate: 'Not available',
      note: 'The column exists in the dataset but GET /api/stats returns no '
          'gender breakdown, and the only route that exposes gender is '
          'patient-level.',
    ),
    (
      field: 'Age',
      aggregate: 'Mean only',
      note: 'GET /api/stats returns avg_age and nothing else, so the mean is '
          'shown and the age distribution is not.',
    ),
  ];

  /// What an age or gender breakdown would need.
  static const List<({String requirement, String detail})>
      _breakdownRequirements = <({String requirement, String detail})>[
    (
      requirement: 'Aggregate-only endpoint',
      detail: 'Counts per band or per category, returned pre-aggregated so '
          'no record reaches the client.',
    ),
    (
      requirement: 'Agreed band boundaries',
      detail: 'Age bands fixed on the backend, so two readings of the same '
          'dataset produce the same bands.',
    ),
    (
      requirement: 'Small-cell suppression',
      detail: 'Cross-tabulations of small categories can re-identify '
          'individuals, so low counts must be suppressed before release.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const NationalLoadingState(message: 'Reading health indicators');
    }
    if (controller.snapshotState.hasFailed) {
      return NationalErrorState(
        title: 'Health indicators unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }
    if (controller.stats == null) {
      return const NationalEmptyState(
        title: 'No indicators loaded',
        message: 'The national aggregates have not been loaded.',
        icon: Icons.monitor_heart_outlined,
      );
    }

    return NationalContentArea(
      children: <Widget>[
        const _PopulationBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        _PopulationHeader(onNavigate: onNavigate),
        const SizedBox(height: NemrasSpacing.section),
        const _SurveillanceGaps(),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Incident velocity',
          subtitle: 'The reference charts twelve months of incidence by '
              'clinical category.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: kTrendUnavailable,
          explanation: 'No endpoint groups records by month, so no velocity '
              'curve is drawn. Condition names in this dataset are free '
              'text, not ICD-11 syndromes.',
          icon: Icons.show_chart_outlined,
        ),
        const SizedBox(height: NemrasSpacing.section),
        ProvenanceNotice(
          title: 'Risk_Score is not a probability',
          message: 'Risk_Score is a categorical dataset label with the '
              'values Critical, Elevated and Stable. It is not a validated '
              'clinical probability and no model produced it, so no figure '
              'on this page expresses risk as a percentage of anything '
              'other than a share of records. '
              '${MetricProvenance.datasetAggregate.explanation}',
        ),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: controller.chronicConditionKpi,
              icon: Icons.monitor_heart_outlined,
            ),
            NationalKpiCard(
              metric: controller.drugInteractionKpi,
              icon: Icons.medication_outlined,
            ),
            NationalKpiCard(
              metric: controller.conditionVarietyKpi,
              icon: Icons.category_outlined,
            ),
            NationalKpiCard(
              metric: controller.averageAgeKpi,
              icon: Icons.cake_outlined,
              unitSuffix: ' yrs',
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: controller.ageDistributionKpi,
              icon: Icons.bar_chart_outlined,
            ),
            NationalKpiCard(
              metric: controller.genderDistributionKpi,
              icon: Icons.people_outline,
            ),
            NationalKpiCard(
              metric: controller.geographicCoverageKpi,
              icon: Icons.public_off_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Clinical distributions',
          subtitle: 'Counts of dataset records by category. A count of '
              'records is not a prevalence in the population.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.conditionDistribution,
            limit: 10,
            color: semantics.informational.solid,
          ),
          secondary: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NationalDistributionCard(
                distribution: controller.chronicConditionDistribution,
                order: const <String>['Yes', 'No'],
                color: semantics.stable.solid,
              ),
              const SizedBox(height: NemrasSpacing.xl),
              NationalDistributionCard(
                distribution: controller.drugInteractionDistribution,
                order: const <String>['Yes', 'No'],
                color: semantics.advisory.solid,
              ),
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.triageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.riskDistribution,
            order: const <String>['Critical', 'Elevated', 'Stable'],
            color: semantics.elevated.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Demographic breakdowns',
          subtitle: 'Gender and age bands are in the dataset but not in the '
              'aggregate API.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.genderDistribution,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.ageDistribution,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const UnavailablePanel(
          headline: 'Demographic breakdowns need an aggregate endpoint',
          explanation: 'Gender and age are recorded per patient, so the only '
              'route that exposes them is patient-level. Reading enough rows '
              'to build a national breakdown would mean pulling the dataset '
              'into the browser, which this dashboard must not do, so the '
              'breakdowns are reported as unavailable instead.',
          requirements: _breakdownRequirements,
          icon: Icons.groups_outlined,
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Field coverage',
          subtitle: 'Every field this phase asks about, and whether a '
              'national aggregate exists for it.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Dataset field', flex: 3),
              NationalColumn(label: 'National aggregate', flex: 2),
              NationalColumn(label: 'Meaning and limits', flex: 7),
            ],
            rows: <List<Widget>>[
              for (final row in _fieldCoverage)
                <Widget>[
                  NationalMonoCell(row.field, emphasise: true),
                  NationalStatusPill(
                    label: row.aggregate,
                    status: row.aggregate == 'Available'
                        ? semantics.stable
                        : row.aggregate == 'Mean only'
                            ? semantics.advisory
                            : semantics.elevated,
                  ),
                  NationalTextCell(row.note),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        Text(
          'Fields marked "$kNotAvailable" are absent from the aggregate API, '
          'not absent from the dataset.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const _DirectivesCard(),
      ],
    );
  }
}

class _PopulationBanner extends StatelessWidget {
  const _PopulationBanner();

  @override
  Widget build(BuildContext context) {
    final info = NemrasSemantics.of(context).informational;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: info.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border.all(color: info.solid),
      ),
      child: Text(
        'AGGREGATE DATA ONLY. No patient-level record is shown. This page '
        'does not claim a k-anonymity threshold, and it is not a live '
        'epidemiological feed.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: info.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PopulationHeader extends StatelessWidget {
  const _PopulationHeader({required this.onNavigate});

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
          'Population health',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Dataset record counts. A rolling year, a clinical-category '
          'filter and a location filter are not available.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ChoiceChip(
              label: Text('Full dataset'),
              selected: true,
              onSelected: _ignore,
            ),
            ChoiceChip(
              label: Text('Rolling 12 months'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Category filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Location filter not available'),
              selected: false,
              onSelected: null,
            ),
            OutlinedButton(
              onPressed: null,
              child: Text('Filtering facets is not available'),
            ),
            FilledButton(
              onPressed: null,
              child: Text('Exporting a bulletin is not available'),
            ),
          ],
        ),
      ],
    );
  }

  static void _ignore(bool _) {}
}

class _SurveillanceGaps extends StatelessWidget {
  const _SurveillanceGaps();

  static const List<String> _gaps = <String>[
    'Cardiovascular surge',
    'Road-traffic share',
    'Respiratory alerts',
    'Thermal stress',
  ];

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const NationalSectionHeader(
          title: 'Surveillance headlines',
          subtitle: 'The reference quotes seasonal and location-specific '
              'alerts. NEMRAS has no weather, traffic or place field.',
          trailing: ProvenanceBadge(MetricProvenance.unavailable),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (final gap in _gaps)
              NationalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    NationalLabel(gap),
                    const SizedBox(height: NemrasSpacing.s),
                    Text(
                      kNotAvailable,
                      style: NemrasTextStyles.metricValue.copyWith(
                        color: semantics.textPlaceholder,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.l),
        NationalCard(
          child: Text(
            'No telemetry status is recorded for any reporting node.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DirectivesCard extends StatelessWidget {
  const _DirectivesCard();

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NationalLabel('Action directives'),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'No forecast and no tasking channel exist, so no directive is '
            'issued from this page.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const OutlinedButton(
            onPressed: null,
            child: Text('Issuing an action directive is not available'),
          ),
        ],
      ),
    );
  }
}
