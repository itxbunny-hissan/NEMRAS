import 'dart:async';

import 'package:ministry_dashboard/src/data/federation_models.dart';
import 'package:ministry_dashboard/src/data/governance_models.dart';
import 'package:ministry_dashboard/src/data/hospital_aggregate_models.dart';
import 'package:ministry_dashboard/src/data/national_models.dart';

/// A fixed instant, so every timestamp, staleness and "as of" value in the
/// suite is deterministic.
final DateTime kTestNow = DateTime.utc(2026, 5, 20, 11, 15);

/// A stats payload shaped exactly like `GET /api/stats`.
///
/// Note what is absent: there is no gender key and no age-band key, because
/// the real endpoint returns neither. The fakes must not be more generous
/// than the backend, or the tests would pass against data the app will never
/// see.
Map<String, dynamic> fakeStatsPayload({int total = 64183}) {
  return <String, dynamic>{
    'total_patients': total,
    'avg_age': 51.4,
    'risk_score': <String, dynamic>{
      'Stable': (total * 0.55).round(),
      'Elevated': (total * 0.30).round(),
      'Critical': (total * 0.15).round(),
    },
    'triage_level': <String, dynamic>{
      'Low': (total * 0.50).round(),
      'Medium': (total * 0.32).round(),
      'High': (total * 0.18).round(),
    },
    'admission_type': <String, dynamic>{
      'Elective': (total * 0.45).round(),
      'Urgent': (total * 0.30).round(),
      'Emergency': (total * 0.25).round(),
    },
    'chronic_condition': <String, dynamic>{
      'No': (total * 0.62).round(),
      'Yes': (total * 0.38).round(),
    },
    'drug_interaction_risk': <String, dynamic>{
      'No': (total * 0.88).round(),
      'Yes': (total * 0.12).round(),
    },
    'medical_condition': <String, dynamic>{
      'Hypertension': 9120,
      'Diabetes': 8740,
      'Asthma': 6210,
      'Arthritis': 5880,
      'Obesity': 4410,
      'Cancer': 3990,
    },
  };
}

NationalStats fakeStats({int total = 64183}) =>
    NationalStats.fromJson(fakeStatsPayload(total: total));

/// Rows shaped like `GET /api/dashboard/critical`, including the identifying
/// fields the real endpoint returns.
///
/// The CNIC and name are present here on purpose: the privacy tests need to
/// prove that `RiskSampleRow` drops them, and a fake that omitted them would
/// prove nothing.
List<Map<String, dynamic>> fakeCriticalPayload({int count = 6}) {
  const conditions = <String>[
    'Hypertension',
    'Diabetes',
    'Hypertension',
    'Cancer',
    'Asthma',
    'Diabetes',
  ];
  const triage = <String>['High', 'High', 'Medium', 'High', 'Low', 'Medium'];

  return <Map<String, dynamic>>[
    for (var i = 0; i < count; i++)
      <String, dynamic>{
        'CNIC': '42101-${(1234567 + i)}-${i % 10}',
        'Patient_Name': 'Test Patient ${i + 1}',
        'Phone_Number': '+92300000000$i',
        'Email': 'patient$i@example.invalid',
        'Age': 40 + i,
        'Gender': i.isEven ? 'Male' : 'Female',
        'Medical_Condition': conditions[i % conditions.length],
        'Triage_Level': triage[i % triage.length],
        'Risk_Score': 'Critical',
        'Admission_Type': 'Emergency',
        'Hospital': 'Test Hospital ${i % 2 + 1}',
      },
  ];
}

RiskSample fakeRiskSample({int count = 6, int requestedLimit = 20}) {
  return RiskSample(
    requestedLimit: requestedLimit,
    rows: <RiskSampleRow>[
      for (final json in fakeCriticalPayload(count: count))
        RiskSampleRow.fromJson(json),
    ],
  );
}

NationalSnapshot fakeSnapshot({int total = 64183, int sampleCount = 6}) {
  return NationalSnapshot(
    stats: fakeStats(total: total),
    riskSample: fakeRiskSample(count: sampleCount),
    capturedAt: kTestNow,
  );
}

/// Raised by the failing fakes, so a test can assert on the message a screen
/// shows without depending on a real transport's wording.
class NationalRepositoryException implements Exception {
  const NationalRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A national repository that always succeeds.
class FakeNationalRepository implements NationalRepository {
  FakeNationalRepository({
    this.total = 64183,
    this.sampleCount = 6,
    this.status = NationalDataSourceStatus.reachable,
  });

  final int total;
  final int sampleCount;
  final NationalDataSourceStatus status;

  int snapshotCalls = 0;
  int probeCalls = 0;
  int? lastRequestedLimit;

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) async {
    snapshotCalls++;
    lastRequestedLimit = riskSampleLimit;
    return fakeSnapshot(total: total, sampleCount: sampleCount);
  }

  @override
  Future<NationalDataSourceStatus> probeStatus() async {
    probeCalls++;
    return status;
  }
}

/// A national repository with an empty dataset, for the zero-total paths.
class EmptyNationalRepository implements NationalRepository {
  const EmptyNationalRepository();

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) async {
    return NationalSnapshot(
      stats: const NationalStats(
        totalRecords: 0,
        averageAge: null,
        riskScore: <String, int>{},
        triageLevel: <String, int>{},
        medicalCondition: <String, int>{},
        admissionType: <String, int>{},
        chronicCondition: <String, int>{},
        drugInteractionRisk: <String, int>{},
      ),
      riskSample: const RiskSample(
        rows: <RiskSampleRow>[],
        requestedLimit: 20,
      ),
      capturedAt: kTestNow,
    );
  }

  @override
  Future<NationalDataSourceStatus> probeStatus() async =>
      NationalDataSourceStatus.degraded;
}

/// A national repository whose reads always fail.
class FailingNationalRepository implements NationalRepository {
  const FailingNationalRepository({
    this.message = 'Could not reach the NEMRAS aggregate API.',
  });

  final String message;

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) async {
    throw NationalRepositoryException(message);
  }

  @override
  Future<NationalDataSourceStatus> probeStatus() async =>
      NationalDataSourceStatus.unreachable;
}

/// A national repository whose probe throws.
///
/// `probeStatus` is documented not to throw; this proves the controller still
/// survives a source that breaks the contract.
class ThrowingProbeRepository implements NationalRepository {
  const ThrowingProbeRepository();

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) async =>
      fakeSnapshot();

  @override
  Future<NationalDataSourceStatus> probeStatus() async {
    throw const NationalRepositoryException('probe exploded');
  }
}

/// A national repository whose reads never complete.
///
/// Backed by a [Completer] rather than a long delay, so the loading state is
/// observable without any timing race.
class PendingNationalRepository implements NationalRepository {
  final Completer<NationalSnapshot> _snapshot = Completer<NationalSnapshot>();
  final Completer<NationalDataSourceStatus> _status =
      Completer<NationalDataSourceStatus>();

  @override
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit = 20}) =>
      _snapshot.future;

  @override
  Future<NationalDataSourceStatus> probeStatus() => _status.future;
}

/// A hospital aggregate repository that returns facilities.
///
/// Nothing in Phase 5A can supply this, so it exists to prove the Hospital
/// Network screen renders correctly the moment an aggregate endpoint does.
class FakeHospitalAggregateRepository implements HospitalAggregateRepository {
  const FakeHospitalAggregateRepository();

  @override
  Future<HospitalNetworkSummary> fetchNetworkSummary() async {
    return const HospitalNetworkSummary(
      availability: HospitalAggregateAvailability.available,
      reason: 'Returned by a hypothetical aggregate endpoint.',
      hospitals: <HospitalAggregate>[
        HospitalAggregate(
          hospitalName: 'Test Facility Alpha',
          recordCount: 12400,
          emergencyRecords: 3100,
          criticalRiskRecords: 1860,
          isDemo: true,
        ),
        HospitalAggregate(
          hospitalName: 'Test Facility Beta',
          recordCount: 8200,
          emergencyRecords: 1640,
          criticalRiskRecords: 902,
          isDemo: true,
        ),
      ],
    );
  }
}

/// A hospital aggregate repository whose endpoint answers with no rows.
class EmptyHospitalAggregateRepository implements HospitalAggregateRepository {
  const EmptyHospitalAggregateRepository();

  @override
  Future<HospitalNetworkSummary> fetchNetworkSummary() async =>
      const HospitalNetworkSummary(
        availability: HospitalAggregateAvailability.empty,
        reason: 'The aggregate endpoint returned no facilities.',
        hospitals: <HospitalAggregate>[],
      );
}

/// A hospital aggregate repository that fails.
class FailingHospitalAggregateRepository
    implements HospitalAggregateRepository {
  const FailingHospitalAggregateRepository();

  @override
  Future<HospitalNetworkSummary> fetchNetworkSummary() async {
    throw const NationalRepositoryException(
      'The hospital aggregate source is unavailable.',
    );
  }
}

/// A federation repository that fails.
class FailingFederationRepository implements FederationRepository {
  const FailingFederationRepository();

  @override
  Future<FederationSnapshot> fetchFederation({
    required String organizationId,
  }) async {
    throw const NationalRepositoryException(
      'The demo federation provider failed.',
    );
  }
}

/// A federation repository whose nodes are all healthy, for asserting that
/// the attention badge and the degraded-node alert stay absent.
class HealthyFederationRepository implements FederationRepository {
  const HealthyFederationRepository();

  @override
  Future<FederationSnapshot> fetchFederation({
    required String organizationId,
  }) async {
    return FederationSnapshot(
      capturedAt: kTestNow,
      isDemo: true,
      nodes: <FederationNode>[
        for (var i = 0; i < 3; i++)
          FederationNode(
            nodeId: 'NMR-${(i + 1).toString().padLeft(3, '0')}',
            hospitalId: 'HOSP-${(i + 1).toString().padLeft(3, '0')}',
            health: NodeHealth.online,
            lastSynchronizedAt: kTestNow.subtract(const Duration(minutes: 2)),
            recordsSynchronized: 1000 * (i + 1),
            isDemo: true,
          ),
      ],
    );
  }
}

/// A national audit repository that fails on read.
class FailingNationalAuditRepository implements NationalAuditRepository {
  const FailingNationalAuditRepository();

  @override
  Future<void> record(NationalAuditEvent event) async {}

  @override
  Future<List<NationalAuditEvent>> fetchEvents({
    required String organizationId,
    GovernanceFilter filter = GovernanceFilter.all,
  }) async {
    throw const NationalRepositoryException('The audit source failed.');
  }
}

/// A small audit seed with one event in each category that the governance
/// screen groups by.
List<NationalAuditEvent> testAuditSeed({required String organizationId}) {
  NationalAuditEvent event(
    NationalAuditAction action,
    int minutesAgo, {
    String actorId = 'ANALYST-001',
    String? hospitalId,
    String? nodeId,
    String? note,
  }) {
    return NationalAuditEvent(
      action: action,
      actorId: actorId,
      organizationId: organizationId,
      timestamp: kTestNow.subtract(Duration(minutes: minutesAgo)),
      isDemo: true,
      hospitalId: hospitalId,
      nodeId: nodeId,
      note: note,
    );
  }

  return <NationalAuditEvent>[
    event(NationalAuditAction.aggregateDataRefreshed, 2),
    event(
      NationalAuditAction.breakGlassAccessGranted,
      10,
      actorId: 'STAFF-001',
      hospitalId: 'HOSP-001',
      note: 'Reason recorded at the facility.',
    ),
    event(
      NationalAuditAction.patientRecordViewed,
      20,
      actorId: 'STAFF-002',
      hospitalId: 'HOSP-001',
    ),
    event(
      NationalAuditAction.federationSyncFailed,
      30,
      actorId: 'SYSTEM',
      nodeId: 'NMR-008',
    ),
    event(NationalAuditAction.governanceReviewCompleted, 40),
  ];
}
