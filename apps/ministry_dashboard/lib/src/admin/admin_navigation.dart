import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// The administration console's sidebar.
///
/// Kept separate from [NationalNavigation]. The national analytics sidebar is
/// pinned at eight destinations, and this console is a different workflow.
abstract final class AdminNavigation {
  static const int overviewIndex = 0;
  static const int verificationIndex = 1;
  static const int rolesIndex = 2;
  static const int hospitalsIndex = 3;
  static const int fleetIndex = 4;
  static const int auditIndex = 5;

  static const NemrasNavigationConfig sidebar = NemrasNavigationConfig(
    <NemrasNavigationGroup>[
      NemrasNavigationGroup(
        title: 'ADMINISTRATION',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Admin Overview',
            icon: Icons.dashboard_outlined,
            route: '/central/admin/overview',
          ),
          NemrasNavigationItem(
            label: 'User Verification',
            icon: Icons.verified_user_outlined,
            route: '/central/admin/verification',
          ),
          NemrasNavigationItem(
            label: 'Roles & Permissions',
            icon: Icons.admin_panel_settings_outlined,
            route: '/central/admin/roles',
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'REGISTRY',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Hospital Network',
            icon: Icons.local_hospital_outlined,
            route: '/central/admin/hospitals',
          ),
          NemrasNavigationItem(
            label: 'Responders & Fleet',
            icon: Icons.emergency_outlined,
            route: '/central/admin/fleet',
          ),
        ],
      ),
      NemrasNavigationGroup(
        title: 'GOVERNANCE',
        items: <NemrasNavigationItem>[
          NemrasNavigationItem(
            label: 'Audit Logs & Settings',
            icon: Icons.gavel_outlined,
            route: '/central/admin/audit',
          ),
        ],
      ),
    ],
  );

  static String titleFor(int index) {
    final items = sidebar.items;
    if (index < 0 || index >= items.length) return 'Administration';
    return items[index].label;
  }
}
