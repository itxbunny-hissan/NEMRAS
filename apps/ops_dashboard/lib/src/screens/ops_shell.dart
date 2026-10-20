import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../data/admin_identity.dart';
import '../data/operations_models.dart';
import '../navigation/ops_navigation.dart';
import '../state/ops_console_controller.dart';
import '../state/ops_scope.dart';
import '../widgets/ops_ui.dart';
import 'audit_trail_screen.dart';
import 'bed_occupancy_screen.dart';
import 'compliance_screen.dart';
import 'department_workload_screen.dart';
import 'emergency_operations_screen.dart';
import 'operational_reports_screen.dart';
import 'operations_overview_screen.dart';
import 'ops_settings_screen.dart';
import 'patient_flow_screen.dart';

/// The operational dashboard shell.
///
/// Holds the sidebar selection and renders the selected screen inside
/// [AdaptiveScaffold]. The pattern is pinned to
/// [AdaptiveNavigationPattern.sidebar] so narrowing the window never degrades
/// an administrative desktop surface into a mobile bottom bar.
class OpsShell extends StatefulWidget {
  const OpsShell({super.key, this.initialIndex = OpsNavigation.overviewIndex});

  final int initialIndex;

  @override
  State<OpsShell> createState() => _OpsShellState();
}

class _OpsShellState extends State<OpsShell> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);

    return AdaptiveScaffold(
      navigation: OpsNavigation.withPendingCount(
        controller.handoverState.isReady ? controller.handoverTally.pending : 0,
      ),
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
      pattern: AdaptiveNavigationPattern.sidebar,
      title: _titleFor(_selectedIndex),
      breadcrumb: OpsNavigation.breadcrumbFor(_selectedIndex),
      brand: _HospitalBrand(hospital: controller.hospital),
      avatar: _AdminAvatar(administrator: controller.administrator),
      // The top bar's search box is an affordance with no behaviour attached.
      // The reference draws one, but shipping a dead control on an
      // administrative surface is worse than omitting it.
      showSearch: false,
      hasUnreadNotifications: controller.alerts.isNotEmpty,
      body: ColoredBox(
        color: semantics.screenBackground,
        child: Column(
          children: <Widget>[
            // The shared top bar has no slot for operational status or a
            // timestamp, and it is frozen for this phase, so the status strip
            // sits directly beneath it as the first row of the content area.
            const OpsStatusStrip(),
            Expanded(child: _screenFor(_selectedIndex)),
          ],
        ),
      ),
    );
  }

  static String _titleFor(int index) {
    switch (index) {
      case OpsNavigation.overviewIndex:
        return 'Hospital Operations Overview';
      case OpsNavigation.emergencyIndex:
        return 'Emergency Operations';
      case OpsNavigation.bedOccupancyIndex:
        return 'Bed and Room Occupancy';
      case OpsNavigation.patientsIndex:
        return 'Patient Flow';
      case OpsNavigation.departmentsIndex:
        return 'Department Workload';
      case OpsNavigation.reportsIndex:
        return 'Operational Reports';
      case OpsNavigation.complianceIndex:
        return 'Compliance';
      case OpsNavigation.auditTrailIndex:
        return 'Audit Trail';
      case OpsNavigation.settingsIndex:
        return 'Settings';
      default:
        return 'Hospital Operations';
    }
  }

  Widget _screenFor(int index) {
    switch (index) {
      case OpsNavigation.overviewIndex:
        return const OperationsOverviewScreen();
      case OpsNavigation.emergencyIndex:
        return const EmergencyOperationsScreen();
      case OpsNavigation.bedOccupancyIndex:
        return const BedOccupancyScreen();
      case OpsNavigation.patientsIndex:
        return const PatientFlowScreen();
      case OpsNavigation.departmentsIndex:
        return const DepartmentWorkloadScreen();
      case OpsNavigation.reportsIndex:
        return const OperationalReportsScreen();
      case OpsNavigation.complianceIndex:
        return const ComplianceScreen();
      case OpsNavigation.auditTrailIndex:
        return const AuditTrailScreen();
      case OpsNavigation.settingsIndex:
        return const OpsSettingsScreen();
      default:
        return const OperationsOverviewScreen();
    }
  }
}

/// The hospital identity block in the sidebar header.
class _HospitalBrand extends StatelessWidget {
  const _HospitalBrand({required this.hospital});

  final OpsHospitalIdentity hospital;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NEMRAS OPERATIONS',
          style: NemrasTextStyles.badge.copyWith(color: NemrasColors.white),
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          hospital.displayName,
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: NemrasColors.fieldTextSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The administrator initials square in the top bar.
class _AdminAvatar extends StatelessWidget {
  const _AdminAvatar({required this.administrator});

  final HospitalAdminProfile administrator;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Tooltip(
      message: '${administrator.displayLabel}\n'
          '${administrator.role.label}\n'
          'Staff ID ${administrator.staffId}',
      child: ColoredBox(
        color: semantics.accent,
        child: Center(
          child: Text(
            administrator.initials,
            style: NemrasTextStyles.badge.copyWith(color: semantics.onAccent),
          ),
        ),
      ),
    );
  }
}

/// The operational status strip: environment, data-source state, current
/// administrator, and when the figures were last read.
///
/// It reports a data-freshness timestamp rather than a running clock. A
/// ticking clock would leave a periodic timer alive in every test and would
/// imply the figures behind it are also live, which they are not.
class OpsStatusStrip extends StatelessWidget {
  const OpsStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OpsScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final status = controller.backendStatus;

    final NemrasStatusColor statusColor;
    switch (status) {
      case OpsBackendStatus.reachable:
        statusColor = semantics.stable;
      case OpsBackendStatus.degraded:
        statusColor = semantics.elevated;
      case OpsBackendStatus.unreachable:
        statusColor = semantics.critical;
      case OpsBackendStatus.unknown:
        statusColor = semantics.informational;
    }

    final capturedAt = controller.snapshot?.capturedAt;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NemrasSpacing.section,
        vertical: NemrasSpacing.m,
      ),
      decoration: BoxDecoration(
        color: semantics.cardBackground,
        border: Border(bottom: BorderSide(color: semantics.barBorder)),
      ),
      child: Wrap(
        spacing: NemrasSpacing.l,
        runSpacing: NemrasSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (controller.environment.isDemo) const DemoChip(),
          OpsStatusPill(
            label: status.label,
            status: statusColor,
            icon: Icons.sensors,
          ),
          _StripFact(
            label: 'Hospital',
            value: controller.hospital.hospitalId,
          ),
          _StripFact(
            label: 'Administrator',
            value: controller.administrator.staffId,
          ),
          _StripFact(
            label: 'Data as of',
            value: capturedAt == null
                ? kNotAvailable
                : formatUtcTimestamp(capturedAt),
          ),
          TextButton.icon(
            onPressed: controller.refreshAll,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _StripFact extends StatelessWidget {
  const _StripFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        OpsLabel(label),
        const SizedBox(width: NemrasSpacing.xs),
        Text(
          value,
          style: NemrasTextStyles.dataValue.copyWith(
            color: value == kNotAvailable
                ? semantics.textPlaceholder
                : semantics.textPrimary,
          ),
        ),
      ],
    );
  }
}
