import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../content/portfolio_copy.dart';

const double portfolioContentWidth = 1120;

NemrasStatusColor portfolioTone(PortfolioMark mark, NemrasSemantics semantics) {
  switch (mark) {
    case PortfolioMark.implemented:
    case PortfolioMark.current:
      return semantics.stable;
    case PortfolioMark.demo:
    case PortfolioMark.ruleBased:
      return semantics.elevated;
    case PortfolioMark.partial:
      return semantics.informational;
    case PortfolioMark.planned:
    case PortfolioMark.proposed:
      return semantics.advisory;
  }
}

/// Teal focus ring, dark enough to read on white and on the filled teal button.
ButtonStyle portfolioButtonStyle({
  Color foreground = NemrasColors.ink,
  Color? background,
  BorderSide? restingSide,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
    horizontal: NemrasSpacing.xxl,
  ),
  TextStyle? textStyle,
}) {
  return ButtonStyle(
    foregroundColor: WidgetStatePropertyAll<Color>(foreground),
    backgroundColor: background == null
        ? null
        : WidgetStatePropertyAll<Color>(background),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size(NemrasTouchTargets.minimum, NemrasTouchTargets.minimum),
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry>(padding),
    textStyle: WidgetStatePropertyAll<TextStyle>(
      textStyle ?? NemrasTextStyles.button,
    ),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return NemrasColors.teal.withValues(alpha: 0.2);
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: NemrasColors.tealDeep, width: 3);
      }
      return restingSide;
    }),
    shape: const WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: NemrasRadii.controlBorder),
    ),
  );
}

ButtonStyle portfolioIconButtonStyle() {
  return ButtonStyle(
    foregroundColor: const WidgetStatePropertyAll<Color>(NemrasColors.ink),
    minimumSize: const WidgetStatePropertyAll<Size>(
      Size(NemrasTouchTargets.minimum, NemrasTouchTargets.minimum),
    ),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return NemrasColors.teal.withValues(alpha: 0.2);
      }
      return null;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.focused)) {
        return const BorderSide(color: NemrasColors.tealDeep, width: 3);
      }
      return BorderSide.none;
    }),
    shape: const WidgetStatePropertyAll<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: NemrasRadii.controlBorder),
    ),
  );
}

class MarkBadge extends StatelessWidget {
  const MarkBadge(this.mark, {super.key});

  final PortfolioMark mark;

  @override
  Widget build(BuildContext context) {
    final tone = portfolioTone(mark, NemrasSemantics.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.s,
        vertical: NemrasSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: NemrasRadii.pillBorder,
        border: Border.all(color: tone.solid.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tone.solid,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: NemrasSpacing.xs),
          Text(
            mark.label,
            style: NemrasTextStyles.tag.copyWith(color: NemrasColors.ink),
          ),
        ],
      ),
    );
  }
}

class PortfolioCard extends StatelessWidget {
  const PortfolioCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NemrasSpacing.xxl),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        borderRadius: NemrasRadii.cardBorder,
        border: Border.all(color: semantics.cardBorder),
        boxShadow: NemrasShadows.card,
      ),
      child: ClipRRect(
        borderRadius: NemrasRadii.cardBorder,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionIntro extends StatelessWidget {
  const SectionIntro({
    super.key,
    required this.section,
    required this.title,
    required this.lede,
  });

  final PortfolioSection section;
  final String title;
  final String lede;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          section.number,
          style: NemrasTextStyles.fieldLabel.copyWith(color: semantics.accent),
        ),
        const SizedBox(height: NemrasSpacing.s),
        Semantics(
          header: true,
          headingLevel: 2,
          child: Text(
            title,
            style: NemrasTextStyles.metricValue.copyWith(
              color: semantics.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: NemrasSpacing.l),
        Text(
          lede,
          style: NemrasTextStyles.body.copyWith(color: semantics.textSecondary),
        ),
      ],
    );
  }
}

class PortfolioGrid extends StatelessWidget {
  const PortfolioGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final window = NemrasBreakpoints.fromWidth(constraints.maxWidth);
        final columns = switch (window) {
          NemrasWindowSize.expanded => maxColumns,
          NemrasWindowSize.medium => maxColumns == 1 ? 1 : 2,
          NemrasWindowSize.compact => 1,
        };
        return _columnGrid(children, columns);
      },
    );
  }
}

Widget _columnGrid(List<Widget> children, int columns) {
  final rows = <Widget>[];
  for (var start = 0; start < children.length; start += columns) {
    final slice = children.sublist(
      start,
      start + columns > children.length ? children.length : start + columns,
    );
    rows.add(
      Padding(
        padding: EdgeInsets.only(top: start == 0 ? 0 : NemrasSpacing.xl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (var index = 0; index < columns; index++) ...<Widget>[
              if (index > 0) const SizedBox(width: NemrasSpacing.xl),
              Expanded(
                child: index < slice.length
                    ? slice[index]
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  return Column(children: rows);
}

class PortfolioAction extends StatelessWidget {
  const PortfolioAction({
    super.key,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton(
        style: portfolioButtonStyle(
          foreground: NemrasColors.white,
          background: NemrasColors.teal,
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: portfolioButtonStyle(
        restingSide: const BorderSide(color: NemrasColors.line),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class PersonPortrait extends StatelessWidget {
  const PersonPortrait({super.key, required this.person});

  final PortfolioPerson person;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final portrait = person.asset == null
        ? _Initials(person: person)
        : ClipOval(
            child: Image.asset(
              person.asset!,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          );
    return Semantics(
      label: person.name,
      image: person.asset != null,
      child: SizedBox(
        width: 88,
        height: 88,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: semantics.cardBorder),
          ),
          child: portrait,
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.person});

  final PortfolioPerson person;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: NemrasColors.tealSoft,
      ),
      child: Center(
        child: Text(
          person.initials,
          style: NemrasTextStyles.summaryName.copyWith(
            color: NemrasColors.tealDeep,
          ),
        ),
      ),
    );
  }
}
