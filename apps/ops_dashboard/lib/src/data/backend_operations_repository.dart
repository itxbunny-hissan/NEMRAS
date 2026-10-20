import 'operations_models.dart';
import 'ops_api_client.dart';

/// Reads operational figures from the existing NEMRAS FastAPI routes.
///
/// It uses `GET /api/stats` for population aggregates and
/// `GET /api/dashboard/critical` for a bounded highest-risk slice. Nothing is
/// added to the backend by this phase.
///
/// Four fields the dashboard would like are present in
/// `NEMRAS_Dataset.csv` but are not exposed as an aggregate by any route:
/// `Hospital`, `Medication`, `Allergy` and `Room_Number`. Those views report
/// "Not available" rather than substituting a sample for a population, and
/// the gap is reported rather than worked around.
class BackendOperationsRepository implements OperationsRepository {
  BackendOperationsRepository({
    OpsApiClient? apiClient,
    DateTime Function()? clock,
  })  : _api = apiClient ?? OpsApiClient(),
        _clock = clock ?? DateTime.now;

  /// `/api/dashboard/critical` caps its limit at 100. Asking for more would
  /// be silently rejected, so the ceiling is honoured here.
  static const int maxRiskFeedLimit = 100;

  final OpsApiClient _api;
  final DateTime Function() _clock;

  String get baseUrl => _api.baseUrl;

  @override
  Future<OperationsSnapshot> fetchSnapshot({
    int riskFeedLimit = maxRiskFeedLimit,
  }) async {
    final limit = riskFeedLimit.clamp(1, maxRiskFeedLimit);
    final stats = await _api.fetchStats();
    final rows = await _api.fetchHighestRisk(limit: limit);

    return OperationsSnapshot(
      stats: OpsPopulationStats.fromJson(stats),
      riskFeed: RiskFeed(
        rows: <RiskFeedRow>[
          for (final row in rows) RiskFeedRow.fromJson(row),
        ],
        requestedLimit: limit,
      ),
      capturedAt: _clock().toUtc(),
    );
  }

  @override
  Future<OpsBackendStatus> probeStatus() async {
    final health = await _api.fetchHealth();
    if (health == null) return OpsBackendStatus.unreachable;
    final loaded = health['dataset_loaded'];
    if (loaded is bool && !loaded) return OpsBackendStatus.degraded;
    return OpsBackendStatus.reachable;
  }

  void dispose() => _api.dispose();
}
