import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_layout/nemras_layout.dart';
import 'package:ops_dashboard/src/app.dart';
import 'package:ops_dashboard/src/data/audit_models.dart';
import 'package:ops_dashboard/src/data/handover_models.dart';
import 'package:ops_dashboard/src/screens/audit_trail_screen.dart';
import 'package:ops_dashboard/src/screens/bed_occupancy_screen.dart';
import 'package:ops_dashboard/src/screens/compliance_screen.dart';
import 'package:ops_dashboard/src/screens/department_workload_screen.dart';
import 'package:ops_dashboard/src/screens/emergency_operations_screen.dart';
import 'package:ops_dashboard/src/screens/operational_reports_screen.dart';
import 'package:ops_dashboard/src/screens/operations_overview_screen.dart';
import 'package:ops_dashboard/src/screens/ops_settings_screen.dart';
import 'package:ops_dashboard/src/screens/ops_shell.dart';
import 'package:ops_dashboard/src/screens/patient_flow_screen.dart';
import 'package:ops_dashboard/src/widgets/ops_ui.dart';

import 'support/fake_repositories.dart';
import 'support/pump.dart';

void main() {
  group('app boot', () {
    testWidgets('boots into the shell with no login screen', (tester) async {
      tester.view.physicalSize = kDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = buildTestController();
      await tester.pumpWidget(OpsDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(OpsShell), findsOneWidget);
      expect(find.byType(OperationsOverviewScreen), findsOneWidget);
      expect(find.text('Hospital Operations Overview'), findsOneWidget);
      // No credential field anywhere: this surface has no second auth system.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('routes a known destination to its own screen',
        (tester) async {
      await pumpRoute(
        tester,
        NemrasRouteNames.hospitalSettings,
        controller: buildTestController(),
      );

      expect(find.byType(OpsSettingsScreen), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('routes an unknown destination to overview', (tester) async {
      await pumpRoute(
        tester,
        '/nonsense',
        controller: buildTestController(),
      );

      expect(find.byType(OperationsOverviewScreen), findsOneWidget);
    });
  });

  group('shell navigation', () {
    testWidgets('each sidebar destination swaps in its screen',
        (tester) async {
      tester.view.physicalSize = kDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = buildTestController();
      await tester.pumpWidget(OpsDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      final expected = <String, Type>{
        'Emergency': EmergencyOperationsScreen,
        'Bed Occupancy': BedOccupancyScreen,
        'Patients': PatientFlowScreen,
        'Departments': DepartmentWorkloadScreen,
        'Reports': OperationalReportsScreen,
        'Compliance': ComplianceScreen,
        'Audit Trail': AuditTrailScreen,
        'Settings': OpsSettingsScreen,
        'Overview': OperationsOverviewScreen,
      };

      for (final entry in expected.entries) {
        await tester.tap(find.text(entry.key));
        await tester.pumpAndSettle();
        expect(
          find.byType(entry.value),
          findsOneWidget,
          reason: 'tapping ${entry.key} should show ${entry.value}',
        );
      }
    });

    testWidgets('the status strip reports environment, scope and freshness',
        (tester) async {
      tester.view.physicalSize = kDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = buildTestController();
      await tester.pumpWidget(OpsDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(OpsStatusStrip), findsOneWidget);
      expect(find.text('DEMO'), findsWidgets);
      expect(find.text('DATA SOURCE REACHABLE'), findsOneWidget);
      expect(find.text('HOSP-001'), findsWidgets);
      expect(find.text('ADMIN-001'), findsWidgets);
      expect(find.text('2026-03-14 09:30 UTC'), findsOneWidget);
    });

    testWidgets('the emergency badge shows the pending handover count',
        (tester) async {
      tester.view.physicalSize = kDesktop;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = buildTestController();
      await tester.pumpWidget(OpsDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(NemrasDesktopSidebar),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the shell keeps the sidebar on a narrow window',
        (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = buildTestController();
      await tester.pumpWidget(OpsDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.byType(NemrasDesktopSidebar), findsOneWidget);
      expect(find.byType(NemrasBottomNavigation), findsNothing);
    });
  });

  group('operations overview', () {
    testWidgets('renders the six KPIs with their provenance badges',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
      );

      expect(find.byType(OpsKpiCard), findsNWidgets(6));
      expect(find.text('EMERGENCY CASES'), findsOneWidget);
      expect(find.text('ACTIVE ADMISSIONS'), findsOneWidget);
      expect(find.text('OCCUPIED ROOMS'), findsOneWidget);
      expect(find.text('AVAILABLE ROOMS'), findsOneWidget);
      expect(find.text('PENDING HANDOVERS'), findsOneWidget);
      expect(find.text('CRITICAL CASES'), findsOneWidget);
      expect(find.text('DATASET-DERIVED'), findsWidgets);
      expect(find.text('NOT AVAILABLE'), findsWidgets);
    });

    testWidgets('states that dataset counts are not live hospital figures',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
      );

      expect(
        find.textContaining('not current hospital statistics'),
        findsOneWidget,
      );
      expect(
        find.textContaining('not cases currently in this hospital'),
        findsOneWidget,
      );
      expect(find.textContaining('dataset records'), findsWidgets);
    });

    testWidgets('shows a loading state while the dataset read is pending',
        (tester) async {
      final controller = buildTestController(
        operations: PendingOperationsRepository(),
      );
      // Not bootstrapped through pumpDesktop: the fake never resolves.
      controller.bootstrap();
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
        bootstrap: false,
      );

      expect(find.text('Reading dataset aggregates'), findsOneWidget);
    });

    testWidgets('shows an error state with a retry when the source fails',
        (tester) async {
      final controller = buildTestController(
        operations: const FailingOperationsRepository(),
      );
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
      );

      expect(find.text('Dataset figures unavailable'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('shows an empty alert state when nothing is raised',
        (tester) async {
      final controller = buildTestController(
        occupancy: FakeOccupancyRepository(
          plan: const <({String ward, int occupied, int available})>[
            (ward: 'General Medicine', occupied: 2, available: 8),
          ],
        ),
        handovers: FakeHandoverRepository(
          statuses: const <HandoverStatus>[HandoverStatus.completed],
        ),
        audit: InMemoryAuditRepository(),
      );
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
      );

      expect(find.text('No operational alerts'), findsOneWidget);
    });

    testWidgets('renders an alert panel per raised alert', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationsOverviewScreen(),
        controller: controller,
      );

      expect(
        find.byType(OpsAlertPanel),
        findsNWidgets(controller.alerts.length),
      );
      expect(find.textContaining('awaiting acceptance'), findsOneWidget);
    });
  });

  group('emergency operations', () {
    testWidgets('lists emergency records and leaves absent fields blank',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const EmergencyOperationsScreen(),
        controller: controller,
      );

      expect(find.text('Highest-risk emergency records'), findsOneWidget);
      expect(find.text('HANDOVER STATUS'), findsOneWidget);
      expect(find.text('DESTINATION'), findsOneWidget);
      // Three of the five fake rows are emergency admissions, and each leaves
      // handover status and destination unavailable.
      expect(find.text('Not available'), findsWidgets);
    });

    testWidgets('labels the case table a bounded sample', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const EmergencyOperationsScreen(),
        controller: controller,
      );

      expect(find.text('DATASET SAMPLE'), findsWidgets);
      expect(
        find.textContaining('bounded sample skewed towards severe cases'),
        findsOneWidget,
      );
    });

    testWidgets('switches to the handover monitor and shows demo state',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const EmergencyOperationsScreen(),
        controller: controller,
      );

      await tester.tap(find.text('Handover monitor'));
      await tester.pumpAndSettle();

      expect(find.text('DEMO HANDOVER STATE'), findsOneWidget);
      expect(find.text('Handover queue'), findsOneWidget);
      expect(find.text('INCOMING'), findsWidgets);
      expect(find.text('COMPLETED'), findsWidgets);
      expect(
        find.textContaining('not connected to the Hospital Clinical'),
        findsOneWidget,
      );
    });

    testWidgets('shows the handover empty state on an empty queue',
        (tester) async {
      final controller = buildTestController(
        handovers: FakeHandoverRepository(statuses: const <HandoverStatus>[]),
      );
      await pumpDesktop(
        tester,
        const EmergencyOperationsScreen(),
        controller: controller,
      );

      await tester.tap(find.text('Handover monitor'));
      await tester.pumpAndSettle();

      expect(find.text('No handovers'), findsOneWidget);
    });

    testWidgets('shows the handover error state with a retry', (tester) async {
      final controller = buildTestController(
        handovers: const FailingHandoverRepository(),
      );
      await pumpDesktop(
        tester,
        const EmergencyOperationsScreen(),
        controller: controller,
      );

      await tester.tap(find.text('Handover monitor'));
      await tester.pumpAndSettle();

      expect(find.text('Handover state unavailable'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('bed occupancy', () {
    testWidgets('labels the whole screen as not live telemetry',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const BedOccupancyScreen(),
        controller: controller,
      );

      // ProvenanceNotice renders its title through OpsLabel, which
      // upper-cases.
      expect(find.text('DEMO — NOT LIVE BED TELEMETRY'), findsOneWidget);
      expect(find.text('DEMO / DATASET-DERIVED'), findsOneWidget);
      expect(
        find.textContaining('no backend route exposes'),
        findsOneWidget,
      );
      expect(find.text('DEMO'), findsWidgets);
    });

    testWidgets('renders per-ward occupancy with the computed share',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const BedOccupancyScreen(),
        controller: controller,
      );

      expect(find.text('Emergency'), findsWidgets);
      expect(find.text('90%'), findsWidgets);
      expect(find.text('50%'), findsWidgets);
      expect(
        find.textContaining('9 occupied, 1 available'),
        findsOneWidget,
      );
    });

    testWidgets('reports length of stay as unavailable', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const BedOccupancyScreen(),
        controller: controller,
      );

      expect(find.text('MEAN LENGTH OF STAY'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
    });

    testWidgets('shows the empty state when no ward is reported',
        (tester) async {
      final controller = buildTestController(
        occupancy: const EmptyOccupancyRepository(),
      );
      await pumpDesktop(
        tester,
        const BedOccupancyScreen(),
        controller: controller,
      );

      expect(find.text('No occupancy data'), findsOneWidget);
    });

    testWidgets('shows the error state with a retry', (tester) async {
      final controller = buildTestController(
        occupancy: const FailingOccupancyRepository(),
      );
      await pumpDesktop(
        tester,
        const BedOccupancyScreen(),
        controller: controller,
      );

      expect(find.text('Occupancy state unavailable'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });
  });

  group('department workload', () {
    testWidgets('renders aggregate breakdowns and no staffing figure',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const DepartmentWorkloadScreen(),
        controller: controller,
      );

      expect(find.text('Medical Condition'), findsOneWidget);
      expect(find.text('Triage Level'), findsOneWidget);
      expect(find.text('Admission Type'), findsWidgets);
      expect(find.text('STAFF ON SHIFT'), findsOneWidget);
      expect(find.text('CASES PER CLINICIAN'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
    });

    testWidgets('reports cases by hospital as unavailable', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const DepartmentWorkloadScreen(),
        controller: controller,
      );

      expect(find.text('Cases by Hospital'), findsOneWidget);
      expect(
        find.textContaining('Hospital exists in the dataset but no endpoint'),
        findsOneWidget,
      );
    });

    testWidgets('shows the error state when the aggregate read fails',
        (tester) async {
      final controller = buildTestController(
        operations: const FailingOperationsRepository(),
      );
      await pumpDesktop(
        tester,
        const DepartmentWorkloadScreen(),
        controller: controller,
      );

      expect(find.text('Workload aggregates unavailable'), findsOneWidget);
    });
  });

  group('patient flow', () {
    testWidgets('reports every time-based metric as unavailable',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const PatientFlowScreen(),
        controller: controller,
      );

      expect(find.text('DISCHARGES TODAY'), findsOneWidget);
      expect(find.text('ACTIVE ENCOUNTERS'), findsOneWidget);
      expect(find.text('ADMISSIONS LAST 24H'), findsOneWidget);
      expect(find.text('WARD TRANSFERS'), findsOneWidget);
      expect(find.text('ACTIVE ADMISSIONS'), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
    });

    testWidgets('explains why, and documents the sources it would need',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const PatientFlowScreen(),
        controller: controller,
      );

      expect(
        find.text('WHY MOST OF THIS PAGE IS UNAVAILABLE'),
        findsOneWidget,
      );
      expect(find.textContaining('Nothing on this page is a rate'),
          findsOneWidget);
      expect(find.text('What a real flow view would need'), findsOneWidget);
      expect(find.text('Admission timestamp per encounter'), findsOneWidget);
    });

    testWidgets('still renders the admission counts the dataset supports',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const PatientFlowScreen(),
        controller: controller,
      );

      expect(find.text('URGENT ADMISSION RECORDS'), findsOneWidget);
      expect(find.text('350'), findsWidgets);
      expect(find.text('250'), findsWidgets);
    });
  });

  group('operational reports', () {
    testWidgets('lists all six reports with their status', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationalReportsScreen(),
        controller: controller,
      );

      expect(find.text('Medication Distribution'), findsWidgets);
      expect(find.text('Allergy Coverage'), findsWidgets);
      expect(find.text('Cases by Hospital'), findsWidgets);
      expect(find.text('Available reports'), findsOneWidget);
    });

    testWidgets('uses tables and bars rather than a chart dependency',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationalReportsScreen(),
        controller: controller,
      );

      expect(find.byType(OpsTable), findsWidgets);
      expect(find.byType(OpsProgressBar), findsWidgets);
    });

    testWidgets('records an export request and says no file was produced',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OperationalReportsScreen(),
        controller: controller,
      );

      await tester.tap(find.text('Request export'));
      await tester.pumpAndSettle();

      expect(
        controller.auditEvents.first.action,
        OpsAuditAction.reportExportRequested,
      );
      expect(find.textContaining('No file was produced'), findsOneWidget);
    });
  });

  group('compliance', () {
    testWidgets('summarises emergency access and its justification',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const ComplianceScreen(),
        controller: controller,
      );

      // The KPI label and the per-staff table column share this label.
      expect(find.text('EMERGENCY ACCESS'), findsNWidgets(2));
      expect(find.text('GRANTS WITHOUT REASON'), findsOneWidget);
      expect(find.text('Emergency access review'), findsOneWidget);
      expect(
        find.text('Unconscious patient, no consent obtainable.'),
        findsOneWidget,
      );
    });

    testWidgets('shows masked patient references and no CNIC', (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const ComplianceScreen(),
        controller: controller,
      );

      expect(find.text('PAT-REF-****0001'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              RegExp(r'\d{5}-\d{7}-\d').hasMatch(widget.data ?? ''),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the clean state when no emergency access exists',
        (tester) async {
      final controller = buildTestController(
        audit: InMemoryAuditRepository(),
      );
      await pumpDesktop(
        tester,
        const ComplianceScreen(),
        controller: controller,
      );

      expect(find.text('No emergency access to review'), findsOneWidget);
    });

    testWidgets('states that the backend remains the security boundary',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const ComplianceScreen(),
        controller: controller,
      );

      expect(
        find.textContaining('backend remains the security boundary'),
        findsOneWidget,
      );
    });
  });

  group('audit trail', () {
    testWidgets('renders the log newest first with UTC timestamps',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const AuditTrailScreen(),
        controller: controller,
      );

      expect(find.text('Audit events'), findsOneWidget);
      expect(find.text('2026-03-14 09:30 UTC'), findsWidgets);
      expect(find.text('Session started'), findsOneWidget);
    });

    testWidgets('filtering narrows the log to the chosen scope',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const AuditTrailScreen(),
        controller: controller,
      );

      expect(find.text('Dashboard viewed'), findsOneWidget);

      await tester.tap(find.text('Emergency access'));
      await tester.pumpAndSettle();

      expect(find.text('Break-glass access granted'), findsOneWidget);
      expect(find.text('Dashboard viewed'), findsNothing);
      expect(find.text('EMERGENCY'), findsWidgets);
    });

    testWidgets('shows the empty state when a filter matches nothing',
        (tester) async {
      final controller = buildTestController(
        audit: InMemoryAuditRepository(),
      );
      await pumpDesktop(
        tester,
        const AuditTrailScreen(),
        controller: controller,
      );

      await tester.tap(find.text('Emergency access'));
      await tester.pumpAndSettle();

      expect(find.text('No audit events'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('reports the hospital, environment and identity',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OpsSettingsScreen(),
        controller: controller,
      );

      expect(find.text('HOSPITAL ID'), findsOneWidget);
      expect(find.text('HOSP-001'), findsWidgets);
      expect(find.text('ENVIRONMENT'), findsWidgets);
      expect(find.text('FIREBASE UID'), findsOneWidget);
      expect(find.text('DEMO-ADMIN-UID'), findsOneWidget);
      expect(find.text('Hospital Administrator'), findsWidgets);
    });

    testWidgets('names every data source and whether it is demo',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OpsSettingsScreen(),
        controller: controller,
      );

      expect(find.text('GET /api/stats'), findsOneWidget);
      expect(find.text('GET /api/dashboard/critical'), findsOneWidget);
      expect(find.text('DemoOccupancyRepository'), findsOneWidget);
      expect(find.text('DemoHandoverRepository'), findsOneWidget);
      expect(find.text('InMemoryAuditRepository'), findsOneWidget);
    });

    testWidgets('states that no second authentication system was added',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OpsSettingsScreen(),
        controller: controller,
      );

      expect(
        find.textContaining('adds no second authentication system'),
        findsOneWidget,
      );
    });

    testWidgets('lists configuration placeholders as unavailable',
        (tester) async {
      final controller = buildTestController();
      await pumpDesktop(
        tester,
        const OpsSettingsScreen(),
        controller: controller,
      );

      expect(find.text('Configuration placeholders'), findsOneWidget);
      expect(find.text('A bed-management or ADT system'), findsOneWidget);
      expect(
        find.text('SSE, WebSocket or a message broker'),
        findsOneWidget,
      );
    });
  });
}
