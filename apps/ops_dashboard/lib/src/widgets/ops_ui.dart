import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/metric_provenance.dart';
import '../data/operations_models.dart';

/// The shared presentation vocabulary for the operational dashboard.
///
/// Every widget here resolves its colours, spacing, radii and text styles
/// from `nemras_design`. No raw colour, size or font is declared in this app.

/// `.card` — the standard bordered panel.
class OpsCard extends StatelessWidget {
  const OpsCard({
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
      // The accent edge is drawn as a strip rather than a left BorderSide,
      // because a Border with per-side colours cannot carry a borderRadius.
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
class OpsLabel extends StatelessWidget {
  const OpsLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Text(
      text.toUpperCase(),
      style: NemrasTextStyles.metricLabel.copyWith(
        color: color ?? semantics.textSecondary,
      ),
    );
  }
}

/// A section heading with an optional trailing control.
class OpsSectionHeader extends StatelessWidget {
  const OpsSectionHeader({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
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
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// A soft-filled status pill. `.tag` in the reference.
class OpsStatusPill extends StatelessWidget {
  const OpsStatusPill({
    super.key,
    required this.label,
    required this.status,
    this.solid = false,
    this.icon,
  });

  final String label;
  final NemrasStatusColor status;

  /// Solid fill instead of soft. Used sparingly, for the single most
  /// important state on a row.
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
/// one, so a reader can always tell a dataset record count from a simulated
/// value from a figure NEMRAS does not have.
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
      child: OpsStatusPill(label: provenance.badge, status: status),
    );
  }
}

/// A KPI card.
///
/// The provenance badge sits beside the label rather than below the value, so
/// it cannot be read as a caption to a number a reader has already taken in.
class OpsKpiCard extends StatelessWidget {
  const OpsKpiCard({super.key, required this.metric, this.icon});

  final OpsMetric metric;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final glyph = icon;
    final caption = metric.caption;

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (glyph != null) ...<Widget>[
                Icon(glyph, size: 16, color: semantics.textSecondary),
                const SizedBox(width: NemrasSpacing.xs),
              ],
              Expanded(child: OpsLabel(metric.label)),
            ],
          ),
          const SizedBox(height: NemrasSpacing.s),
          ProvenanceBadge(metric.provenance),
          const SizedBox(height: NemrasSpacing.m),
          Text(
            metric.displayValue,
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

/// A horizontal proportion bar, used for occupancy and for distributions.
class OpsProgressBar extends StatelessWidget {
  const OpsProgressBar({
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
class OpsDistributionRow extends StatelessWidget {
  const OpsDistributionRow({
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
          OpsProgressBar(fraction: entry.fraction, color: color),
        ],
      ),
    );
  }
}

/// A distribution rendered as a card of labelled rows.
///
/// Tables and proportion bars rather than a chart library: NEMRAS has no
/// charting dependency and this phase does not add one.
class OpsDistributionCard extends StatelessWidget {
  const OpsDistributionCard({
    super.key,
    required this.distribution,
    this.limit,
    this.order,
    this.color,
  });

  final OpsDistribution distribution;

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
      return OpsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            OpsSectionHeader(title: distribution.title),
            const SizedBox(height: NemrasSpacing.l),
            ProvenanceBadge(distribution.provenance),
            const SizedBox(height: NemrasSpacing.m),
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

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OpsSectionHeader(
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
            OpsDistributionRow(entry: row, color: barColor),
          Text(
            'Total ${formatCount(distribution.total)}',
            style: NemrasTextStyles.dataCaption.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// One column of an [OpsTable].
@immutable
class OpsColumn {
  const OpsColumn({
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
class OpsTable extends StatelessWidget {
  const OpsTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<OpsColumn> columns;

  /// One list of cells per row. Each must match [columns] in length.
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
                    child: OpsLabel(column.label),
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
class OpsMonoCell extends StatelessWidget {
  const OpsMonoCell(this.text, {super.key, this.emphasise = false});

  final String text;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Text(
      text,
      style: NemrasTextStyles.dataValue.copyWith(
        color: emphasise ? semantics.textPrimary : semantics.textSecondary,
        fontWeight: emphasise ? FontWeight.w600 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A body-text cell.
class OpsTextCell extends StatelessWidget {
  const OpsTextCell(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final missing = text == kNotAvailable;
    return Text(
      text,
      style: NemrasTextStyles.body.copyWith(
        color: missing ? semantics.textPlaceholder : semantics.textPrimary,
        fontStyle: missing ? FontStyle.italic : FontStyle.normal,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// A labelled value pair, for settings and detail panels.
class OpsField extends StatelessWidget {
  const OpsField({
    super.key,
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;

  /// Monospace, for identifiers and codes.
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
          OpsLabel(label),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            value,
            style: (mono
                    ? NemrasTextStyles.dataValue
                    : NemrasTextStyles.body)
                .copyWith(
              color: missing ? semantics.textPlaceholder : semantics.textPrimary,
              fontStyle: missing ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// An operational alert panel.
class OpsAlertPanel extends StatelessWidget {
  const OpsAlertPanel({super.key, required this.alert});

  final OpsAlert alert;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final NemrasStatusColor status;
    final IconData icon;
    switch (alert.severity) {
      case OpsAlertSeverity.critical:
        status = semantics.critical;
        icon = Icons.error_outline;
      case OpsAlertSeverity.warning:
        status = semantics.elevated;
        icon = Icons.warning_amber_outlined;
      case OpsAlertSeverity.info:
        status = semantics.informational;
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: NemrasSpacing.l),
      padding: const EdgeInsets.fromLTRB(
        NemrasSpacing.xxl,
        NemrasSpacing.xl,
        NemrasSpacing.xl,
        NemrasSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: status.soft,
        borderRadius: NemrasRadii.metricBorder,
        // A left-only accent cannot be a BorderSide here: a Border with
        // per-side colours and a borderRadius cannot be painted.
        border: Border.all(color: status.solid, width: 1),
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

/// A standing notice that explains where a screen's figures come from.
///
/// Placed at the top of every data screen so the provenance rules are stated
/// once in prose, not only encoded in badges.
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
                  OpsLabel(heading, color: semantics.informational.onSoft),
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

/// The DEMO marker.
class DemoChip extends StatelessWidget {
  const DemoChip({super.key, this.label = 'DEMO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return OpsStatusPill(
      label: label,
      status: semantics.elevated,
      icon: Icons.science_outlined,
    );
  }
}

/// The shared loading state.
///
/// Sizes to its content rather than to a fixed height, so it can sit inside a
/// card, inside a scroll view, or fill a screen body without overflowing.
class OpsLoadingState extends StatelessWidget {
  const OpsLoadingState({super.key, this.message = 'Loading'});

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

/// The shared empty state. Sizes to its content, as [OpsLoadingState] does.
class OpsEmptyState extends StatelessWidget {
  const OpsEmptyState({
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

/// The shared error state. Sizes to its content, as [OpsLoadingState] does.
class OpsErrorState extends StatelessWidget {
  const OpsErrorState({
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
///
/// The cap keeps line lengths and table columns readable on an ultrawide
/// monitor, which the operational screens are otherwise prone to stretching
/// across.
class OpsContentArea extends StatelessWidget {
  const OpsContentArea({
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
///
/// Used for KPI cards and for paired panels. Falls back to a plain [Wrap]
/// when the width is unbounded, which happens inside an unconstrained
/// scrollable during tests.
class OpsWrapGrid extends StatelessWidget {
  const OpsWrapGrid({
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
class OpsSplitPanels extends StatelessWidget {
  const OpsSplitPanels({
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

/// Formats a UTC instant for display, labelled UTC so a log read in another
/// timezone is unambiguous.
String formatUtcTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}

/// Formats a UTC instant as a time only.
String formatUtcTime(DateTime value) {
  final utc = value.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(utc.hour)}:${two(utc.minute)} UTC';
}
