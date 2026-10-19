import 'package:flutter/material.dart';

import 'navigation_models.dart';

/// `.bottom-nav` - the 64dp bottom bar used by the patient and paramedic
/// surfaces.
///
/// Wraps Material's [NavigationBar] rather than reimplementing it, so the
/// height, active colour and label typography all come from the Phase 1A
/// `navigationBarTheme`. That is what makes the same widget render teal on the
/// clinical theme and `#4DD0E1` on the field theme with no branching here.
class NemrasBottomNavigation extends StatelessWidget {
  const NemrasBottomNavigation({
    super.key,
    required this.config,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final NemrasNavigationConfig config;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final items = config.items;
    assert(items.isNotEmpty, 'Bottom navigation needs at least one item.');

    return NavigationBar(
      selectedIndex: selectedIndex.clamp(0, items.length - 1),
      onDestinationSelected: onDestinationSelected,
      destinations: <Widget>[
        for (final item in items)
          NavigationDestination(
            icon: _Icon(icon: item.icon, badgeCount: item.badgeCount),
            selectedIcon:
                _Icon(icon: item.activeIcon, badgeCount: item.badgeCount),
            label: item.label,
            tooltip: item.label,
          ),
      ],
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon({required this.icon, this.badgeCount});

  final IconData icon;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon);
    if (badgeCount == null || badgeCount! <= 0) return glyph;
    return Badge.count(count: badgeCount!, child: glyph);
  }
}
