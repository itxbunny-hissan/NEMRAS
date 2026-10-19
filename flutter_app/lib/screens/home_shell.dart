import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';

/// Legacy two-tab shell pairing patient lookup with the hospital dashboard.
///
/// Not reachable at runtime: nothing constructs it, and the live patient flow
/// goes Sign In -> PatientShell. It is retained as the host for the future
/// desktop operational shell, where [DashboardScreen] becomes the hospital
/// Overview. See the Phase 1B reuse assessment.
///
/// Its two destinations are local to this shell rather than part of
/// `NemrasNavigationCatalog`, because they do not appear in the UI reference.
/// Kept on [AdaptiveNavigationPattern.bottomBar] so behaviour is unchanged.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static final _navigation = NemrasNavigationConfig.flat(
    const <NemrasNavigationItem>[
      NemrasNavigationItem(
        label: 'Patient Lookup',
        icon: Icons.qr_code_scanner_outlined,
        selectedIcon: Icons.qr_code_scanner,
        route: NemrasRouteNames.signIn,
      ),
      NemrasNavigationItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        route: NemrasRouteNames.hospitalOverview,
      ),
    ],
  );

  static const _pages = <Widget>[
    ScanScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      navigation: _navigation,
      pattern: AdaptiveNavigationPattern.bottomBar,
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      body: IndexedStack(index: _tab, children: _pages),
    );
  }
}
