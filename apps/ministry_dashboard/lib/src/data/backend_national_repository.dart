import 'national_api_client.dart';
import 'national_models.dart';

/// Reads national aggregates from the existing NEMRAS FastAPI routes.
///
/// Uses `GET /api/stats` for population aggregates and
/// `GET /api/dashboard/critical` for a bounded highest-risk slice. No route
/// is added to the backend by this phase.
///
/// Fields present in `NEMRAS_Dataset.csv` that no endpoint aggregates, and
/// which therefore report unavailable rather than being approximated from
/// the slice: `Gender`, `Age` bands, `Hospital`, `Medication`, `Allergy`,
/// `Admission_Date` and `Discharge_Date`. The last two matter most here,
/// because they are populated and would support a genuine time series — the
/// gap is the endpoint, not the data.
class BackendNationalRepository implements NationalRepository {
  BackendNationalRepository({
    NationalApiClient? apiClient,
    DateTime Function()? clock,
  })  : _api = apiClient ?? NationalApiClient(),
        _clock = clock ?? DateTime.now;

  /// `/api/dashboard/critical` caps its limit at 100. Asking for more would
  /// be silently rejected, so the ceiling is honoured here.
  static const int maxRiskSampleLimit = 100;

  final NationalApiClient _api;
  final DateTime Function() _clock;

  String get baseUrl => _api.baseUrl;

  @override
  Future<NationalSnapshot> fetchSnapshot({
    int riskSampleLimit = maxRiskSampleLimit,
  }) async {
    final limit = riskSampleLimit.clamp(1, maxRiskSampleLimit);
    final stats = await _api.fetchStats();
    final rows = await _api.fetchHighestRisk(limit: limit);

    return NationalSnapshot(
      stats: NationalStats.fromJson(stats),
      riskSample: RiskSample(
        rows: <RiskSampleRow>[
          // Identifiers are dropped here, at the parse boundary, so nothing
          // downstream can render one even by mistake.
          for (final row in rows) RiskSampleRow.fromJson(row),
        ],
        requestedLimit: limit,
      ),
      capturedAt: _clock().toUtc(),
    );
  }

  @override
  Future<NationalDataSourceStatus> probeStatus() async {
    final health = await _api.fetchHealth();
    if (health == null) return NationalDataSourceStatus.unreachable;
    final loaded = health['dataset_loaded'];
    if (loaded is bool && !loaded) return NationalDataSourceStatus.degraded;
    return NationalDataSourceStatus.reachable;
  }

  void dispose() => _api.dispose();
}
