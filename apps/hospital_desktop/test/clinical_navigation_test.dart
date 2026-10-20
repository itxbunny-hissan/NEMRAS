import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_desktop/src/app.dart';
import 'package:hospital_desktop/src/navigation/clinical_navigation.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  group('clinical sidebar', () {
    test('exposes the nine clinical destinations in order', () {
      expect(
        HospitalClinicalNavigation.clinicalSidebar.items
            .map((i) => i.label)
            .toList(),
        <String>[
          'Overview',
          'Emergency Queue',
          'Patients',
          'Clinical Records',
          'AI Assistant',
          'Medications',
          'Handover',
          'Audit',
          'Settings',
        ],
      );
      expect(HospitalClinicalNavigation.clinicalSidebar.length, 9);
    });

    test('named indices match the flat order', () {
      final config = HospitalClinicalNavigation.clinicalSidebar;
      expect(
        config.indexOfRoute(NemrasRouteNames.hospitalOverview),
        HospitalClinicalNavigation.overviewIndex,
      );
      expect(
        config.indexOfRoute(NemrasRouteNames.hospitalEmergency),
        HospitalClinicalNavigation.emergencyQueueIndex,
      );
      expect(
        config.indexOfRoute(NemrasRouteNames.hospitalClinicalRecords),
        HospitalClinicalNavigation.clinicalRecordsIndex,
      );
      expect(
        config.indexOfRoute(NemrasRouteNames.hospitalSettings),
        HospitalClinicalNavigation.settingsIndex,
      );
    });

    test('every destination has a unique route', () {
      final routes = HospitalClinicalNavigation.clinicalSidebar.items
          .map((i) => i.route)
          .toList();
      expect(routes.toSet().length, routes.length);
    });

    test('ships no fabricated badge count', () {
      expect(
        HospitalClinicalNavigation.clinicalSidebar.items
            .every((i) => i.badgeCount == null),
        isTrue,
      );
    });

    test('a pending count badges only the emergency destination', () {
      final config = HospitalClinicalNavigation.withPendingCount(3);
      final badged =
          config.items.where((i) => i.badgeCount != null).toList();
      expect(badged, hasLength(1));
      expect(badged.single.route, NemrasRouteNames.hospitalEmergency);
      expect(badged.single.badgeCount, 3);
    });

    test('a zero pending count adds no badge', () {
      expect(
        HospitalClinicalNavigation.withPendingCount(0),
        HospitalClinicalNavigation.clinicalSidebar,
      );
    });

    test('leaves the shared reference hospital catalogue untouched', () {
      // `NemrasNavigationCatalog.hospital` is transcribed from the reference
      // operations sidebar and is pinned by the layout package's own tests.
      // The clinical surface composes its own navigation instead.
      expect(NemrasNavigationCatalog.hospital.length, 8);
      expect(
        NemrasNavigationCatalog.hospital,
        isNot(HospitalClinicalNavigation.clinicalSidebar),
      );
    });
  });

  group('HospitalRouter', () {
    test('resolves every clinical destination to a sidebar index', () {
      for (final item in HospitalClinicalNavigation.clinicalSidebar.items) {
        expect(
          HospitalRouter.indexForRoute(item.route),
          isNotNull,
          reason: '${item.route} must open the shell on a destination',
        );
      }
    });

    test('returns null for a route that is not a destination', () {
      expect(HospitalRouter.indexForRoute('/not/a/destination'), isNull);
    });

    test('builds a route for login and for every clinical destination', () {
      final names = <String>[
        NemrasRouteNames.hospitalLogin,
        for (final item in HospitalClinicalNavigation.clinicalSidebar.items)
          item.route,
      ];
      for (final name in names) {
        expect(
          HospitalRouter.onGenerateRoute(RouteSettings(name: name)),
          isNotNull,
          reason: '$name must be routable',
        );
      }
    });

    test('refuses an unknown route so it cannot silently open the shell', () {
      expect(
        HospitalRouter.onGenerateRoute(
          const RouteSettings(name: '/hospital/not-a-screen'),
        ),
        isNull,
      );
    });

    test('patient and paramedic routes are not served by this app', () {
      for (final route in <String>[
        NemrasRouteNames.patientHome,
        NemrasRouteNames.paramedicScan,
      ]) {
        expect(HospitalRouter.onGenerateRoute(RouteSettings(name: route)),
            isNull);
      }
    });
  });
}
