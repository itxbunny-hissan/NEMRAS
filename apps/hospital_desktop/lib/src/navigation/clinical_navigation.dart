import 'package:flutter/material.dart';
import 'package:nemras_layout/nemras_layout.dart';

/// The clinical desktop's own sidebar.
///
/// `NemrasNavigationCatalog.hospital` is transcribed from the reference
/// hospital *operations* sidebar and is pinned by the layout package's tests,
/// so it is deliberately left untouched. This configuration is the clinical
/// set of destinations and lives with the surface that owns it, which is the
/// same pattern the patient shell already uses for its non-reference rows.
///
/// Selection indices address [clinicalSidebar.items] in the order below.
abstract final class HospitalClinicalNavigation {
  static const int overviewIndex = 0;
  static const int emergencyQueueIndex = 1;
  static const int patientsIndex = 2;
  static const int clinicalRecordsIndex = 3;
  static const int assistantIndex = 4;
  static const int medicationsIndex = 5;
  static const int handoverIndex = 6;
  static const int auditIndex = 7;
  static const int settingsIndex = 8;

  static const NemrasNavigationConfig clinicalSidebar =
      NemrasNavigationConfig(<NemrasNavigationGroup>[
    NemrasNavigationGroup(
      title: 'CLINICAL',
      items: <NemrasNavigationItem>[
        NemrasNavigationItem(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
          route: NemrasRouteNames.hospitalOverview,
        ),
        NemrasNavigationItem(
          label: 'Emergency Queue',
          icon: Icons.emergency_outlined,
          selectedIcon: Icons.emergency,
          route: NemrasRouteNames.hospitalEmergency,
        ),
        NemrasNavigationItem(
          label: 'Patients',
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
          route: NemrasRouteNames.hospitalPatients,
        ),
        NemrasNavigationItem(
          label: 'Clinical Records',
          icon: Icons.folder_shared_outlined,
          selectedIcon: Icons.folder_shared,
          route: NemrasRouteNames.hospitalClinicalRecords,
        ),
      ],
    ),
    NemrasNavigationGroup(
      title: 'DECISION SUPPORT',
      items: <NemrasNavigationItem>[
        NemrasNavigationItem(
          label: 'AI Assistant',
          icon: Icons.forum_outlined,
          selectedIcon: Icons.forum,
          route: NemrasRouteNames.hospitalAiAssistant,
        ),
        NemrasNavigationItem(
          label: 'Medications',
          icon: Icons.medication_outlined,
          selectedIcon: Icons.medication,
          route: NemrasRouteNames.hospitalMedications,
        ),
      ],
    ),
    NemrasNavigationGroup(
      title: 'CONTINUITY',
      items: <NemrasNavigationItem>[
        NemrasNavigationItem(
          label: 'Handover',
          icon: Icons.assignment_turned_in_outlined,
          selectedIcon: Icons.assignment_turned_in,
          route: NemrasRouteNames.hospitalHandover,
        ),
        NemrasNavigationItem(
          label: 'Audit',
          icon: Icons.history_outlined,
          selectedIcon: Icons.history,
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
          selectedIcon: Icons.settings,
          route: NemrasRouteNames.hospitalSettings,
        ),
      ],
    ),
  ]);

  /// The sidebar with a live pending-case count on Emergency Queue.
  ///
  /// The count comes from the demo queue, never from a hard-coded literal; the
  /// reference's static `7` badge is mock content and is not reproduced.
  static NemrasNavigationConfig withPendingCount(int pendingCount) {
    if (pendingCount <= 0) return clinicalSidebar;
    return NemrasNavigationConfig(<NemrasNavigationGroup>[
      for (final group in clinicalSidebar.groups)
        NemrasNavigationGroup(
          title: group.title,
          items: <NemrasNavigationItem>[
            for (final item in group.items)
              if (item.route == NemrasRouteNames.hospitalEmergency)
                item.copyWith(badgeCount: pendingCount)
              else
                item,
          ],
        ),
    ]);
  }

  /// The breadcrumb shown under the top-bar title for each destination.
  static String breadcrumbFor(int index) {
    switch (index) {
      case overviewIndex:
        return 'NEMRAS  ·  CLINICAL  ·  OVERVIEW';
      case emergencyQueueIndex:
        return 'NEMRAS  ·  CLINICAL  ·  EMERGENCY QUEUE';
      case patientsIndex:
        return 'NEMRAS  ·  CLINICAL  ·  PATIENT SEARCH';
      case clinicalRecordsIndex:
        return 'NEMRAS  ·  CLINICAL  ·  PATIENT RECORD';
      case assistantIndex:
        return 'NEMRAS  ·  DECISION SUPPORT  ·  ASSISTANT';
      case medicationsIndex:
        return 'NEMRAS  ·  DECISION SUPPORT  ·  MEDICATION SAFETY';
      case handoverIndex:
        return 'NEMRAS  ·  CONTINUITY  ·  DISCHARGE / HANDOVER';
      case auditIndex:
        return 'NEMRAS  ·  CONTINUITY  ·  ACCESS AUDIT';
      case settingsIndex:
        return 'NEMRAS  ·  SYSTEM  ·  SETTINGS';
      default:
        return 'NEMRAS  ·  CLINICAL';
    }
  }
}
