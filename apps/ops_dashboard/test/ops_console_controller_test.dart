import 'package:flutter_test/flutter_test.dart';
import 'package:ops_dashboard/src/data/admin_identity.dart';
import 'package:ops_dashboard/src/data/audit_models.dart';
import 'package:ops_dashboard/src/data/handover_models.dart';
import 'package:ops_dashboard/src/data/metric_provenance.dart';
import 'package:ops_dashboard/src/data/operations_models.dart';
import 'package:ops_dashboard/src/state/ops_console_controller.dart';

import 'support/fake_repositories.dart';
import 'support/pump.dart';

void main() {
  const hospitalId = DemoOpsIdentity.hospitalId;

  group('bootstrap', () {
    test('loads every source and reaches the ready state', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(controller.snapshotState, LoadState.ready);
      expect(controller.occupancyState, LoadState.ready);
      expect(controller.handoverState, LoadState.ready);
      expect(controller.auditState, LoadState.ready);
      expect(controller.isBootstrapped, isTrue);
    });

    test('records a session-started audit event', () async {
      final audit = InMemoryAuditRepository();
      final controller = buildTestController(audit: audit);
      await controller.bootstrap();

      expect(
        controller.auditEvents.first.action,
        OpsAuditAction.sessionStarted,
      );
      expect(controller.auditEvents.first.staffId, 'ADMIN-001');
      expect(controller.auditEvents.first.isDemo, isTrue);
    });

    test('is idempotent, so a rebuild does not refetch', () async {
      final operations = FakeOperationsRepository();
      final controller = buildTestController(operations: operations);
      await controller.bootstrap();
      await controller.bootstrap();

      expect(operations.fetchCount, 1);
    });

    test('one failing source does not blank the others', () async {
      final controller = buildTestController(
        operations: const FailingOperationsRepository(),
      );
      await controller.bootstrap();

      expect(controller.snapshotState, LoadState.failed);
      expect(controller.occupancyState, LoadState.ready);
      expect(controller.handoverState, LoadState.ready);
    });
  });

  group('load states', () {
    test('a failing operations source records its message', () async {
      final controller = buildTestController(
        operations: const FailingOperationsRepository(message: 'boom'),
      );
      await controller.refreshSnapshot(recordAudit: false);

      expect(controller.snapshotState, LoadState.failed);
      expect(controller.snapshotError, contains('boom'));
      expect(controller.backendStatus, OpsBackendStatus.unreachable);
    });

    test('a pending source stays in the loading state', () async {
      final controller = buildTestController(
        operations: PendingOperationsRepository(),
      );
      // Not awaited: the fake never resolves, which is the point.
      controller.refreshSnapshot(recordAudit: false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.snapshotState, LoadState.loading);
      expect(controller.snapshot, isNull);
    });

    test('a failing occupancy source records its message', () async {
      final controller = buildTestController(
        occupancy: const FailingOccupancyRepository(),
      );
      await controller.refreshOccupancy();

      expect(controller.occupancyState, LoadState.failed);
      expect(controller.occupancyError, contains('occupancy'));
    });

    test('a failing handover source records its message', () async {
      final controller = buildTestController(
        handovers: const FailingHandoverRepository(),
      );
      await controller.refreshHandovers();

      expect(controller.handoverState, LoadState.failed);
      expect(controller.handoverError, contains('handover'));
    });

    test('an empty occupancy source is ready with zero rooms', () async {
      final controller = buildTestController(
        occupancy: const EmptyOccupancyRepository(),
      );
      await controller.refreshOccupancy();

      expect(controller.occupancyState, LoadState.ready);
      expect(controller.occupancy!.totalRooms, 0);
      expect(controller.occupancy!.occupancyFraction, 0);
    });
  });

  group('KPI calculation and provenance', () {
    test('emergency cases counts emergency admission records', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final kpi = controller.emergencyCasesKpi;
      expect(kpi.value, 400);
      expect(kpi.provenance, MetricProvenance.datasetAggregate);
      expect(kpi.basis, contains('Admission_Type = Emergency'));
    });

    test('critical cases counts critical risk records', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final kpi = controller.criticalCasesKpi;
      expect(kpi.value, 120);
      expect(kpi.provenance, MetricProvenance.datasetAggregate);
    });

    test('active admissions is always unavailable', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final kpi = controller.activeAdmissionsKpi;
      expect(kpi.provenance, MetricProvenance.unavailable);
      expect(kpi.isAvailable, isFalse);
      expect(kpi.displayValue, 'Not available');
    });

    test('occupied and available rooms are demo and sum to the estate',
        () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final occupied = controller.occupiedRoomsKpi;
      final available = controller.availableRoomsKpi;
      expect(occupied.provenance, MetricProvenance.demo);
      expect(available.provenance, MetricProvenance.demo);
      expect(occupied.value, 14);
      expect(available.value, 6);
      expect(occupied.value! + available.value!, 20);
    });

    test('pending handovers counts only incoming cases', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final kpi = controller.pendingHandoversKpi;
      expect(kpi.value, 2);
      expect(kpi.provenance, MetricProvenance.demo);
    });

    test('the six overview KPIs carry the briefed provenance split',
        () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(
        controller.overviewKpis.map((kpi) => kpi.label).toList(),
        <String>[
          'Emergency Cases',
          'Active Admissions',
          'Occupied Rooms',
          'Available Rooms',
          'Pending Handovers',
          'Critical Cases',
        ],
      );
      expect(
        controller.overviewKpis.map((kpi) => kpi.provenance).toList(),
        <MetricProvenance>[
          MetricProvenance.datasetAggregate,
          MetricProvenance.unavailable,
          MetricProvenance.demo,
          MetricProvenance.demo,
          MetricProvenance.demo,
          MetricProvenance.datasetAggregate,
        ],
      );
    });

    test('every KPI reports unavailable before any load', () {
      final controller = buildTestController();

      for (final kpi in controller.overviewKpis) {
        expect(kpi.provenance, MetricProvenance.unavailable);
        expect(kpi.isAvailable, isFalse);
      }
    });

    test('no dataset KPI is ever labelled demo or live', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      for (final kpi in controller.overviewKpis) {
        expect(kpi.provenance.isNotLive, isTrue);
      }
      expect(
        controller.emergencyCasesKpi.caption,
        contains('not cases currently in this hospital'),
      );
    });
  });

  group('aggregate distributions', () {
    test('triage totals the dataset population', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final triage = controller.triageDistribution;
      expect(triage.isAvailable, isTrue);
      expect(triage.total, 1000);
      expect(triage.countFor('High'), 200);
      expect(triage.provenance, MetricProvenance.datasetAggregate);
    });

    test('a fixed order renders an ordinal scale in that order', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final rows = controller.triageDistribution
          .entriesInOrder(const <String>['High', 'Medium', 'Low']);
      expect(rows.map((row) => row.label).toList(),
          <String>['High', 'Medium', 'Low']);
    });

    test('entries sort largest first and respect a limit', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final rows = controller.conditionDistribution.entries(limit: 3);
      expect(rows.length, 3);
      expect(rows.first.label, 'Hypertension');
      expect(rows.map((row) => row.count).toList(), <int>[300, 250, 200]);
    });

    test('shares are computed against the distribution total', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final high = controller.triageDistribution
          .entriesInOrder(const <String>['High'])
          .single;
      expect(high.fraction, closeTo(0.2, 1e-9));
      expect(high.percentLabel, '20.0%');
    });

    test('hospital, medication and allergy report unavailable', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      for (final distribution in <OpsDistribution>[
        controller.hospitalDistribution,
        controller.medicationDistribution,
        controller.allergyDistribution,
      ]) {
        expect(distribution.isAvailable, isFalse);
        expect(distribution.provenance, MetricProvenance.unavailable);
        expect(distribution.basis, contains('no endpoint'));
      }
    });

    test('the risk-slice breakdown is labelled a sample, not a population',
        () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final sample = controller.riskFeedTriageDistribution;
      expect(sample.provenance, MetricProvenance.datasetSample);
      expect(sample.total, 5);
      expect(sample.basis, contains('not the population'));
    });
  });

  group('handover tally', () {
    test('counts each workflow state', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final tally = controller.handoverTally;
      expect(tally.incoming, 2);
      expect(tally.accepted, 1);
      expect(tally.inProgress, 1);
      expect(tally.completed, 1);
      expect(tally.total, 5);
      expect(tally.pending, 2);
      expect(tally.active, 2);
    });

    test('an empty queue tallies to zero everywhere', () async {
      final controller = buildTestController(
        handovers: FakeHandoverRepository(statuses: const <HandoverStatus>[]),
      );
      await controller.bootstrap();

      expect(controller.handoverTally.total, 0);
      expect(controller.pendingHandoversKpi.value, 0);
      expect(controller.handoverEntries, isEmpty);
    });

    test('filters entries by status', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(
        controller.handoversWithStatus(HandoverStatus.incoming).length,
        2,
      );
      expect(
        controller.handoversWithStatus(HandoverStatus.completed).length,
        1,
      );
    });

    test('waiting time is measured from the injected clock', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final newest = controller.handoverEntries.first;
      expect(newest.waitingFor(controller.now), const Duration(minutes: 5));
      expect(newest.waitingLabel(controller.now), '5m');
    });

    test('a future announcement clamps to zero instead of going negative',
        () {
      final entry = HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000099',
        caseReference: 'CASE-****0099',
        triageLevel: 'Low',
        riskCategory: 'Stable',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-001',
        destinationHospitalId: hospitalId,
        destinationWard: 'Emergency',
        announcedAt: kTestNow.add(const Duration(minutes: 10)),
        status: HandoverStatus.incoming,
        isDemo: true,
      );
      expect(entry.waitingFor(kTestNow), Duration.zero);
    });
  });

  group('occupancy derivation', () {
    test('ward and estate occupancy fractions agree with the room states',
        () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final snapshot = controller.occupancy!;
      expect(snapshot.totalRooms, 20);
      expect(snapshot.occupiedRooms, 14);
      expect(snapshot.occupancyFraction, closeTo(0.7, 1e-9));

      final emergency = snapshot.wards.first;
      expect(emergency.ward, 'Emergency');
      expect(emergency.occupancyFraction, closeTo(0.9, 1e-9));
      expect(emergency.occupancyPercentLabel, '90%');
    });

    test('wards at or above the threshold are reported busiest first',
        () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final pressured = controller.occupancy!.wardsUnderPressure();
      expect(pressured.map((ward) => ward.ward).toList(), <String>['Emergency']);
    });

    test('every room and ward is flagged demo', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final snapshot = controller.occupancy!;
      expect(snapshot.isDemo, isTrue);
      for (final ward in snapshot.wards) {
        expect(ward.isDemo, isTrue);
        for (final room in ward.rooms) {
          expect(room.isDemo, isTrue);
        }
      }
    });
  });

  group('audit filtering', () {
    test('defaults to every event in this hospital', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      // Three seeded events for HOSP-001 plus the session-started event. The
      // fourth seed belongs to HOSP-999 and must be excluded.
      expect(controller.auditEvents.length, 4);
      expect(
        controller.auditEvents.every((e) => e.hospitalId == hospitalId),
        isTrue,
      );
    });

    test('emergency access narrows to break-glass grants', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      await controller.setAuditFilter(AuditFilter.emergencyAccess);

      expect(controller.auditEvents.length, 1);
      expect(
        controller.auditEvents.single.action,
        OpsAuditAction.breakGlassAccessGranted,
      );
    });

    test('patient access includes break-glass and record views', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      await controller.setAuditFilter(AuditFilter.patientAccess);

      expect(controller.auditEvents.length, 2);
      expect(
        controller.auditEvents.every((e) => e.action.touchesPatientData),
        isTrue,
      );
    });

    test('operational activity excludes anything patient-scoped', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      await controller.setAuditFilter(AuditFilter.operationalActivity);

      expect(
        controller.auditEvents.any((e) => e.action.touchesPatientData),
        isFalse,
      );
      expect(controller.auditEvents.length, 2);
    });

    test('reselecting the same filter is a no-op', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      final before = controller.auditEvents.length;
      await controller.setAuditFilter(AuditFilter.all);

      expect(controller.auditEvents.length, before);
      expect(controller.auditFilter, AuditFilter.all);
    });

    test('no audit entry carries a raw CNIC', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      for (final event in controller.auditEvents) {
        final reference = event.subjectReference;
        if (reference == null) continue;
        expect(reference, startsWith('PAT-REF-****'));
        expect(RegExp(r'\d{5}-\d{7}-\d').hasMatch(reference), isFalse);
      }
    });

    test('the trail stays newest first after a new event', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      await controller.recordExportRequest('Operational reports');

      expect(
        controller.auditEvents.first.action,
        OpsAuditAction.reportExportRequested,
      );
      expect(controller.auditEvents.first.reason, 'Operational reports');
    });

    test('a refresh records an audit event of its own', () async {
      final controller = buildTestController();
      await controller.bootstrap();
      await controller.refreshSnapshot();

      expect(
        controller.auditEvents.first.action,
        OpsAuditAction.operationalDataRefreshed,
      );
    });
  });

  group('operational alerts', () {
    test('raises a ward-pressure alert from the demo occupancy', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final pressure = controller.alerts
          .where((alert) => alert.title.contains('Emergency at'))
          .toList();
      expect(pressure, hasLength(1));
      expect(pressure.single.provenance, MetricProvenance.demo);
    });

    test('raises a pending-handover alert and pluralises it', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final pending = controller.alerts
          .where((alert) => alert.title.contains('awaiting acceptance'))
          .single;
      expect(pending.title, startsWith('2 handovers'));
    });

    test('raises no handover alert when nothing is pending', () async {
      final controller = buildTestController(
        handovers: FakeHandoverRepository(
          statuses: const <HandoverStatus>[HandoverStatus.completed],
        ),
      );
      await controller.bootstrap();

      expect(
        controller.alerts
            .any((alert) => alert.title.contains('awaiting acceptance')),
        isFalse,
      );
    });

    test('raises a break-glass review alert from the audit trail', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(controller.emergencyAccessCount, 1);
      expect(
        controller.alerts
            .any((alert) => alert.title.contains('break-glass access')),
        isTrue,
      );
    });

    test('raises an unavailable-data alert when the source is unreachable',
        () async {
      final controller = buildTestController(
        operations: const FailingOperationsRepository(),
      );
      await controller.bootstrap();

      final outage = controller.alerts
          .where((alert) => alert.title == 'Dataset figures unavailable')
          .single;
      expect(outage.provenance, MetricProvenance.unavailable);
    });

    test('every alert declares a provenance', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(controller.alerts, isNotEmpty);
      for (final alert in controller.alerts) {
        expect(alert.provenance.badge, isNotEmpty);
      }
    });
  });

  group('demo and live labelling', () {
    test('the default session is demo throughout', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(controller.environment.isDemo, isTrue);
      expect(controller.administrator.isDemo, isTrue);
      expect(controller.hospital.isDemo, isTrue);
      expect(controller.handoverTally.isDemo, isTrue);
    });

    test('a production environment still labels the demo providers',
        () async {
      final controller = buildTestController(
        environment: OpsEnvironment.production,
      );
      await controller.bootstrap();

      expect(controller.environment.isDemo, isFalse);
      // The environment flag does not change where a figure came from.
      expect(controller.occupiedRoomsKpi.provenance, MetricProvenance.demo);
      expect(controller.pendingHandoversKpi.provenance, MetricProvenance.demo);
    });

    test('provenance badges and explanations are distinct per kind', () {
      final badges =
          MetricProvenance.values.map((kind) => kind.badge).toList();
      expect(badges.toSet().length, badges.length);
      for (final kind in MetricProvenance.values) {
        expect(kind.explanation, isNotEmpty);
      }
    });

    test('an unavailable metric distinguishes no value from zero', () {
      final zero = OpsMetric.demo(label: 'z', value: 0, basis: 'b');
      final missing = OpsMetric.unavailable(label: 'm', basis: 'b');

      expect(zero.isAvailable, isTrue);
      expect(zero.displayValue, '0');
      expect(missing.isAvailable, isFalse);
      expect(missing.displayValue, 'Not available');
    });

    test('large counts are thousands-separated', () {
      expect(formatCount(64242), '64,242');
      expect(formatCount(1000), '1,000');
      expect(formatCount(999), '999');
      expect(formatCount(0), '0');
    });
  });

  group('risk feed handling', () {
    test('masks the CNIC to a non-identifying case reference', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      final row = controller.riskFeed!.rows.first;
      expect(row.cnic, '00000-0000001-1');
      // Only the last four digits survive, and the dashes are gone, so the
      // reference cannot be read back as a CNIC.
      expect(row.caseReference, 'CASE-****0011');
      expect(row.caseReference, isNot(contains(row.cnic)));
    });

    test('reports a missing field as not available rather than blank', () {
      final row = RiskFeedRow.fromJson(const <String, dynamic>{
        'CNIC': '00000-0000001-1',
        'Age': null,
        'Medical_Condition': '   ',
      });
      expect(row.ageLabel, 'Not available');
      expect(row.medicalCondition, 'Not available');
      expect(row.triageLevel, 'Not available');
    });

    test('carries the requested limit so the UI can say "top N"', () async {
      final controller = buildTestController();
      await controller.bootstrap();

      expect(controller.riskFeed!.requestedLimit, 100);
      expect(controller.riskFeed!.length, 5);
    });

    test('malformed stats degrade to empty breakdowns, not a crash', () {
      final stats = OpsPopulationStats.fromJson(const <String, dynamic>{
        'total_patients': 'not a number',
        'risk_score': 'not a map',
      });
      expect(stats.totalRecords, 0);
      expect(stats.riskScore, isEmpty);
      expect(stats.averageAgeLabel, 'Not available');
    });
  });

  group('administrator identity', () {
    test('each demo role has a distinct staff id', () {
      final ids = OpsRole.values
          .map((role) => DemoOpsIdentity.forRole(role).staffId)
          .toList();
      expect(ids.toSet().length, ids.length);
    });

    test('derives initials for the top-bar avatar', () {
      expect(DemoOpsIdentity.administrator.initials, 'DA');
      expect(DemoOpsIdentity.supervisor.initials, 'DS');
    });

    test('all demo roles share the hospital scope', () {
      for (final role in OpsRole.values) {
        expect(DemoOpsIdentity.forRole(role).hospitalId, hospitalId);
        expect(DemoOpsIdentity.forRole(role).isDemo, isTrue);
      }
    });
  });
}
