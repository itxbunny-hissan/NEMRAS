import 'package:flutter/widgets.dart';

/// A single navigation destination.
///
/// [badgeCount] is a presentation slot only. The reference draws a hard-coded
/// `7` on the hospital Emergency row; that is mock content, so the shipped
/// configurations leave this null and a real count must come from the backend.
@immutable
class NemrasNavigationItem {
  const NemrasNavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.selectedIcon,
    this.badgeCount,
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final String route;
  final int? badgeCount;

  IconData get activeIcon => selectedIcon ?? icon;

  NemrasNavigationItem copyWith({int? badgeCount}) => NemrasNavigationItem(
        label: label,
        icon: icon,
        route: route,
        selectedIcon: selectedIcon,
        badgeCount: badgeCount ?? this.badgeCount,
      );

  @override
  bool operator ==(Object other) =>
      other is NemrasNavigationItem &&
      other.label == label &&
      other.icon == icon &&
      other.selectedIcon == selectedIcon &&
      other.route == route &&
      other.badgeCount == badgeCount;

  @override
  int get hashCode =>
      Object.hash(label, icon, selectedIcon, route, badgeCount);
}

/// A titled run of destinations. `.nav-grp` in the reference sidebar.
///
/// Bottom navigation has no grouping, so a compact configuration is a single
/// group with no [title].
@immutable
class NemrasNavigationGroup {
  const NemrasNavigationGroup({required this.items, this.title});

  final String? title;
  final List<NemrasNavigationItem> items;

  @override
  bool operator ==(Object other) =>
      other is NemrasNavigationGroup &&
      other.title == title &&
      _listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(items));
}

/// The navigation a surface exposes, supplied by the consuming surface rather
/// than hard-coded into any scaffold.
@immutable
class NemrasNavigationConfig {
  const NemrasNavigationConfig(this.groups);

  /// Convenience for flat, ungrouped navigation such as a bottom bar.
  NemrasNavigationConfig.flat(List<NemrasNavigationItem> items)
      : groups = <NemrasNavigationGroup>[
          NemrasNavigationGroup(items: items),
        ];

  final List<NemrasNavigationGroup> groups;

  /// Every destination, in sidebar order. Selection indices address this list.
  List<NemrasNavigationItem> get items =>
      <NemrasNavigationItem>[for (final group in groups) ...group.items];

  int get length => items.length;

  /// The flat index of [route], or null when the route is not a destination.
  int? indexOfRoute(String route) {
    final all = items;
    for (var i = 0; i < all.length; i++) {
      if (all[i].route == route) return i;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is NemrasNavigationConfig && _listEquals(other.groups, groups);

  @override
  int get hashCode => Object.hashAll(groups);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
