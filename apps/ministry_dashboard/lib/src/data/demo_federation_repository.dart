import 'federation_models.dart';

/// A deterministic demo federation.
///
/// There is no federation behind this. NEMRAS runs one FastAPI process
/// against one CSV file; there are no hospital nodes, no synchronisation
/// protocol, no event stream and no national index. This provider generates a
/// fixed set of nodes purely so the federation screen has a shape to render,
/// and every value it produces is flagged demo.
///
/// Node identifiers follow the reference's `NMR-NNN` format and hospital
/// identifiers follow the `HOSP-NNN` format the hospital surfaces use, so a
/// future integration maps onto the same fields. The nodes are not named
/// after real hospitals: the reference images show real Pakistani hospital
/// names beside simulated figures, which would present invented telemetry as
/// if it described identifiable institutions.
class DemoFederationRepository implements FederationRepository {
  DemoFederationRepository({DateTime? now})
      : _now = (now ?? DateTime.now()).toUtc();

  final DateTime _now;

  /// Node count, health and simulated backlog.
  ///
  /// Chosen to exercise every branch of the UI: most online, two degraded,
  /// one offline and badly stale.
  static const List<({NodeHealth health, int minutesStale, int records})>
      _plan = <({NodeHealth health, int minutesStale, int records})>[
    (health: NodeHealth.online, minutesStale: 2, records: 8412),
    (health: NodeHealth.online, minutesStale: 3, records: 12743),
    (health: NodeHealth.online, minutesStale: 1, records: 6541),
    (health: NodeHealth.degraded, minutesStale: 46, records: 5214),
    (health: NodeHealth.online, minutesStale: 4, records: 9231),
    (health: NodeHealth.online, minutesStale: 2, records: 1843),
    (health: NodeHealth.degraded, minutesStale: 88, records: 3320),
    (health: NodeHealth.offline, minutesStale: 1510, records: 742),
  ];

  @override
  Future<FederationSnapshot> fetchFederation({
    required String organizationId,
  }) async {
    return FederationSnapshot(
      capturedAt: _now,
      isDemo: true,
      nodes: <FederationNode>[
        for (var i = 0; i < _plan.length; i++)
          FederationNode(
            nodeId: 'NMR-${(i + 1).toString().padLeft(3, '0')}',
            hospitalId: 'HOSP-${(i + 1).toString().padLeft(3, '0')}',
            health: _plan[i].health,
            lastSynchronizedAt: _now.subtract(
              Duration(minutes: _plan[i].minutesStale),
            ),
            recordsSynchronized: _plan[i].records,
            isDemo: true,
          ),
      ],
    );
  }
}

/// A federation with no nodes, for exercising the empty state.
class EmptyFederationRepository implements FederationRepository {
  const EmptyFederationRepository();

  @override
  Future<FederationSnapshot> fetchFederation({
    required String organizationId,
  }) async =>
      FederationSnapshot(
        nodes: const <FederationNode>[],
        capturedAt: DateTime.now().toUtc(),
        isDemo: true,
      );
}
