import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_layout/nemras_layout.dart';
import 'package:ops_dashboard/src/navigation/ops_navigation.dart';

void main() {
  group('operational sidebar', () {
    test('exposes exactly the nine briefed destinations in order', () {
      expect(
        OpsNavigation.sidebar.items.map((item) => item.label).toList(),
        <String>[
          'Overview',
          'Emergency',
          'Bed Occupancy',
          'Patients',
          'Departments',
          'Reports',
          'Compliance',
          'Audit Trail',
          'Settings',
        ],
      );
    });

    test('groups destinations as operations, reports and system', () {
      expect(
        OpsNavigation.sidebar.groups.map((group) => group.title).toList(),
        <String>['OPERATIONS', 'REPORTS', 'SYSTEM'],
      );
    });

    test('named indices match the flat sidebar order', () {
      final items = OpsNavigation.sidebar.items;
      expect(items[OpsNavigation.overviewIndex].label, 'Overview');
      expect(items[OpsNavigation.emergencyIndex].label, 'Emergency');
      expect(items[OpsNavigation.bedOccupancyIndex].label, 'Bed Occupancy');
      expect(items[OpsNavigation.patientsIndex].label, 'Patients');
      expect(items[OpsNavigation.departmentsIndex].label, 'Departments');
      expect(items[OpsNavigation.reportsIndex].label, 'Reports');
      expect(items[OpsNavigation.complianceIndex].label, 'Compliance');
      expect(items[OpsNavigation.auditTrailIndex].label, 'Audit Trail');
      expect(items[OpsNavigation.settingsIndex].label, 'Settings');
    });

    test('every route resolves back to its own index', () {
      final items = OpsNavigation.sidebar.items;
      for (var i = 0; i < items.length; i++) {
        expect(OpsNavigation.indexForRoute(items[i].route), i);
        expect(OpsNavigation.routeFor(i), items[i].route);
      }
    });

    test('routes are unique, so no two destinations collide', () {
      final routes =
          OpsNavigation.sidebar.items.map((item) => item.route).toList();
      expect(routes.toSet().length, routes.length);
    });

    test('an unknown route resolves to no index', () {
      expect(OpsNavigation.indexForRoute('/not-a-destination'), isNull);
    });

    test('an out-of-range index falls back to overview', () {
      expect(
        OpsNavigation.routeFor(-1),
        NemrasRouteNames.hospitalOverview,
      );
      expect(
        OpsNavigation.routeFor(99),
        NemrasRouteNames.hospitalOverview,
      );
    });
  });

  group('reuse of the shared catalogue', () {
    test('Reports is the only destination not in the shared catalogue', () {
      final sharedRoutes = NemrasNavigationCatalog.hospital.items
          .map((item) => item.route)
          .toSet();
      final novel = OpsNavigation.sidebar.items
          .where((item) => !sharedRoutes.contains(item.route))
          .map((item) => item.label)
          .toList();
      expect(novel, <String>['Reports']);
    });

    test('shared destinations keep the catalogue label and icon', () {
      for (final shared in NemrasNavigationCatalog.hospital.items) {
        final local = OpsNavigation.sidebar.items
            .where((item) => item.route == shared.route)
            .single;
        expect(local.label, shared.label);
        expect(local.icon, shared.icon);
      }
    });

    test('the shared catalogue is left at its transcribed eight items', () {
      // Pinned by nemras_layout's own tests too. Asserted here so a change to
      // the ops sidebar can never be made by editing the reference instead.
      expect(NemrasNavigationCatalog.hospital.length, 8);
    });
  });

  group('pending-handover badge', () {
    test('attaches the count to Emergency only', () {
      final config = OpsNavigation.withPendingCount(3);
      for (final item in config.items) {
        if (item.route == NemrasRouteNames.hospitalEmergency) {
          expect(item.badgeCount, 3);
        } else {
          expect(item.badgeCount, isNull);
        }
      }
    });

    test('hides the badge at zero rather than drawing a 0', () {
      final config = OpsNavigation.withPendingCount(0);
      expect(
        config.items.every((item) => item.badgeCount == null),
        isTrue,
      );
    });

    test('preserves the nine destinations and their order', () {
      final config = OpsNavigation.withPendingCount(7);
      expect(config.length, 9);
      expect(
        config.items.map((item) => item.route).toList(),
        OpsNavigation.sidebar.items.map((item) => item.route).toList(),
      );
    });
  });

  group('breadcrumbs', () {
    test('every destination has a two-level breadcrumb', () {
      for (var i = 0; i < OpsNavigation.sidebar.length; i++) {
        expect(OpsNavigation.breadcrumbFor(i), contains(' / '));
      }
    });

    test('breadcrumbs are distinct per destination', () {
      final crumbs = <String>[
        for (var i = 0; i < OpsNavigation.sidebar.length; i++)
          OpsNavigation.breadcrumbFor(i),
      ];
      expect(crumbs.toSet().length, crumbs.length);
    });
  });
}
