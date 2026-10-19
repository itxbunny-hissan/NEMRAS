import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:ops_dashboard/src/data/admin_identity.dart';
import 'package:ops_dashboard/src/data/audit_models.dart';
import 'package:ops_dashboard/src/data/handover_models.dart';
import 'package:ops_dashboard/src/data/occupancy_models.dart';
import 'package:ops_dashboard/src/data/operations_models.dart';
import 'package:ops_dashboard/src/app.dart';
import 'package:ops_dashboard/src/state/ops_console_controller.dart';
import 'package:ops_dashboard/src/state/ops_scope.dart';

import 'fake_repositories.dart';

/// A wide desktop surface. The operational dashboard is desktop-first, so
/// tests must not run it at the default 800x600 test size.
const Size kDesktop = Size(1600, 1200);

/// Builds a controller over mocked repositories. No test touches a backend.
OpsConsoleController buildTestController({
  OperationsRepository? operations,
  OccupancyRepository? occupancy,
  HandoverMonitorRepository? handovers,
  AuditRepository? audit,
  HospitalAdminProfile? administrator,
  OpsEnvironment environment = OpsEnvironment.demo,
}) {
  final hospitalId = DemoOpsIdentity.hospitalId;
  return OpsConsoleController(
    operationsRepository: operations ?? FakeOperationsRepository(),
    occupancyRepository: occupancy ?? FakeOccupancyRepository(),
    handoverRepository: handovers ?? FakeHandoverRepository(),
    auditRepository: audit ??
        InMemoryAuditRepository(seed: testAuditSeed(hospitalId: hospitalId)),
    administrator: administrator,
    environment: environment,
    clock: testClock,
  );
}

/// Pumps [child] on a desktop-sized surface inside the NEMRAS theme and an
/// [OpsScope].
///
/// The screens are normally hosted inside the shell's Scaffold, so a Material
/// ancestor has to be supplied when one is pumped alone.
Future<void> pumpDesktop(
  WidgetTester tester,
  Widget child, {
  required OpsConsoleController controller,
  bool bootstrap = true,
}) async {
  tester.view.physicalSize = kDesktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  if (bootstrap) await controller.bootstrap();

  await tester.pumpWidget(
    MaterialApp(
      theme: nemrasClinicalLightTheme(),
      home: OpsScope(
        controller: controller,
        child: Scaffold(body: child),
      ),
    ),
  );
  await tester.pump();
}

/// Resolves [route] through [OpsRouter] and pumps whatever it produces, so
/// routing is exercised through the real router rather than by inspecting a
/// route object.
Future<void> pumpRoute(
  WidgetTester tester,
  String route, {
  required OpsConsoleController controller,
}) async {
  tester.view.physicalSize = kDesktop;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await controller.bootstrap();

  await tester.pumpWidget(
    MaterialApp(
      theme: nemrasClinicalLightTheme(),
      initialRoute: route,
      onGenerateRoute: OpsRouter.onGenerateRoute,
      builder: (BuildContext context, Widget? child) => OpsScope(
        controller: controller,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
