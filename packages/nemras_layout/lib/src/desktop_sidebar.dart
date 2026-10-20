import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import 'navigation_models.dart';

/// `.hd-sidebar` - the 200dp dark sidebar used by the hospital and ministry
/// surfaces.
///
/// Structure only. The consuming surface supplies the navigation model and the
/// brand area; this widget invents no destinations.
class NemrasDesktopSidebar extends StatelessWidget {
  const NemrasDesktopSidebar({
    super.key,
    required this.config,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.brand,
  });

  final NemrasNavigationConfig config;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Optional brand slot at the top of the sidebar.
  final Widget? brand;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var flatIndex = 0;

    for (final group in config.groups) {
      if (group.title != null) {
        rows.add(_GroupLabel(group.title!));
      }
      for (final item in group.items) {
        final index = flatIndex;
        rows.add(_NavigationRow(
          item: item,
          selected: index == selectedIndex,
          onTap: () => onDestinationSelected(index),
        ));
        flatIndex++;
      }
    }

    return Container(
      width: NemrasTouchTargets.sidebarWidth,
      color: NemrasColors.ink,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (brand != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NemrasSpacing.l,
                  NemrasSpacing.xxl,
                  NemrasSpacing.l,
                  NemrasSpacing.s,
                ),
                child: brand,
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: NemrasSpacing.s,
                  vertical: NemrasSpacing.s,
                ),
                children: rows,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NemrasSpacing.s,
        NemrasSpacing.xl,
        NemrasSpacing.s,
        NemrasSpacing.s,
      ),
      child: Text(
        title,
        style: NemrasTextStyles.metricLabel.copyWith(
          fontSize: 9,
          letterSpacing: 1.62,
          color: const Color.fromRGBO(255, 255, 255, 0.4),
        ),
      ),
    );
  }
}

class _NavigationRow extends StatelessWidget {
  const _NavigationRow({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NemrasNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? NemrasColors.fieldAccent
        : const Color.fromRGBO(255, 255, 255, 0.65);

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: NemrasRadii.badgeBorder,
        child: Container(
          // [REC] The reference row is ~34dp tall. Raised to the Phase 1A
          // baseline so the whole row is an accessible target.
          constraints: const BoxConstraints(
            minHeight: NemrasTouchTargets.minimum,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: NemrasSpacing.m,
            vertical: NemrasSpacing.s,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color.fromRGBO(77, 208, 225, 0.12)
                : Colors.transparent,
            borderRadius: NemrasRadii.badgeBorder,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                selected ? item.activeIcon : item.icon,
                size: 16,
                color: foreground,
              ),
              const SizedBox(width: NemrasSpacing.m),
              Expanded(
                child: Text(
                  item.label,
                  style: NemrasTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    color: foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badgeCount != null && item.badgeCount! > 0)
                _CountBadge(item.badgeCount!),
            ],
          ),
        ),
      ),
    );
  }
}

/// `.hd-nav-item .badge`
class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: NemrasSpacing.xs,
          vertical: 2),
      decoration: const BoxDecoration(
        color: NemrasColors.red,
        borderRadius: NemrasRadii.badgeBorder,
      ),
      child: Text(
        '$count',
        style: NemrasTextStyles.badge.copyWith(color: NemrasColors.white),
      ),
    );
  }
}
