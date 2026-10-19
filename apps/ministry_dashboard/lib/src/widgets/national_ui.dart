import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../data/national_models.dart';

/// The shared presentation vocabulary for the national dashboard.
///
/// Every widget here resolves its colours, spacing, radii and text styles
/// from `nemras_design`. No raw colour, size or font is declared in this app,
/// and no second theme system is introduced.
///
/// These widgets mirror the vocabulary Phase 4A built for the operational
/// dashboard. They are declared locally because `apps/ops_dashboard` is an
/// application rather than a package, so nothing can import from it, and both
/// of those surfaces are frozen for this phase. Extracting a shared
/// `nemras_components` package is the right fix and is reported as debt.

/// `.card` — the standard bordered panel.
class NationalCard extends StatelessWidget {
  const NationalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NemrasSpacing.cardPadding),
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Draws a 3dp left edge in this colour, for cards that carry a status.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final edge = accent;
    final content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: NemrasRadii.cardBorder,
        border: Border.all(color: semantics.cardBorder),
      ),
      // The accent edge is a strip rather than a left BorderSide, because a
      // Border with per-side colours cannot carry a borderRadius.
      child: edge == null
          ? content
          : ClipRRect(
              borderRadius: NemrasRadii.cardBorder,
              child: Stack(
                children: <Widget>[
                  content,
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 3,
                    child: ColoredBox(color: edge),
                  ),
                ],
              ),
            ),
    );
  }
}

/// A monospace uppercase label. Upper-cases its input so every label in the
/// app reads the same regardless of how the caller wrote it.
class NationalLabel extends StatelessWidget {
  const NationalLabel(this.text, {super.key, this.color, this.maxLines});

  final String text;
  final Color? color;

  /// Set on a narrow column so a long label ellipsizes instead of overflowing.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Text(
      text.toUpperCase(),
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: NemrasTextStyles.metricLabel.copyWith(
        color: color ?? semantics.textSecondary,
      ),
    );
  }
}

/// A section heading with an optional trailing control.
class NationalSectionHeader extends StatelessWidget {
  const NationalSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final caption = subtitle;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: NemrasTextStyles.sectionTitle.copyWith(
            color: semantics.textPrimary,
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            caption,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ],
    );
    final action = trailing;
    if (action == null) return titleBlock;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // A trailing control such as an export button can be wider than a
        // phone-width column. Stack it, and scale it down only as far as it
        // needs to fit, instead of squeezing the title to zero width.
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              titleBlock,
              const SizedBox(height: NemrasSpacing.s),
              SizedBox(
                width: constraints.maxWidth,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: action,
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: titleBlock),
            action,
          ],
        );
      },
    );
  }
}

/// A soft-filled status pill. `.tag` in the reference.
class NationalStatusPill extends StatelessWidget {
  const NationalStatusPill({
    super.key,
    required this.label,
    required this.status,
    this.solid = false,
    this.icon,
  });

  final String label;
  final NemrasStatusColor status;
  final bool solid;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.s,
        vertical: NemrasSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: solid ? status.solid : status.soft,
        borderRadius: NemrasRadii.tagBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (glyph != null) ...<Widget>[
            Icon(
              glyph,
              size: 12,
              color: solid ? status.onSolid : status.onSoft,
            ),
            const SizedBox(width: NemrasSpacing.xxs),
          ],
          // Flexible so a long status in a narrow table column ellipsizes
          // instead of overflowing the row.
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: NemrasTextStyles.tag.copyWith(
                color: solid ? status.onSolid : status.onSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The provenance badge.
///
/// This is the honesty mechanism of the whole dashboard: every figure carries
/// one, so a reader can always tell a dataset record count from a bounded
/// sample from a simulation from a figure NEMRAS does not have.
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge(this.provenance, {super.key});

  final MetricProvenance provenance;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final NemrasStatusColor status;
    switch (provenance) {
      case MetricProvenance.datasetAggregate:
        status = semantics.informational;
      case MetricProvenance.datasetSample:
        status = semantics.advisory;
      case MetricProvenance.demo:
        status = semantics.elevated;
      case MetricProvenance.unavailable:
        status = semantics.stable;
    }

    return Tooltip(
      message: provenance.explanation,
      child: NationalStatusPill(label: provenance.badge, status: status),
    );
  }
}

/// A national KPI card.
///
/// The provenance badge sits beside the label rather than below the value, so
/// it cannot be read as a caption to a number the reader has already taken
/// in.
class NationalKpiCard extends StatelessWidget {
  const NationalKpiCard({
    super.key,
    required this.metric,
    this.icon,
    this.unitSuffix,
  });

  final NationalMetric metric;
  final IconData? icon;

  /// Appended to the value when it is available, for figures such as a
  /// percent share or an age in years.
  final String? unitSuffix;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final glyph = icon;
    final caption = metric.caption;
    final suffix = metric.isAvailable ? (unitSuffix ?? '') : '';

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                Icon(glyph, size: 16, color: semantics.textSecondary),
                const SizedBox(width: NemrasSpacing.xs),
              ],
              Expanded(child: NationalLabel(metric.label)),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          ProvenanceBadge(metric.provenance),
          const SizedBox(height: NemrasSpacing.m),
          Text(
            '${metric.displayValue}$suffix',
            style: NemrasTextStyles.metricValue.copyWith(
              color: metric.isAvailable
                  ? semantics.textPrimary
                  : semantics.textPlaceholder,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            metric.basis,
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: NemrasSpacing.xxs),
            Text(
              caption,
              style: NemrasTextStyles.bodyCaption.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A horizontal proportion bar, used for distributions and node health.
class NationalProgressBar extends StatelessWidget {
  const NationalProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 8,
  });

  /// Clamped, so a malformed input cannot overflow the track.
  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            ColoredBox(
              color: semantics.controlBackground,
              child: const SizedBox.expand(),
            ),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled row with a count, a share and a proportion bar.
class NationalDistributionRow extends StatelessWidget {
  const NationalDistributionRow({
    super.key,
    required this.entry,
    required this.color,
  });

  final DistributionEntry entry;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.label,
                  style: NemrasTextStyles.body.copyWith(
                    color: semantics.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: NemrasSpacing.s),
              Text(
                formatCount(entry.count),
                style: NemrasTextStyles.dataValue.copyWith(
                  color: semantics.textPrimary,
                ),
              ),
              const SizedBox(width: NemrasSpacing.s),
              SizedBox(
                width: 52,
                child: Text(
                  entry.percentLabel,
                  textAlign: TextAlign.end,
                  style: NemrasTextStyles.dataCaption.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xs),
          NationalProgressBar(fraction: entry.fraction, color: color),
        ],
      ),
    );
  }
}

/// A distribution rendered as a card of labelled rows.
///
/// Proportion bars and tables rather than a chart library: NEMRAS has no
/// charting dependency and this phase adds none.
class NationalDistributionCard extends StatelessWidget {
  const NationalDistributionCard({
    super.key,
    required this.distribution,
    this.limit,
    this.order,
    this.color,
  });

  final NationalDistribution distribution;

  /// Caps how many rows are drawn. Long breakdowns such as medical condition
  /// would otherwise dominate the page.
  final int? limit;

  /// A fixed row order, for ordinal scales such as High/Medium/Low.
  final List<String>? order;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    if (!distribution.isAvailable) {
      return NationalCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NationalSectionHeader(
              title: distribution.title,
              trailing: ProvenanceBadge(distribution.provenance),
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              kNotAvailable,
              style: NemrasTextStyles.summaryName.copyWith(
                color: semantics.textPlaceholder,
              ),
            ),
            const SizedBox(height: NemrasSpacing.xxs),
            Text(
              distribution.basis,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final fixedOrder = order;
    final rows = fixedOrder != null
        ? distribution.entriesInOrder(fixedOrder)
        : distribution.entries(limit: limit);
    final barColor = color ?? semantics.accent;

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NationalSectionHeader(
            title: distribution.title,
            trailing: ProvenanceBadge(distribution.provenance),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            distribution.basis,
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xxl),
          for (final row in rows)
            NationalDistributionRow(entry: row, color: barColor),
          Text(
            'Total ${formatCount(distribution.total)} across '
            '${distribution.categoryCount} categor'
            '${distribution.categoryCount == 1 ? 'y' : 'ies'}',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One column of a [NationalTable].
@immutable
class NationalColumn {
  const NationalColumn({
    required this.label,
    required this.flex,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final bool alignEnd;
}

/// A bordered data table.
///
/// Built from rows of widgets rather than `DataTable` so each cell can carry
/// a status pill or a monospace identifier, and so column widths follow the
/// reference's proportional layout.
class NationalTable extends StatelessWidget {
  const NationalTable({super.key, required this.columns, required this.rows});

  final List<NationalColumn> columns;

  /// One list of cells per row. Each should match [columns] in length.
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: NemrasSpacing.s),
          child: Row(
            children: <Widget>[
              for (final column in columns)
                Expanded(
                  flex: column.flex,
                  child: Align(
                    alignment: column.alignEnd
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: NationalLabel(column.label, maxLines: 1),
                  ),
                ),
            ],
          ),
        ),
        Divider(height: 1, color: semantics.divider),
        for (final row in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: NemrasSpacing.m),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: semantics.divider)),
            ),
            child: Row(
              children: <Widget>[
                for (var i = 0; i < columns.length; i++)
                  Expanded(
                    flex: columns[i].flex,
                    child: Align(
                      alignment: columns[i].alignEnd
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: i < row.length ? row[i] : const SizedBox.shrink(),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A monospace cell, for identifiers and counts.
class NationalMonoCell extends StatelessWidget {
  const NationalMonoCell(this.text, {super.key, this.emphasise = false});

  final String text;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final missing = text == kNotAvailable;
    return Text(
      text,
      style: NemrasTextStyles.dataValue.copyWith(
        color: missing
            ? semantics.textPlaceholder
            : emphasise
                ? semantics.textPrimary
                : semantics.textSecondary,
        fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A body-text cell. Missing values render italic and muted.
class NationalTextCell extends StatelessWidget {
  const NationalTextCell(this.text, {super.key, this.maxLines});

  final String text;

  /// Null wraps freely, which suits explanatory columns. A value of 1 keeps
  /// short identifiers on one line.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final missing = text == kNotAvailable;
    return Text(
      text,
      maxLines: maxLines,
      style: NemrasTextStyles.body.copyWith(
        color: missing ? semantics.textPlaceholder : semantics.textPrimary,
        fontStyle: missing ? FontStyle.italic : FontStyle.normal,
      ),
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// A labelled value pair, for settings and detail panels.
class NationalField extends StatelessWidget {
  const NationalField({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final missing = value == kNotAvailable;

    return Padding(
      padding: const EdgeInsets.only(bottom: NemrasSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NationalLabel(label),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            value,
            style:
                (mono ? NemrasTextStyles.dataValue : NemrasTextStyles.body)
                    .copyWith(
              color:
                  missing ? semantics.textPlaceholder : semantics.textPrimary,
              fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// A national alert panel.
class NationalAlertPanel extends StatelessWidget {
  const NationalAlertPanel({super.key, required this.alert});

  final NationalAlert alert;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final NemrasStatusColor status;
    final IconData icon;
    switch (alert.severity) {
      case NationalAlertSeverity.critical:
        status = semantics.critical;
        icon = Icons.error_outline;
      case NationalAlertSeverity.warning:
        status = semantics.elevated;
        icon = Icons.warning_amber_outlined;
      case NationalAlertSeverity.info:
        status = semantics.informational;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: NemrasSpacing.l),
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: status.soft,
        borderRadius: NemrasRadii.metricBorder,
        border: Border.all(color: status.solid),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: status.onSoft),
          const SizedBox(width: NemrasSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  alert.title,
                  style: NemrasTextStyles.alertTitle.copyWith(
                    color: status.onSoft,
                  ),
                ),
                const SizedBox(height: NemrasSpacing.xxs),
                Text(
                  alert.detail,
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NemrasSpacing.m),
          ProvenanceBadge(alert.provenance),
        ],
      ),
    );
  }
}

/// A standing notice explaining where a screen's figures come from.
class ProvenanceNotice extends StatelessWidget {
  const ProvenanceNotice({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final heading = title;

    return Container(
      margin: const EdgeInsets.only(bottom: NemrasSpacing.xxl),
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: semantics.informational.soft,
        borderRadius: NemrasRadii.metricBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 16,
            color: semantics.informational.onSoft,
          ),
          const SizedBox(width: NemrasSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (heading != null) ...<Widget>[
                  NationalLabel(
                    heading,
                    color: semantics.informational.onSoft,
                  ),
                  const SizedBox(height: NemrasSpacing.xxs),
                ],
                Text(
                  message,
                  style: NemrasTextStyles.bodySmall.copyWith(
                    color: semantics.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A panel stating that something cannot be shown, and why.
///
/// This is the component that replaces every chart, map or trend the data
/// cannot support. It is a first-class panel rather than a grey box, because
/// on this surface a stated absence is a real answer to the analyst's
/// question and should read as one.
class UnavailablePanel extends StatelessWidget {
  const UnavailablePanel({
    super.key,
    required this.headline,
    required this.explanation,
    this.requirements = const <({String requirement, String detail})>[],
    this.icon = Icons.block_outlined,
  });

  /// The exact sentence the phase requires, such as the geographic notice or
  /// the trend notice.
  final String headline;

  final String explanation;

  /// What would be needed to make this available, rendered as a list.
  final List<({String requirement, String detail})> requirements;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return NationalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: semantics.textPlaceholder),
              const SizedBox(width: NemrasSpacing.m),
              const Expanded(child: NationalLabel('Not available')),
              const ProvenanceBadge(MetricProvenance.unavailable),
            ],
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Text(
            headline,
            style: NemrasTextStyles.sectionTitle.copyWith(
              color: semantics.textPrimary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            explanation,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          if (requirements.isNotEmpty) ...<Widget>[
            const SizedBox(height: NemrasSpacing.huge),
            const NationalLabel('What this would require'),
            const SizedBox(height: NemrasSpacing.l),
            for (final entry in requirements)
              Padding(
                padding: const EdgeInsets.only(bottom: NemrasSpacing.l),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 170,
                      child: Text(
                        entry.requirement,
                        style: NemrasTextStyles.listTitle.copyWith(
                          color: semantics.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: NemrasSpacing.l),
                    Expanded(
                      child: Text(
                        entry.detail,
                        style: NemrasTextStyles.bodySmall.copyWith(
                          color: semantics.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// The DEMO marker.
class DemoChip extends StatelessWidget {
  const DemoChip({super.key, this.label = 'DEMO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return NationalStatusPill(
      label: label,
      status: semantics.elevated,
      icon: Icons.science_outlined,
    );
  }
}

/// The shared loading state. Sizes to its content.
class NationalLoadingState extends StatelessWidget {
  const NationalLoadingState({super.key, this.message = 'Loading'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: NemrasSpacing.section),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: semantics.accent,
            ),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Text(
            message,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
          const SizedBox(height: NemrasSpacing.section),
        ],
      ),
    );
  }
}

/// The shared empty state. Sizes to its content.
class NationalEmptyState extends StatelessWidget {
  const NationalEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 32, color: semantics.textPlaceholder),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              title,
              style: NemrasTextStyles.sectionTitle.copyWith(
                color: semantics.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NemrasSpacing.xxs),
            Text(
              message,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The shared error state. Sizes to its content.
class NationalErrorState extends StatelessWidget {
  const NationalErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final retry = onRetry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NemrasSpacing.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 32,
              color: semantics.critical.onSoft,
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              title,
              style: NemrasTextStyles.sectionTitle.copyWith(
                color: semantics.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NemrasSpacing.xxs),
            Text(
              message,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (retry != null) ...<Widget>[
              const SizedBox(height: NemrasSpacing.huge),
              FilledButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A scrollable, padded, width-capped content area.
class NationalContentArea extends StatelessWidget {
  const NationalContentArea({
    super.key,
    required this.children,
    this.maxWidth = 1440,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(NemrasSpacing.section),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A responsive grid that wraps its children into as many columns as fit.
class NationalWrapGrid extends StatelessWidget {
  const NationalWrapGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260,
    this.gap = NemrasSpacing.xl,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final available = constraints.maxWidth;
        if (!available.isFinite) {
          return Wrap(spacing: gap, runSpacing: gap, children: children);
        }

        final columns = ((available + gap) / (minTileWidth + gap))
            .floor()
            .clamp(1, children.length);
        final tileWidth = (available - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}

/// A two-panel row that stacks on narrow windows.
class NationalSplitPanels extends StatelessWidget {
  const NationalSplitPanels({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
    this.stackBelow = 1000,
  });

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth.isFinite &&
            constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              primary,
              const SizedBox(height: NemrasSpacing.xl),
              secondary,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: primaryFlex, child: primary),
            const SizedBox(width: NemrasSpacing.xl),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

/// Formats a UTC instant for display, labelled UTC so a figure read in
/// another timezone is unambiguous.
String formatUtcTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}
