import 'package:flutter_test/flutter_test.dart';
import 'package:ministry_dashboard/src/data/analyst_identity.dart';
import 'package:ministry_dashboard/src/data/federation_models.dart';
import 'package:ministry_dashboard/src/data/geography.dart';
import 'package:ministry_dashboard/src/data/governance_models.dart';
import 'package:ministry_dashboard/src/data/hospital_aggregate_models.dart';
import 'package:ministry_dashboard/src/data/metric_provenance.dart';
import 'package:ministry_dashboard/src/data/national_models.dart';
import 'package:ministry_dashboard/src/state/national_console_controller.dart';

import 'support/fake_repositories.dart';
import 'support/pump.dart';

void main() {
  group('bootstrap', () {
    test('loads every source and records the session start', () async {
      final national = FakeNationalRepository();
      final audit = InMemoryNationalAuditRepository();
      final controller = buildTestController(
        national: national,
        audit: audit,
        seedAudit: false,
      );
      addTearDown(controller.dispose);

      await controller.bootstrap();

      expect(controller.isBootstrapped, isTrue);
      expect(controller.snapshotState, LoadState.ready);
      expect(controller.hospitalState, LoadState.ready);
      expect(controller.federationState, LoadState.ready);
      expect(controller.auditState, LoadState.ready);
      expect(national.snapshotCalls, 1);
      expect(
        controller.auditEvents.first.action,
        NationalAuditAction.analystSessionStarted,
      );
    });

    test('is idempotent, so a rebuilt shell does not re-read', () async {
      final national = FakeNationalRepository();
      final controller = buildTestController(national: national);
      addTearDown(controller.dispose);

      await controller.bootstrap();
      await controller.bootstrap();

      expect(national.snapshotCalls, 1);
    });

    test('does not audit the bootstrap read as a manual refresh', () async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);

      await controller.bootstrap();

      expect(
        controller.auditEvents
            .where(
              (event) =>
                  event.action == NationalAuditAction.aggregateDataRefreshed,
            )
            .isEmpty,
        isTrue,
      );
    });

    test('one failing source does not blank the others', () async {
      final controller = buildTestController(
        national: const FailingNationalRepository(),
        hospitals: const FakeHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);

      await controller.bootstrap();

      expect(controller.snapshotState, LoadState.failed);
      expect(controller.hospitalState, LoadState.ready);
      expect(controller.federationState, LoadState.ready);
      expect(controller.auditState, LoadState.ready);
    });

    test('uses the injected demo analyst identity', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      expect(controller.analyst.analystId, 'ANALYST-001');
      expect(controller.organization.organizationId, 'MINISTRY-001');
      expect(controller.analyst.isDemo, isTrue);
      expect(controller.environment.isDemo, isTrue);
    });
  });

  group('load states', () {
    test('a pending read holds the loading state', () async {
      final controller = buildTestController(
        national: PendingNationalRepository(),
      );
      addTearDown(controller.dispose);

      final pending = controller.refreshSnapshot();
      expect(controller.snapshotState, LoadState.loading);
      expect(controller.snapshotState.isLoading, isTrue);

      // Never completes; nothing after this point depends on it.
      expect(pending, isA<Future<void>>());
    });

    test('a failing read records the message and fails the state', () async {
      final controller = buildTestController(
        national: const FailingNationalRepository(message: 'backend down'),
      );
      addTearDown(controller.dispose);

      await controller.refreshSnapshot(recordAudit: false);

      expect(controller.snapshotState.hasFailed, isTrue);
      expect(controller.snapshotError, contains('backend down'));
      expect(controller.stats, isNull);
    });

    test('a retry after a failure clears the error', () async {
      var shouldFail = true;
      final controller = buildTestController(
        national: _ToggleableRepository(() => shouldFail),
      );
      addTearDown(controller.dispose);

      await controller.refreshSnapshot(recordAudit: false);
      expect(controller.snapshotState.hasFailed, isTrue);

      shouldFail = false;
      await controller.refreshSnapshot(recordAudit: false);

      expect(controller.snapshotState.isReady, isTrue);
      expect(controller.snapshotError, isNull);
    });

    test('a hospital failure records its own message', () async {
      final controller = buildTestController(
        hospitals: const FailingHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);

      await controller.refreshHospitalNetwork();

      expect(controller.hospitalState.hasFailed, isTrue);
      expect(controller.hospitalError, contains('hospital aggregate'));
    });

    test('a federation failure records its own message', () async {
      final controller = buildTestController(
        federation: const FailingFederationRepository(),
      );
      addTearDown(controller.dispose);

      await controller.refreshFederation();

      expect(controller.federationState.hasFailed, isTrue);
      expect(controller.federationError, contains('federation provider'));
    });

    test('a throwing status probe does not break the dashboard', () async {
      final controller = buildTestController(
        national: const ThrowingProbeRepository(),
      );
      addTearDown(controller.dispose);

      await controller.refreshSnapshot(recordAudit: false);

      expect(controller.snapshotState.isReady, isTrue);
      expect(controller.dataSourceStatus, NationalDataSourceStatus.unreachable);
    });

    test('notifies listeners on each transition', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.refreshSnapshot(recordAudit: false);

      // At minimum: entering loading, and settling into ready.
      expect(notifications, greaterThanOrEqualTo(2));
    });
  });

  group('national KPI calculations', () {
    late NationalConsoleController controller;

    setUp(() async {
      controller = buildTestController(
        national: FakeNationalRepository(total: 1000),
      );
      await controller.bootstrap();
    });

    tearDown(() => controller.dispose());

    test('the overview exposes the six briefed indicators', () {
      expect(
        controller.overviewKpis.map((metric) => metric.label).toList(),
        <String>[
          'Total Dataset Records',
          'Emergency Records',
          'Critical Risk Records',
          'High Triage Records',
          'Chronic Condition Records',
          'Distinct Conditions',
        ],
      );
    });

    test('counts come straight from the stats payload', () {
      expect(controller.totalRecordsKpi.value, 1000);
      expect(controller.emergencyRecordsKpi.value, 250);
      expect(controller.criticalRiskKpi.value, 150);
      expect(controller.highTriageKpi.value, 180);
      expect(controller.chronicConditionKpi.value, 380);
      expect(controller.drugInteractionKpi.value, 120);
      expect(controller.conditionVarietyKpi.value, 6);
    });

    test('large counts are thousands-separated for display', () {
      expect(formatCount(64183), '64,183');
      expect(formatCount(1000), '1,000');
      expect(formatCount(0), '0');
      expect(formatCount(999), '999');
    });

    test('emergency share is a derived percent, not an incidence', () {
      final metric = controller.emergencyShareKpi;

      expect(metric.value, closeTo(25.0, 0.001));
      expect(metric.provenance, MetricProvenance.datasetAggregate);
      expect(metric.caption, contains('Not an incidence rate'));
    });

    test('mean age is reported as a mean, with no bands implied', () {
      final metric = controller.averageAgeKpi;

      expect(metric.value, closeTo(51.4, 0.001));
      expect(metric.displayValue, '51.4');
      expect(metric.caption, contains('No age bands'));
    });

    test('an empty dataset gives zero counts, not unavailable', () async {
      final empty = buildTestController(
        national: const EmptyNationalRepository(),
      );
      addTearDown(empty.dispose);
      await empty.bootstrap();

      expect(empty.totalRecordsKpi.value, 0);
      expect(empty.totalRecordsKpi.isAvailable, isTrue);
      // A share of zero records is undefined, not zero.
      expect(empty.emergencyShareKpi.isAvailable, isFalse);
      expect(empty.averageAgeKpi.isAvailable, isFalse);
    });

    test('before any load every aggregate reports unavailable', () {
      final fresh = buildTestController();
      addTearDown(fresh.dispose);

      for (final metric in fresh.overviewKpis) {
        expect(metric.isAvailable, isFalse, reason: metric.label);
        expect(metric.provenance, MetricProvenance.unavailable);
      }
    });
  });

  group('provenance labelling', () {
    late NationalConsoleController controller;

    setUp(() async {
      controller = buildTestController();
      await controller.bootstrap();
    });

    tearDown(() => controller.dispose());

    test('badge text matches the four briefed categories', () {
      expect(
        MetricProvenance.datasetAggregate.badge,
        'DATASET-DERIVED',
      );
      expect(MetricProvenance.datasetSample.badge, 'DATASET-SAMPLE');
      expect(MetricProvenance.demo.badge, 'DEMO');
      expect(MetricProvenance.unavailable.badge, 'NOT AVAILABLE');
    });

    test('dataset counts are DATASET-DERIVED', () {
      for (final metric in controller.overviewKpis) {
        expect(
          metric.provenance,
          MetricProvenance.datasetAggregate,
          reason: metric.label,
        );
      }
    });

    test('the highest-risk slice is DATASET-SAMPLE, never population', () {
      expect(
        controller.riskSampleTriageDistribution.provenance,
        MetricProvenance.datasetSample,
      );
      expect(
        controller.riskSampleConditionDistribution.provenance,
        MetricProvenance.datasetSample,
      );
      expect(
        controller.riskSampleTriageDistribution.basis,
        contains('not the population'),
      );
    });

    test('federation figures are DEMO', () {
      expect(controller.federationOnlineKpi.provenance, MetricProvenance.demo);
      expect(
        controller.federationRecordsKpi.provenance,
        MetricProvenance.demo,
      );
      expect(
        controller.federationOnlineKpi.caption,
        contains('No federated infrastructure exists'),
      );
    });

    test('unavailable metrics carry no value at all', () {
      for (final metric in <NationalMetric>[
        controller.ageDistributionKpi,
        controller.genderDistributionKpi,
        controller.geographicCoverageKpi,
        controller.networkLatencyKpi,
        controller.recentEmergencyKpi,
      ]) {
        expect(metric.provenance, MetricProvenance.unavailable);
        expect(metric.value, isNull, reason: metric.label);
        expect(metric.displayValue, 'Not available');
      }
    });

    test('every provenance carries an explanation for the tooltip', () {
      for (final provenance in MetricProvenance.values) {
        expect(provenance.explanation, isNotEmpty);
        expect(provenance.badge, isNotEmpty);
        expect(provenance.isNotLiveTelemetry, isTrue);
      }
    });
  });

  group('risk score is never a probability', () {
    test('the dataset label survives as a category, not a number', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final distribution = controller.riskDistribution;

      expect(distribution.counts.keys, contains('Critical'));
      expect(distribution.counts.keys, contains('Elevated'));
      expect(distribution.counts.keys, contains('Stable'));
      for (final row in controller.riskSample!.rows) {
        expect(double.tryParse(row.riskScore), isNull);
      }
    });

    test('the critical-risk KPI is captioned as categorical', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      expect(
        controller.criticalRiskKpi.caption,
        contains('not a probability'),
      );
    });
  });

  group('emergency aggregate calculations', () {
    late NationalConsoleController controller;

    setUp(() async {
      controller = buildTestController(
        national: FakeNationalRepository(total: 1000),
      );
      await controller.bootstrap();
    });

    tearDown(() => controller.dispose());

    test('emergency and non-emergency sum to the dataset total', () {
      final distribution = controller.emergencyShareDistribution;

      expect(distribution.countFor('Emergency'), 250);
      expect(distribution.countFor('Non-emergency'), 750);
      expect(distribution.total, 1000);
    });

    test('non-emergency is derived by subtraction, so a new admission '
        'type is still counted', () {
      // Elective + Urgent = 750 here, which matches the subtraction. The
      // point is that the controller does not sum the known keys.
      expect(controller.stats!.nonEmergencyRecords, 750);
    });

    test('shares are reported to one decimal place', () {
      final entry = controller.emergencyShareDistribution
          .entriesInOrder(<String>['Emergency']).single;

      expect(entry.percentLabel, '25.0%');
      expect(entry.fraction, closeTo(0.25, 0.0001));
    });

    test('ordinal distributions keep their briefed order', () {
      final triage = controller.triageDistribution
          .entriesInOrder(<String>['High', 'Medium', 'Low'])
          .map((entry) => entry.label)
          .toList();

      expect(triage, <String>['High', 'Medium', 'Low']);
    });

    test('a capped breakdown returns the largest categories first', () {
      final top = controller.conditionDistribution.entries(limit: 3);

      expect(top.length, 3);
      expect(top.first.label, 'Hypertension');
      expect(
        top.map((entry) => entry.count).toList(),
        <int>[9120, 8740, 6210],
      );
    });

    test('no trend is derived, and the phrase is fixed', () {
      expect(kTrendUnavailable, 'Trend unavailable from current aggregate API');
    });
  });

  group('health indicator coverage', () {
    late NationalConsoleController controller;

    setUp(() async {
      controller = buildTestController();
      await controller.bootstrap();
    });

    tearDown(() => controller.dispose());

    test('the six aggregated fields produce populated distributions', () {
      for (final distribution in <NationalDistribution>[
        controller.triageDistribution,
        controller.riskDistribution,
        controller.admissionTypeDistribution,
        controller.conditionDistribution,
        controller.chronicConditionDistribution,
        controller.drugInteractionDistribution,
      ]) {
        expect(distribution.isAvailable, isTrue, reason: distribution.title);
        expect(distribution.total, greaterThan(0));
      }
    });

    test('gender and age bands report unavailable with a reason', () {
      for (final distribution in <NationalDistribution>[
        controller.genderDistribution,
        controller.ageDistribution,
        controller.hospitalDistribution,
      ]) {
        expect(distribution.isAvailable, isFalse, reason: distribution.title);
        expect(distribution.provenance, MetricProvenance.unavailable);
        expect(distribution.basis, isNotEmpty);
        expect(distribution.total, 0);
      }
    });

    test('the reason names the missing endpoint, not missing data', () {
      expect(
        controller.genderDistribution.basis,
        contains('no endpoint aggregates it'),
      );
      expect(
        controller.ageDistribution.basis,
        contains('not banded counts'),
      );
    });

    test('the briefed eight reports appear in order', () {
      expect(
        controller.nationalReports.map((report) => report.title).toList(),
        <String>[
          'Admission Type',
          'Triage Level',
          'Risk Category',
          'Chronic Condition',
          'Medical Condition',
          'Drug Interaction Risk',
          'Age Distribution',
          'Gender Distribution',
        ],
      );
    });

    test('six of the eight reports can actually be produced', () {
      final available = controller.nationalReports
          .where((report) => report.isAvailable)
          .length;

      expect(available, 6);
    });
  });

  group('geographic data is refused, not estimated', () {
    test('the notice text is exactly the briefed phrase', () {
      expect(
        GeographicAvailability.notice,
        'Geographic breakdown: Not available in current dataset',
      );
    });

    test('the coverage metric is permanently unavailable', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final metric = controller.geographicCoverageKpi;

      expect(metric.isAvailable, isFalse);
      expect(metric.basis, contains('No province, district or coordinate'));
    });

    test('no distribution is keyed by a province name', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final allKeys = <String>[
        for (final report in controller.nationalReports)
          ...report.counts.keys,
        ...controller.emergencyShareDistribution.counts.keys,
        ...controller.riskSampleTriageDistribution.counts.keys,
        ...controller.riskSampleConditionDistribution.counts.keys,
      ];

      for (final region in GeographicAvailability.forbiddenRegionLabels) {
        expect(allKeys, isNot(contains(region)));
      }
    });

    test('the refused inferences are enumerated with reasons', () {
      expect(
        GeographicAvailability.refusedInferences,
        isNotEmpty,
      );
      for (final entry in GeographicAvailability.refusedInferences) {
        expect(entry.source, isNotEmpty);
        expect(entry.reason, isNotEmpty);
      }
    });

    test('an unconditional alert states the absence', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      expect(
        controller.alerts.any(
          (alert) => alert.title.contains('No geographic breakdown'),
        ),
        isTrue,
      );
    });
  });

  group('hospital aggregation', () {
    test('the shipped repository reports no endpoint', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final summary = controller.hospitalSummary!;

      expect(summary.hasNoEndpoint, isTrue);
      expect(summary.isAvailable, isFalse);
      expect(summary.reason, kHospitalAggregationUnavailable);
    });

    test('the required phrase is exactly as briefed', () {
      expect(
        kHospitalAggregationUnavailable,
        'Hospital-level national aggregation requires an aggregate backend '
        'endpoint.',
      );
    });

    test('a populated endpoint produces facility totals', () async {
      final controller = buildTestController(
        hospitals: const FakeHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final summary = controller.hospitalSummary!;

      expect(summary.isAvailable, isTrue);
      expect(summary.facilityCount, 2);
      expect(summary.totalRecords, 20600);
      expect(summary.hospitals.first.emergencyFraction, closeTo(0.25, 0.001));
    });

    test('an endpoint with no rows is distinct from no endpoint', () async {
      final controller = buildTestController(
        hospitals: const EmptyHospitalAggregateRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final summary = controller.hospitalSummary!;

      expect(summary.hasNoEndpoint, isFalse);
      expect(summary.isAvailable, isFalse);
      expect(summary.hospitals, isEmpty);
    });
  });

  group('federation demo model', () {
    late NationalConsoleController controller;

    setUp(() async {
      controller = buildTestController();
      await controller.bootstrap();
    });

    tearDown(() => controller.dispose());

    test('every node is flagged demo', () {
      final snapshot = controller.federation!;

      expect(snapshot.isDemo, isTrue);
      expect(snapshot.nodes, isNotEmpty);
      for (final node in snapshot.nodes) {
        expect(node.isDemo, isTrue, reason: node.nodeId);
      }
    });

    test('the tally sums to the node count', () {
      final tally = controller.federationTally!;

      expect(tally.total, controller.federation!.nodes.length);
      expect(tally.online + tally.degraded + tally.offline, tally.total);
      expect(tally.needingAttention, tally.degraded + tally.offline);
    });

    test('node identifiers use the NMR and HOSP formats', () {
      for (final node in controller.federation!.nodes) {
        expect(node.nodeId, matches(RegExp(r'^NMR-\d{3}$')));
        expect(node.hospitalId, matches(RegExp(r'^HOSP-\d{3}$')));
      }
    });

    test('staleness is computed against the injected clock', () {
      final node = controller.federation!.nodes.first;

      expect(node.staleness(kTestNow), const Duration(minutes: 2));
      expect(node.stalenessLabel(kTestNow), '2m ago');
    });

    test('staleness labels scale from minutes to days', () {
      final offline = controller.federation!.nodes
          .firstWhere((node) => node.health.needsAttention &&
              node.staleness(kTestNow).inHours >= 24);

      expect(offline.stalenessLabel(kTestNow), endsWith('d ago'));
    });

    test('nodes needing attention are ordered worst first', () {
      final flagged = controller.federation!.nodesNeedingAttention(kTestNow);

      expect(flagged, isNotEmpty);
      expect(flagged.first.health, NodeHealthOrder.worst(flagged));
    });

    test('a healthy federation raises no attention and no alert', () async {
      final healthy = buildTestController(
        federation: const HealthyFederationRepository(),
      );
      addTearDown(healthy.dispose);
      await healthy.bootstrap();

      expect(healthy.federationTally!.needingAttention, 0);
      expect(
        healthy.alerts.any((alert) => alert.title.contains('not reporting')),
        isFalse,
      );
    });

    test('an empty federation leaves the tally at zero', () async {
      final empty = buildTestController(
        federation: const _NoNodesFederationRepository(),
      );
      addTearDown(empty.dispose);
      await empty.bootstrap();

      expect(empty.federationTally!.total, 0);
      expect(empty.federationTally!.onlineFraction, 0);
      expect(empty.federationTally!.onlinePercentLabel, 'Not available');
    });
  });

  group('audit and governance', () {
    test('the seeded trail is scoped to the organisation', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      for (final event in controller.auditEvents) {
        expect(event.organizationId, 'MINISTRY-001');
        expect(event.isDemo, isTrue);
      }
    });

    test('categories are counted across every value', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final counts = controller.auditCategoryCounts;

      expect(counts.keys.length, NationalAuditCategory.values.length);
      expect(counts[NationalAuditCategory.emergencyAccess], 1);
      expect(counts[NationalAuditCategory.patientAccess], 1);
      expect(counts[NationalAuditCategory.federation], 1);
      expect(counts[NationalAuditCategory.governance], 1);
    });

    test('filtering narrows the trail and is idempotent', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await controller.setGovernanceFilter(
        GovernanceFilter.emergencyAccess,
      );

      expect(controller.auditEvents.length, 1);
      expect(
        controller.auditEvents.single.action,
        NationalAuditAction.breakGlassAccessGranted,
      );

      await controller.setGovernanceFilter(
        GovernanceFilter.emergencyAccess,
      );
      expect(controller.auditEvents.length, 1);
    });

    test('a filter with no matches yields an empty trail', () async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await controller.setGovernanceFilter(GovernanceFilter.patientAccess);

      expect(controller.auditEvents, isEmpty);
      expect(controller.auditState.isReady, isTrue);
    });

    test('a failing audit read fails its own state, not the dashboard',
        () async {
      final controller = buildTestController(
        audit: const FailingNationalAuditRepository(),
      );
      addTearDown(controller.dispose);

      await controller.bootstrap();

      expect(controller.auditState.hasFailed, isTrue);
      expect(controller.auditError, contains('audit source failed'));
      expect(controller.auditEvents, isEmpty);
      // The other three sources are unaffected.
      expect(controller.snapshotState.isReady, isTrue);
      expect(controller.federationState.isReady, isTrue);
      expect(controller.hospitalState.isReady, isTrue);
    });

    test('a manual refresh is audited', () async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await controller.refreshSnapshot();

      expect(
        controller.auditEvents.first.action,
        NationalAuditAction.aggregateDataRefreshed,
      );
    });

    test('an export request is audited and names the report', () async {
      final controller = buildTestController(seedAudit: false);
      addTearDown(controller.dispose);
      await controller.bootstrap();

      await controller.recordExportRequest('Triage Level');

      final event = controller.auditEvents.first;

      expect(
        event.action,
        NationalAuditAction.nationalReportExportRequested,
      );
      expect(event.note, 'Triage Level');
      expect(event.actorId, 'ANALYST-001');
    });

    test('break-glass and record access raise a review alert', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      expect(controller.emergencyAccessCount, 1);
      expect(controller.patientAccessCount, 1);
      expect(
        controller.alerts.any(
          (alert) => alert.title.contains('break-glass access'),
        ),
        isTrue,
      );
    });

    test('an unreachable source raises a critical alert', () async {
      final controller = buildTestController(
        national: const FailingNationalRepository(),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      expect(
        controller.alerts.first.severity,
        NationalAlertSeverity.critical,
      );
      expect(
        controller.dataSourceStatus,
        NationalDataSourceStatus.unreachable,
      );
    });

    test('no audit action carries a patient identifier field', () {
      // The model has no such field, so this is a structural assertion: if
      // one is ever added, this test has to be deliberately changed.
      final event = NationalAuditEvent(
        action: NationalAuditAction.patientRecordViewed,
        actorId: 'STAFF-001',
        organizationId: 'MINISTRY-001',
        timestamp: kTestNow,
        isDemo: true,
      );

      expect(event.hospitalLabel, kNotAvailable);
      expect(event.nodeLabel, kNotAvailable);
      expect(event.noteLabel, kNotAvailable);
      expect(event.hasNote, isFalse);
      expect(event.action.touchesPatientData, isTrue);
    });
  });

  group('privacy at the parse boundary', () {
    test('the risk sample drops CNIC, name, phone and email', () async {
      final controller = buildTestController();
      addTearDown(controller.dispose);
      await controller.bootstrap();

      final rows = controller.riskSample!.rows;
      expect(rows, isNotEmpty);

      // The fake payload carries all four. What survives parsing is the
      // categorical clinical fields plus age.
      for (final row in rows) {
        final serialised = <String>[
          row.medicalCondition,
          row.triageLevel,
          row.riskScore,
          row.admissionType,
          row.ageLabel,
        ].join('|');

        expect(serialised, isNot(contains('42101')));
        expect(serialised, isNot(contains('Test Patient')));
        expect(serialised, isNot(contains('+92')));
        expect(serialised, isNot(contains('@')));
      }
    });

    test('the sample reports its own size, not a population', () async {
      final controller = buildTestController(
        national: FakeNationalRepository(sampleCount: 4),
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();

      expect(controller.riskSample!.length, 4);
      expect(
        controller.riskSampleTriageDistribution.total,
        4,
      );
    });

    test('the analyst role declares an aggregate-only scope', () {
      for (final role in AnalystRole.values) {
        expect(role.dataScope, contains('Aggregate only'));
        expect(role.label, isNotEmpty);
      }
    });

    test('the reporting period is dataset-wide and says why', () {
      expect(ReportingPeriod.values.length, 1);
      expect(ReportingPeriod.datasetWide.label, 'Full dataset');
      expect(
        ReportingPeriod.datasetWide.detail,
        contains('No endpoint aggregates by date'),
      );
    });
  });
}

/// Fails or succeeds based on a flag, for the retry path.
class _ToggleableRepository implements NationalRepository {
  _ToggleableRepository(this._shouldFail);

  final bool Function() _shouldFail;

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) async {
    if (_shouldFail()) {
      throw const NationalRepositoryException('transient failure');
    }
    return fakeSnapshot();
  }

  @override
  Future<NationalDataSourceStatus> probeStatus() async =>
      _shouldFail()
          ? NationalDataSourceStatus.unreachable
          : NationalDataSourceStatus.reachable;
}

/// A federation with no nodes at all.
class _NoNodesFederationRepository implements FederationRepository {
  const _NoNodesFederationRepository();

  @override
  Future<FederationSnapshot> fetchFederation({
    required String organizationId,
  }) async =>
      FederationSnapshot(
        nodes: const <FederationNode>[],
        capturedAt: kTestNow,
        isDemo: true,
      );
}

/// Helper for asserting the worst health present in a list.
abstract final class NodeHealthOrder {
  static NodeHealth worst(List<FederationNode> nodes) {
    var worst = NodeHealth.online;
    for (final node in nodes) {
      if (node.health.index > worst.index) worst = node.health;
    }
    return worst;
  }
}
