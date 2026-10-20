import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../data/analyst_identity.dart';
import '../data/national_models.dart';
import '../navigation/national_navigation.dart';
import '../state/national_console_controller.dart';
import '../state/national_scope.dart';
import '../widgets/national_ui.dart';
import 'emergency_trends_screen.dart';
import 'federation_screen.dart';
import 'governance_screen.dart';
import 'health_indicators_screen.dart';
import 'hospital_network_screen.dart';
import 'national_overview_screen.dart';
import 'national_reports_screen.dart';
import 'national_settings_screen.dart';

/// The national dashboard shell.
///
/// Holds the sidebar selection and renders the selected screen inside
/// [AdaptiveScaffold]. The pattern is pinned to
/// [AdaptiveNavigationPattern.sidebar] so narrowing the window never degrades
/// a national analytics surface into a mobile bottom bar.
class NationalShell extends StatefulWidget {
  const NationalShell({
    super.key,
    this.initialIndex = NationalNavigation.overviewIndex,
  });

  final int initialIndex;

  @override
  State<NationalShell> createState() => _NationalShellState();
}

class _NationalShellState extends State<NationalShell> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final tally = controller.federationTally;

    return AdaptiveScaffold(
      navigation: NationalNavigation.withNodeAttentionCount(
        controller.federationState.isReady ? (tally?.needingAttention ?? 0) : 0,
      ),
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
      pattern: AdaptiveNavigationPattern.sidebar,
      title: _titleFor(_selectedIndex),
      breadcrumb: NationalNavigation.breadcrumbFor(_selectedIndex),
      brand: _NationalBrand(organization: controller.organization),
      avatar: _AnalystAvatar(analyst: controller.analyst),
      // The top bar's search box is an affordance with no behaviour attached,
      // and a national search would in any case have to be a patient search,
      // which this surface must not offer.
      showSearch: false,
      hasUnreadNotifications: controller.alerts.isNotEmpty,
      body: ColoredBox(
        color: semantics.screenBackground,
        child: Column(
          children: <Widget>[
            // The shared top bar has no slot for system status, reporting
            // period or a freshness timestamp, and it is frozen for this
            // phase, so the status strip sits directly beneath it.
            const NationalStatusStrip(),
            Expanded(child: _screenFor(_selectedIndex)),
          ],
        ),
      ),
    );
  }

  static String _titleFor(int index) {
    switch (index) {
      case NationalNavigation.overviewIndex:
        return 'National Overview';
      case NationalNavigation.emergencyTrendsIndex:
        return 'Emergency Trends';
      case NationalNavigation.healthIndicatorsIndex:
        return 'Health Indicators';
      case NationalNavigation.hospitalNetworkIndex:
        return 'Hospital Network';
      case NationalNavigation.federationIndex:
        return 'Federation Node Status';
      case NationalNavigation.reportsIndex:
        return 'National Reports';
      case NationalNavigation.governanceIndex:
        return 'Audit and Governance';
      case NationalNavigation.settingsIndex:
        return 'Settings';
      default:
        return 'NEMRAS National';
    }
  }

  Widget _screenFor(int index) {
    switch (index) {
      case NationalNavigation.overviewIndex:
        return NationalOverviewScreen(
          onNavigate: (int i) => setState(() => _selectedIndex = i),
        );
      case NationalNavigation.emergencyTrendsIndex:
        return EmergencyTrendsScreen(
          onNavigate: (int i) => setState(() => _selectedIndex = i),
        );
      case NationalNavigation.healthIndicatorsIndex:
        return HealthIndicatorsScreen(
          onNavigate: (int i) => setState(() => _selectedIndex = i),
        );
      case NationalNavigation.hospitalNetworkIndex:
        return HospitalNetworkScreen(
          onNavigate: (int i) => setState(() => _selectedIndex = i),
        );
      case NationalNavigation.federationIndex:
        return const FederationScreen();
      case NationalNavigation.reportsIndex:
        return NationalReportsScreen(
          onNavigate: (int i) => setState(() => _selectedIndex = i),
        );
      case NationalNavigation.governanceIndex:
        return const GovernanceScreen();
      case NationalNavigation.settingsIndex:
        return const NationalSettingsScreen();
      default:
        return const NationalOverviewScreen();
    }
  }
}

/// The national identity block in the sidebar header.
class _NationalBrand extends StatelessWidget {
  const _NationalBrand({required this.organization});

  final NationalOrganization organization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NEMRAS CENTRAL',
          style: NemrasTextStyles.badge.copyWith(color: NemrasColors.white),
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          organization.displayName,
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: NemrasColors.fieldTextSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// The analyst initials square in the top bar.
class _AnalystAvatar extends StatelessWidget {
  const _AnalystAvatar({required this.analyst});

  final MinistryAnalystProfile analyst;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    return Tooltip(
      message: '${analyst.displayLabel}\n'
          '${analyst.role.label}\n'
          'Analyst ID ${analyst.analystId}\n'
          '${analyst.role.dataScope}',
      child: ColoredBox(
        color: semantics.accent,
        child: Center(
          child: Text(
            analyst.initials,
            style: NemrasTextStyles.badge.copyWith(color: semantics.onAccent),
          ),
        ),
      ),
    );
  }
}

/// The national status strip: environment, data-source state, analyst,
/// reporting period, and when the figures were last read.
///
/// It reports a data-freshness timestamp rather than a running clock. A
/// ticking clock would leave a periodic timer alive in every test and would
/// imply the figures behind it are also live, which they are not.
class NationalStatusStrip extends StatelessWidget {
  const NationalStatusStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NationalScope.of(context);
    final semantics = NemrasSemantics.of(context);
    final status = controller.dataSourceStatus;

    final NemrasStatusColor statusColor;
    switch (status) {
      case NationalDataSourceStatus.reachable:
        statusColor = semantics.stable;
      case NationalDataSourceStatus.degraded:
        statusColor = semantics.elevated;
      case NationalDataSourceStatus.unreachable:
        statusColor = semantics.critical;
      case NationalDataSourceStatus.unknown:
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
          NationalStatusPill(
            label: status.label,
            status: statusColor,
            icon: Icons.sensors,
          ),
          _StripFact(
            label: 'Organisation',
            value: controller.organization.organizationId,
          ),
          _StripFact(
            label: 'Analyst',
            value: controller.analyst.analystId,
          ),
          Tooltip(
            message: controller.reportingPeriod.detail,
            child: _StripFact(
              label: 'Reporting period',
              value: controller.reportingPeriod.label,
            ),
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
        NationalLabel(label),
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
