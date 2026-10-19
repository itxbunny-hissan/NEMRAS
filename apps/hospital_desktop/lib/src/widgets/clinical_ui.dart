import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import '../data/clinical_models.dart';

/// A bordered clinical panel. `.card` in the NEMRAS reference.
class ClinicalCard extends StatelessWidget {
  const ClinicalCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(NemrasSpacing.cardPadding),
    this.borderColor,
    this.background,
  });

  final Widget child;

  /// Rendered as a `.card-title` micro-heading above [child].
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? semantics.cardBackground,
        borderRadius: NemrasRadii.cardBorder,
        border: Border.all(color: borderColor ?? semantics.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: ClinicalSectionLabel(title!)),
                ?trailing,
              ],
            ),
            const SizedBox(height: NemrasSpacing.titleGap),
          ],
          child,
        ],
      ),
    );
  }
}

/// `.card-title` - a monospace all-caps micro-heading.
class ClinicalSectionLabel extends StatelessWidget {
  const ClinicalSectionLabel(this.label, {super.key, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Text(
      label.toUpperCase(),
      style: NemrasTextStyles.fieldLabel.copyWith(
        color: color ?? semantics.textSecondary,
      ),
    );
  }
}

/// `.risk-pill` - a solid status pill.
class ClinicalStatusPill extends StatelessWidget {
  const ClinicalStatusPill({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  final String label;
  final NemrasStatusColor status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.m,
        vertical: NemrasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.solid,
        borderRadius: NemrasRadii.pillBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: status.onSolid),
            const SizedBox(width: NemrasSpacing.xxs),
          ],
          Text(
            label.toUpperCase(),
            style: NemrasTextStyles.riskPill.copyWith(color: status.onSolid),
          ),
        ],
      ),
    );
  }
}

/// `.tag` - a soft-background clinical tag.
class ClinicalTag extends StatelessWidget {
  const ClinicalTag({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  final String label;
  final NemrasStatusColor status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.s,
        vertical: NemrasSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: status.soft,
        borderRadius: NemrasRadii.tagBorder,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: status.onSoft),
            const SizedBox(width: NemrasSpacing.xxs),
          ],
          Text(
            label.toUpperCase(),
            style: NemrasTextStyles.tag.copyWith(color: status.onSoft),
          ),
        ],
      ),
    );
  }
}

/// Marks state that is synthetic. Every emergency case and audit event in
/// Phase 3A carries one.
class DemoChip extends StatelessWidget {
  const DemoChip({super.key, this.label = 'DEMO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Semantics(
      label: 'Synthetic demo data',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NemrasSpacing.s,
          vertical: NemrasSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: semantics.advisory.soft,
          borderRadius: NemrasRadii.tagBorder,
          border: Border.all(color: semantics.advisory.solid),
        ),
        child: Text(
          label,
          style: NemrasTextStyles.tag.copyWith(
            color: semantics.advisory.onSoft,
          ),
        ),
      ),
    );
  }
}

/// A labelled clinical value. The value uses the monospace data style so
/// identifiers and clinical fields stay visually distinct from prose.
class ClinicalDataField extends StatelessWidget {
  const ClinicalDataField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Renders the value at body weight instead of the data style, for long
  /// free-text values such as a handover note.
  final bool emphasise;

  bool get _isMissing => value == kNotAvailable;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final resolved = _isMissing
        ? semantics.textPlaceholder
        : valueColor ?? semantics.textPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClinicalSectionLabel(label),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          value,
          style: (emphasise
                  ? NemrasTextStyles.body
                  : NemrasTextStyles.dataValue)
              .copyWith(
            color: resolved,
            fontStyle: _isMissing ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

/// A key figure. `.kpi` in the reference.
class ClinicalMetric extends StatelessWidget {
  const ClinicalMetric({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      padding: const EdgeInsets.all(NemrasSpacing.xxl),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        borderRadius: NemrasRadii.metricBorder,
        border: Border.all(color: semantics.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClinicalSectionLabel(label),
          const SizedBox(height: NemrasSpacing.s),
          Text(
            value,
            style: NemrasTextStyles.metricValue.copyWith(
              color: valueColor ?? semantics.textPrimary,
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: NemrasSpacing.xxs),
            Text(
              caption!,
              style: NemrasTextStyles.metricDelta.copyWith(
                color: semantics.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A rule-based alert row. `.alert-box` in the reference.
class ClinicalAlertBox extends StatelessWidget {
  const ClinicalAlertBox({
    super.key,
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final NemrasStatusColor status;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.xl),
      decoration: BoxDecoration(
        color: status.soft,
        borderRadius: NemrasRadii.controlBorder,
        border: Border(left: BorderSide(color: status.solid, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: NemrasTextStyles.alertTitle.copyWith(color: status.onSoft),
          ),
          const SizedBox(height: NemrasSpacing.xxs),
          Text(
            detail,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A banner for statements that must not be mistaken for a clinical claim.
class ProvenanceNotice extends StatelessWidget {
  const ProvenanceNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NemrasSpacing.l),
      decoration: BoxDecoration(
        color: semantics.informational.soft,
        borderRadius: NemrasRadii.controlBorder,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 14, color: semantics.informational.onSoft),
          const SizedBox(width: NemrasSpacing.s),
          Expanded(
            child: Text(
              message,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.informational.onSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while a request is in flight.
class ClinicalLoadingState extends StatelessWidget {
  const ClinicalLoadingState({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: NemrasSpacing.xl),
          Text(
            message,
            style: NemrasTextStyles.bodySmall.copyWith(
              color: semantics.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when there is nothing to display yet.
class ClinicalEmptyState extends StatelessWidget {
  const ClinicalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: semantics.textPlaceholder),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: NemrasTextStyles.screenTitle.copyWith(
                color: semantics.textPrimary,
              ),
            ),
            const SizedBox(height: NemrasSpacing.s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: NemrasSpacing.huge),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when a request failed.
class ClinicalErrorState extends StatelessWidget {
  const ClinicalErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: semantics.critical.onSoft,
            ),
            const SizedBox(height: NemrasSpacing.xl),
            Text(
              message,
              textAlign: TextAlign.center,
              style: NemrasTextStyles.bodySmall.copyWith(
                color: semantics.textSecondary,
              ),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: NemrasSpacing.huge),
              OutlinedButton.icon(
                onPressed: onRetry,
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

/// A scrolling desktop content area with the reference's screen padding.
class ClinicalContentArea extends StatelessWidget {
  const ClinicalContentArea({
    super.key,
    required this.children,
    this.maxWidth = 1180,
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
            children: <Widget>[
              for (var i = 0; i < children.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: NemrasSpacing.stackGap),
                children[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two side-by-side panels on a wide window, stacked when the content area is
/// too narrow to keep both readable.
class ClinicalSplitPanels extends StatelessWidget {
  const ClinicalSplitPanels({
    super.key,
    required this.primary,
    required this.secondary,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
    this.stackBelow = 980,
  });

  final Widget primary;
  final Widget secondary;
  final int primaryFlex;
  final int secondaryFlex;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              primary,
              const SizedBox(height: NemrasSpacing.stackGap),
              secondary,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(flex: primaryFlex, child: primary),
            const SizedBox(width: NemrasSpacing.stackGap),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

/// A responsive grid of fixed-ish cells, used for metric rows and field grids.
class ClinicalWrapGrid extends StatelessWidget {
  const ClinicalWrapGrid({
    super.key,
    required this.children,
    this.minCellWidth = 200,
    this.spacing = NemrasSpacing.xl,
  });

  final List<Widget> children;
  final double minCellWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        if (!available.isFinite) {
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children,
          );
        }
        final columns =
            (available / minCellWidth).floor().clamp(1, children.length);
        final cellWidth = (available - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: <Widget>[
            for (final child in children)
              SizedBox(width: cellWidth, child: child),
          ],
        );
      },
    );
  }
}
