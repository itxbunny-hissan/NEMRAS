import 'package:flutter/foundation.dart';

import '../data/analyst_identity.dart';
import '../data/federation_models.dart';
import '../data/governance_models.dart';
import '../data/hospital_aggregate_models.dart';
import '../data/metric_provenance.dart';
import '../data/national_models.dart';

/// Where an asynchronous read has got to.
enum LoadState { idle, loading, ready, failed }

extension LoadStateFlags on LoadState {
  bool get isLoading => this == LoadState.loading;
  bool get isReady => this == LoadState.ready;
  bool get hasFailed => this == LoadState.failed;
}

/// Holds the national state the dashboard renders.
///
/// A plain [ChangeNotifier] so NEMRAS takes on no state-management
/// dependency, matching the other four surfaces. Every data source arrives as
/// an interface, so tests inject mocks and nothing here needs a backend.
///
/// All KPI and distribution derivation lives here rather than in widgets, so
/// the provenance of every national figure is unit-testable without pumping a
/// frame.
class NationalConsoleController extends ChangeNotifier {
  NationalConsoleController({
    required NationalRepository nationalRepository,
    required HospitalAggregateRepository hospitalRepository,
    required FederationRepository federationRepository,
    required NationalAuditRepository auditRepository,
    MinistryAnalystProfile? analyst,
    NationalOrganization? organization,
    this.environment = NationalEnvironment.demo,
    DateTime Function()? clock,
  })  : _national = nationalRepository,
        _hospitals = hospitalRepository,
        _federation = federationRepository,
        _audit = auditRepository,
        _analyst = analyst ?? DemoMinistryIdentity.analyst,
        _organization = organization ?? DemoMinistryIdentity.organization,
        _clock = clock ?? DateTime.now;

  final NationalRepository _national;
  final HospitalAggregateRepository _hospitals;
  final FederationRepository _federation;
  final NationalAuditRepository _audit;

  /// Injected so "as of" timestamps and staleness are deterministic in tests.
  /// The dashboard renders a data-freshness timestamp rather than a ticking
  /// clock, so no widget holds a periodic timer.
  final DateTime Function() _clock;

  final MinistryAnalystProfile _analyst;
  final NationalOrganization _organization;

  /// Which build this is. Drives the demo indicator on every screen.
  final NationalEnvironment environment;

  MinistryAnalystProfile get analyst => _analyst;
  NationalOrganization get organization => _organization;
  DateTime get now => _clock();

  /// The only honest reporting period: no endpoint aggregates by date.
  ReportingPeriod get reportingPeriod => ReportingPeriod.datasetWide;

  // --- National aggregates -------------------------------------------------

  LoadState _snapshotState = LoadState.idle;
  NationalSnapshot? _snapshot;
  String? _snapshotError;

  LoadState get snapshotState => _snapshotState;
  NationalSnapshot? get snapshot => _snapshot;
  String? get snapshotError => _snapshotError;
  NationalStats? get stats => _snapshot?.stats;
  RiskSample? get riskSample => _snapshot?.riskSample;

  // --- Hospital network ----------------------------------------------------

  LoadState _hospitalState = LoadState.idle;
  HospitalNetworkSummary? _hospitalSummary;
  String? _hospitalError;

  LoadState get hospitalState => _hospitalState;
  HospitalNetworkSummary? get hospitalSummary => _hospitalSummary;
  String? get hospitalError => _hospitalError;

  // --- Federation ----------------------------------------------------------

  LoadState _federationState = LoadState.idle;
  FederationSnapshot? _federationSnapshot;
  String? _federationError;

  LoadState get federationState => _federationState;
  FederationSnapshot? get federation => _federationSnapshot;
  String? get federationError => _federationError;

  FederationTally? get federationTally => _federationSnapshot?.tally;

  // --- Governance ----------------------------------------------------------

  LoadState _auditState = LoadState.idle;
  List<NationalAuditEvent> _auditEvents = const <NationalAuditEvent>[];
  GovernanceFilter _governanceFilter = GovernanceFilter.all;
  String? _auditError;

  LoadState get auditState => _auditState;
  List<NationalAuditEvent> get auditEvents => _auditEvents;
  GovernanceFilter get governanceFilter => _governanceFilter;
  String? get auditError => _auditError;

  int get emergencyAccessCount =>
      _auditEvents.where((event) => event.action.isEmergencyAccess).length;

  int get patientAccessCount => _auditEvents
      .where((event) => event.category == NationalAuditCategory.patientAccess)
      .length;

  /// Event counts per access category, for the governance summary.
  Map<NationalAuditCategory, int> get auditCategoryCounts {
    final counts = <NationalAuditCategory, int>{};
    for (final category in NationalAuditCategory.values) {
      counts[category] =
          _auditEvents.where((event) => event.category == category).length;
    }
    return counts;
  }

  // --- Data source ---------------------------------------------------------

  NationalDataSourceStatus _dataSourceStatus =
      NationalDataSourceStatus.unknown;
  NationalDataSourceStatus get dataSourceStatus => _dataSourceStatus;

  // --- Lifecycle -----------------------------------------------------------

  bool _bootstrapped = false;
  bool get isBootstrapped => _bootstrapped;

  /// Loads everything the shell needs and records the session-start event.
  ///
  /// The reads are independent, so one failing source does not blank the
  /// whole dashboard.
  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    await _audit.record(
      NationalAuditEvent(
        action: NationalAuditAction.analystSessionStarted,
        actorId: _analyst.analystId,
        organizationId: _organization.organizationId,
        timestamp: _clock().toUtc(),
        isDemo: _analyst.isDemo,
      ),
    );

    await Future.wait(<Future<void>>[
      refreshSnapshot(recordAudit: false),
      refreshHospitalNetwork(),
      refreshFederation(),
      refreshAudit(),
    ]);
  }

  /// Re-reads every source and records the refresh.
  Future<void> refreshAll() async {
    await Future.wait(<Future<void>>[
      refreshSnapshot(),
      refreshHospitalNetwork(),
      refreshFederation(),
    ]);
    await refreshAudit();
  }

  Future<void> refreshSnapshot({bool recordAudit = true}) async {
    _snapshotState = LoadState.loading;
    _snapshotError = null;
    notifyListeners();

    try {
      _snapshot = await _national.fetchSnapshot();
      _snapshotState = LoadState.ready;
    } catch (error) {
      _snapshotError = error.toString();
      _snapshotState = LoadState.failed;
    }

    _dataSourceStatus = await _safeProbe();
    notifyListeners();

    if (recordAudit) {
      await _audit.record(
        NationalAuditEvent(
          action: NationalAuditAction.aggregateDataRefreshed,
          actorId: _analyst.analystId,
          organizationId: _organization.organizationId,
          timestamp: _clock().toUtc(),
          isDemo: _analyst.isDemo,
        ),
      );
      await refreshAudit();
    }
  }

  Future<NationalDataSourceStatus> _safeProbe() async {
    try {
      return await _national.probeStatus();
    } catch (_) {
      // probeStatus is documented not to throw, but a mock may. The status
      // indicator must never be the thing that crashes the dashboard.
      return NationalDataSourceStatus.unreachable;
    }
  }

  Future<void> refreshHospitalNetwork() async {
    _hospitalState = LoadState.loading;
    _hospitalError = null;
    notifyListeners();

    try {
      _hospitalSummary = await _hospitals.fetchNetworkSummary();
      _hospitalState = LoadState.ready;
    } catch (error) {
      _hospitalError = error.toString();
      _hospitalState = LoadState.failed;
    }
    notifyListeners();
  }

  Future<void> refreshFederation() async {
    _federationState = LoadState.loading;
    _federationError = null;
    notifyListeners();

    try {
      _federationSnapshot = await _federation.fetchFederation(
        organizationId: _organization.organizationId,
      );
      _federationState = LoadState.ready;
    } catch (error) {
      _federationError = error.toString();
      _federationState = LoadState.failed;
    }
    notifyListeners();
  }

  Future<void> refreshAudit() async {
    _auditState = LoadState.loading;
    _auditError = null;
    notifyListeners();

    try {
      _auditEvents = await _audit.fetchEvents(
        organizationId: _organization.organizationId,
        filter: _governanceFilter,
      );
      _auditState = LoadState.ready;
    } catch (error) {
      // A failed audit read must surface as a failed state rather than
      // propagating: it is called from bootstrap and from every refresh, and
      // an unhandled throw there would leave the whole dashboard loading.
      _auditError = error.toString();
      _auditEvents = const <NationalAuditEvent>[];
      _auditState = LoadState.failed;
    }
    notifyListeners();
  }

  Future<void> setGovernanceFilter(GovernanceFilter filter) async {
    if (_governanceFilter == filter) return;
    _governanceFilter = filter;
    await refreshAudit();
  }

  /// Records that a national report export was requested.
  ///
  /// Phase 5A writes no file. The action is audited because an export of
  /// national health data is exactly the kind of event a governance reviewer
  /// needs to see, and the UI says plainly that nothing was produced.
  Future<void> recordExportRequest(String reportName) async {
    await _audit.record(
      NationalAuditEvent(
        action: NationalAuditAction.nationalReportExportRequested,
        actorId: _analyst.analystId,
        organizationId: _organization.organizationId,
        timestamp: _clock().toUtc(),
        isDemo: _analyst.isDemo,
        note: reportName,
      ),
    );
    await refreshAudit();
  }

  // --- National KPIs ------------------------------------------------------

  /// The National Overview indicators, each carrying its own provenance.
  List<NationalMetric> get overviewKpis => <NationalMetric>[
        totalRecordsKpi,
        emergencyRecordsKpi,
        criticalRiskKpi,
        highTriageKpi,
        chronicConditionKpi,
        conditionVarietyKpi,
      ];

  NationalMetric get totalRecordsKpi => _aggregate(
        label: 'Total Dataset Records',
        select: (stats) => stats.totalRecords,
        basis: 'Rows in NEMRAS_Dataset.csv',
        caption: 'Dataset records. Not a national population figure.',
      );

  NationalMetric get emergencyRecordsKpi => _aggregate(
        label: 'Emergency Records',
        select: (stats) => stats.emergencyRecords,
        basis: 'Records with Admission_Type = Emergency',
        caption: 'Dataset records, not emergencies in progress.',
      );

  NationalMetric get criticalRiskKpi => _aggregate(
        label: 'Critical Risk Records',
        select: (stats) => stats.criticalRiskRecords,
        basis: 'Records with Risk_Score = Critical',
        caption: 'A categorical dataset label, not a probability.',
      );

  NationalMetric get highTriageKpi => _aggregate(
        label: 'High Triage Records',
        select: (stats) => stats.highTriageRecords,
        basis: 'Records with Triage_Level = High',
        caption: 'Dataset records, not current triage decisions.',
      );

  NationalMetric get chronicConditionKpi => _aggregate(
        label: 'Chronic Condition Records',
        select: (stats) => stats.chronicRecords,
        basis: 'Records with Chronic_Condition = Yes',
        caption: 'Dataset records, not national disease prevalence.',
      );

  NationalMetric get conditionVarietyKpi => _aggregate(
        label: 'Distinct Conditions',
        select: (stats) => stats.conditionVariety,
        basis: 'Unique Medical_Condition values in the dataset',
        caption: 'Free-text condition names, not ICD-coded categories.',
      );

  NationalMetric get drugInteractionKpi => _aggregate(
        label: 'Interaction-Flagged Records',
        select: (stats) => stats.interactionFlaggedRecords,
        basis: 'Records with Drug_Interaction_Risk = Yes',
        caption: 'A binary dataset flag with no severity grading.',
      );

  /// The dataset mean of `Age`, the only age statistic available.
  NationalMetric get averageAgeKpi {
    final current = stats;
    final average = current?.averageAge;
    if (current == null || average == null) {
      return NationalMetric.unavailable(
        label: 'Mean Recorded Age',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return NationalMetric.datasetMeasure(
      label: 'Mean Recorded Age',
      value: average,
      basis: 'Mean of Age across the dataset',
      caption: 'A mean only. No age bands are exposed.',
    );
  }

  /// Age distribution. Deliberately unavailable.
  ///
  /// `Age` is in the dataset, but `GET /api/stats` returns only its mean. An
  /// age distribution needs banded counts, and deriving bands client-side
  /// would mean paging every record into the browser, which this surface must
  /// not do.
  NationalMetric get ageDistributionKpi => NationalMetric.unavailable(
        label: 'Age Distribution',
        basis: 'No banded age counts exposed by any endpoint',
        caption: 'Only the dataset mean is available.',
      );

  /// Gender distribution. Deliberately unavailable.
  ///
  /// `Gender` is a dataset column and the patient endpoint returns it per
  /// record, but no endpoint aggregates it, and a national surface must not
  /// read records to count them.
  NationalMetric get genderDistributionKpi => NationalMetric.unavailable(
        label: 'Gender Distribution',
        basis: 'Gender is in the dataset but no endpoint aggregates it',
        caption: 'Requires an aggregate endpoint.',
      );

  /// Any geographic figure. Permanently unavailable on this dataset.
  NationalMetric get geographicCoverageKpi => NationalMetric.unavailable(
        label: 'Geographic Coverage',
        basis: 'No province, district or coordinate field exists',
        caption: 'Geographic breakdown is not available in this dataset.',
      );

  /// Emergency admissions as a share of all records.
  ///
  /// A derived statistic, so it is labelled as one: it is a ratio of two
  /// dataset counts and nothing more.
  NationalMetric get emergencyShareKpi {
    final current = stats;
    if (current == null || current.totalRecords <= 0) {
      return NationalMetric.unavailable(
        label: 'Emergency Share',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    final share =
        current.emergencyRecords / current.totalRecords * 100;
    return NationalMetric.datasetMeasure(
      label: 'Emergency Share',
      value: share,
      basis: 'Emergency records as a percent of all dataset records',
      caption: 'Derived from two dataset counts. Not an incidence rate.',
    );
  }

  /// Simulated federated nodes reporting normally.
  NationalMetric get federationOnlineKpi {
    final tally = federationTally;
    if (tally == null || _federationState != LoadState.ready) {
      return NationalMetric.unavailable(
        label: 'Nodes Online',
        basis: 'Demo federation provider not loaded.',
      );
    }
    return NationalMetric.demo(
      label: 'Nodes Online',
      value: tally.online,
      basis: 'Demo federation provider, ${tally.total} simulated nodes',
      caption: 'Simulated. No federated infrastructure exists.',
    );
  }

  /// Simulated records synchronised across the demo federation.
  NationalMetric get federationRecordsKpi {
    final tally = federationTally;
    if (tally == null || _federationState != LoadState.ready) {
      return NationalMetric.unavailable(
        label: 'Records Synchronised',
        basis: 'Demo federation provider not loaded.',
      );
    }
    return NationalMetric.demo(
      label: 'Records Synchronised',
      value: tally.recordsSynchronized,
      basis: 'Demo federation provider, cumulative',
      caption: 'Simulated. No synchronisation has occurred.',
    );
  }

  /// National network latency. Never available.
  ///
  /// The reference dashboard shows a P95 latency figure. NEMRAS has no node
  /// agents and no telemetry pipeline, so there is nothing to measure, and a
  /// simulated latency presented beside real dataset counts would be the most
  /// misleading number on the screen.
  NationalMetric get networkLatencyKpi => NationalMetric.unavailable(
        label: 'National P95 Latency',
        basis: 'No node telemetry exists in NEMRAS',
        caption: 'Requires instrumented federated nodes.',
      );

  /// Emergency visits in the last 24 hours. Never available.
  NationalMetric get recentEmergencyKpi => NationalMetric.unavailable(
        label: 'Emergency Visits · 24h',
        basis: 'No endpoint aggregates Admission_Date',
        caption: 'The dataset carries dates; no route groups by them.',
      );

  /// The operations headline the reference command dashboard leads with.
  /// None of it has a source: NEMRAS receives no dispatch, CAD or bed feed.
  List<NationalMetric> get operationsKpis => <NationalMetric>[
        activeIncidentsKpi,
        recentEmergencyKpi,
        bedOccupancyKpi,
        dispatchSpeedKpi,
      ];

  NationalMetric get activeIncidentsKpi => NationalMetric.unavailable(
        label: 'Active Emergency Incidents',
        basis: 'No live incident or dispatch feed reaches NEMRAS',
        caption: 'Requires a national dispatch integration.',
      );

  /// Bed and diversion figures the hospital-network reference leads with.
  /// Facility record counts, when an endpoint supplies them, are separate.
  List<NationalMetric> get networkCapacityKpis => <NationalMetric>[
        NationalMetric.unavailable(
          label: 'Total network beds',
          basis: 'No facility reports a bed count to NEMRAS',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Network occupancy',
          basis: 'Occupancy needs a bed count, which is not recorded',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Immediately available beds',
          basis: 'No facility reports available beds',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Active diversions',
          basis: 'No diversion or surge feed is connected',
          caption: 'Not available.',
        ),
      ];

  NationalMetric get bedOccupancyKpi => NationalMetric.unavailable(
        label: 'National ER Bed Occupancy',
        basis: 'No hospital reports bed or capacity data to NEMRAS',
        caption: 'Requires facility capacity reporting.',
      );

  /// Operational rates the regional analytics reference leads with.
  /// None of them can be computed from the dataset aggregates.
  List<NationalMetric> get trendOperationalKpis => <NationalMetric>[
        NationalMetric.unavailable(
          label: 'National average response',
          basis: 'NEMRAS records no dispatch or on-scene timestamps',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Median handoff latency',
          basis: 'No hospital handoff times are recorded',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Critical survival rate',
          basis: 'The dataset has no outcome or survival field',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Break-glass override rate',
          basis: 'Break-glass events are facility audit records, not a '
              'share of national intakes',
          caption: 'Not available as a rate.',
        ),
      ];

  NationalMetric get dispatchSpeedKpi => NationalMetric.unavailable(
        label: 'Median Dispatch Time',
        basis: 'NEMRAS records no dispatch timestamps',
        caption: 'Requires dispatch event times.',
      );

  NationalMetric _aggregate({
    required String label,
    required int Function(NationalStats stats) select,
    required String basis,
    String? caption,
  }) {
    final current = stats;
    if (current == null) {
      return NationalMetric.unavailable(
        label: label,
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return NationalMetric.datasetAggregate(
      label: label,
      value: select(current),
      basis: basis,
      caption: caption,
    );
  }

  // --- Distributions -------------------------------------------------------

  NationalDistribution get triageDistribution => _distribution(
        title: 'Triage Level',
        select: (stats) => stats.triageLevel,
        basis: 'Triage_Level across the dataset',
      );

  NationalDistribution get riskDistribution => _distribution(
        title: 'Risk Category',
        select: (stats) => stats.riskScore,
        basis: 'Risk_Score across the dataset',
      );

  NationalDistribution get admissionTypeDistribution => _distribution(
        title: 'Admission Type',
        select: (stats) => stats.admissionType,
        basis: 'Admission_Type across the dataset',
      );

  NationalDistribution get conditionDistribution => _distribution(
        title: 'Medical Condition',
        select: (stats) => stats.medicalCondition,
        basis: 'Medical_Condition across the dataset',
      );

  NationalDistribution get chronicConditionDistribution => _distribution(
        title: 'Chronic Condition',
        select: (stats) => stats.chronicCondition,
        basis: 'Chronic_Condition across the dataset',
      );

  NationalDistribution get drugInteractionDistribution => _distribution(
        title: 'Drug Interaction Risk',
        select: (stats) => stats.drugInteractionRisk,
        basis: 'Drug_Interaction_Risk across the dataset',
      );

  /// Emergency against everything else, derived from the admission mix.
  NationalDistribution get emergencyShareDistribution {
    final current = stats;
    if (current == null || current.totalRecords <= 0) {
      return const NationalDistribution.unavailable(
        title: 'Emergency vs Non-Emergency',
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return NationalDistribution(
      title: 'Emergency vs Non-Emergency',
      counts: <String, int>{
        'Emergency': current.emergencyRecords,
        'Non-emergency': current.nonEmergencyRecords,
      },
      provenance: MetricProvenance.datasetAggregate,
      basis: 'Derived from Admission_Type across the dataset',
    );
  }

  /// Gender distribution, reported unavailable.
  NationalDistribution get genderDistribution =>
      const NationalDistribution.unavailable(
        title: 'Gender Distribution',
        basis: 'Gender is in the dataset but no endpoint aggregates it',
      );

  /// Age distribution, reported unavailable.
  NationalDistribution get ageDistribution =>
      const NationalDistribution.unavailable(
        title: 'Age Distribution',
        basis: 'Only the dataset mean of Age is exposed, not banded counts',
      );

  /// Cases by hospital, reported unavailable.
  NationalDistribution get hospitalDistribution =>
      const NationalDistribution.unavailable(
        title: 'Records by Hospital',
        basis: 'Hospital is in the dataset but no endpoint aggregates it',
      );

  /// Triage spread within the highest-risk slice.
  ///
  /// Explicitly a sample: the endpoint returns the top N by risk tier, so
  /// this skews high by construction and must never be read as a national
  /// spread.
  NationalDistribution get riskSampleTriageDistribution {
    final sample = riskSample;
    if (sample == null || sample.isEmpty) {
      return const NationalDistribution.unavailable(
        title: 'Triage in Highest-Risk Slice',
        basis: 'Highest-risk slice not loaded.',
      );
    }
    return NationalDistribution(
      title: 'Triage in Highest-Risk Slice',
      counts: sample.countBy((row) => row.triageLevel),
      provenance: MetricProvenance.datasetSample,
      basis: 'Top ${sample.length} records by risk tier, not the population',
    );
  }

  /// Condition spread within the highest-risk slice.
  NationalDistribution get riskSampleConditionDistribution {
    final sample = riskSample;
    if (sample == null || sample.isEmpty) {
      return const NationalDistribution.unavailable(
        title: 'Conditions in Highest-Risk Slice',
        basis: 'Highest-risk slice not loaded.',
      );
    }
    return NationalDistribution(
      title: 'Conditions in Highest-Risk Slice',
      counts: sample.countBy((row) => row.medicalCondition),
      provenance: MetricProvenance.datasetSample,
      basis: 'Top ${sample.length} records by risk tier, not the population',
    );
  }

  NationalDistribution _distribution({
    required String title,
    required Map<String, int> Function(NationalStats stats) select,
    required String basis,
  }) {
    final current = stats;
    if (current == null) {
      return NationalDistribution.unavailable(
        title: title,
        basis: 'Dataset aggregate not loaded.',
      );
    }
    return NationalDistribution(
      title: title,
      counts: select(current),
      provenance: MetricProvenance.datasetAggregate,
      basis: basis,
    );
  }

  /// Live incident figures the reports reference leads with.
  /// Dataset report tables are a separate, supported view.
  List<NationalMetric> get incidentArchiveKpis => <NationalMetric>[
        NationalMetric.unavailable(
          label: 'Incidents in 7 days',
          basis: 'No endpoint groups emergencies by date',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Mean response time',
          basis: 'NEMRAS records no dispatch timestamps',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Signed break-glass audits',
          basis: 'Break-glass reasons stay at the facility and are not a '
              'signed national count',
          caption: 'Not available.',
        ),
        NationalMetric.unavailable(
          label: 'Active regional units',
          basis: 'No province or responding-unit registry is connected',
          caption: 'Not available.',
        ),
      ];

  /// The eight national reports the Reports screen lists, in order.
  List<NationalDistribution> get nationalReports => <NationalDistribution>[
        admissionTypeDistribution,
        triageDistribution,
        riskDistribution,
        chronicConditionDistribution,
        conditionDistribution,
        drugInteractionDistribution,
        ageDistribution,
        genderDistribution,
      ];

  // --- Alerts --------------------------------------------------------------

  /// Governance and data-quality alerts, derived by fixed rules.
  List<NationalAlert> get alerts {
    final results = <NationalAlert>[];

    if (_dataSourceStatus == NationalDataSourceStatus.unreachable ||
        _dataSourceStatus == NationalDataSourceStatus.degraded) {
      results.add(
        NationalAlert(
          title: 'National aggregates unavailable',
          detail: _dataSourceStatus.detail,
          severity: NationalAlertSeverity.critical,
          provenance: MetricProvenance.unavailable,
        ),
      );
    }

    final snapshot = _federationSnapshot;
    if (snapshot != null) {
      final flagged = snapshot.nodesNeedingAttention(now);
      if (flagged.isNotEmpty) {
        results.add(
          NationalAlert(
            title: '${flagged.length} simulated node'
                '${flagged.length == 1 ? '' : 's'} not reporting normally',
            detail: 'Nodes ${flagged.map((n) => n.nodeId).join(', ')} are '
                'degraded or offline in the demo federation.',
            severity: snapshot.tally.offline > 0
                ? NationalAlertSeverity.critical
                : NationalAlertSeverity.warning,
            provenance: MetricProvenance.demo,
          ),
        );
      }
    }

    if (emergencyAccessCount > 0) {
      results.add(
        NationalAlert(
          title: '$emergencyAccessCount break-glass access'
              '${emergencyAccessCount == 1 ? '' : 'es'} to review',
          detail: 'Emergency access bypasses normal authorisation. Reasons '
              'are recorded at the facility and are not replicated '
              'nationally.',
          severity: NationalAlertSeverity.warning,
          provenance: MetricProvenance.demo,
        ),
      );
    }

    // Raised unconditionally: the absence of geography is a standing property
    // of this dataset, not a transient condition, and the national surface is
    // where it most needs stating.
    results.add(
      const NationalAlert(
        title: 'No geographic breakdown is possible',
        detail: 'The dataset records no province, district or coordinate, so '
            'no figure on this dashboard is broken down by location.',
        severity: NationalAlertSeverity.info,
        provenance: MetricProvenance.unavailable,
      ),
    );

    return results;
  }
}
