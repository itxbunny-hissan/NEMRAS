import 'package:flutter/material.dart';

import 'adaptive_scaffold.dart';
import 'navigation_models.dart';
import 'route_names.dart';

/// The NEMRAS user roles.
///
/// This is navigation architecture only. It carries no authorisation meaning:
/// the backend remains the security boundary, and nothing here grants access to
/// patient data.
enum NemrasRole {
  patient,
  paramedic,
  emergencyPhysician,
  hospitalAdministrator,
  ministryAnalyst,
  systemAdministrator,
}

/// Which shell a role lands in after authentication.
enum NemrasShellKind {
  patientMobile,
  paramedicField,
  desktopClinical,
  desktopOperational,
  desktopCentral,
}

/// Which Phase 1A theme a shell is built with.
enum NemrasSurfaceTheme { clinicalLight, fieldDark }

/// Navigation catalogues transcribed from `NEMRAS_UI_Design.html`.
///
/// Icons are Material equivalents of the reference's inline SVGs; NEMRAS adds
/// no vector-asset dependency. No destination here is invented - each one
/// appears in the reference.
abstract final class NemrasNavigationCatalog {
  /// Patient bottom navigation. Mirrors the live patient shell exactly.
  static final NemrasNavigationConfig patient = NemrasNavigationConfig.flat(
    const <NemrasNavigationItem>[
      NemrasNavigationItem(
        label: 'Home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        route: NemrasRouteNames.patientHome,
      ),
      NemrasNavigationItem(
        label: 'Record',
        icon: Icons.article_outlined,
        selectedIcon: Icons.article,
        route: NemrasRouteNames.patientRecord,
      ),
      NemrasNavigationItem(
        label: 'Chat',
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        route: NemrasRouteNames.patientChat,
      ),
      NemrasNavigationItem(
        label: 'Profile',
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        route: NemrasRouteNames.patientProfile,
      ),
    ],
  );

  /// Paramedic bottom navigation. Phase 2A implements these as field-mode
  /// destinations; Drugs is a record-only medication safety view and does not
  /// invent a prescribing or interaction database.
  static final NemrasNavigationConfig paramedic = NemrasNavigationConfig.flat(
    const <NemrasNavigationItem>[
      NemrasNavigationItem(
        label: 'Scan',
        icon: Icons.qr_code_scanner_outlined,
        selectedIcon: Icons.qr_code_scanner,
        route: NemrasRouteNames.paramedicScan,
      ),
      NemrasNavigationItem(
        label: 'Voice',
        icon: Icons.mic_none_outlined,
        selectedIcon: Icons.mic,
        route: NemrasRouteNames.paramedicVoice,
      ),
      NemrasNavigationItem(
        label: 'Drugs',
        icon: Icons.medication_outlined,
        selectedIcon: Icons.medication,
        route: NemrasRouteNames.paramedicDrugs,
      ),
      NemrasNavigationItem(
        label: 'Route',
        icon: Icons.alt_route_outlined,
        selectedIcon: Icons.alt_route,
        route: NemrasRouteNames.paramedicRoute,
      ),
    ],
  );

  /// Hospital sidebar. The reference draws one hospital sidebar and reuses it
  /// across the administrator and physician screens, so both roles share it.
  static const NemrasNavigationConfig hospital = NemrasNavigationConfig(
    <NemrasNavigationGroup>[
      NemrasNavigationGroup(
        title: 'OPERATIONS',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Overview',
            icon: Icons.dashboard_outlined,
            route: NemrasRouteNames.hospitalOverview,
          ),
          NemrasNavigationItem(
            label: 'Bed Occupancy',
            icon: Icons.bed_outlined,
            route: NemrasRouteNames.hospitalBedOccupancy,
          ),
          NemrasNavigationItem(
            label: 'Emergency',
            icon: Icons.emergency_outlined,
            route: NemrasRouteNames.hospitalEmergency,
          ),
          NemrasNavigationItem(
            label: 'Patients',
            icon: Icons.people_outline,
            route: NemrasRouteNames.hospitalPatients,
          ),
          NemrasNavigationItem(
            label: 'Departments',
            icon: Icons.meeting_room_outlined,
            route: NemrasRouteNames.hospitalDepartments,
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'REPORTS',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Compliance',
            icon: Icons.description_outlined,
            route: NemrasRouteNames.hospitalCompliance,
          ),
          NemrasNavigationItem(
            label: 'Audit Trail',
            icon: Icons.history_outlined,
            route: NemrasRouteNames.hospitalAuditTrail,
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'SYSTEM',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Settings',
            icon: Icons.settings_outlined,
            route: NemrasRouteNames.hospitalSettings,
          ),
        ],
      ),
    ],
  );

  /// Central/ministry sidebar.
  static const NemrasNavigationConfig central = NemrasNavigationConfig(
    <NemrasNavigationGroup>[
      NemrasNavigationGroup(
        title: 'ANALYTICS',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'National Overview',
            icon: Icons.dashboard_outlined,
            route: NemrasRouteNames.centralNationalOverview,
          ),
          NemrasNavigationItem(
            label: 'Regional Maps',
            icon: Icons.place_outlined,
            route: NemrasRouteNames.centralRegionalMaps,
          ),
          NemrasNavigationItem(
            label: 'Disease Trends',
            icon: Icons.show_chart_outlined,
            route: NemrasRouteNames.centralDiseaseTrends,
          ),
          NemrasNavigationItem(
            label: 'Demographics',
            icon: Icons.people_outline,
            route: NemrasRouteNames.centralDemographics,
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'FEDERATION',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Hospital Nodes',
            icon: Icons.hub_outlined,
            route: NemrasRouteNames.centralHospitalNodes,
          ),
          NemrasNavigationItem(
            label: 'System Health',
            icon: Icons.monitor_heart_outlined,
            route: NemrasRouteNames.centralSystemHealth,
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'REPORTS',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Policy Reports',
            icon: Icons.description_outlined,
            route: NemrasRouteNames.centralPolicyReports,
          ),
        ],
      ),
    ],
  );
}

/// Maps a role to the shell, theme, navigation and landing route it uses.
@immutable
class NemrasRoleConfig {
  const NemrasRoleConfig({
    required this.role,
    required this.shell,
    required this.surfaceTheme,
    required this.navigation,
    required this.landingRoute,
  });

  final NemrasRole role;
  final NemrasShellKind shell;
  final NemrasSurfaceTheme surfaceTheme;
  final NemrasNavigationConfig navigation;
  final String landingRoute;

  bool get usesFieldTheme => surfaceTheme == NemrasSurfaceTheme.fieldDark;

  /// True for the two mobile surfaces, which navigate with a bottom bar.
  bool get isMobileShell =>
      shell == NemrasShellKind.patientMobile ||
      shell == NemrasShellKind.paramedicField;

  /// True for the three desktop surfaces, which navigate with a sidebar.
  bool get isDesktopShell => !isMobileShell;

  /// The navigation chrome this role's shell should use.
  AdaptiveNavigationPattern get navigationPattern => isMobileShell
      ? AdaptiveNavigationPattern.bottomBar
      : AdaptiveNavigationPattern.sidebar;

  static NemrasRoleConfig of(NemrasRole role) {
    switch (role) {
      case NemrasRole.patient:
        return NemrasRoleConfig(
          role: role,
          shell: NemrasShellKind.patientMobile,
          surfaceTheme: NemrasSurfaceTheme.clinicalLight,
          navigation: NemrasNavigationCatalog.patient,
          landingRoute: NemrasRouteNames.patientHome,
        );
      case NemrasRole.paramedic:
        return NemrasRoleConfig(
          role: role,
          shell: NemrasShellKind.paramedicField,
          surfaceTheme: NemrasSurfaceTheme.fieldDark,
          navigation: NemrasNavigationCatalog.paramedic,
          landingRoute: NemrasRouteNames.paramedicScan,
        );
      case NemrasRole.emergencyPhysician:
        return NemrasRoleConfig(
          role: role,
          shell: NemrasShellKind.desktopClinical,
          surfaceTheme: NemrasSurfaceTheme.clinicalLight,
          navigation: NemrasNavigationCatalog.hospital,
          landingRoute: NemrasRouteNames.hospitalPatients,
        );
      case NemrasRole.hospitalAdministrator:
        return NemrasRoleConfig(
          role: role,
          shell: NemrasShellKind.desktopOperational,
          surfaceTheme: NemrasSurfaceTheme.clinicalLight,
          navigation: NemrasNavigationCatalog.hospital,
          landingRoute: NemrasRouteNames.hospitalOverview,
        );
      case NemrasRole.ministryAnalyst:
      case NemrasRole.systemAdministrator:
        return NemrasRoleConfig(
          role: role,
          shell: NemrasShellKind.desktopCentral,
          surfaceTheme: NemrasSurfaceTheme.clinicalLight,
          navigation: NemrasNavigationCatalog.central,
          landingRoute: NemrasRouteNames.centralNationalOverview,
        );
    }
  }
}
