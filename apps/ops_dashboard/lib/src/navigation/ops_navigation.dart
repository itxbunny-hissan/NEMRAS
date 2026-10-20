import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// The operational dashboard's sidebar.
///
/// Eight of the nine destinations are taken from
/// [NemrasNavigationCatalog.hospital] by route rather than redeclared, so the
/// shared catalogue stays the single source of each destination's label and
/// icon. Only Reports is new: the shared catalogue is transcribed from
/// `NEMRAS_UI_Design.html`, which draws eight hospital rows, and it is pinned
/// by `nemras_layout` tests, so this phase composes its ninth destination
/// locally instead of editing a reference transcription.
abstract final class OpsNavigation {
  // Flat sidebar indices. Named so routing and tests never carry a bare int.
  static const int overviewIndex = 0;
  static const int emergencyIndex = 1;
  static const int bedOccupancyIndex = 2;
  static const int patientsIndex = 3;
  static const int departmentsIndex = 4;
  static const int reportsIndex = 5;
  static const int complianceIndex = 6;
  static const int auditTrailIndex = 7;
  static const int settingsIndex = 8;

  /// Reports. The one destination not present in the shared catalogue.
  static const NemrasNavigationItem reportsItem = NemrasNavigationItem(
    label: 'Reports',
    icon: Icons.insert_chart_outlined,
    route: NemrasRouteNames.hospitalReports,
  );

  /// Looks a destination up in the shared hospital catalogue.
  static NemrasNavigationItem _shared(String route) {
    final item = NemrasNavigationCatalog.hospital.items
        .where((candidate) => candidate.route == route)
        .firstOrNull;
    assert(
      item != null,
      'Route $route is not in NemrasNavigationCatalog.hospital.',
    );
    return item ?? reportsItem;
  }

  /// The nine operational destinations, grouped as the reference sidebar is.
  static NemrasNavigationConfig get sidebar => NemrasNavigationConfig(
        <NemrasNavigationGroup>[
          NemrasNavigationGroup(
            title: 'OPERATIONS',
            items: <NemrasNavigationItem>[
              _shared(NemrasRouteNames.hospitalOverview),
              _shared(NemrasRouteNames.hospitalEmergency),
              _shared(NemrasRouteNames.hospitalBedOccupancy),
              _shared(NemrasRouteNames.hospitalPatients),
              _shared(NemrasRouteNames.hospitalDepartments),
            ],
          ),
          NemrasNavigationGroup(
            title: 'REPORTS',
            items: <NemrasNavigationItem>[
              reportsItem,
              _shared(NemrasRouteNames.hospitalCompliance),
              _shared(NemrasRouteNames.hospitalAuditTrail),
            ],
          ),
          NemrasNavigationGroup(
            title: 'SYSTEM',
            items: <NemrasNavigationItem>[
              _shared(NemrasRouteNames.hospitalSettings),
            ],
          ),
        ],
      );

  /// The sidebar with a live pending-handover count on Emergency.
  ///
  /// The reference draws a hard-coded badge there. This supplies a real count
  /// from the demo handover provider instead, and hides the badge at zero so
  /// an empty queue does not read as a pending item.
  static NemrasNavigationConfig withPendingCount(int pending) {
    final base = sidebar;
    return NemrasNavigationConfig(
      <NemrasNavigationGroup>[
        for (final group in base.groups)
          NemrasNavigationGroup(
            title: group.title,
            items: <NemrasNavigationItem>[
              for (final item in group.items)
                if (item.route == NemrasRouteNames.hospitalEmergency &&
                    pending > 0)
                  item.copyWith(badgeCount: pending)
                else
                  item,
            ],
          ),
      ],
    );
  }

  /// The breadcrumb shown above the screen title.
  static String breadcrumbFor(int index) {
    switch (index) {
      case overviewIndex:
        return 'Operations / Overview';
      case emergencyIndex:
        return 'Operations / Emergency';
      case bedOccupancyIndex:
        return 'Operations / Bed Occupancy';
      case patientsIndex:
        return 'Operations / Patient Flow';
      case departmentsIndex:
        return 'Operations / Departments';
      case reportsIndex:
        return 'Reports / Operational Reports';
      case complianceIndex:
        return 'Reports / Compliance';
      case auditTrailIndex:
        return 'Reports / Audit Trail';
      case settingsIndex:
        return 'System / Settings';
      default:
        return 'Operations';
    }
  }

  /// The route for a flat sidebar index.
  static String routeFor(int index) {
    final items = sidebar.items;
    if (index < 0 || index >= items.length) {
      return NemrasRouteNames.hospitalOverview;
    }
    return items[index].route;
  }

  /// The flat index for a route, or null when the route is not a destination.
  static int? indexForRoute(String route) => sidebar.indexOfRoute(route);
}
