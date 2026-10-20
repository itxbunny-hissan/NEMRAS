import 'package:flutter/foundation.dart';

import '../data/admin_identity.dart';
import '../data/audit_models.dart';
import '../data/handover_models.dart';
import '../data/metric_provenance.dart';
import '../data/occupancy_models.dart';
import '../data/operations_models.dart';

/// Where an asynchronous read has got to.
enum LoadState { idle, loading, ready, failed }

extension LoadStateFlags on LoadState {
  bool get isLoading => this == LoadState.loading;
  bool get isReady => this == LoadState.ready;
  bool get hasFailed => this == LoadState.failed;
}

/// Holds the operational state the dashboard renders.
///
/// A plain [ChangeNotifier] so NEMRAS takes on no state-management
/// dependency, matching the other three surfaces. Every data source arrives
/// as an interface, so tests inject mocks and nothing here needs a backend.
class OpsConsoleController extends ChangeNotifier {
  OpsConsoleController({
    required OperationsRepository operationsRepository,
    required OccupancyRepository occupancyRepository,
    required HandoverMonitorRepository handoverRepository,
    required AuditRepository auditRepository,
    HospitalAdminProfile? administrator,
    OpsHospitalIdentity? hospital,
    this.environment = OpsEnvironment.demo,
    DateTime Function()? clock,
  })  : _operations = operationsRepository,
        _occupancy = occupancyRepository,
        _handovers = handoverRepository,
        _audit = auditRepository,
        _administrator = administrator ?? DemoOpsIdentity.administrator,
        _hospital = hospital ?? DemoOpsIdentity.hospital,
        _clock = clock ?? DateTime.now;

  final OperationsRepository _operations;
  final OccupancyRepository _occupancy;
  final HandoverMonitorRepository _handovers;
  final AuditRepository _audit;

  /// Injected so "as of" timestamps and elapsed times are deterministic in
  /// tests. The dashboard renders a data-freshness timestamp rather than a
  /// ticking clock, so no widget holds a periodic timer.
  final DateTime Function() _clock;

  final HospitalAdminProfile _administrator;
  final OpsHospitalIdentity _hospital;

  /// Which build this is. Drives the demo indicator on every screen.
  final OpsEnvironment environment;

  HospitalAdminProfile get administrator => _administrator;
  OpsHospitalIdentity get hospital => _hospital;
  DateTime get now => _clock();

  // --- Dataset figures -----------------------------------------------------

  LoadState _snapshotState = LoadState.idle;
  OperationsSnapshot? _snapshot;
  String? _snapshotError;

  LoadState get snapshotState => _snapshotState;
  OperationsSnapshot? get snapshot => _snapshot;
  String? get snapshotError => _snapshotError;
  OpsPopulationStats? get stats => _snapshot?.stats;
  RiskFeed? get riskFeed => _snapshot?.riskFeed;

  // --- Occupancy -----------------------------------------------------------

  LoadState _occupancyState = LoadState.idle;
  OccupancySnapshot? _occupancySnapshot;
  String? _occupancyError;

  LoadState get occupancyState => _occupancyState;
  OccupancySnapshot? get occupancy => _occupancySnapshot;
  String? get occupancyError => _occupancyError;

  // --- Handovers -----------------------------------------------------------

  LoadState _handoverState = LoadState.idle;
  List<HandoverMonitorEntry> _handoverEntries = const <HandoverMonitorEntry>[];
  String? _handoverError;

  LoadState get handoverState => _handoverState;
  List<HandoverMonitorEntry> get handoverEntries => _handoverEntries;
  String? get handoverError => _handoverError;

  HandoverTally get handoverTally => HandoverTally.from(
        _handoverEntries,
        isDemo: true,
      );

  /// Entries in one workflow state, newest first.
  List<HandoverMonitorEntry> handoversWithStatus(HandoverStatus status) =>
      _handoverEntries.where((entry) => entry.status == status).toList();

  // --- Audit ---------------------------------------------------------------

  LoadState _auditState = LoadState.idle;
  List<OpsAuditEvent> _auditEvents = const <OpsAuditEvent>[];
  AuditFilter _auditFilter = AuditFilter.all;

  LoadState get auditState => _auditState;
  List<OpsAuditEvent> get auditEvents => _auditEvents;
  AuditFilter get auditFilter => _auditFilter;

  int get emergencyAccessCount =>
      _auditEvents.where((e) => e.action.isEmergencyAccess).length;

  // --- Data source ---------------------------------------------------------

  OpsBackendStatus _backendStatus = OpsBackendStatus.unknown;
  OpsBackendStatus get backendStatus => _backendStatus;

  // --- Lifecycle -----------------------------------------------------------

  bool _bootstrapped = false;
  bool get isBootstrapped => _bootstrapped;

  /// Loads everything the shell needs and records the session-start event.
  ///
  /// The four reads are independent, so one failing source does not blank the
  /// whole dashboard: the demo providers still render while the dataset
  /// figures show their error state, and vice versa.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    await _audit.record(
      OpsAuditEvent(
        action: OpsAuditAction.sessionStarted,
        staffId: _administrator.staffId,
        hospitalId: _hospital.hospitalId,
        timestamp: _clock().toUtc(),
        isDemo: _administrator.isDemo,
      ),
    );

    await Future.wait(<Future<void>>[
      refreshSnapshot(recordAudit: false),
      refreshOccupancy(),
      refreshHandovers(),
      refreshAudit(),
    ]);
  }

  /// Re-reads every source and records the refresh.
  Future<void> refreshAll() async {
    await Future.wait(<Future<void>>[
      refreshSnapshot(),
      refreshOccupancy(),
      refreshHandovers(),
    ]);
    await refreshAudit();
  }

  Future<void> refreshSnapshot({bool recordAudit = true}) async {
    _snapshotState = LoadState.loading;
    _snapshotError = null;
    notifyListeners();

    try {
      _snapshot = await _operations.fetchSnapshot();
      _snapshotState = LoadState.ready;
    } catch (error) {
      _snapshotError = error.toString();
      _snapshotState = LoadState.failed;
    }

    _backendStatus = await _safeProbe();
    notifyListeners();

    if (recordAudit) {
      await _audit.record(
        OpsAuditEvent(
          action: OpsAuditAction.operationalDataRefreshed,
          staffId: _administrator.staffId,
          hospitalId: _hospital.hospitalId,
          timestamp: _clock().toUtc(),
          isDemo: _administrator.isDemo,
        ),
      );
      await refreshAudit();
    }
  }

  Future<OpsBackendStatus> _safeProbe() async {
    try {
      return await _operations.probeStatus();
    } catch (_) {
      // probeStatus is documented not to throw, but a mock may. The status
      // indicator must never be the thing that crashes the dashboard.
      return OpsBackendStatus.unreachable;
    }
  }

  Future<void> refreshOccupancy() async {
    _occupancyState = LoadState.loading;
    _occupancyError = null;
    notifyListeners();

    try {
      _occupancySnapshot = await _occupancy.fetchOccupancy(
        hospitalId: _hospital.hospitalId,
      );
      _occupancyState = LoadState.ready;
    } catch (error) {
      _occupancyError = error.toString();
      _occupancyState = LoadState.failed;
    }
    notifyListeners();
  }

  Future<void> refreshHandovers() async {
    _handoverState = LoadState.loading;
    _handoverError = null;
    notifyListeners();

    try {
      _handoverEntries = await _handovers.fetchHandovers(
        hospitalId: _hospital.hospitalId,
      );
      _handoverState = LoadState.ready;
    } catch (error) {
      _handoverError = error.toString();
      _handoverState = LoadState.failed;
    }
    notifyListeners();
  }

  Future<void> refreshAudit() async {
    _auditState = LoadState.loading;
    notifyListeners();
    _auditEvents = await _audit.fetchEvents(
      hospitalId: _hospital.hospitalId,
      filter: _auditFilter,
    );
    _auditState = LoadState.ready;
    notifyListeners();
  }

  Future<void> setAuditFilter(AuditFilter filter) async {
    if (_auditFilter == filter) return;
    _auditFilter = filter;
    await refreshAudit();
  }

  /// Records that a report export was requested.
  ///
  /// Phase 4A writes no file. The action is audited because an export of
  /// hospital data is exactly the kind of event a compliance reviewer needs
  /// to see, and the UI says plainly that nothing was produced.
  Future<void> recordExportRequest(String reportName) async {
    await _audit.record(
      OpsAuditEvent(
        action: OpsAuditAction.reportExportRequested,
        staffId: _administrator.staffId,
        hospitalId: _hospital.hospitalId,
        timestamp: _clock().toUtc(),
        isDemo: _administrator.isDemo,
        reason: reportName,
      ),
    );
    await refreshAudit();
  }

  // --- Derived KPIs --------------------------------------------------------

  /// The six Overview KPIs, each carrying its own provenance.
  ///
  /// Three are dataset record counts, three come from demo providers, and one
  /// has no source at all. They are built here rather than in the widget so
  /// the provenance of each is unit-testable.
  List<OpsMetric> get overviewKpis => <OpsMetric>[
        emergencyCasesKpi,
        activeAdmissionsKpi,
        occupiedRoomsKpi,
        availableRoomsKpi,
        pendingHandoversKpi,
        criticalCasesKpi,
      ];

  /// Records whose `Admission_Type` is `Emergency`.
  OpsMetric get emergencyCasesKpi {
    final current = stats;
    if (current == null) {
      return OpsMetric.unavailable(
        label: 'Emergency Cases',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return OpsMetric.datasetAggregate(
      label: 'Emergency Cases',
      value: current.emergencyAdmissionRecords,
      basis: 'Records with Admission_Type = Emergency',
      caption: 'Dataset records, not cases currently in this hospital.',
    );
  }

  /// Deliberately unavailable.
  ///
  /// An admission is active only if it has an admission time and no discharge
  /// time. `NEMRAS_Dataset.csv` records neither, and no backend route exposes
  /// an admission state, so this figure cannot be computed. Showing a record
  /// count here would be the exact misreading the brief forbids.
  OpsMetric get activeAdmissionsKpi => OpsMetric.unavailable(
        label: 'Active Admissions',
        basis: 'No admission/discharge timestamps in NEMRAS',
        caption: 'Requires an admission-discharge-transfer source.',
      );

  OpsMetric get occupiedRoomsKpi {
    final current = _occupancySnapshot;
    if (current == null) {
      return OpsMetric.unavailable(
        label: 'Occupied Rooms',
        basis: 'Demo occupancy provider not loaded.',
      );
    }
    return OpsMetric.demo(
      label: 'Occupied Rooms',
      value: current.occupiedRooms,
      basis: 'Demo occupancy provider, ${current.totalRooms} rooms',
      caption: 'Simulated. NEMRAS has no bed telemetry.',
    );
  }

  OpsMetric get availableRoomsKpi {
    final current = _occupancySnapshot;
    if (current == null) {
      return OpsMetric.unavailable(
        label: 'Available Rooms',
        basis: 'Demo occupancy provider not loaded.',
      );
    }
    return OpsMetric.demo(
      label: 'Available Rooms',
      value: current.availableRooms,
      basis: 'Demo occupancy provider, ${current.totalRooms} rooms',
      caption: 'Simulated. NEMRAS has no bed telemetry.',
    );
  }

  OpsMetric get pendingHandoversKpi {
    if (_handoverState != LoadState.ready) {
      return OpsMetric.unavailable(
        label: 'Pending Handovers',
        basis: 'Demo handover provider not loaded.',
      );
    }
    return OpsMetric.demo(
      label: 'Pending Handovers',
      value: handoverTally.pending,
      basis: 'Demo handover provider, ${handoverTally.total} cases',
      caption: 'Simulated. No live paramedic link exists.',
    );
  }

  /// Records whose `Risk_Score` is `Critical`.
  OpsMetric get criticalCasesKpi {
    final current = stats;
    if (current == null) {
      return OpsMetric.unavailable(
        label: 'Critical Cases',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return OpsMetric.datasetAggregate(
      label: 'Critical Cases',
      value: current.criticalRiskRecords,
      basis: 'Records with Risk_Score = Critical',
      caption: 'A categorical dataset label, not a live severity reading.',
    );
  }

  /// Total records in the dataset, for the header line.
  OpsMetric get datasetSizeKpi {
    final current = stats;
    if (current == null) {
      return OpsMetric.unavailable(
        label: 'Dataset Records',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return OpsMetric.datasetAggregate(
      label: 'Dataset Records',
      value: current.totalRecords,
      basis: 'Rows in NEMRAS_Dataset.csv',
    );
  }

  // --- Distributions -------------------------------------------------------

  OpsDistribution get triageDistribution => _fromStats(
        title: 'Triage Level',
        selector: (s) => s.triageLevel,
        basis: 'Triage_Level across the dataset',
      );

  OpsDistribution get riskDistribution => _fromStats(
        title: 'Risk Category',
        selector: (s) => s.riskScore,
        basis: 'Risk_Score across the dataset',
      );

  OpsDistribution get admissionTypeDistribution => _fromStats(
        title: 'Admission Type',
        selector: (s) => s.admissionType,
        basis: 'Admission_Type across the dataset',
      );

  OpsDistribution get conditionDistribution => _fromStats(
        title: 'Medical Condition',
        selector: (s) => s.medicalCondition,
        basis: 'Medical_Condition across the dataset',
      );

  OpsDistribution get chronicConditionDistribution => _fromStats(
        title: 'Chronic Condition',
        selector: (s) => s.chronicCondition,
        basis: 'Chronic_Condition across the dataset',
      );

  OpsDistribution get drugInteractionDistribution => _fromStats(
        title: 'Drug Interaction Risk',
        selector: (s) => s.drugInteractionRisk,
        basis: 'Drug_Interaction_Risk across the dataset',
      );

  /// Cases by hospital.
  ///
  /// `Hospital` is a dataset column, but no backend route aggregates it, so
  /// this reports unavailable rather than substituting the 100-row risk feed
  /// for a 64,000-row population.
  OpsDistribution get hospitalDistribution =>
      const OpsDistribution.unavailable(
        title: 'Cases by Hospital',
        basis: 'Hospital exists in the dataset but no endpoint aggregates it',
      );

  /// Medication distribution. Same gap as [hospitalDistribution].
  OpsDistribution get medicationDistribution =>
      const OpsDistribution.unavailable(
        title: 'Medication Distribution',
        basis: 'Medication exists in the dataset but no endpoint '
            'aggregates it',
      );

  /// Allergy coverage. Same gap as [hospitalDistribution].
  OpsDistribution get allergyDistribution =>
      const OpsDistribution.unavailable(
        title: 'Allergy Coverage',
        basis: 'Allergy exists in the dataset but no endpoint aggregates it',
      );

  OpsDistribution _fromStats({
    required String title,
    required Map<String, int> Function(OpsPopulationStats stats) selector,
    required String basis,
  }) {
    final current = stats;
    if (current == null) {
      return OpsDistribution.unavailable(
        title: title,
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return OpsDistribution(
      title: title,
      counts: selector(current),
      provenance: MetricProvenance.datasetAggregate,
      basis: basis,
    );
  }

  /// Triage spread within the highest-risk slice.
  ///
  /// Explicitly a sample: `/api/dashboard/critical` returns the top N by risk
  /// tier, so this skews high by construction and must never be read as a
  /// hospital-wide spread.
  OpsDistribution get riskFeedTriageDistribution {
    final feed = riskFeed;
    if (feed == null || feed.rows.isEmpty) {
      return const OpsDistribution.unavailable(
        title: 'Triage in Highest-Risk Slice',
        basis: 'Highest-risk slice not loaded.',
      );
    }
    return OpsDistribution(
      title: 'Triage in Highest-Risk Slice',
      counts: feed.countBy((row) => row.triageLevel),
      provenance: MetricProvenance.datasetSample,
      basis: 'Top ${feed.length} records by risk tier, not the population',
    );
  }

  // --- Alerts --------------------------------------------------------------

  /// Operational alerts, derived by fixed rules from figures already held.
  ///
  /// These are rules, not a model: each one is a threshold comparison, and
  /// each carries the provenance of the figure it was derived from.
  List<OpsAlert> get alerts {
    final results = <OpsAlert>[];

    final occupancySnapshot = _occupancySnapshot;
    if (occupancySnapshot != null) {
      for (final ward in occupancySnapshot.wardsUnderPressure()) {
        results.add(
          OpsAlert(
            title: '${ward.ward} at ${ward.occupancyPercentLabel} occupancy',
            detail: '${ward.occupied} of ${ward.total} rooms occupied, '
                '${ward.available} available.',
            severity: ward.occupancyFraction >= 0.95
                ? OpsAlertSeverity.critical
                : OpsAlertSeverity.warning,
            provenance: MetricProvenance.demo,
          ),
        );
      }
    }

    if (_handoverState == LoadState.ready && handoverTally.pending > 0) {
      results.add(
        OpsAlert(
          title: '${handoverTally.pending} handover'
              '${handoverTally.pending == 1 ? '' : 's'} awaiting acceptance',
          detail: 'Announced by the field and not yet accepted by clinical '
              'staff.',
          severity: handoverTally.pending >= 3
              ? OpsAlertSeverity.critical
              : OpsAlertSeverity.warning,
          provenance: MetricProvenance.demo,
        ),
      );
    }

    if (emergencyAccessCount > 0) {
      results.add(
        OpsAlert(
          title: '$emergencyAccessCount break-glass access'
              '${emergencyAccessCount == 1 ? '' : 'es'} to review',
          detail: 'Emergency access bypasses normal authorisation and '
              'requires compliance review.',
          severity: OpsAlertSeverity.warning,
          provenance: MetricProvenance.demo,
        ),
      );
    }

    if (_backendStatus == OpsBackendStatus.unreachable ||
        _backendStatus == OpsBackendStatus.degraded) {
      results.add(
        OpsAlert(
          title: 'Dataset figures unavailable',
          detail: _backendStatus.detail,
          severity: OpsAlertSeverity.critical,
          provenance: MetricProvenance.unavailable,
        ),
      );
    }

    return results;
  }
}
