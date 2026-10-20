import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

import 'breakpoints.dart';
import 'desktop_sidebar.dart';
import 'desktop_topbar.dart';
import 'mobile_navigation.dart';
import 'navigation_models.dart';

/// Which navigation chrome a surface uses.
enum AdaptiveNavigationPattern {
  /// Bottom bar on compact windows, sidebar on expanded ones.
  adaptive,

  /// Always the 64dp bottom bar.
  ///
  /// The patient and paramedic surfaces are mobile-only in the reference,
  /// which draws no desktop layout for either. Without this, a wide browser
  /// window would give a patient the hospital sidebar - a layout NEMRAS has
  /// never specified.
  bottomBar,

  /// Always the 200dp sidebar with the top bar. The hospital and ministry
  /// surfaces are desktop-only.
  sidebar,
}

/// The single shell every NEMRAS surface navigates through.
///
/// Renders the two patterns the reference establishes: a 64dp bottom bar and a
/// 200dp dark sidebar with a 54dp top bar. It deliberately does not supply an
/// app bar in the bottom-bar layout, because the existing patient screens each
/// build their own.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.navigation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.pattern = AdaptiveNavigationPattern.adaptive,
    this.title,
    this.breadcrumb,
    this.brand,
    this.avatar,
    this.showSearch = true,
    this.showNotifications = true,
    this.hasUnreadNotifications = false,
    this.mediumUsesDesktopLayout = false,
  });

  final NemrasNavigationConfig navigation;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final AdaptiveNavigationPattern pattern;

  /// Top-bar title. Unused in the bottom-bar layout.
  final String? title;
  final String? breadcrumb;
  final Widget? brand;
  final Widget? avatar;
  final bool showSearch;
  final bool showNotifications;
  final bool hasUnreadNotifications;

  /// [REC] Medium windows use the bottom bar by default. The reference draws
  /// only phone and desktop layouts, so a tablet pattern such as a navigation
  /// rail would be invented rather than transcribed. Applies only to
  /// [AdaptiveNavigationPattern.adaptive].
  final bool mediumUsesDesktopLayout;

  bool _useDesktop(BuildContext context) {
    switch (pattern) {
      case AdaptiveNavigationPattern.bottomBar:
        return false;
      case AdaptiveNavigationPattern.sidebar:
        return true;
      case AdaptiveNavigationPattern.adaptive:
        final size = NemrasBreakpoints.of(context);
        return size == NemrasWindowSize.expanded ||
            (size == NemrasWindowSize.medium && mediumUsesDesktopLayout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _useDesktop(context) ? _buildDesktop(context) : _buildCompact();
  }

  Widget _buildCompact() {
    return Scaffold(
      body: body,
      bottomNavigationBar: NemrasBottomNavigation(
        config: navigation,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final semantics = NemrasSemantics.of(context);

    return Scaffold(
      body: Row(
        children: <Widget>[
          NemrasDesktopSidebar(
            config: navigation,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            brand: brand,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                NemrasDesktopTopBar(
                  title: title ?? _selectedLabel(),
                  breadcrumb: breadcrumb,
                  showSearch: showSearch,
                  showNotifications: showNotifications,
                  hasUnreadNotifications: hasUnreadNotifications,
                  avatar: avatar,
                ),
                Expanded(
                  child: ColoredBox(
                    color: semantics.screenBackground,
                    child: body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _selectedLabel() {
    final items = navigation.items;
    if (items.isEmpty) return '';
    return items[selectedIndex.clamp(0, items.length - 1)].label;
  }
}
