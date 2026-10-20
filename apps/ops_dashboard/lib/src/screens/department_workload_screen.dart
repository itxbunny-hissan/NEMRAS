import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 4 — Department and Hospital Workload.
///
/// Aggregate values only. Four of the six requested breakdowns come from
/// `GET /api/stats`; cases by hospital reports unavailable because `Hospital`
/// is in the dataset but no route aggregates it, and substituting the
/// 100-record risk slice for a 64,000-record population would be a
/// misrepresentation rather than an approximation.
class DepartmentWorkloadScreen extends StatelessWidget {
  const DepartmentWorkloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const OpsLoadingState(message: 'Reading dataset aggregates');
    }
    if (controller.snapshotState.hasFailed) {
      return OpsErrorState(
        title: 'Workload aggregates unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }

    final stats = controller.stats;
    if (stats == null) {
      return const OpsEmptyState(
        title: 'No workload data',
        message: 'The dataset aggregates have not been loaded.',
        icon: Icons.meeting_room_outlined,
      );
    }

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Aggregate dataset breakdowns',
          message: 'These are counts of records in NEMRAS_Dataset.csv, not a '
              'measure of what any department is handling today. NEMRAS '
              'records no department assignment, no staff roster and no shift '
              'data, so clinical categories stand in for departmental '
              'workload and staff workload is reported as unavailable.',
        ),
        OpsWrapGrid(
          children: <Widget>[
            OpsKpiCard(
              metric: controller.datasetSizeKpi,
              icon: Icons.storage_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.datasetAggregate(
                label: 'High Triage Records',
                value: stats.highTriageRecords,
                basis: 'Records with Triage_Level = High',
                caption: 'Dataset records, not today\u2019s caseload.',
              ),
              icon: Icons.priority_high_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.datasetAggregate(
                label: 'Chronic Condition Records',
                value: stats.chronicRecords,
                basis: 'Records with Chronic_Condition = Yes',
                caption: 'Dataset records, not today\u2019s caseload.',
              ),
              icon: Icons.monitor_heart_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Staff On Shift',
                basis: 'NEMRAS holds no staff roster or shift data',
                caption: 'Requires a workforce management source.',
              ),
              icon: Icons.badge_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Cases Per Clinician',
                basis: 'No staff roster and no department assignment',
                caption: 'Cannot be derived from patient records alone.',
              ),
              icon: Icons.group_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Clinical workload composition',
          subtitle: 'Population breakdowns from GET /api/stats.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsDistributionCard(
          distribution: controller.conditionDistribution,
          limit: 12,
          color: semantics.informational.solid,
        ),
        const SizedBox(height: NemrasSpacing.xl),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.triageDistribution,
            order: const <String>['High', 'Medium', 'Low'],
            color: semantics.critical.solid,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.admissionTypeDistribution,
            color: semantics.advisory.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.chronicConditionDistribution,
            order: const <String>['Yes', 'No'],
            color: semantics.elevated.solid,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.drugInteractionDistribution,
            order: const <String>['Yes', 'No'],
            color: semantics.critical.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        OpsDistributionCard(
          distribution: controller.hospitalDistribution,
        ),
      ],
    );
  }
}
