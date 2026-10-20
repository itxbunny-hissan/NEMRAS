import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/geography.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 2 — Emergency Trends.
///
/// The screen's title promises a trend, and the honest answer is that no
/// trend can be computed. `Admission_Date` and `Discharge_Date` are populated
/// in `NEMRAS_Dataset.csv` and span several years, so the *data* could support
/// a genuine time series — but no endpoint groups by date, and deriving one
/// client-side would mean paging every record into the browser, which this
/// surface must not do. So the temporal panel states the gap and names the
/// endpoint that would close it, and the rest of the screen shows the
/// distributions the aggregate API genuinely supports.
class EmergencyTrendsScreen extends StatelessWidget {
  const EmergencyTrendsScreen({super.key, this.onNavigate});

  /// Switches the shell sidebar. Null when the screen is shown on its own.
  final ValueChanged<int>? onNavigate;

  /// What a real emergency trend would need.
  static const List<({String requirement, String detail})> _trendRequirements =
      <({String requirement, String detail})>[
    (
      requirement: 'Date-grouped endpoint',
      detail: 'Counts returned already grouped by day, week or month, so no '
          'record-level data reaches the client.',
    ),
    (
      requirement: 'Admission_Date parsing',
      detail: 'The column is populated but stored as free-form text, so the '
          'backend would need to parse and validate it.',
    ),
    (
      requirement: 'Stable period boundaries',
      detail: 'A defined window and timezone, so two readings of the same '
          'period agree.',
    ),
    (
      requirement: 'Denominators per period',
      detail: 'Without them a rising count cannot be told apart from rising '
          'coverage of the dataset itself.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const NationalLoadingState(
        message: 'Reading emergency aggregates',
      );
    }
    if (controller.snapshotState.hasFailed) {
      return NationalErrorState(
        title: 'Emergency aggregates unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }

    final stats = controller.stats;
    if (stats == null) {
      return const NationalEmptyState(
        title: 'No emergency data',
        message: 'The national aggregates have not been loaded.',
        icon: Icons.emergency_outlined,
      );
    }

    return NationalContentArea(
      children: <Widget>[
        const _SampleBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        _TrendsHeader(onNavigate: onNavigate),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Dispatch metrics',
          subtitle: 'The reference leads with response time, handoff '
              'latency and survival. None of those fields exist here.',
          trailing: ProvenanceBadge(MetricProvenance.unavailable),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (final metric in controller.trendOperationalKpis)
              NationalKpiCard(metric: metric),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Dataset emergency counts',
          subtitle: 'Record counts from the national aggregate. They are '
              'not dispatch volumes and not a trend.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            NationalKpiCard(
              metric: controller.emergencyRecordsKpi,
              icon: Icons.emergency_outlined,
            ),
            NationalKpiCard(
              metric: controller.emergencyShareKpi,
              icon: Icons.percent_outlined,
              unitSuffix: '%',
            ),
            NationalKpiCard(
              metric: controller.criticalRiskKpi,
              icon: Icons.priority_high_outlined,
            ),
            NationalKpiCard(
              metric: controller.highTriageKpi,
              icon: Icons.local_hospital_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Response time by province',
          subtitle: 'The reference charts dispatch and transit times for '
              'each province.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: 'Provincial response times are not available',
          explanation: 'No province, district or coordinate is recorded, and '
              'NEMRAS stores no dispatch or transit timestamps. No ranking '
              'and no provincial chart is drawn.',
          requirements: GeographicAvailability.requirements,
          icon: Icons.public_off_outlined,
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Demand over time',
          subtitle: 'The reference draws a 24-hour demand heatmap and a '
              'multi-day admission trend here.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const UnavailablePanel(
          headline: kTrendUnavailable,
          explanation: 'No NEMRAS endpoint returns counts grouped by date or '
              'by hour, so there is no series and no heatmap to plot. The '
              'dataset does hold populated Admission_Date and Discharge_Date '
              'values, which means the obstacle is the missing endpoint '
              'rather than the missing data. No forecast is shown either.',
          requirements: _trendRequirements,
          icon: Icons.grid_on_outlined,
        ),
        const SizedBox(height: NemrasSpacing.section),
        _LedgerCard(onNavigate: onNavigate),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Incident severity from the dataset',
          subtitle: 'Triage labels in the dataset are High, Medium and Low. '
              'They are record counts, not live colour-coded incidents.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        const NationalSectionHeader(
          title: 'Emergency against the rest of the dataset',
          subtitle: 'The admission mix, derived from two dataset counts.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalDistributionCard(
          distribution: controller.emergencyShareDistribution,
          order: const <String>['Emergency', 'Non-emergency'],
          color: semantics.critical.solid,
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.admissionTypeDistribution,
            color: semantics.advisory.solid,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.triageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.riskDistribution,
            order: const <String>['Critical', 'Elevated', 'Stable'],
            color: semantics.elevated.solid,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.chronicConditionDistribution,
            order: const <String>['Yes', 'No'],
            color: semantics.stable.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        NationalSectionHeader(
          title: 'Highest-risk slice',
          subtitle: 'The one per-record view the API offers, reduced to '
              'categorical fields. It is sorted by risk tier, so it skews '
              'severe by construction.',
          trailing: const ProvenanceBadge(MetricProvenance.datasetSample),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: NationalDistributionCard(
            distribution: controller.riskSampleTriageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.advisory.solid,
          ),
          secondary: NationalDistributionCard(
            distribution: controller.riskSampleConditionDistribution,
            limit: 8,
            color: semantics.advisory.solid,
          ),
        ),
      ],
    );
  }
}

class _SampleBanner extends StatelessWidget {
  const _SampleBanner();

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
        'SAMPLE DATA. Counts of records in the NEMRAS dataset. Not live '
        'dispatch statistics and not a provincial ranking.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: elevated.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TrendsHeader extends StatelessWidget {
  const _TrendsHeader({required this.onNavigate});

  final ValueChanged<int>? onNavigate;

  static const List<String> _windows = <String>[
    'Today',
    'Last 7 days',
    'Last 30 days',
  ];

  static const List<String> _cohorts = <String>[
    'Response times',
    'Case resolution',
    'Hospital handoff latency',
    'Surveillance reach',
  ];

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
          'Emergency trends',
          style: NemrasTextStyles.screenTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xs),
        Text(
          'Dataset-wide counts. Rolling windows and operational cohorts '
          'are not available.',
          style: NemrasTextStyles.bodySmall.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Full dataset'),
              selected: true,
              onSelected: (_) {},
            ),
            for (final window in _windows)
              ChoiceChip(
                label: Text(window),
                selected: false,
                onSelected: null,
              ),
            for (final cohort in _cohorts)
              ChoiceChip(
                label: Text(cohort),
                selected: false,
                onSelected: null,
              ),
          ],
        ),
      ],
    );
  }
}

class _LedgerCard extends StatelessWidget {
  const _LedgerCard({required this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final openAudit = onNavigate;
    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const NationalLabel('Provincial telemetry ledger'),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            'Not available. No province, dispatch time or connected-hospital '
            'count is recorded, so no ledger rows are listed.',
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          const TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'Filter the ledger',
              hintText: 'Not available',
            ),
          ),
          const SizedBox(height: NemrasSpacing.l),
          Wrap(
            spacing: NemrasSpacing.s,
            runSpacing: NemrasSpacing.s,
            children: <Widget>[
              const OutlinedButton(
                onPressed: null,
                child: Text('Exporting CSV is not available'),
              ),
              if (openAudit != null)
                TextButton.icon(
                  onPressed: () =>
                      openAudit(NationalNavigation.governanceIndex),
                  icon: const Icon(Icons.gavel_outlined, size: 16),
                  label: const Text('Open audit / governance'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
