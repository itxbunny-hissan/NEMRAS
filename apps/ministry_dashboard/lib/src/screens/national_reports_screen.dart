import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/analyst_identity.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';

/// Screen 6 — National Reports.
///
/// The eight reports the phase names, in order, each as a table of counts
/// and shares. Two of the eight — age distribution and gender distribution —
/// have no aggregate source, so they appear in their briefed position
/// reporting that, rather than being quietly dropped from the list.
///
/// Reports render as tables and proportion bars. No charting package is
/// added: nothing here needs one, and a dependency added for decoration is a
/// dependency that has to be maintained.
class NationalReportsScreen extends StatelessWidget {
  const NationalReportsScreen({super.key, this.onNavigate});

  /// Switches the shell sidebar. Null when the screen is shown on its own.
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);

    if (controller.snapshotState.isLoading) {
      return const NationalLoadingState(message: 'Compiling national reports');
    }
    if (controller.snapshotState.hasFailed) {
      return NationalErrorState(
        title: 'Reports unavailable',
        message: controller.snapshotError ??
            'The NEMRAS backend could not be reached.',
        onRetry: controller.refreshSnapshot,
      );
    }
    if (controller.stats == null) {
      return const NationalEmptyState(
        title: 'No reports available',
        message: 'The national aggregates have not been loaded.',
        icon: Icons.insert_chart_outlined,
      );
    }

    final reports = controller.nationalReports;
    final available = reports.where((report) => report.isAvailable).length;

    return NationalContentArea(
      children: <Widget>[
        const _ArchiveBanner(),
        const SizedBox(height: NemrasSpacing.xl),
        ProvenanceNotice(
          title: 'Report scope',
          message: '$available of ${reports.length} requested reports can be '
              'produced from the current aggregate API. The remainder are '
              'listed in place with the reason they cannot. Every count is a '
              'count of records in NEMRAS_Dataset.csv over the whole '
              'dataset: there is no date filter, because no endpoint '
              'aggregates by date.',
        ),
        NationalSectionHeader(
          title: 'Report index',
          subtitle: 'Reporting period: ${controller.reportingPeriod.label}.',
          trailing: OutlinedButton.icon(
            onPressed: () => controller.recordExportRequest(
              'National aggregate report set',
            ),
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text('Record export request'),
          ),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalCard(
          child: NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: '#', flex: 1),
              NationalColumn(label: 'Report', flex: 5),
              NationalColumn(label: 'Source', flex: 3),
              NationalColumn(label: 'Categories', flex: 2, alignEnd: true),
              NationalColumn(label: 'Records', flex: 2, alignEnd: true),
            ],
            rows: <List<Widget>>[
              for (var i = 0; i < reports.length; i++)
                <Widget>[
                  NationalMonoCell('${i + 1}'),
                  NationalTextCell(reports[i].title, maxLines: 1),
                  ProvenanceBadge(reports[i].provenance),
                  NationalMonoCell(
                    reports[i].isAvailable
                        ? '${reports[i].categoryCount}'
                        : kNotAvailable,
                  ),
                  NationalMonoCell(
                    reports[i].isAvailable
                        ? formatCount(reports[i].total)
                        : kNotAvailable,
                    emphasise: reports[i].isAvailable,
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        const NationalSectionHeader(
          title: 'Reports',
          subtitle: 'Full breakdowns, in the order the reports are listed '
              'above.',
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        for (var i = 0; i < reports.length; i++) ...<Widget>[
          _ReportBlock(
            index: i + 1,
            distribution: reports[i],
            color: semantics.informational.solid,
          ),
          const SizedBox(height: NemrasSpacing.xl),
        ],
        const SizedBox(height: NemrasSpacing.s),
        Text(
          'Export records the request in the national audit trail. It does '
          'not produce a file in this phase, and no report contains any '
          'patient identifier.',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: semantics.textSecondary,
          ),
        ),
        const SizedBox(height: NemrasSpacing.section),
        _IncidentArchive(onNavigate: onNavigate),
      ],
    );
  }
}

class _ArchiveBanner extends StatelessWidget {
  const _ArchiveBanner();

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
        'DATASET REPORTS. Not a live incident archive. No statutory brief '
        'is generated, and no patient record is shown.',
        style: NemrasTextStyles.bodySmall.copyWith(
          color: info.onSoft,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _IncidentArchive extends StatelessWidget {
  const _IncidentArchive({required this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final openAudit = onNavigate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (openAudit != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openAudit(NationalNavigation.overviewIndex),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to command'),
            ),
          ),
        const NationalSectionHeader(
          title: 'Incident archive',
          subtitle: 'The reference lists live incidents, a case dossier and '
              'district response times. None of those sources exist.',
          trailing: ProvenanceBadge(MetricProvenance.unavailable),
        ),
        const SizedBox(height: NemrasSpacing.xxl),
        NationalWrapGrid(
          children: <Widget>[
            for (final metric in NationalScope.of(context).incidentArchiveKpis)
              NationalKpiCard(metric: metric),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xl),
        const TextField(
          enabled: false,
          decoration: InputDecoration(
            labelText: 'Search incidents',
            hintText: 'Not available',
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        const Wrap(
          spacing: NemrasSpacing.s,
          runSpacing: NemrasSpacing.s,
          children: <Widget>[
            ChoiceChip(
              label: Text('Date window not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Acuity filter not available'),
              selected: false,
              onSelected: null,
            ),
            ChoiceChip(
              label: Text('Jurisdiction filter not available'),
              selected: false,
              onSelected: null,
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.l),
        const FilledButton(
          onPressed: null,
          child: Text(
            'Generating a statutory brief is not available',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: NemrasSpacing.s),
        const OutlinedButton(
          onPressed: null,
          child: Text(
            'Exporting a query to CSV is not available',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: NemrasSpacing.xl),
        NationalCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NationalLabel('Active incident stream'),
              const SizedBox(height: NemrasSpacing.s),
              Text(
                'No live incident is recorded. The tables above are dataset '
                'category counts, not an incident log.',
                style: NemrasTextStyles.bodySmall.copyWith(
                  color: semantics.textSecondary,
                ),
              ),
              const SizedBox(height: NemrasSpacing.l),
              const NationalWrapGrid(
                minTileWidth: 160,
                children: <Widget>[
                  NationalField(
                    label: 'Selected incident',
                    value: 'Not recorded',
                  ),
                  NationalField(label: 'Clinical profile', value: 'Not recorded'),
                  NationalField(label: 'Milestone times', value: kNotAvailable),
                  NationalField(
                    label: 'District response',
                    value: kNotAvailable,
                  ),
                ],
              ),
              const SizedBox(height: NemrasSpacing.l),
              if (openAudit != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () =>
                        openAudit(NationalNavigation.governanceIndex),
                    icon: const Icon(Icons.gavel_outlined, size: 16),
                    label: const Text('Open audit / governance'),
                  ),
                ),
              const OutlinedButton(
                onPressed: null,
                child: Text(
                  'Printing a legal dossier is not available',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text(
                  'Flagging to a director is not available',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: NemrasSpacing.s),
              const OutlinedButton(
                onPressed: null,
                child: Text(
                  'Closing an incident is not available',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One numbered report: a table of counts and shares, or a stated absence.
class _ReportBlock extends StatelessWidget {
  const _ReportBlock({
    required this.index,
    required this.distribution,
    required this.color,
  });

  final int index;
  final NationalDistribution distribution;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    if (!distribution.isAvailable) {
      return UnavailablePanel(
        headline: 'Report $index — ${distribution.title}',
        explanation: distribution.basis,
        icon: Icons.insert_chart_outlined,
      );
    }

    // Capped so a free-text breakdown such as medical condition does not run
    // to hundreds of rows in a report page.
    const int rowCap = 15;
    final rows = distribution.entries(limit: rowCap);
    final truncated = distribution.categoryCount > rowCap;

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NationalSectionHeader(
            title: 'Report $index — ${distribution.title}',
            subtitle: distribution.basis,
            trailing: ProvenanceBadge(distribution.provenance),
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          NationalTable(
            columns: const <NationalColumn>[
              NationalColumn(label: 'Category', flex: 4),
              NationalColumn(label: 'Records', flex: 2, alignEnd: true),
              NationalColumn(label: 'Share', flex: 2, alignEnd: true),
              NationalColumn(label: 'Proportion', flex: 5),
            ],
            rows: <List<Widget>>[
              for (final entry in rows)
                <Widget>[
                  NationalTextCell(entry.label, maxLines: 1),
                  NationalMonoCell(
                    formatCount(entry.count),
                    emphasise: true,
                  ),
                  NationalMonoCell(entry.percentLabel),
                  Padding(
                    padding: const EdgeInsets.only(right: NemrasSpacing.l),
                    child: NationalProgressBar(
                      fraction: entry.fraction,
                      color: color,
                    ),
                  ),
                ],
            ],
          ),
          const SizedBox(height: NemrasSpacing.l),
          Text(
            truncated
                ? 'Showing the $rowCap largest of '
                    '${distribution.categoryCount} categories. '
                    'Total ${formatCount(distribution.total)} records.'
                : 'All ${distribution.categoryCount} categories. '
                    'Total ${formatCount(distribution.total)} records.',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
