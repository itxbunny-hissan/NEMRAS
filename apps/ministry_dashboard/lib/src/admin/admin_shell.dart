import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import '../state/national_scope.dart';
import 'admin_audit_settings_screen.dart';
import 'admin_fleet_screen.dart';
import 'admin_navigation.dart';
import 'admin_hospital_registry_screen.dart';
import 'admin_overview_screen.dart';
import 'roles_permissions_screen.dart';
import 'user_verification_screen.dart';

/// The national administration console.
///
/// Pushed over the analytics dashboard. Its sidebar is its own: it does not
/// replace the eight analytics destinations.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialIndex = AdminNavigation.overviewIndex});

  final int initialIndex;

  static Route<void> route() => MaterialPageRoute<void>(
        builder: (_) => const AdminShell(),
      );

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final semantics = NemrasSemantics.of(context);
    final analyst = NationalScope.of(context).analyst;

    return AdaptiveScaffold(
      navigation: AdminNavigation.sidebar,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
      pattern: AdaptiveNavigationPattern.sidebar,
      title: AdminNavigation.titleFor(_selectedIndex),
      breadcrumb: 'Administration / ${AdminNavigation.titleFor(_selectedIndex)}',
      brand: const _AdminBrand(),
      avatar: Tooltip(
        message: analyst.displayLabel,
        child: Center(
          child: Text(
            analyst.initials,
            style: NemrasTextStyles.badge.copyWith(color: semantics.onAccent),
          ),
        ),
      ),
      showSearch: false,
      body: ColoredBox(
        color: semantics.screenBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NemrasSpacing.section,
                NemrasSpacing.m,
                NemrasSpacing.section,
                0,
              ),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Back to national dashboard'),
              ),
            ),
            Expanded(child: _screenFor(_selectedIndex)),
          ],
        ),
      ),
    );
  }

  Widget _screenFor(int index) {
    switch (index) {
      case AdminNavigation.overviewIndex:
        return AdminOverviewScreen(
          onOpenSection: (int i) => setState(() => _selectedIndex = i),
        );
      case AdminNavigation.verificationIndex:
        return const UserVerificationScreen();
      case AdminNavigation.rolesIndex:
        return const RolesPermissionsScreen();
      case AdminNavigation.hospitalsIndex:
        return const AdminHospitalRegistryScreen();
      case AdminNavigation.fleetIndex:
        return const AdminFleetScreen();
      case AdminNavigation.auditIndex:
        return const AdminAuditSettingsScreen();
      default:
        return const AdminOverviewScreen();
    }
  }
}

class _AdminBrand extends StatelessWidget {
  const _AdminBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'NEMRAS ADMIN',
          style: NemrasTextStyles.badge.copyWith(color: NemrasColors.white),
        ),
        const SizedBox(height: NemrasSpacing.xxs),
        Text(
          'Demonstration console',
          style: NemrasTextStyles.bodyCaption.copyWith(
            color: NemrasColors.fieldTextSecondary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
