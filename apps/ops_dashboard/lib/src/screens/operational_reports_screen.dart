import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/operations_models.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';

/// Screen 7 — Operational Reports.
///
/// Tables, counts and proportion bars rather than charts: NEMRAS carries no
/// charting dependency and this phase does not add one.
///
/// Three of the six requested reports report unavailable. `Medication`,
/// `Allergy` and `Hospital` are all columns in `NEMRAS_Dataset.csv`, but
/// `GET /api/stats` aggregates none of them and no other route does either.
/// Computing them client-side would mean downloading the dataset to the
/// browser, which an operations surface has no business doing.
class OperationalReportsScreen extends StatelessWidget {
  const OperationalReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const OpsLoadingState(message: 'Reading dataset aggregates');
    }
    if (controller.snapshotState.hasFailed) {
      return OpsErrorState(
        title: 'Report data unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }

    return OpsContentArea(
      children: <Widget>[
        const ProvenanceNotice(
          title: 'Report coverage',
          message: 'Reports are built from the aggregates GET /api/stats '
              'exposes. Medication distribution, allergy coverage and cases '
              'by hospital are listed below but report as unavailable: those '
              'columns exist in the dataset, yet no backend route aggregates '
              'them, and this phase does not change the backend. They are '
              'shown rather than omitted so the gap is visible.',
        ),
        OpsSectionHeader(
          title: 'Available reports',
          subtitle: 'Six operational reports and their current status.',
          trailing: _ExportButton(controller: controller),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsCard(
          child: OpsTable(
            columns: const <OpsColumn>[
              OpsColumn(label: 'Report', flex: 3),
              OpsColumn(label: 'Source', flex: 4),
              OpsColumn(label: 'Rows', flex: 1, alignEnd: true),
              OpsColumn(label: 'Status', flex: 2, alignEnd: true),
            ],
            rows: <List<Widget>>[
              for (final report in <OpsDistribution>[
                controller.conditionDistribution,
                controller.triageDistribution,
                controller.admissionTypeDistribution,
                controller.medicationDistribution,
                controller.allergyDistribution,
                controller.hospitalDistribution,
              ])
                <Widget>[
                  OpsTextCell(report.title),
                  OpsTextCell(report.basis),
                  OpsMonoCell(
                    report.isAvailable
                        ? '${report.counts.length}'
                        : kNotAvailable,
                  ),
                  ProvenanceBadge(report.provenance),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const OpsSectionHeader(
          title: 'Cases by condition',
          subtitle: 'The twenty most frequent recorded conditions.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        OpsDistributionCard(
          distribution: controller.conditionDistribution,
          limit: 20,
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
            distribution: controller.riskDistribution,
            order: const <String>['Critical', 'Elevated', 'Stable'],
            color: semantics.elevated.solid,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.admissionTypeDistribution,
            color: semantics.advisory.solid,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.medicationDistribution,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        OpsSplitPanels(
          primaryFlex: 1,
          secondaryFlex: 1,
          primary: OpsDistributionCard(
            distribution: controller.allergyDistribution,
          ),
          secondary: OpsDistributionCard(
            distribution: controller.hospitalDistribution,
          ),
        ),
      ],
    );
  }
}

/// Requests a report export.
///
/// Nothing is written. The button exists because the export itself is an
/// auditable event, and the snackbar says plainly that no file was produced
/// rather than letting the absence of a download read as a failure.
class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.controller});

  final OpsConsoleController controller;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        await controller.recordExportRequest('Operational reports');
        messenger?.showSnackBar(
          const SnackBar(
            content: Text(
              'Export recorded in the audit trail. No file was produced: '
              'report export is not implemented in this phase.',
            ),
          ),
        );
      },
      icon: const Icon(Icons.download_outlined, size: 16),
      label: const Text('Request export'),
    );
  }
}
