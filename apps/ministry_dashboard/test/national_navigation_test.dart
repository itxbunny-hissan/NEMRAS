import 'package:flutter_test/flutter_test.dart';
import 'package:ministry_dashboard/src/navigation/national_navigation.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  group('sidebar composition', () {
    test('exposes exactly the eight briefed destinations, in order', () {
      final labels = NationalNavigation.sidebar.items
          .map((item) => item.label)
          .toList();

      expect(labels, <String>[
        'National Overview',
        'Emergency Trends',
        'Health Indicators',
        'Hospital Network',
        'Federation',
        'Reports',
        'Audit / Governance',
        'Settings',
      ]);
    });

    test('groups the destinations into four titled runs', () {
      final titles = NationalNavigation.sidebar.groups
          .map((group) => group.title)
          .toList();

      expect(titles, <String>['ANALYTICS', 'FEDERATION', 'REPORTS', 'SYSTEM']);
    });

    test('reuses National Overview from the shared central catalogue', () {
      final shared = NemrasNavigationCatalog.central.items.firstWhere(
        (item) => item.route == NemrasRouteNames.centralNationalOverview,
      );

      // Equality covers label, icon and route, so this fails if the local
      // sidebar ever starts redeclaring the destination instead of reusing it.
      expect(NationalNavigation.sidebar.items.first, shared);
    });

    test('every destination has a distinct route', () {
      final routes =
          NationalNavigation.sidebar.items.map((item) => item.route).toList();

      expect(routes.toSet().length, routes.length);
    });

    test('every route is a central route', () {
      for (final item in NationalNavigation.sidebar.items) {
        expect(item.route, startsWith('/central/'));
      }
    });

    test('no destination carries a hard-coded badge', () {
      for (final item in NationalNavigation.sidebar.items) {
        expect(item.badgeCount, isNull, reason: item.label);
      }
    });
  });

  group('named indices', () {
    test('match the position of their destination', () {
      final items = NationalNavigation.sidebar.items;

      expect(
        items[NationalNavigation.overviewIndex].label,
        'National Overview',
      );
      expect(
        items[NationalNavigation.emergencyTrendsIndex].label,
        'Emergency Trends',
      );
      expect(
        items[NationalNavigation.healthIndicatorsIndex].label,
        'Health Indicators',
      );
      expect(
        items[NationalNavigation.hospitalNetworkIndex].label,
        'Hospital Network',
      );
      expect(items[NationalNavigation.federationIndex].label, 'Federation');
      expect(items[NationalNavigation.reportsIndex].label, 'Reports');
      expect(
        items[NationalNavigation.governanceIndex].label,
        'Audit / Governance',
      );
      expect(items[NationalNavigation.settingsIndex].label, 'Settings');
    });
  });

  group('route resolution', () {
    test('routeFor round-trips through indexForRoute', () {
      for (var i = 0; i < NationalNavigation.sidebar.length; i++) {
        expect(
          NationalNavigation.indexForRoute(NationalNavigation.routeFor(i)),
          i,
        );
      }
    });

    test('an out-of-range index falls back to the national overview', () {
      expect(
        NationalNavigation.routeFor(-1),
        NemrasRouteNames.centralNationalOverview,
      );
      expect(
        NationalNavigation.routeFor(99),
        NemrasRouteNames.centralNationalOverview,
      );
    });

    test('an unknown route resolves to no index', () {
      expect(NationalNavigation.indexForRoute('/patient/home'), isNull);
      expect(NationalNavigation.indexForRoute(''), isNull);
    });

    test('routes this surface does not implement resolve to no index', () {
      // Regional Maps is in the shared central catalogue because the
      // reference sidebar draws it. This phase deliberately does not
      // implement it, so it must not resolve to a destination here.
      expect(
        NationalNavigation.indexForRoute(NemrasRouteNames.centralRegionalMaps),
        isNull,
      );
    });
  });

  group('federation attention badge', () {
    test('is applied to Federation only', () {
      final config = NationalNavigation.withNodeAttentionCount(3);
      final federation =
          config.items[NationalNavigation.federationIndex];

      expect(federation.badgeCount, 3);
      for (final item in config.items) {
        if (item.route == NemrasRouteNames.centralFederation) continue;
        expect(item.badgeCount, isNull, reason: item.label);
      }
    });

    test('is omitted at zero rather than drawing a 0', () {
      final config = NationalNavigation.withNodeAttentionCount(0);

      expect(
        config.items[NationalNavigation.federationIndex].badgeCount,
        isNull,
      );
    });

    test('preserves the group structure and ordering', () {
      final config = NationalNavigation.withNodeAttentionCount(2);

      expect(
        config.groups.map((group) => group.title).toList(),
        NationalNavigation.sidebar.groups
            .map((group) => group.title)
            .toList(),
      );
      expect(
        config.items.map((item) => item.route).toList(),
        NationalNavigation.sidebar.items.map((item) => item.route).toList(),
      );
    });
  });

  group('breadcrumbs', () {
    test('name the group the destination sits in', () {
      expect(
        NationalNavigation.breadcrumbFor(NationalNavigation.overviewIndex),
        'Analytics / National Overview',
      );
      expect(
        NationalNavigation.breadcrumbFor(NationalNavigation.federationIndex),
        'Federation / Node Status',
      );
      expect(
        NationalNavigation.breadcrumbFor(NationalNavigation.governanceIndex),
        'Reports / Audit and Governance',
      );
      expect(
        NationalNavigation.breadcrumbFor(NationalNavigation.settingsIndex),
        'System / Settings',
      );
    });

    test('every destination has a non-empty breadcrumb', () {
      for (var i = 0; i < NationalNavigation.sidebar.length; i++) {
        expect(NationalNavigation.breadcrumbFor(i), isNotEmpty);
      }
    });
  });
}
