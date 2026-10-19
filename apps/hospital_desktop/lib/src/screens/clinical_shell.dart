import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../data/staff_identity.dart';
import '../navigation/clinical_navigation.dart';
import '../state/hospital_session_controller.dart';
import '../state/session_scope.dart';
import '../widgets/clinical_ui.dart';
import 'ai_clinical_assistant_screen.dart';
import 'clinical_audit_screen.dart';
import 'clinical_overview_screen.dart';
import 'clinical_settings_screen.dart';
import 'discharge_handover_screen.dart';
import 'emergency_queue_screen.dart';
import 'medication_safety_screen.dart';
import 'patient_clinical_record_screen.dart';
import 'patient_search_screen.dart';

/// The desktop clinical shell: the 200dp sidebar, the 54dp top bar and the
/// multi-panel content area.
///
/// Navigation is held in local state rather than pushed onto the Navigator,
/// because a sidebar destination replaces the content area instead of opening
/// a new page. [AdaptiveNavigationPattern.sidebar] pins the desktop layout so
/// a narrow window never degrades this surface into a mobile bottom bar.
class ClinicalShell extends StatefulWidget {
  const ClinicalShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ClinicalShell> createState() => _ClinicalShellState();
}

class _ClinicalShellState extends State<ClinicalShell> {
  late int _selectedIndex = widget.initialIndex;

  void _select(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  /// Lets a screen hand the clinician to another destination, which the
  /// Emergency Queue and Patient Search both need.
  void _navigateTo(int index) => _select(index);

  Widget _bodyFor(int index) {
    switch (index) {
      case HospitalClinicalNavigation.overviewIndex:
        return ClinicalOverviewScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.emergencyQueueIndex:
        return const EmergencyQueueScreen();
      case HospitalClinicalNavigation.patientsIndex:
        return PatientSearchScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.clinicalRecordsIndex:
        return PatientClinicalRecordScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.assistantIndex:
        return AiClinicalAssistantScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.medicationsIndex:
        return MedicationSafetyScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.handoverIndex:
        return DischargeHandoverScreen(onNavigate: _navigateTo);
      case HospitalClinicalNavigation.auditIndex:
        return const ClinicalAuditScreen();
      case HospitalClinicalNavigation.settingsIndex:
        return const ClinicalSettingsScreen();
      default:
        return ClinicalOverviewScreen(onNavigate: _navigateTo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = HospitalSessionScope.of(context);
    final navigation = HospitalClinicalNavigation.withPendingCount(
      controller.pendingCaseCount,
    );
    final index = _selectedIndex.clamp(0, navigation.length - 1);

    return AdaptiveScaffold(
      navigation: navigation,
      selectedIndex: index,
      onDestinationSelected: _select,
      pattern: AdaptiveNavigationPattern.sidebar,
      title: navigation.items[index].label,
      breadcrumb: HospitalClinicalNavigation.breadcrumbFor(index),
      hasUnreadNotifications: controller.pendingCaseCount > 0,
      showSearch: false,
      brand: _HospitalBrand(controller: controller),
      avatar: _StaffAvatar(controller: controller),
      body: Column(
        children: <Widget>[
          _SystemStatusStrip(controller: controller),
          Expanded(child: _bodyFor(index)),
        ],
      ),
    );
  }
}

/// The sidebar brand slot: hospital identity, pinned to the demo hospital.
class _HospitalBrand extends StatelessWidget {
  const _HospitalBrand({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.local_hospital,
              size: 18,
              color: NemrasColors.fieldAccent,
            ),
            const SizedBox(width: NemrasSpacing.s),
            Expanded(
              child: Text(
                'NEMRAS',
                style: NemrasTextStyles.screenTitle.copyWith(
                  color: NemrasColors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          controller.hospital.displayName,
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: NemrasColors.fieldTextSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          controller.hospital.hospitalId,
          style: NemrasTextStyles.dataCaption.copyWith(
            color: NemrasColors.fieldAccent,
          ),
        ),
      ],
    );
  }
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final staff = controller.staff;
    return Tooltip(
      message: staff == null
          ? 'No clinical session'
          : '${staff.displayLabel} · ${staff.staffId}',
      child: ColoredBox(
        color: semantics.accent,
        child: Center(
          child: Text(
            staff?.initials ?? '—',
            style: NemrasTextStyles.badge.copyWith(
              color: semantics.onAccent,
            ),
          ),
        ),
      ),
    );
  }
}

/// A persistent strip under the top bar carrying the signed-in clinician, the
/// backend status and the demo marker.
///
/// The status reflects whether the NEMRAS API answered a probe. It is not a
/// hospital network or dispatch status, because NEMRAS has neither.
class _SystemStatusStrip extends StatelessWidget {
  const _SystemStatusStrip({required this.controller});

  final HospitalSessionController controller;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final staff = controller.staff;
    final reachable = controller.backendReachable;

    final NemrasStatusColor backendStatus;
    final String backendLabel;
    if (reachable == null) {
      backendStatus = semantics.informational;
      backendLabel = 'BACKEND: NOT CHECKED';
    } else if (reachable) {
      backendStatus = semantics.stable;
      backendLabel = 'BACKEND: REACHABLE';
    } else {
      backendStatus = semantics.critical;
      backendLabel = 'BACKEND: UNREACHABLE';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.section,
        vertical: NemrasSpacing.s,
      ),
      decoration: BoxDecoration(
        color: semantics.controlBackground,
        border: Border(bottom: BorderSide(color: semantics.cardBorder)),
      ),
      child: Wrap(
        spacing: NemrasSpacing.xl,
        runSpacing: NemrasSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (staff != null)
            _StatusItem(
              icon: Icons.badge_outlined,
              label: '${staff.role.shortLabel}  ·  ${staff.staffId}',
            ),
          _StatusItem(
            icon: Icons.apartment_outlined,
            label: controller.hospital.hospitalId,
          ),
          _StatusItem(
            icon: Icons.circle,
            label: backendLabel,
            color: backendStatus.onSoft,
          ),
          if (controller.pendingCaseCount > 0)
            _StatusItem(
              icon: Icons.notifications_active_outlined,
              label:
                  '${controller.pendingCaseCount} PENDING EMERGENCY '
                  '${controller.pendingCaseCount == 1 ? 'CASE' : 'CASES'}',
              color: semantics.critical.onSoft,
            ),
          const DemoChip(label: 'DEMO SESSION'),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final resolved = color ?? semantics.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 11, color: resolved),
        const SizedBox(width: NemrasSpacing.xxs),
        Text(
          label,
          style: NemrasTextStyles.dataCaption.copyWith(color: resolved),
        ),
      ],
    );
  }
}
