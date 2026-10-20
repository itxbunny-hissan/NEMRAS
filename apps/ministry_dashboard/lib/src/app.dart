import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'data/analyst_identity.dart';
import 'data/backend_national_repository.dart';
import 'data/demo_federation_repository.dart';
import 'data/governance_models.dart';
import 'data/hospital_aggregate_models.dart';
import 'navigation/national_navigation.dart';
import 'screens/national_shell.dart';
import 'state/national_console_controller.dart';
import 'state/national_scope.dart';

/// The NEMRAS National / Ministry Dashboard.
///
/// There is no login screen. NEMRAS already has one identity layer, and a
/// second sign-in form here would be a second authentication system, which
/// this phase must not create. The demo analyst identity is therefore
/// declared in the controller and disclosed on the Settings screen.
class MinistryDashboardApp extends StatefulWidget {
  const MinistryDashboardApp({super.key, this.controller});

  /// Supplied by tests with mocked repositories. When null the app builds a
  /// controller over the real backend client and the demo providers.
  final NationalConsoleController? controller;

  @override
  State<MinistryDashboardApp> createState() => _MinistryDashboardAppState();
}

class _MinistryDashboardAppState extends State<MinistryDashboardApp> {
  late final NationalConsoleController _controller;
  late final bool _ownsController;

  /// Held only so its HTTP client can be closed on dispose.
  BackendNationalRepository? _national;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    if (injected != null) {
      _controller = injected;
    } else {
      final national = BackendNationalRepository();
      _national = national;
      _controller = NationalConsoleController(
        nationalRepository: national,
        hospitalRepository: const UnavailableHospitalAggregateRepository(),
        federationRepository: DemoFederationRepository(),
        auditRepository: InMemoryNationalAuditRepository(
          seed: demoNationalAuditSeed(
            organizationId: DemoMinistryIdentity.organizationId,
          ),
        ),
      );
    }
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _national?.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMRAS National Dashboard',
      debugShowCheckedModeBanner: false,
      theme: nemrasClinicalLightTheme(),
      initialRoute: NemrasRouteNames.centralNationalOverview,
      onGenerateRoute: NationalRouter.onGenerateRoute,
      builder: (BuildContext context, Widget? child) => NationalScope(
        controller: _controller,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Resolves national routes to the shell with the matching tab selected.
///
/// Every destination renders inside one [NationalShell] rather than as its
/// own page, so the sidebar and status strip are built once and selection is
/// local state. An unknown route lands on the National Overview rather than
/// on an error page, because a national analyst following a stale link
/// should arrive somewhere useful.
abstract final class NationalRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final index =
        NationalNavigation.indexForRoute(settings.name ?? '') ??
            NationalNavigation.overviewIndex;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => NationalShell(initialIndex: index),
    );
  }
}
