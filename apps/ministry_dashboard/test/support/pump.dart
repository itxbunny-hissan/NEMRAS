import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ministry_dashboard/src/data/analyst_identity.dart';
import 'package:ministry_dashboard/src/data/demo_federation_repository.dart';
import 'package:ministry_dashboard/src/data/federation_models.dart';
import 'package:ministry_dashboard/src/data/governance_models.dart';
import 'package:ministry_dashboard/src/data/hospital_aggregate_models.dart';
import 'package:ministry_dashboard/src/data/national_models.dart';
import 'package:ministry_dashboard/src/state/national_console_controller.dart';
import 'package:ministry_dashboard/src/state/national_scope.dart';
import 'package:nemras_design/nemras_design.dart';

import 'fake_repositories.dart';

/// A desktop-sized surface. The national dashboard is desktop-first, and a
/// phone-sized test surface would overflow panels the real users never see at
/// that width.
const Size kDesktop = Size(1800, 1400);

/// Builds a controller over mocked sources.
///
/// Defaults are the honest Phase 5A configuration: real-shaped aggregates,
/// no hospital endpoint, a demo federation and an in-memory audit trail.
NationalConsoleController buildTestController({
  NationalRepository? national,
  HospitalAggregateRepository? hospitals,
  FederationRepository? federation,
  NationalAuditRepository? audit,
  MinistryAnalystProfile? analyst,
  NationalOrganization? organization,
  NationalEnvironment environment = NationalEnvironment.demo,
  bool seedAudit = true,
  DateTime? now,
}) {
  final org = organization ?? DemoMinistryIdentity.organization;
  final clockValue = now ?? kTestNow;

  return NationalConsoleController(
    nationalRepository: national ?? FakeNationalRepository(),
    hospitalRepository:
        hospitals ?? const UnavailableHospitalAggregateRepository(),
    federationRepository:
        federation ?? DemoFederationRepository(now: clockValue),
    auditRepository: audit ??
        InMemoryNationalAuditRepository(
          seed: seedAudit
              ? testAuditSeed(organizationId: org.organizationId)
              : const <NationalAuditEvent>[],
        ),
    analyst: analyst,
    organization: org,
    environment: environment,
    clock: () => clockValue,
  );
}

/// Pumps a widget on a desktop surface inside the NEMRAS theme and scope.
///
/// Wrapped in a [Scaffold] so screens that use [Material] descendants such as
/// chips and buttons have the ancestor they need.
Future<void> pumpDesktop(
  WidgetTester tester,
  NationalConsoleController controller,
  Widget child, {
  Size size = kDesktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    NationalScope(
      controller: controller,
      child: MaterialApp(
        theme: nemrasClinicalLightTheme(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Pumps a route through the real router inside a [MaterialApp].
///
/// Used so routing is verified against the actual `onGenerateRoute`
/// implementation rather than against a re-stated mapping.
Future<void> pumpRoute(
  WidgetTester tester,
  NationalConsoleController controller,
  String route, {
  required Route<dynamic> Function(RouteSettings settings) onGenerateRoute,
  Size size = kDesktop,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      // Keyed by route so a test that pumps several routes in sequence gets a
      // fresh navigator each time. Without it the first initialRoute wins.
      key: ValueKey<String>(route),
      theme: nemrasClinicalLightTheme(),
      initialRoute: route,
      onGenerateRoute: onGenerateRoute,
      builder: (BuildContext context, Widget? child) => NationalScope(
        controller: controller,
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

/// Every string rendered anywhere in the current tree.
///
/// Used by the privacy assertions, which have to check what the UI actually
/// shows rather than what any one widget was handed.
List<String> renderedStrings(WidgetTester tester) {
  final found = <String>[];
  for (final widget in tester.allWidgets) {
    if (widget is Text) {
      final data = widget.data;
      if (data != null) found.add(data);
      final span = widget.textSpan;
      if (span != null) found.add(span.toPlainText());
    } else if (widget is RichText) {
      found.add(widget.text.toPlainText());
    } else if (widget is Tooltip) {
      final message = widget.message;
      if (message != null) found.add(message);
    }
  }
  return found;
}
