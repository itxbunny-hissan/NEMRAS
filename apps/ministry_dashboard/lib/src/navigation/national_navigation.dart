import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// The national dashboard's sidebar.
///
/// National Overview is taken from [NemrasNavigationCatalog.central] by route
/// rather than redeclared, so the shared catalogue stays the source of that
/// destination's label and icon. The other eight destinations are new: the
/// reference sidebar draws Regional Maps, Disease Trends and Demographics,
/// and this phase deliberately does not implement a Regional Maps screen,
/// because a national map on this dataset could only be fabricated. The
/// shared catalogue is a transcription of the reference and is pinned by
/// `nemras_layout` tests, so it is left exactly as it is.
abstract final class NationalNavigation {
  // Flat sidebar indices. Named so routing and tests never carry a bare int.
  static const int overviewIndex = 0;
  static const int emergencyTrendsIndex = 1;
  static const int healthIndicatorsIndex = 2;
  static const int hospitalNetworkIndex = 3;
  static const int federationIndex = 4;
  static const int reportsIndex = 5;
  static const int governanceIndex = 6;
  static const int settingsIndex = 7;

  static const NemrasNavigationItem emergencyTrendsItem =
      NemrasNavigationItem(
    label: 'Emergency Trends',
    icon: Icons.emergency_outlined,
    route: NemrasRouteNames.centralEmergencyTrends,
  );

  static const NemrasNavigationItem healthIndicatorsItem =
      NemrasNavigationItem(
    label: 'Health Indicators',
    icon: Icons.monitor_heart_outlined,
    route: NemrasRouteNames.centralHealthIndicators,
  );

  static const NemrasNavigationItem hospitalNetworkItem =
      NemrasNavigationItem(
    label: 'Hospital Network',
    icon: Icons.local_hospital_outlined,
    route: NemrasRouteNames.centralHospitalNetwork,
  );

  static const NemrasNavigationItem federationItem = NemrasNavigationItem(
    label: 'Federation',
    icon: Icons.hub_outlined,
    route: NemrasRouteNames.centralFederation,
  );

  static const NemrasNavigationItem reportsItem = NemrasNavigationItem(
    label: 'Reports',
    icon: Icons.insert_chart_outlined,
    route: NemrasRouteNames.centralReports,
  );

  static const NemrasNavigationItem governanceItem = NemrasNavigationItem(
    label: 'Audit / Governance',
    icon: Icons.gavel_outlined,
    route: NemrasRouteNames.centralGovernance,
  );

  static const NemrasNavigationItem settingsItem = NemrasNavigationItem(
    label: 'Settings',
    icon: Icons.settings_outlined,
    route: NemrasRouteNames.centralSettings,
  );

  /// Looks a destination up in the shared central catalogue.
  static NemrasNavigationItem _shared(String route) {
    final item = NemrasNavigationCatalog.central.items
        .where((candidate) => candidate.route == route)
        .firstOrNull;
    assert(
      item != null,
      'Route $route is not in NemrasNavigationCatalog.central.',
    );
    return item ?? reportsItem;
  }

  /// The eight national destinations, grouped as the reference sidebar is.
  static NemrasNavigationConfig get sidebar => NemrasNavigationConfig(
        <NemrasNavigationGroup>[
          NemrasNavigationGroup(
            title: 'ANALYTICS',
            items: <NemrasNavigationItem>[
              _shared(NemrasRouteNames.centralNationalOverview),
              emergencyTrendsItem,
              healthIndicatorsItem,
            ],
          ),
          const NemrasNavigationGroup(
            title: 'FEDERATION',
            items: <NemrasNavigationItem>[
              hospitalNetworkItem,
              federationItem,
            ],
          ),
          const NemrasNavigationGroup(
            title: 'REPORTS',
            items: <NemrasNavigationItem>[reportsItem, governanceItem],
          ),
          const NemrasNavigationGroup(
            title: 'SYSTEM',
            items: <NemrasNavigationItem>[settingsItem],
          ),
        ],
      );

  /// The sidebar with a count of simulated nodes needing attention.
  ///
  /// The badge is hidden at zero rather than drawing a 0, so a healthy demo
  /// federation does not read as a pending item.
  static NemrasNavigationConfig withNodeAttentionCount(int count) {
    final base = sidebar;
    return NemrasNavigationConfig(
      <NemrasNavigationGroup>[
        for (final group in base.groups)
          NemrasNavigationGroup(
            title: group.title,
            items: <NemrasNavigationItem>[
              for (final item in group.items)
                if (item.route == NemrasRouteNames.centralFederation &&
                    count > 0)
                  item.copyWith(badgeCount: count)
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
        return 'Analytics / National Overview';
      case emergencyTrendsIndex:
        return 'Analytics / Emergency Trends';
      case healthIndicatorsIndex:
        return 'Analytics / Health Indicators';
      case hospitalNetworkIndex:
        return 'Federation / Hospital Network';
      case federationIndex:
        return 'Federation / Node Status';
      case reportsIndex:
        return 'Reports / National Reports';
      case governanceIndex:
        return 'Reports / Audit and Governance';
      case settingsIndex:
        return 'System / Settings';
      default:
        return 'Analytics';
    }
  }

  /// The route for a flat sidebar index.
  static String routeFor(int index) {
    final items = sidebar.items;
    if (index < 0 || index >= items.length) {
      return NemrasRouteNames.centralNationalOverview;
    }
    return items[index].route;
  }

  /// The flat index for a route, or null when the route is not a destination.
  static int? indexForRoute(String route) => sidebar.indexOfRoute(route);
}
