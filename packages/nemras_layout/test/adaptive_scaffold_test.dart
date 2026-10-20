import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  /// Placeholder bodies only. No NEMRAS product screen is built here.
  Widget harness({
    required Size windowSize,
    required NemrasNavigationConfig navigation,
    ThemeData? theme,
    int selectedIndex = 0,
    ValueChanged<int>? onSelected,
    bool mediumUsesDesktopLayout = false,
    AdaptiveNavigationPattern pattern = AdaptiveNavigationPattern.adaptive,
  }) {
    return MaterialApp(
      theme: theme ?? nemrasClinicalLightTheme(),
      home: MediaQuery(
        data: MediaQueryData(size: windowSize),
        child: AdaptiveScaffold(
          navigation: navigation,
          selectedIndex: selectedIndex,
          onDestinationSelected: onSelected ?? (_) {},
          title: 'NEMRAS',
          breadcrumb: 'TEST / HARNESS',
          pattern: pattern,
          mediumUsesDesktopLayout: mediumUsesDesktopLayout,
          body: const Center(child: Text('body')),
        ),
      ),
    );
  }

  group('compact layout', () {
    testWidgets('uses the bottom bar and no sidebar', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.patient,
      ));

      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      expect(find.byType(NemrasDesktopSidebar), findsNothing);
      expect(find.byType(NemrasDesktopTopBar), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('renders every patient destination', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.patient,
      ));

      for (final label in <String>['Home', 'Record', 'Chat', 'Profile']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('bottom bar is the reference 64dp', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.patient,
      ));

      final bar = tester.getSize(find.byType(NavigationBar));
      expect(bar.height, NemrasTouchTargets.bottomNavHeight);
    });

    testWidgets('reports taps by flat index', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.patient,
        onSelected: taps.add,
      ));

      await tester.tap(find.text('Chat'));
      expect(taps, <int>[2]);
    });

    testWidgets('medium windows use the compact pattern by default',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(820, 1180),
        navigation: NemrasNavigationCatalog.patient,
      ));

      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      expect(find.byType(NemrasDesktopSidebar), findsNothing);
    });

    testWidgets('medium can opt into the desktop pattern', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(820, 1180),
        navigation: NemrasNavigationCatalog.hospital,
        mediumUsesDesktopLayout: true,
      ));

      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsNothing);
    });
  });

  group('expanded layout', () {
    testWidgets('uses the sidebar and top bar, not the bottom bar',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
      ));

      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasDesktopTopBar), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('sidebar is the reference 200dp', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
      ));

      final sidebar = tester.getSize(find.byType(NemrasDesktopSidebar));
      expect(sidebar.width, NemrasTouchTargets.sidebarWidth);
    });

    testWidgets('top bar is the reference 54dp', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
      ));

      final bar = tester.getSize(find.byType(NemrasDesktopTopBar));
      expect(bar.height, NemrasTouchTargets.barHeight);
    });

    testWidgets('renders group labels and destinations', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
      ));

      expect(find.text('OPERATIONS'), findsOneWidget);
      expect(find.text('REPORTS'), findsOneWidget);
      expect(find.text('SYSTEM'), findsOneWidget);
      expect(find.text('Bed Occupancy'), findsOneWidget);
      expect(find.text('Audit Trail'), findsOneWidget);
    });

    testWidgets('shows the breadcrumb slot', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.central,
      ));

      expect(find.text('TEST / HARNESS'), findsOneWidget);
    });

    testWidgets('sidebar rows meet the accessible touch target',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
      ));

      final row = tester.getSize(
        find.ancestor(
          of: find.text('Overview'),
          matching: find.byType(InkWell),
        ).first,
      );
      expect(row.height, greaterThanOrEqualTo(NemrasTouchTargets.minimum));
    });

    testWidgets('reports sidebar taps by flat index across groups',
        (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.hospital,
        onSelected: taps.add,
      ));

      await tester.tap(find.text('Audit Trail'));
      expect(taps, <int>[6]);
    });
  });

  group('navigation pattern', () {
    testWidgets('a mobile-only surface keeps the bottom bar on a wide window, '
        'so a patient never gets the hospital sidebar', (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(1440, 900),
        navigation: NemrasNavigationCatalog.patient,
        pattern: AdaptiveNavigationPattern.bottomBar,
      ));

      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      expect(find.byType(NemrasDesktopSidebar), findsNothing);
    });

    testWidgets('a desktop-only surface keeps the sidebar on a narrow window',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.hospital,
        pattern: AdaptiveNavigationPattern.sidebar,
      ));

      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsNothing);
    });

    test('role configurations choose the right pattern', () {
      expect(
        NemrasRoleConfig.of(NemrasRole.patient).navigationPattern,
        AdaptiveNavigationPattern.bottomBar,
      );
      expect(
        NemrasRoleConfig.of(NemrasRole.paramedic).navigationPattern,
        AdaptiveNavigationPattern.bottomBar,
      );
      expect(
        NemrasRoleConfig.of(NemrasRole.hospitalAdministrator)
            .navigationPattern,
        AdaptiveNavigationPattern.sidebar,
      );
      expect(
        NemrasRoleConfig.of(NemrasRole.ministryAnalyst).navigationPattern,
        AdaptiveNavigationPattern.sidebar,
      );
    });
  });

  group('field theme support', () {
    testWidgets('paramedic navigation renders on the dark field theme',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.paramedic,
        theme: nemrasFieldDarkTheme(),
      ));

      expect(find.byType(NemrasBottomNavigation), findsOneWidget);
      for (final label in <String>['Scan', 'Voice', 'Drugs', 'Route']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('field bottom bar picks up the field accent from the theme',
        (tester) async {
      await tester.pumpWidget(harness(
        windowSize: const Size(390, 844),
        navigation: NemrasNavigationCatalog.paramedic,
        theme: nemrasFieldDarkTheme(),
      ));

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final context = tester.element(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0);
      expect(
        Theme.of(context).navigationBarTheme.iconTheme!
            .resolve(<WidgetState>{WidgetState.selected})!.color,
        NemrasColors.fieldAccent,
      );
    });
  });
}
