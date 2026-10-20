import 'dart:async';

import 'package:ops_dashboard/src/data/audit_models.dart';
import 'package:ops_dashboard/src/data/handover_models.dart';
import 'package:ops_dashboard/src/data/occupancy_models.dart';
import 'package:ops_dashboard/src/data/operations_models.dart';

/// A fixed clock, so every "as of" timestamp and elapsed duration in the
/// tests is exact rather than approximate.
final DateTime kTestNow = DateTime.utc(2026, 3, 14, 9, 30);

DateTime testClock() => kTestNow;

/// The `GET /api/stats` payload shape, with small round numbers so expected
/// counts can be written by hand.
Map<String, dynamic> fakeStatsPayload({int total = 1000}) =>
    <String, dynamic>{
      'total_patients': total,
      'avg_age': 47.5,
      'risk_score': <String, dynamic>{
        'Critical': 120,
        'Elevated': 380,
        'Stable': 500,
      },
      'triage_level': <String, dynamic>{
        'High': 200,
        'Medium': 450,
        'Low': 350,
      },
      'medical_condition': <String, dynamic>{
        'Hypertension': 300,
        'Diabetes': 250,
        'Asthma': 200,
        'Cardiac Arrest': 150,
        'Fracture': 100,
      },
      'admission_type': <String, dynamic>{
        'Emergency': 400,
        'Urgent': 350,
        'Elective': 250,
      },
      'chronic_condition': <String, dynamic>{'Yes': 600, 'No': 400},
      'drug_interaction_risk': <String, dynamic>{'Yes': 150, 'No': 850},
    };

/// Rows in the `GET /api/dashboard/critical` shape.
List<Map<String, dynamic>> fakeRiskRows({int count = 5}) => <
    Map<String, dynamic>>[
  for (var i = 0; i < count; i++)
    <String, dynamic>{
      'CNIC': '00000-000000${i + 1}-1',
      'Age': 40 + i,
      'Medical_Condition': i.isEven ? 'Cardiac Arrest' : 'Severe Trauma',
      'Triage_Level': i < 3 ? 'High' : 'Medium',
      'Risk_Score': 'Critical',
      // Alternating so tests can exercise the emergency filter.
      'Admission_Type': i.isEven ? 'Emergency' : 'Urgent',
      'Hospital': 'Demo Hospital $i',
    },
];

/// An [OperationsRepository] that returns a fixed snapshot.
class FakeOperationsRepository implements OperationsRepository {
  FakeOperationsRepository({
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? rows,
    this.status = OpsBackendStatus.reachable,
    this.capturedAt,
  })  : _stats = stats ?? fakeStatsPayload(),
        _rows = rows ?? fakeRiskRows();

  final Map<String, dynamic> _stats;
  final List<Map<String, dynamic>> _rows;
  final OpsBackendStatus status;
  final DateTime? capturedAt;

  int fetchCount = 0;

  @override
  Future<OperationsSnapshot> fetchSnapshot({int riskFeedLimit = 100}) async {
    fetchCount++;
    return OperationsSnapshot(
      stats: OpsPopulationStats.fromJson(_stats),
      riskFeed: RiskFeed(
        rows: <RiskFeedRow>[
          for (final row in _rows) RiskFeedRow.fromJson(row),
        ],
        requestedLimit: riskFeedLimit,
      ),
      capturedAt: capturedAt ?? kTestNow,
    );
  }

  @override
  Future<OpsBackendStatus> probeStatus() async => status;
}

/// An [OperationsRepository] that always fails, for the error state.
class FailingOperationsRepository implements OperationsRepository {
  const FailingOperationsRepository({
    this.message = 'Cannot reach the NEMRAS backend.',
  });

  final String message;

  @override
  Future<OperationsSnapshot> fetchSnapshot({int riskFeedLimit = 100}) async {
    throw OpsRepositoryException(message);
  }

  @override
  Future<OpsBackendStatus> probeStatus() async =>
      OpsBackendStatus.unreachable;
}

/// A repository whose reads never complete, so the loading state can be
/// observed without a timing race.
class PendingOperationsRepository implements OperationsRepository {
  PendingOperationsRepository();

  final Completer<OperationsSnapshot> _snapshot =
      Completer<OperationsSnapshot>();
  final Completer<OpsBackendStatus> _status = Completer<OpsBackendStatus>();

  @override
  Future<OperationsSnapshot> fetchSnapshot({int riskFeedLimit = 100}) =>
      _snapshot.future;

  @override
  Future<OpsBackendStatus> probeStatus() => _status.future;
}

/// A plain error type so the fakes do not depend on the HTTP client.
class OpsRepositoryException implements Exception {
  const OpsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// An [OccupancyRepository] built from a ward plan, so a test can state the
/// occupancy it expects rather than deriving it.
class FakeOccupancyRepository implements OccupancyRepository {
  FakeOccupancyRepository({
    this.plan = const <({String ward, int occupied, int available})>[
      (ward: 'Emergency', occupied: 9, available: 1),
      (ward: 'General Medicine', occupied: 5, available: 5),
    ],
  });

  final List<({String ward, int occupied, int available})> plan;

  @override
  Future<OccupancySnapshot> fetchOccupancy({
    required String hospitalId,
  }) async {
    final wards = <WardOccupancy>[];
    for (var w = 0; w < plan.length; w++) {
      final entry = plan[w];
      wards.add(
        WardOccupancy(
          ward: entry.ward,
          isDemo: true,
          rooms: <RoomOccupancy>[
            for (var i = 0; i < entry.occupied; i++)
              RoomOccupancy(
                roomNumber: '${(w + 1) * 100 + i}',
                ward: entry.ward,
                state: RoomState.occupied,
                isDemo: true,
              ),
            for (var i = 0; i < entry.available; i++)
              RoomOccupancy(
                roomNumber: '${(w + 1) * 100 + entry.occupied + i}',
                ward: entry.ward,
                state: RoomState.available,
                isDemo: true,
              ),
          ],
        ),
      );
    }
    return OccupancySnapshot(
      wards: wards,
      capturedAt: kTestNow,
      isDemo: true,
    );
  }
}

/// An occupancy repository reporting no wards, for the empty state.
class EmptyOccupancyRepository implements OccupancyRepository {
  const EmptyOccupancyRepository();

  @override
  Future<OccupancySnapshot> fetchOccupancy({
    required String hospitalId,
  }) async =>
      OccupancySnapshot(
        wards: const <WardOccupancy>[],
        capturedAt: kTestNow,
        isDemo: true,
      );
}

/// An occupancy repository that fails, for the error state.
class FailingOccupancyRepository implements OccupancyRepository {
  const FailingOccupancyRepository();

  @override
  Future<OccupancySnapshot> fetchOccupancy({
    required String hospitalId,
  }) async {
    throw const OpsRepositoryException('Demo occupancy provider failed.');
  }
}

/// A [HandoverMonitorRepository] returning a stated set of statuses.
class FakeHandoverRepository implements HandoverMonitorRepository {
  FakeHandoverRepository({
    this.statuses = const <HandoverStatus>[
      HandoverStatus.incoming,
      HandoverStatus.incoming,
      HandoverStatus.accepted,
      HandoverStatus.inProgress,
      HandoverStatus.completed,
    ],
  });

  final List<HandoverStatus> statuses;

  @override
  Future<List<HandoverMonitorEntry>> fetchHandovers({
    required String hospitalId,
  }) async {
    return <HandoverMonitorEntry>[
      for (var i = 0; i < statuses.length; i++)
        HandoverMonitorEntry(
          emergencyId: 'EMG-2026-00000${i + 1}',
          caseReference: 'CASE-****000${i + 1}',
          triageLevel: i.isEven ? 'High' : 'Medium',
          riskCategory: i.isEven ? 'Critical' : 'Elevated',
          paramedicId: 'PARA-00${i + 1}',
          ambulanceId: 'NEMRAS-AMB-00${i + 1}',
          destinationHospitalId: hospitalId,
          destinationWard: 'Emergency',
          announcedAt: kTestNow.subtract(Duration(minutes: 5 * (i + 1))),
          status: statuses[i],
          isDemo: true,
          acceptedByStaffId:
              statuses[i] == HandoverStatus.incoming ? null : 'STAFF-001',
        ),
    ];
  }
}

/// A handover repository that fails, for the error state.
class FailingHandoverRepository implements HandoverMonitorRepository {
  const FailingHandoverRepository();

  @override
  Future<List<HandoverMonitorEntry>> fetchHandovers({
    required String hospitalId,
  }) async {
    throw const OpsRepositoryException('Demo handover provider failed.');
  }
}

/// A small audit seed with one event of each scope, so filter tests have a
/// known expected count per filter.
List<OpsAuditEvent> testAuditSeed({required String hospitalId}) {
  return <OpsAuditEvent>[
    OpsAuditEvent(
      action: OpsAuditAction.breakGlassAccessGranted,
      staffId: 'STAFF-001',
      hospitalId: hospitalId,
      timestamp: kTestNow.subtract(const Duration(minutes: 5)),
      isDemo: true,
      subjectReference: 'PAT-REF-****0001',
      emergencyId: 'EMG-2026-000001',
      reason: 'Unconscious patient, no consent obtainable.',
    ),
    OpsAuditEvent(
      action: OpsAuditAction.patientRecordViewed,
      staffId: 'STAFF-002',
      hospitalId: hospitalId,
      timestamp: kTestNow.subtract(const Duration(minutes: 10)),
      isDemo: true,
      subjectReference: 'PAT-REF-****0002',
    ),
    OpsAuditEvent(
      action: OpsAuditAction.dashboardViewed,
      staffId: 'ADMIN-001',
      hospitalId: hospitalId,
      timestamp: kTestNow.subtract(const Duration(minutes: 15)),
      isDemo: true,
    ),
    // Scoped to another hospital, so the scope filter has something to drop.
    OpsAuditEvent(
      action: OpsAuditAction.dashboardViewed,
      staffId: 'ADMIN-009',
      hospitalId: 'HOSP-999',
      timestamp: kTestNow.subtract(const Duration(minutes: 20)),
      isDemo: true,
    ),
  ];
}
