import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 5 — Patient Flow.
///
/// Flow is movement over time, and `NEMRAS_Dataset.csv` records no admission
/// time, no discharge time and no transfer. Most of this page therefore reads
/// "Not available" by design. That is the honest result: the alternative
/// would be to present a static record count as a daily throughput figure,
/// which is exactly the misreading the data-honesty rules forbid.
class PatientFlowScreen extends StatelessWidget {
  const PatientFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const OpsLoadingState(message: 'Reading dataset aggregates');
    }
    if (controller.snapshotState.hasFailed) {
      return OpsErrorState(
        title: 'Patient flow data unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }

    final stats = controller.stats;

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Why most of this page is unavailable',
          message: 'Patient flow describes movement over time: arrivals per '
              'hour, discharges per day, transfers between wards. The NEMRAS '
              'dataset records none of these events and carries no admission '
              'or discharge timestamp, so no throughput figure can be '
              'computed from it. The counts that are shown are static record '
              'counts by admission type. Nothing on this page is a rate.',
        ),
        const OpsSectionHeader(
          title: 'Flow indicators',
          subtitle: 'Each indicator states its source or the source it would '
              'need.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsWrapGrid(
          children: <Widget>[
            OpsKpiCard(
              metric: controller.emergencyCasesKpi,
              icon: Icons.emergency_outlined,
            ),
            OpsKpiCard(
              metric: stats == null
                  ? OpsMetric.unavailable(
                      label: 'Urgent Admission Records',
                      basis: 'Dataset aggregate not loaded.',
                    )
                  : OpsMetric.datasetAggregate(
                      label: 'Urgent Admission Records',
                      value: stats.admissionType['Urgent'] ?? 0,
                      basis: 'Records with Admission_Type = Urgent',
                      caption: 'A record count, not an arrival rate.',
                    ),
              icon: Icons.schedule_send_outlined,
            ),
            OpsKpiCard(
              metric: stats == null
                  ? OpsMetric.unavailable(
                      label: 'Elective Admission Records',
                      basis: 'Dataset aggregate not loaded.',
                    )
                  : OpsMetric.datasetAggregate(
                      label: 'Elective Admission Records',
                      value: stats.admissionType['Elective'] ?? 0,
                      basis: 'Records with Admission_Type = Elective',
                      caption: 'A record count, not an arrival rate.',
                    ),
              icon: Icons.event_available_outlined,
            ),
            OpsKpiCard(
              metric: controller.activeAdmissionsKpi,
              icon: Icons.login_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Discharges Today',
                basis: 'No discharge timestamps in NEMRAS',
                caption: 'Requires an admission-discharge-transfer source.',
              ),
              icon: Icons.logout_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Active Encounters',
                basis: 'No encounter open/close state in NEMRAS',
                caption: 'Requires a clinical encounter source.',
              ),
              icon: Icons.pending_actions_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Admissions Last 24h',
                basis: 'No admission timestamps in NEMRAS',
                caption: 'No time dimension exists in the dataset.',
              ),
              icon: Icons.trending_up_outlined,
            ),
            OpsKpiCard(
              metric: OpsMetric.unavailable(
                label: 'Ward Transfers',
                basis: 'No transfer events in NEMRAS',
                caption: 'Requires an admission-discharge-transfer source.',
              ),
              icon: Icons.swap_horiz_outlined,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Admission mix',
          subtitle: 'The one flow-adjacent breakdown the dataset supports.',
          trailing: ProvenanceBadge(MetricProvenance.datasetAggregate),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsDistributionCard(
          distribution: controller.admissionTypeDistribution,
          color: semantics.informational.solid,
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'What a real flow view would need',
          subtitle: 'Recorded so the gap is documented rather than hidden.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: OpsTable(
            columns: const <OpsColumn>[
              OpsColumn(label: 'Metric', flex: 3),
              OpsColumn(label: 'Required source', flex: 4),
              OpsColumn(label: 'Status', flex: 2),
            ],
            rows: const <List<Widget>>[
              <Widget>[
                OpsTextCell('Admissions per hour'),
                OpsTextCell('Admission timestamp per encounter'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Discharges per day'),
                OpsTextCell('Discharge timestamp per encounter'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Active encounters'),
                OpsTextCell('Encounter open/close state'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Length of stay'),
                OpsTextCell('Paired admission and discharge timestamps'),
                OpsTextCell(kNotAvailable),
              ],
              <Widget>[
                OpsTextCell('Ward transfers'),
                OpsTextCell('Transfer event stream'),
                OpsTextCell(kNotAvailable),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
