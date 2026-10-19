import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ministry_dashboard/src/admin/admin_audit_settings_screen.dart';
import 'package:ministry_dashboard/src/admin/admin_fleet_screen.dart';
import 'package:ministry_dashboard/src/admin/admin_navigation.dart';
import 'package:ministry_dashboard/src/admin/admin_hospital_registry_screen.dart';
import 'package:ministry_dashboard/src/admin/admin_overview_screen.dart';
import 'package:ministry_dashboard/src/admin/admin_shell.dart';
import 'package:ministry_dashboard/src/admin/roles_permissions_screen.dart';
import 'package:ministry_dashboard/src/admin/user_verification_screen.dart';
import 'package:ministry_dashboard/src/app.dart';
import 'package:ministry_dashboard/src/data/analyst_identity.dart';
import 'package:ministry_dashboard/src/data/demo_federation_repository.dart';
import 'package:ministry_dashboard/src/data/geography.dart';
import 'package:ministry_dashboard/src/data/hospital_aggregate_models.dart';
import 'package:ministry_dashboard/src/data/governance_models.dart';
import 'package:ministry_dashboard/src/data/national_models.dart';
import 'package:ministry_dashboard/src/navigation/national_navigation.dart';
import 'package:ministry_dashboard/src/screens/emergency_map_screen.dart';
import 'package:ministry_dashboard/src/screens/emergency_trends_screen.dart';
import 'package:ministry_dashboard/src/screens/federation_screen.dart';
import 'package:ministry_dashboard/src/screens/governance_screen.dart';
import 'package:ministry_dashboard/src/screens/health_indicators_screen.dart';
import 'package:ministry_dashboard/src/screens/hospital_network_screen.dart';
import 'package:ministry_dashboard/src/screens/national_overview_screen.dart';
import 'package:ministry_dashboard/src/screens/national_reports_screen.dart';
import 'package:ministry_dashboard/src/screens/national_settings_screen.dart';
import 'package:ministry_dashboard/src/screens/national_shell.dart';
import 'package:ministry_dashboard/src/state/national_scope.dart';
import 'package:nemras_design/nemras_design.dart';
import 'package:nemras_layout/nemras_layout.dart';

import 'support/fake_repositories.dart';
import 'support/pump.dart';

void main() {
  group('application boot', () {
    testWidgets('boots into the national overview', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(MinistryDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(find.text('National Overview'), findsWidgets);
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
    });

    testWidgets('boots with a sidebar of eight destinations', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();

      for (final item in NationalNavigation.sidebar.items) {
        expect(find.text(item.label), findsWidgets, reason: item.label);
      }
    });

    testWidgets('bootstraps the controller on first build', (tester) async {
      final national = FakeNationalRepository();
      final controller = buildTestController(national: national);
      addTearDown(controller.dispose);

      await tester.pumpWidget(MinistryDashboardApp(controller: controller));
      await tester.pumpAndSettle();

      expect(controller.isBootstrapped, isTrue);
      expect(national.snapshotCalls, 1);
    });
  });

  group('navigation', () {
    testWidgets('selecting a destination swaps the screen', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Federation').last);
      await tester.pumpAndSettle();

      expect(find.byType(FederationScreen), findsOneWidget);
      expect(find.byType(NationalOverviewScreen), findsNothing);
    });

    testWidgets('each destination renders its own screen', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      final expected = <int, Type>{
        NationalNavigation.overviewIndex: NationalOverviewScreen,
        NationalNavigation.emergencyTrendsIndex: EmergencyTrendsScreen,
        NationalNavigation.healthIndicatorsIndex: HealthIndicatorsScreen,
        NationalNavigation.hospitalNetworkIndex: HospitalNetworkScreen,
        NationalNavigation.federationIndex: FederationScreen,
        NationalNavigation.reportsIndex: NationalReportsScreen,
        NationalNavigation.governanceIndex: GovernanceScreen,
        NationalNavigation.settingsIndex: NationalSettingsScreen,
      };

      for (final entry in expected.entries) {
        await pumpDesktop(
          tester,
          controller,
          // Keyed per index: without a distinct key, re-pumping the same
          // widget type reuses the shell's State and the new initialIndex is
          // ignored, so the loop would only ever assert the first screen.
          NationalShell(key: ValueKey<int>(entry.key), initialIndex: entry.key),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(entry.value),
          findsOneWidget,
          reason: 'index ${entry.key}',
        );
      }
    });

    testWidgets('the router resolves each central route', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      final routes = <String, Type>{
        NemrasRouteNames.centralNationalOverview: NationalOverviewScreen,
        NemrasRouteNames.centralEmergencyTrends: EmergencyTrendsScreen,
        NemrasRouteNames.centralHealthIndicators: HealthIndicatorsScreen,
        NemrasRouteNames.centralHospitalNetwork: HospitalNetworkScreen,
        NemrasRouteNames.centralFederation: FederationScreen,
        NemrasRouteNames.centralReports: NationalReportsScreen,
        NemrasRouteNames.centralGovernance: GovernanceScreen,
        NemrasRouteNames.centralSettings: NationalSettingsScreen,
      };

      for (final entry in routes.entries) {
        await pumpRoute(
          tester,
          controller,
          entry.key,
          onGenerateRoute: NationalRouter.onGenerateRoute,
        );
        await tester.pumpAndSettle();

        expect(find.byType(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('an unknown route lands on the overview', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await pumpRoute(
        tester,
        controller,
        '/central/does-not-exist',
        onGenerateRoute: NationalRouter.onGenerateRoute,
      );
      await tester.pumpAndSettle();

      expect(find.byType(NationalOverviewScreen), findsOneWidget);
    });
  });

  group('status strip', () {
    testWidgets('shows identity, status, period and freshness',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalStatusStrip());
      await tester.pumpAndSettle();

      expect(find.text('MINISTRY-001'), findsOneWidget);
      expect(find.text('ANALYST-001'), findsOneWidget);
      expect(find.text('Full dataset'), findsOneWidget);
      expect(find.text('AGGREGATE API REACHABLE'), findsOneWidget);
      expect(find.text('2026-05-20 11:15 UTC'), findsOneWidget);
      expect(find.text('DEMO'), findsWidgets);
    });

    testWidgets('reports no freshness timestamp before a load',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      await pumpDesktop(tester, controller, const NationalStatusStrip());
      await tester.pumpAndSettle();

      expect(find.text(kNotAvailable), findsWidgets);
      expect(find.text('NOT CHECKED'), findsOneWidget);
    });

    testWidgets('reports an unreachable source', (tester) async {
      final controller = buildTestController(
        national: const FailingNationalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalStatusStrip());
      await tester.pumpAndSettle();

      expect(find.text('AGGREGATE API UNREACHABLE'), findsOneWidget);
    });
  });

  group('national overview', () {
    testWidgets('shows the six briefed KPIs with provenance badges',
        (tester) async {
      final controller = buildTestController(
        national: FakeNationalRepository(total: 1000),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pumpAndSettle();

      for (final metric in controller.overviewKpis) {
        expect(
          find.text(metric.label.toUpperCase()),
          findsOneWidget,
          reason: metric.label,
        );
      }
      expect(find.text('DATASET-DERIVED'), findsWidgets);
    });

    testWidgets('states that no geographic breakdown is possible',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pumpAndSettle();

      expect(find.text(GeographicAvailability.notice), findsOneWidget);
      expect(find.text('NOT AVAILABLE'), findsWidgets);
    });

    testWidgets('shows a loading state while the aggregates load',
        (tester) async {
      final controller = buildTestController(
        national: PendingNationalRepository(),
      );
      addTearDown(controller.dispose);
      controller.refreshSnapshot(recordAudit: false);

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pump();

      expect(find.text('Reading national aggregates'), findsOneWidget);
    });

    testWidgets('shows an error state with a retry on failure',
        (tester) async {
      final controller = buildTestController(
        national: const FailingNationalRepository(message: 'backend down'),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pumpAndSettle();

      expect(find.text('National aggregates unavailable'), findsWidgets);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('shows the demo federation summary as simulated',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pumpAndSettle();

      expect(find.text('FEDERATED NODES'), findsOneWidget);
      expect(find.text('5 / 8'), findsOneWidget);
      expect(find.text('DEMO'), findsWidgets);
    });

    testWidgets('the operations headline is unavailable and actions disabled',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalOverviewScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('National Emergency Operations Command'),
        findsOneWidget,
      );
      expect(find.textContaining('PROTOTYPE DATA'), findsOneWidget);
      for (final metric in controller.operationsKpis) {
        expect(metric.isAvailable, isFalse, reason: metric.label);
        expect(find.text(metric.label.toUpperCase()), findsOneWidget);
      }
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Full dataset'))
            .selected,
        isTrue,
      );
      for (final window in const <String>[
        'Past 24 hours',
        'Past 7 days',
        'Past 30 days',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, window))
              .onSelected,
          isNull,
          reason: window,
        );
      }
      expect(
        find.text('Not available. No endpoint groups emergency records by '
            'time, so no inflow curve or peak is drawn.'),
        findsOneWidget,
      );
      for (final label in const <String>[
        'Coordinating a diversion is not available',
        'Confirming ICU beds is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }
      expect(find.textContaining('M-4'), findsNothing);
      expect(find.textContaining('Karachi'), findsNothing);
      expect(find.textContaining('1,284'), findsNothing);
      expect(find.textContaining('Kafka'), findsNothing);
    });

    testWidgets('command links open the related destinations', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();

      final scroll = find
          .descendant(
            of: find.byType(NationalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open emergency trends'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open emergency trends'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyTrendsScreen), findsOneWidget);

      await tester.tap(find.text('National Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(NationalOverviewScreen), findsOneWidget);

      final back = find
          .descendant(
            of: find.byType(NationalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open audit / governance'),
        300,
        scrollable: back,
      );
      await tester.tap(find.text('Open audit / governance'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceScreen), findsOneWidget);
    });

    testWidgets('the command view fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: NationalOverviewScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Confirming ICU beds is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('emergency map', () {
    testWidgets('opens from the overview and records no incident',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();

      final scroll = find
          .descendant(
            of: find.byType(NationalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open emergency map'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open emergency map'));
      await tester.pumpAndSettle();

      expect(find.byType(EmergencyMapScreen), findsOneWidget);
      expect(find.text(GeographicAvailability.notice), findsOneWidget);
      expect(find.text('No incident is selected. NEMRAS holds no live '
          'dispatch record.'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.text('Not available'), findsWidgets);
      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('PK-1122'), findsNothing);
      expect(find.textContaining('AMB-37'), findsNothing);
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(find.textContaining(region), findsNothing, reason: region);
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Opening an audit record is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Route diversion is not available',
        'Exporting a log is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }
      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isFalse,
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyMapScreen), findsNothing);
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
    });

    testWidgets('the map page fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: EmergencyMapScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Exporting a log is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('emergency trends', () {
    testWidgets('states the trend is unavailable rather than drawing one',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const EmergencyTrendsScreen());
      await tester.pumpAndSettle();

      expect(find.text(kTrendUnavailable), findsOneWidget);
    });

    testWidgets('shows the emergency and non-emergency split', (tester) async {
      final controller = buildTestController(
        national: FakeNationalRepository(total: 1000),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const EmergencyTrendsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Emergency vs Non-Emergency'), findsOneWidget);
      expect(find.text('Non-emergency'), findsOneWidget);
      expect(find.text('25.0%'), findsWidgets);
    });

    testWidgets('labels the highest-risk slice as a sample', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const EmergencyTrendsScreen());
      await tester.pumpAndSettle();

      expect(find.text('DATASET-SAMPLE'), findsWidgets);
      expect(find.text('Triage in Highest-Risk Slice'), findsOneWidget);
    });

    testWidgets('shows an error state on failure', (tester) async {
      final controller = buildTestController(
        national: const FailingNationalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const EmergencyTrendsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Emergency aggregates unavailable'), findsOneWidget);
    });

    testWidgets('opens from the command page and returns', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();

      final scroll = find
          .descendant(
            of: find.byType(NationalOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open emergency trends'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open emergency trends'));
      await tester.pumpAndSettle();

      expect(find.byType(EmergencyTrendsScreen), findsOneWidget);
      expect(find.textContaining('SAMPLE DATA'), findsOneWidget);
      expect(find.text(kTrendUnavailable), findsOneWidget);
      expect(
        find.text('Provincial response times are not available'),
        findsOneWidget,
      );
      expect(find.text('EMERGENCY RECORDS'), findsOneWidget);
      for (final metric in controller.trendOperationalKpis) {
        expect(metric.isAvailable, isFalse);
        expect(find.text(metric.label.toUpperCase()), findsOneWidget);
      }
      for (final window in const <String>[
        'Today',
        'Last 7 days',
        'Last 30 days',
        'Response times',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, window))
              .onSelected,
          isNull,
          reason: window,
        );
      }
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, 'Full dataset'),
            )
            .selected,
        isTrue,
      );
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(find.textContaining(region), findsNothing, reason: region);
      }

      final trendsScroll = find
          .descendant(
            of: find.byType(EmergencyTrendsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Exporting CSV is not available'),
        300,
        scrollable: trendsScroll,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(
                OutlinedButton,
                'Exporting CSV is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('Emergency vs Non-Emergency'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Back to command'),
        -300,
        scrollable: trendsScroll,
      );
      await tester.tap(find.text('Back to command'));
      await tester.pumpAndSettle();
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
      expect(find.byType(EmergencyTrendsScreen), findsNothing);
      for (final item in NationalNavigation.sidebar.items) {
        expect(find.text(item.label), findsWidgets, reason: item.label);
      }
    });

    testWidgets('an empty dataset still draws no trend', (tester) async {
      final controller = buildTestController(
        national: const EmptyNationalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const EmergencyTrendsScreen());
      await tester.pumpAndSettle();

      expect(find.text(kTrendUnavailable), findsOneWidget);
      expect(find.text('Not available'), findsWidgets);
      expect(find.textContaining('8.4'), findsNothing);
      expect(find.textContaining('Code Red'), findsNothing);
    });

    testWidgets('trends fit phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: EmergencyTrendsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Exporting CSV is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('health indicators', () {
    testWidgets('warns that Risk_Score is not a probability', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HealthIndicatorsScreen());
      await tester.pumpAndSettle();

      expect(find.text('RISK_SCORE IS NOT A PROBABILITY'), findsOneWidget);
    });

    testWidgets('never renders a risk percentage', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HealthIndicatorsScreen());
      await tester.pumpAndSettle();

      final risky = RegExp(r'\d+(\.\d+)?%\s*risk', caseSensitive: false);
      for (final text in renderedStrings(tester)) {
        expect(risky.hasMatch(text), isFalse, reason: text);
      }
    });

    testWidgets('covers all eight briefed dataset fields', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HealthIndicatorsScreen());
      await tester.pumpAndSettle();

      for (final field in <String>[
        'Medical_Condition',
        'Triage_Level',
        'Risk_Score',
        'Chronic_Condition',
        'Drug_Interaction_Risk',
        'Admission_Type',
        'Gender',
        'Age',
      ]) {
        expect(find.text(field), findsOneWidget, reason: field);
      }
    });

    testWidgets('reports gender and age bands as unavailable',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HealthIndicatorsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Gender Distribution'), findsWidgets);
      expect(find.text('Age Distribution'), findsWidgets);
      expect(find.text('NOT AVAILABLE'), findsWidgets);
    });

    testWidgets('surveillance headlines and directives are unavailable',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Health Indicators').last);
      await tester.pumpAndSettle();

      expect(find.byType(HealthIndicatorsScreen), findsOneWidget);
      expect(find.textContaining('AGGREGATE DATA ONLY'), findsOneWidget);
      expect(find.text(kTrendUnavailable), findsOneWidget);
      for (final headline in const <String>[
        'CARDIOVASCULAR SURGE',
        'ROAD-TRAFFIC SHARE',
        'RESPIRATORY ALERTS',
        'THERMAL STRESS',
      ]) {
        expect(find.text(headline), findsOneWidget, reason: headline);
      }
      expect(find.text('Medical Condition'), findsOneWidget);
      for (final control in const <String>[
        'Rolling 12 months',
        'Category filter not available',
        'Location filter not available',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, control))
              .onSelected,
          isNull,
          reason: control,
        );
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Exporting a bulletin is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Lahore'), findsNothing);
      expect(find.textContaining('Jacobabad'), findsNothing);
      expect(find.textContaining('°C'), findsNothing);

      final scroll = find
          .descendant(
            of: find.byType(HealthIndicatorsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Issuing an action directive is not available'),
        400,
        scrollable: scroll,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(
                OutlinedButton,
                'Issuing an action directive is not available',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.scrollUntilVisible(
        find.text('Back to command'),
        -400,
        scrollable: scroll,
      );
      await tester.tap(find.text('Back to command'));
      await tester.pumpAndSettle();
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
    });

    testWidgets('population health fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: HealthIndicatorsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Issuing an action directive is not available'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('hospital network', () {
    testWidgets('states the exact aggregation-unavailable phrase',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HospitalNetworkScreen());
      await tester.pumpAndSettle();

      expect(find.text(kHospitalAggregationUnavailable), findsOneWidget);
    });

    testWidgets('lists the location inferences it refuses to make',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HospitalNetworkScreen());
      await tester.pumpAndSettle();

      for (final entry in GeographicAvailability.refusedInferences) {
        expect(find.text(entry.source), findsOneWidget, reason: entry.source);
      }
    });

    testWidgets('renders facilities when an endpoint supplies them',
        (tester) async {
      final controller = buildTestController(
        hospitals: const FakeHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HospitalNetworkScreen());
      await tester.pumpAndSettle();

      expect(find.text('Test Facility Alpha'), findsOneWidget);
      expect(find.text('12,400'), findsOneWidget);
      expect(find.text(kHospitalAggregationUnavailable), findsNothing);
    });

    testWidgets('shows an empty state when the endpoint returns no rows',
        (tester) async {
      final controller = buildTestController(
        hospitals: const EmptyHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HospitalNetworkScreen());
      await tester.pumpAndSettle();

      expect(find.text('No facilities reported'), findsOneWidget);
    });

    testWidgets('shows an error state when the source fails', (tester) async {
      final controller = buildTestController(
        hospitals: const FailingHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const HospitalNetworkScreen());
      await tester.pumpAndSettle();

      expect(find.text('Hospital aggregation failed'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('opens from the sidebar with capacity marked unavailable',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hospital Network').last);
      await tester.pumpAndSettle();

      expect(find.byType(HospitalNetworkScreen), findsOneWidget);
      expect(find.textContaining('SIMULATED VIEW'), findsOneWidget);
      expect(find.text(kHospitalAggregationUnavailable), findsOneWidget);
      for (final metric in controller.networkCapacityKpis) {
        expect(metric.isAvailable, isFalse);
        expect(find.text(metric.label.toUpperCase()), findsOneWidget);
      }
      expect(find.text('Not recorded'), findsWidgets);
      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isFalse,
      );
      for (final filter in const <String>[
        'Province filter not available',
        'Designation filter not available',
        'Capability filter not available',
        'Status filter not available',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, filter))
              .onSelected,
          isNull,
          reason: filter,
        );
      }
      expect(find.textContaining('Nishtar'), findsNothing);
      expect(find.textContaining('18,900'), findsNothing);
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(find.textContaining(region), findsNothing, reason: region);
      }

      final scroll = find
          .descendant(
            of: find.byType(HospitalNetworkScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Broadcasting an override is not available'),
        400,
        scrollable: scroll,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Declaring a trauma surge is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Transmitting a transfer dossier is not available',
        'Broadcasting an override is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }

      await tester.scrollUntilVisible(
        find.text('Back to command'),
        -400,
        scrollable: scroll,
      );
      await tester.tap(find.text('Back to command'));
      await tester.pumpAndSettle();
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
      for (final item in NationalNavigation.sidebar.items) {
        expect(find.text(item.label), findsWidgets, reason: item.label);
      }
    });

    testWidgets('the network page fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: HospitalNetworkScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Broadcasting an override is not available'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('federation', () {
    testWidgets('marks every node row as DEMO', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      final nodeCount = controller.federation!.nodes.length;

      // One chip per row, plus the two section headers and the page notice
      // chips, so at least one per node.
      expect(
        find.text('DEMO'),
        findsAtLeast(nodeCount),
      );
    });

    testWidgets('shows node and hospital identifiers, not hospital names',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      expect(find.text('NMR-001'), findsOneWidget);
      expect(find.text('HOSP-001'), findsOneWidget);
      expect(find.text('NMR-008'), findsOneWidget);
    });

    testWidgets('never shows a latency figure', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      expect(find.text('NATIONAL P95 LATENCY'), findsOneWidget);
      final latencyPattern = RegExp(r'\d+\s*ms', caseSensitive: false);
      for (final text in renderedStrings(tester)) {
        expect(latencyPattern.hasMatch(text), isFalse, reason: text);
      }
    });

    testWidgets('omits any province column or label', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      final rendered = renderedStrings(tester).join(' ');
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(rendered.contains(region), isFalse, reason: region);
      }
    });

    testWidgets('shows an empty state with no nodes', (tester) async {
      final controller = buildTestController(
        federation: const EmptyFederationRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      expect(find.text('No federated nodes'), findsOneWidget);
    });

    testWidgets('shows an error state when the provider fails',
        (tester) async {
      final controller = buildTestController(
        federation: const FailingFederationRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const FederationScreen());
      await tester.pumpAndSettle();

      expect(find.text('Federation state unavailable'), findsOneWidget);
    });
  });

  group('reports', () {
    testWidgets('lists the eight briefed reports in order', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalReportsScreen());
      await tester.pumpAndSettle();

      for (var i = 0; i < controller.nationalReports.length; i++) {
        final title = controller.nationalReports[i].title;
        expect(
          find.text('Report ${i + 1} — $title'),
          findsOneWidget,
          reason: title,
        );
      }
    });

    testWidgets('states how many reports can be produced', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalReportsScreen());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('6 of 8 requested reports'),
        findsOneWidget,
      );
    });

    testWidgets('an export request is audited rather than producing a file',
        (tester) async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalReportsScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Record export request'));
      await tester.pumpAndSettle();

      expect(
        controller.auditEvents.first.action,
        NationalAuditAction.nationalReportExportRequested,
      );
    });

    testWidgets('shows an error state on failure', (tester) async {
      final controller = buildTestController(
        national: const FailingNationalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalReportsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Reports unavailable'), findsOneWidget);
    });

    testWidgets('the incident archive is unavailable and returns',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();

      expect(find.byType(NationalReportsScreen), findsOneWidget);
      expect(find.textContaining('DATASET REPORTS'), findsOneWidget);
      expect(find.textContaining('6 of 8 requested reports'), findsOneWidget);
      for (final metric in controller.incidentArchiveKpis) {
        expect(metric.isAvailable, isFalse);
        expect(find.text(metric.label.toUpperCase()), findsOneWidget);
      }
      expect(find.text('No live incident is recorded. The tables above are '
          'dataset category counts, not an incident log.'), findsOneWidget);
      expect(find.textContaining('PK-1122'), findsNothing);
      expect(find.textContaining('Nishtar'), findsNothing);
      expect(find.textContaining('Code Red'), findsNothing);
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(find.textContaining(region), findsNothing, reason: region);
      }

      final scroll = find
          .descendant(
            of: find.byType(NationalReportsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Closing an incident is not available'),
        400,
        scrollable: scroll,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Generating a statutory brief is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Exporting a query to CSV is not available',
        'Printing a legal dossier is not available',
        'Flagging to a director is not available',
        'Closing an incident is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
          reason: label,
        );
      }

      await tester.scrollUntilVisible(
        find.text('Back to command'),
        -400,
        scrollable: scroll,
      );
      await tester.tap(find.text('Back to command'));
      await tester.pumpAndSettle();
      expect(find.byType(NationalOverviewScreen), findsOneWidget);
    });

    testWidgets('incident reports fit phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: NationalReportsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Closing an incident is not available'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('audit and governance', () {
    testWidgets('shows the audit trail with categories and actors',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const GovernanceScreen());
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY'), findsWidgets);
      expect(find.text('STAFF-001'), findsOneWidget);
      expect(find.text('Break-glass access granted'), findsOneWidget);
      expect(find.text('2026-05-20 11:05 UTC'), findsOneWidget);
    });

    testWidgets('filtering narrows the table', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const GovernanceScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Federation'));
      await tester.pumpAndSettle();

      expect(find.text('Federation synchronisation failed'), findsOneWidget);
      expect(find.text('Break-glass access granted'), findsNothing);
    });

    testWidgets('shows an empty state when a filter matches nothing',
        (tester) async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);
      await controller.bootstrap();
      await controller.setGovernanceFilter(GovernanceFilter.patientAccess);

      await pumpDesktop(tester, controller, const GovernanceScreen());
      await tester.pumpAndSettle();

      expect(find.text('No events for this filter'), findsOneWidget);
    });

    testWidgets('shows an error state when the audit source fails',
        (tester) async {
      final controller = buildTestController(
        audit: const FailingNationalAuditRepository(),
      );
      addTearDown(controller.dispose);

      // bootstrap would surface the throw; the screen is driven from the
      // failed state the controller records.
      await controller.refreshAudit();
      await pumpDesktop(tester, controller, const GovernanceScreen());
      await tester.pumpAndSettle();

      expect(find.text('Audit trail unavailable'), findsOneWidget);
      expect(find.textContaining('The audit source failed.'), findsOneWidget);
    });

    testWidgets('raises a review due status when break-glass occurred',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const GovernanceScreen());
      await tester.pumpAndSettle();

      expect(find.text('GOVERNANCE STATUS'), findsOneWidget);
      expect(find.text('REVIEW DUE'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('discloses the demo identity and the endpoints read',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('ANALYST-001'), findsOneWidget);
      expect(find.text('MINISTRY-001'), findsOneWidget);
      expect(find.text('DEMO-ANALYST-UID'), findsOneWidget);
      expect(find.text('GET /api/stats'), findsOneWidget);
      expect(find.text('GET /api/dashboard/critical'), findsOneWidget);
      expect(find.text('GET /health'), findsOneWidget);
    });

    testWidgets('explains all four provenance badges', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('DATASET-DERIVED'), findsWidgets);
      expect(find.text('DATASET-SAMPLE'), findsWidgets);
      expect(find.text('DEMO'), findsWidgets);
      expect(find.text('NOT AVAILABLE'), findsWidgets);
    });
  });

  group('administration console', () {
    testWidgets('settings opens the overview and back returns', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const NationalShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      final settingsScroll = find
          .descendant(
            of: find.byType(NationalSettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open administration console'),
        300,
        scrollable: settingsScroll,
      );
      await tester.tap(find.text('Open administration console'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
      expect(find.textContaining('DEMO PROTOTYPE'), findsOneWidget);
      expect(find.text('No verification dossiers are recorded.'), findsOneWidget);
      expect(find.text('PENDING VERIFICATION'), findsOneWidget);
      expect(find.text('REGISTERED RESPONDERS'), findsOneWidget);
      expect(
        find.text('BREAK-GLASS EVENTS IN SESSION AUDIT'),
        findsOneWidget,
      );
      expect(find.textContaining('Farooq'), findsNothing);
      expect(find.textContaining('36302'), findsNothing);
      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(find.textContaining(region), findsNothing, reason: region);
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Batch verification is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(
                OutlinedButton,
                'Filtering the queue is not available',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('User Verification').last);
      await tester.pumpAndSettle();
      expect(find.byType(UserVerificationScreen), findsOneWidget);
      expect(
        find.text('No verification dossiers are recorded.'),
        findsWidgets,
      );
      expect(find.text('No applicant is selected.'), findsOneWidget);
      expect(find.textContaining('Kashaf'), findsNothing);
      expect(find.textContaining('Farooq'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Approving credentials is not available',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Admin Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);

      await tester.tap(find.text('Back to national dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminShell), findsNothing);
      expect(find.byType(NationalSettingsScreen), findsOneWidget);
      for (final item in NationalNavigation.sidebar.items) {
        expect(find.text(item.label), findsWidgets, reason: item.label);
      }
      expect(AdminNavigation.sidebar.items, hasLength(6));
    });

    testWidgets('the national audit opens from the overview and returns',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const AdminShell());
      await tester.pumpAndSettle();

      final scroll = find
          .descendant(
            of: find.byType(AdminOverviewScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open national audit'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open national audit'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
    });

    testWidgets('roles shows the signed-in role and grants nothing',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const AdminShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Roles & Permissions').last);
      await tester.pumpAndSettle();

      expect(find.byType(RolesPermissionsScreen), findsOneWidget);
      expect(find.textContaining('DEMO POLICY VIEW'), findsOneWidget);
      expect(find.textContaining('Demo Ministry Analyst'), findsOneWidget);
      expect(find.textContaining('ANALYST-001'), findsOneWidget);
      expect(
        find.text('Aggregate only. No patient-level access.'),
        findsOneWidget,
      );
      for (final role in AnalystRole.values) {
        final chip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, role.label),
        );
        expect(chip.onSelected, isNull, reason: role.label);
        expect(chip.selected, role == controller.analyst.role);
      }
      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.value, isFalse);
        expect(tile.onChanged, isNull);
      }
      expect(
        find.text('Not available. Past audit events cannot be edited or '
            'deleted.'),
        findsOneWidget,
      );
      expect(find.textContaining('642'), findsNothing);
      expect(find.textContaining('ISO'), findsNothing);

      final scroll = find
          .descendant(
            of: find.byType(RolesPermissionsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Saving a permission schema is not available'),
        300,
        scrollable: scroll,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Saving a permission schema is not available',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.text('Admin Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
      expect(find.byType(NationalShell), findsNothing);
    });

    testWidgets('roles fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: RolesPermissionsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Saving a permission schema is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('administration fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: AdminOverviewScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Fleet registry is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: UserVerificationScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Rejecting an application is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('hospital registry lists only supplied aggregates',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const AdminShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hospital Network').last);
      await tester.pumpAndSettle();

      expect(find.byType(AdminHospitalRegistryScreen), findsOneWidget);
      expect(find.textContaining('NO LIVE FACILITY DIRECTORY'), findsOneWidget);
      expect(find.text(kHospitalAggregationUnavailable), findsOneWidget);
      expect(find.text('No facility directory is recorded.'), findsOneWidget);
      expect(find.text('No facility is selected.'), findsOneWidget);
      expect(find.text('Nishtar'), findsNothing);
      expect(find.textContaining('Punjab'), findsNothing);
      for (final label in const <String>[
        'Territory filter not available',
        'Tier filter not available',
        'Status filter not available',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
              .onSelected,
          isNull,
        );
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Updating facility credentials is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Initiating a surge diversion is not available',
        'Onboarding a facility is not available',
        'Decommissioning a facility is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }

      await tester.tap(find.text('Open national hospital network'));
      await tester.pumpAndSettle();
      expect(find.byType(HospitalNetworkScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminHospitalRegistryScreen), findsOneWidget);

      await tester.tap(find.text('Admin Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
    });

    testWidgets('hospital registry shows an error and empty endpoint',
        (tester) async {
      final failing = buildTestController(
        hospitals: const FailingHospitalAggregateRepository(),
      );
      addTearDown(failing.dispose);
      await failing.bootstrap();
      await pumpDesktop(tester, failing, const AdminHospitalRegistryScreen());
      await tester.pumpAndSettle();
      expect(find.text('Facility list unavailable'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);

      final empty = buildTestController(
        hospitals: const EmptyHospitalAggregateRepository(),
      );
      addTearDown(empty.dispose);
      await empty.bootstrap();
      await pumpDesktop(tester, empty, const AdminHospitalRegistryScreen());
      await tester.pumpAndSettle();
      expect(find.text('No facility directory is recorded.'), findsOneWidget);
      expect(find.textContaining('487'), findsNothing);
    });

    testWidgets('hospital registry shows supplied facility names only',
        (tester) async {
      final controller = buildTestController(
        hospitals: const FakeHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();
      await pumpDesktop(
        tester,
        controller,
        const AdminHospitalRegistryScreen(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Facility Alpha'), findsOneWidget);
      expect(find.textContaining('12400 dataset records'), findsOneWidget);
      expect(find.textContaining('beds Not available'), findsWidgets);
      expect(find.text('Nishtar'), findsNothing);
    });

    testWidgets('hospital registry fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: AdminHospitalRegistryScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Decommissioning a facility is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('fleet registry records no personnel or vehicles',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const AdminShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Responders & Fleet').last);
      await tester.pumpAndSettle();

      expect(find.byType(AdminFleetScreen), findsOneWidget);
      expect(
        find.textContaining('NO RESPONDER OR FLEET REGISTRY'),
        findsOneWidget,
      );
      expect(find.textContaining('Demo Ministry Analyst'), findsOneWidget);
      expect(find.text('No personnel are recorded.'), findsOneWidget);
      expect(find.text('No vehicles are recorded.'), findsOneWidget);
      expect(find.text('No unit is selected.'), findsOneWidget);
      expect(find.text('Not recorded'), findsWidgets);
      expect(find.textContaining('Asad'), findsNothing);
      expect(find.textContaining('1122'), findsNothing);
      expect(find.textContaining('1,248'), findsNothing);
      expect(find.textContaining('AMB-'), findsNothing);

      for (final label in const <String>[
        'Personnel directory not available',
        'Vehicle registry not available',
        'Audit manifest not available',
        'Organisation filter not available',
        'Jurisdiction filter not available',
        'Duty-state filter not available',
      ]) {
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
              .onSelected,
          isNull,
        );
      }
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Updating a unit assignment is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Suspending a unit is not available',
        'Registering a vehicle or crew is not available',
        'Decommissioning a vehicle is not available',
        'Exporting a fleet manifest is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }

      final scroll = find
          .descendant(
            of: find.byType(AdminFleetScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open session audit'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open session audit'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminFleetScreen), findsOneWidget);

      await tester.tap(find.text('Admin Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
      expect(find.byType(AdminHospitalRegistryScreen), findsNothing);
    });

    testWidgets('fleet registry fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: AdminFleetScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Exporting a fleet manifest is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('audit settings shows the session trail and grants nothing',
        (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await pumpDesktop(tester, controller, const AdminShell());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Audit Logs & Settings').last);
      await tester.pumpAndSettle();

      expect(find.byType(AdminAuditSettingsScreen), findsOneWidget);
      expect(find.textContaining('DEMO SESSION AUDIT'), findsOneWidget);
      expect(find.text('Break-glass access granted'), findsOneWidget);
      expect(find.text('Aggregate data refreshed'), findsOneWidget);
      expect(find.textContaining('Farooq'), findsNothing);
      expect(find.textContaining('SHA-256'), findsNothing);
      expect(find.textContaining('1,435'), findsNothing);
      expect(find.textContaining('Punjab'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Emergency access'));
      await tester.pumpAndSettle();
      expect(find.text('Break-glass access granted'), findsOneWidget);
      expect(find.text('Aggregate data refreshed'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All events'));
      await tester.pumpAndSettle();
      expect(find.text('Aggregate data refreshed'), findsOneWidget);

      for (final tile in tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      )) {
        expect(tile.value, isFalse);
        expect(tile.onChanged, isNull);
      }
      expect(
        tester.widget<TextField>(find.byType(TextField)).enabled,
        isFalse,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Saving system policy is not available',
              ),
            )
            .onPressed,
        isNull,
      );
      for (final label in const <String>[
        'Verifying a certificate chain is not available',
        'Exporting an audit brief is not available',
      ]) {
        expect(
          tester
              .widget<OutlinedButton>(
                find.widgetWithText(OutlinedButton, label),
              )
              .onPressed,
          isNull,
        );
      }

      final scroll = find
          .descendant(
            of: find.byType(AdminAuditSettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Open national governance'),
        300,
        scrollable: scroll,
      );
      await tester.tap(find.text('Open national governance'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernanceScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminAuditSettingsScreen), findsOneWidget);

      await tester.tap(find.text('Hospital Network').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminHospitalRegistryScreen), findsOneWidget);
      await tester.tap(find.text('Admin Overview').last);
      await tester.pumpAndSettle();
      expect(find.byType(AdminOverviewScreen), findsOneWidget);
    });

    testWidgets('audit settings shows empty and error states', (tester) async {
      final empty = buildTestController(seedAudit: false);
      addTearDown(empty.dispose);
      await empty.bootstrap();
      await pumpDesktop(tester, empty, const AdminAuditSettingsScreen());
      await tester.pumpAndSettle();
      expect(find.text('Analyst session started'), findsOneWidget);
      expect(find.text('Break-glass access granted'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Federation'));
      await tester.pumpAndSettle();
      expect(
        find.text('No federation events are recorded.'),
        findsOneWidget,
      );

      final failing = buildTestController(
        audit: const FailingNationalAuditRepository(),
      );
      addTearDown(failing.dispose);
      await failing.bootstrap();
      await pumpDesktop(tester, failing, const AdminAuditSettingsScreen());
      await tester.pumpAndSettle();
      expect(find.text('Session audit unavailable'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    });

    testWidgets('audit settings fits phone widths', (tester) async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();
      addTearDown(tester.view.reset);

      for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: nemrasClinicalLightTheme(),
            home: NationalScope(
              controller: controller,
              child: const Scaffold(body: AdminAuditSettingsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Exporting an audit brief is not available'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('privacy sweep across every screen', () {
    /// Patterns that must never appear in the national UI.
    final cnic = RegExp(r'\b\d{5}-\d{7}-\d\b');
    final phone = RegExp(r'(\+92|\b03)\d{6,}');
    final email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

    final screens = <String, Widget>{
      'overview': const NationalOverviewScreen(),
      'emergency map': const EmergencyMapScreen(),
      'emergency trends': const EmergencyTrendsScreen(),
      'health indicators': const HealthIndicatorsScreen(),
      'hospital network': const HospitalNetworkScreen(),
      'federation': const FederationScreen(),
      'reports': const NationalReportsScreen(),
      'governance': const GovernanceScreen(),
      'settings': const NationalSettingsScreen(),
      'administration': const AdminOverviewScreen(),
      'user verification': const UserVerificationScreen(),
      'roles': const RolesPermissionsScreen(),
      'hospital registry': const AdminHospitalRegistryScreen(),
      'fleet': const AdminFleetScreen(),
      'audit settings': const AdminAuditSettingsScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} exposes no patient identifier',
          (tester) async {
        // The populated hospital repository is used so the facility table
        // renders too, which is the widest the UI ever gets.
        final controller = buildTestController(
          hospitals: const FakeHospitalAggregateRepository(),
        );
        addTearDown(controller.dispose);
        await controller.bootstrap();

        await pumpDesktop(tester, controller, entry.value);
        await tester.pumpAndSettle();

        for (final text in renderedStrings(tester)) {
          expect(cnic.hasMatch(text), isFalse, reason: 'CNIC in "$text"');
          expect(phone.hasMatch(text), isFalse, reason: 'phone in "$text"');
          expect(email.hasMatch(text), isFalse, reason: 'email in "$text"');
          expect(
            text.contains('Test Patient'),
            isFalse,
            reason: 'patient name in "$text"',
          );
        }
      });

      testWidgets('${entry.key} names no province', (tester) async {
        final controller = buildTestController(
          hospitals: const FakeHospitalAggregateRepository(),
        );
        addTearDown(controller.dispose);
        await controller.bootstrap();

        await pumpDesktop(tester, controller, entry.value);
        await tester.pumpAndSettle();

        final rendered = renderedStrings(tester).join(' ');
        for (final region in GeographicAvailability.forbiddenRegionLabels) {
          expect(
            rendered.contains(region),
            isFalse,
            reason: '$region on ${entry.key}',
          );
        }
      });
    }
  });
}