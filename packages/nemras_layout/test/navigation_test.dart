import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  group('NemrasNavigationConfig', () {
    test('flattens groups in sidebar order', () {
      const config = NemrasNavigationCatalog.hospital;
      expect(
        config.items.map((i) => i.label).toList(),
        <String>[
          'Overview',
          'Bed Occupancy',
          'Emergency',
          'Patients',
          'Departments',
          'Compliance',
          'Audit Trail',
          'Settings',
        ],
      );
      expect(config.length, 8);
    });

    test('resolves a route to its flat index', () {
      const config = NemrasNavigationCatalog.hospital;
      expect(config.indexOfRoute(NemrasRouteNames.hospitalOverview), 0);
      expect(config.indexOfRoute(NemrasRouteNames.hospitalCompliance), 5);
      expect(config.indexOfRoute(NemrasRouteNames.hospitalSettings), 7);
    });

    test('returns null for a route that is not a destination', () {
      expect(
        NemrasNavigationCatalog.hospital.indexOfRoute('/not/a/destination'),
        isNull,
      );
    });

    test('flat configurations have a single untitled group', () {
      final patient = NemrasNavigationCatalog.patient;
      expect(patient.groups, hasLength(1));
      expect(patient.groups.single.title, isNull);
    });

    test('value equality', () {
      const a = NemrasNavigationItem(
        label: 'Home',
        icon: Icons.home,
        route: '/patient/home',
      );
      const b = NemrasNavigationItem(
        label: 'Home',
        icon: Icons.home,
        route: '/patient/home',
      );
      expect(a, b);
      expect(a.copyWith(badgeCount: 3), isNot(b));
    });
  });

  group('navigation catalogue is transcribed, not invented', () {
    test('patient navigation matches the live patient shell', () {
      expect(
        NemrasNavigationCatalog.patient.items.map((i) => i.label).toList(),
        <String>['Home', 'Record', 'Chat', 'Profile'],
      );
    });

    test('paramedic navigation matches the reference field tabs', () {
      expect(
        NemrasNavigationCatalog.paramedic.items.map((i) => i.label).toList(),
        <String>['Scan', 'Voice', 'Drugs', 'Route'],
      );
    });

    test('central navigation matches the reference ministry sidebar', () {
      expect(
        NemrasNavigationCatalog.central.groups.map((g) => g.title).toList(),
        <String>['ANALYTICS', 'FEDERATION', 'REPORTS'],
      );
      expect(NemrasNavigationCatalog.central.length, 7);
    });

    test('no shipped destination carries a fabricated badge count; the '
        "reference's Emergency 7 is mock content", () {
      final all = <NemrasNavigationItem>[
        ...NemrasNavigationCatalog.patient.items,
        ...NemrasNavigationCatalog.paramedic.items,
        ...NemrasNavigationCatalog.hospital.items,
        ...NemrasNavigationCatalog.central.items,
      ];
      expect(all.every((i) => i.badgeCount == null), isTrue);
    });

    test('every destination has a unique route', () {
      for (final config in <NemrasNavigationConfig>[
        NemrasNavigationCatalog.patient,
        NemrasNavigationCatalog.paramedic,
        NemrasNavigationCatalog.hospital,
        NemrasNavigationCatalog.central,
      ]) {
        final routes = config.items.map((i) => i.route).toList();
        expect(routes.toSet().length, routes.length);
      }
    });
  });

  group('NemrasRoleConfig', () {
    test('patient lands in the light patient shell', () {
      final config = NemrasRoleConfig.of(NemrasRole.patient);
      expect(config.shell, NemrasShellKind.patientMobile);
      expect(config.surfaceTheme, NemrasSurfaceTheme.clinicalLight);
      expect(config.usesFieldTheme, isFalse);
      expect(config.isMobileShell, isTrue);
      expect(config.landingRoute, NemrasRouteNames.patientHome);
      expect(config.navigation, NemrasNavigationCatalog.patient);
    });

    test('paramedic lands in the dark field shell', () {
      final config = NemrasRoleConfig.of(NemrasRole.paramedic);
      expect(config.shell, NemrasShellKind.paramedicField);
      expect(config.surfaceTheme, NemrasSurfaceTheme.fieldDark);
      expect(config.usesFieldTheme, isTrue);
      expect(config.isMobileShell, isTrue);
      expect(config.navigation, NemrasNavigationCatalog.paramedic);
    });

    test('physician and administrator share the reference hospital sidebar '
        'but use different shells', () {
      final physician = NemrasRoleConfig.of(NemrasRole.emergencyPhysician);
      final admin = NemrasRoleConfig.of(NemrasRole.hospitalAdministrator);

      expect(physician.shell, NemrasShellKind.desktopClinical);
      expect(admin.shell, NemrasShellKind.desktopOperational);
      expect(physician.navigation, NemrasNavigationCatalog.hospital);
      expect(admin.navigation, NemrasNavigationCatalog.hospital);
      expect(physician.isDesktopShell, isTrue);
      expect(admin.isDesktopShell, isTrue);
    });

    test('both ministry roles land in the central shell', () {
      for (final role in <NemrasRole>[
        NemrasRole.ministryAnalyst,
        NemrasRole.systemAdministrator,
      ]) {
        final config = NemrasRoleConfig.of(role);
        expect(config.shell, NemrasShellKind.desktopCentral);
        expect(config.navigation, NemrasNavigationCatalog.central);
        expect(config.isDesktopShell, isTrue);
      }
    });

    test('every role resolves to a configuration', () {
      for (final role in NemrasRole.values) {
        final config = NemrasRoleConfig.of(role);
        expect(config.role, role);
        expect(config.navigation.length, greaterThan(0));
        expect(
          config.navigation.indexOfRoute(config.landingRoute),
          isNotNull,
          reason: 'landing route must be one of the role\'s destinations',
        );
      }
    });
  });
}
