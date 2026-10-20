import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'data/admin_identity.dart';
import 'data/audit_models.dart';
import 'data/backend_operations_repository.dart';
import 'data/demo_handover_repository.dart';
import 'data/demo_occupancy_repository.dart';
import 'navigation/ops_navigation.dart';
import 'screens/ops_shell.dart';
import 'state/ops_console_controller.dart';
import 'state/ops_scope.dart';

/// The NEMRAS Hospital Operational Dashboard.
///
/// The fourth NEMRAS surface, for hospital administrators, operations
/// managers and supervisors. It is not the clinical application: it holds no
/// patient-record view, no clinical search and no break-glass flow.
///
/// There is no login screen. The operational dashboard has no authentication
/// of its own by design — adding one would be a second identity system, which
/// the architecture rules forbid — so it boots straight into the shell with a
/// labelled demo administrator session.
class OpsDashboardApp extends StatefulWidget {
  const OpsDashboardApp({super.key, this.controller});

  /// An injected controller, for tests. When null the app builds one over the
  /// real backend repository and the demo providers, and disposes it.
  final OpsConsoleController? controller;

  @override
  State<OpsDashboardApp> createState() => _OpsDashboardAppState();
}

class _OpsDashboardAppState extends State<OpsDashboardApp> {
  late final OpsConsoleController _controller;
  late final bool _ownsController;

  /// Held only so the HTTP client it owns can be closed on dispose.
  BackendOperationsRepository? _operations;

  @override
  void initState() {
    super.initState();
    final injected = widget.controller;
    _ownsController = injected == null;
    _controller = injected ?? _buildController();
    _controller.bootstrap();
  }

  OpsConsoleController _buildController() {
    final hospitalId = DemoOpsIdentity.hospitalId;
    final operations = BackendOperationsRepository();
    _operations = operations;
    return OpsConsoleController(
      operationsRepository: operations,
      occupancyRepository: DemoOccupancyRepository(),
      handoverRepository: DemoHandoverRepository(),
      auditRepository: InMemoryAuditRepository(
        seed: demoAuditSeed(hospitalId: hospitalId),
      ),
    );
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
      _operations?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEMRAS Hospital Operations',
      debugShowCheckedModeBanner: false,
      theme: nemrasClinicalLightTheme(),
      initialRoute: NemrasRouteNames.hospitalOverview,
      onGenerateRoute: OpsRouter.onGenerateRoute,
      builder: (BuildContext context, Widget? child) => OpsScope(
        controller: _controller,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Routes every sidebar destination to the shell with that tab selected.
///
/// The shell owns the selection, so a route exists mainly so a deep link and
/// the browser address bar resolve to the right screen.
abstract final class OpsRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final route = settings.name ?? NemrasRouteNames.hospitalOverview;
    final index = OpsNavigation.indexForRoute(route);

    // Unknown routes land on Overview rather than on an error page: a
    // misremembered URL should not strand an administrator.
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) => OpsShell(
        initialIndex: index ?? OpsNavigation.overviewIndex,
      ),
    );
  }
}
