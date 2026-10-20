import 'package:flutter/foundation.dart';

import 'national_models.dart';

/// The kinds of event the national governance screen reports on.
///
/// The clinical and hospital values mirror the vocabularies the Phase 3A and
/// Phase 4A surfaces use, so one audit language covers all five surfaces.
enum NationalAuditAction {
  analystSessionStarted,
  nationalDashboardViewed,
  aggregateDataRefreshed,
  nationalReportExportRequested,
  breakGlassAccessGranted,
  patientRecordViewed,
  hospitalAccessPolicyChanged,
  federationNodeRegistered,
  federationSyncFailed,
  governanceReviewCompleted,
}

extension NationalAuditActionLabel on NationalAuditAction {
  String get label {
    switch (this) {
      case NationalAuditAction.analystSessionStarted:
        return 'Analyst session started';
      case NationalAuditAction.nationalDashboardViewed:
        return 'National dashboard viewed';
      case NationalAuditAction.aggregateDataRefreshed:
        return 'Aggregate data refreshed';
      case NationalAuditAction.nationalReportExportRequested:
        return 'National report export requested';
      case NationalAuditAction.breakGlassAccessGranted:
        return 'Break-glass access granted';
      case NationalAuditAction.patientRecordViewed:
        return 'Patient record viewed';
      case NationalAuditAction.hospitalAccessPolicyChanged:
        return 'Hospital access policy changed';
      case NationalAuditAction.federationNodeRegistered:
        return 'Federation node registered';
      case NationalAuditAction.federationSyncFailed:
        return 'Federation synchronisation failed';
      case NationalAuditAction.governanceReviewCompleted:
        return 'Governance review completed';
    }
  }

  /// How the event is categorised on the governance screen.
  NationalAuditCategory get category {
    switch (this) {
      case NationalAuditAction.breakGlassAccessGranted:
        return NationalAuditCategory.emergencyAccess;
      case NationalAuditAction.patientRecordViewed:
        return NationalAuditCategory.patientAccess;
      case NationalAuditAction.hospitalAccessPolicyChanged:
      case NationalAuditAction.governanceReviewCompleted:
        return NationalAuditCategory.governance;
      case NationalAuditAction.federationNodeRegistered:
      case NationalAuditAction.federationSyncFailed:
        return NationalAuditCategory.federation;
      case NationalAuditAction.analystSessionStarted:
      case NationalAuditAction.nationalDashboardViewed:
      case NationalAuditAction.aggregateDataRefreshed:
      case NationalAuditAction.nationalReportExportRequested:
        return NationalAuditCategory.analystActivity;
    }
  }

  bool get isEmergencyAccess =>
      category == NationalAuditCategory.emergencyAccess;

  /// True for events that touched a record rather than an aggregate. These
  /// are reported at national level as counts and never with content.
  bool get touchesPatientData =>
      category == NationalAuditCategory.emergencyAccess ||
      category == NationalAuditCategory.patientAccess;
}

/// The access categories the governance screen groups events into.
enum NationalAuditCategory {
  emergencyAccess,
  patientAccess,
  governance,
  federation,
  analystActivity,
}

extension NationalAuditCategoryLabel on NationalAuditCategory {
  String get label {
    switch (this) {
      case NationalAuditCategory.emergencyAccess:
        return 'Emergency access';
      case NationalAuditCategory.patientAccess:
        return 'Patient access';
      case NationalAuditCategory.governance:
        return 'Governance';
      case NationalAuditCategory.federation:
        return 'Federation';
      case NationalAuditCategory.analystActivity:
        return 'Analyst activity';
    }
  }

  String get shortLabel {
    switch (this) {
      case NationalAuditCategory.emergencyAccess:
        return 'EMERGENCY';
      case NationalAuditCategory.patientAccess:
        return 'PATIENT';
      case NationalAuditCategory.governance:
        return 'GOVERNANCE';
      case NationalAuditCategory.federation:
        return 'FEDERATION';
      case NationalAuditCategory.analystActivity:
        return 'ANALYST';
    }
  }
}

/// A single national audit entry.
///
/// There is no patient reference field of any kind, not even a masked one.
/// Phase 4A's hospital compliance screen carries a masked reference because a
/// hospital reviewer may legitimately need to trace one access back to one
/// encounter within their own facility. A national analyst has no such
/// mandate, so national events record only that an access of a given
/// category occurred, by which staff identifier, at which facility, and when.
@immutable
class NationalAuditEvent {
  const NationalAuditEvent({
    required this.action,
    required this.actorId,
    required this.organizationId,
    required this.timestamp,
    required this.isDemo,
    this.hospitalId,
    this.nodeId,
    this.note,
  });

  final NationalAuditAction action;

  /// The staff or analyst identifier that performed the action.
  final String actorId;

  /// The national organisation the event is scoped to.
  final String organizationId;

  /// UTC. Stored UTC and formatted at the edge, so a log read in another
  /// timezone is unambiguous.
  final DateTime timestamp;

  final bool isDemo;

  /// The facility the event occurred at, where applicable.
  final String? hospitalId;

  /// The federation node involved, where applicable.
  final String? nodeId;

  /// A short operational note. Never clinical content and never an
  /// identifier.
  final String? note;

  NationalAuditCategory get category => action.category;

  String get hospitalLabel => hospitalId ?? kNotAvailable;
  String get nodeLabel => nodeId ?? kNotAvailable;
  String get noteLabel => note ?? kNotAvailable;
  bool get hasNote => (note ?? '').trim().isNotEmpty;
}

/// How the governance screen narrows the log.
enum GovernanceFilter {
  all,
  emergencyAccess,
  patientAccess,
  governance,
  federation,
}

extension GovernanceFilterLabel on GovernanceFilter {
  String get label {
    switch (this) {
      case GovernanceFilter.all:
        return 'All events';
      case GovernanceFilter.emergencyAccess:
        return 'Emergency access';
      case GovernanceFilter.patientAccess:
        return 'Patient access';
      case GovernanceFilter.governance:
        return 'Governance';
      case GovernanceFilter.federation:
        return 'Federation';
    }
  }

  bool matches(NationalAuditEvent event) {
    switch (this) {
      case GovernanceFilter.all:
        return true;
      case GovernanceFilter.emergencyAccess:
        return event.category == NationalAuditCategory.emergencyAccess;
      case GovernanceFilter.patientAccess:
        return event.category == NationalAuditCategory.patientAccess;
      case GovernanceFilter.governance:
        return event.category == NationalAuditCategory.governance;
      case GovernanceFilter.federation:
        return event.category == NationalAuditCategory.federation;
    }
  }
}

/// The read boundary for the national audit trail.
///
/// A production NEMRAS must persist this server-side and must aggregate it
/// before it reaches a national surface. Phase 5A keeps a demo trail in
/// memory so the governance screens have something real to render.
abstract interface class NationalAuditRepository {
  Future<void> record(NationalAuditEvent event);

  /// Newest first, optionally narrowed.
  Future<List<NationalAuditEvent>> fetchEvents({
    required String organizationId,
    GovernanceFilter filter,
  });
}

/// An in-memory national audit trail.
class InMemoryNationalAuditRepository implements NationalAuditRepository {
  InMemoryNationalAuditRepository({
    List<NationalAuditEvent> seed = const <NationalAuditEvent>[],
  }) : _events = List<NationalAuditEvent>.of(seed);

  final List<NationalAuditEvent> _events;

  @override
  Future<void> record(NationalAuditEvent event) async {
    // Inserted at the front so the list stays newest-first without a sort on
    // every read.
    _events.insert(0, event);
  }

  @override
  Future<List<NationalAuditEvent>> fetchEvents({
    required String organizationId,
    GovernanceFilter filter = GovernanceFilter.all,
  }) async {
    return _events
        .where((event) => event.organizationId == organizationId)
        .where(filter.matches)
        .toList(growable: false);
  }

  int get length => _events.length;
}

/// A seeded demo trail, so Governance is not empty on boot.
///
/// The entries describe plausible national oversight activity. They are
/// labelled demo and record nothing that actually happened.
List<NationalAuditEvent> demoNationalAuditSeed({
  required String organizationId,
  DateTime? now,
}) {
  final base = (now ?? DateTime.now()).toUtc();

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
      timestamp: base.subtract(Duration(minutes: minutesAgo)),
      isDemo: true,
      hospitalId: hospitalId,
      nodeId: nodeId,
      note: note,
    );
  }

  return <NationalAuditEvent>[
    event(NationalAuditAction.aggregateDataRefreshed, 3),
    event(
      NationalAuditAction.breakGlassAccessGranted,
      14,
      actorId: 'STAFF-001',
      hospitalId: 'HOSP-001',
      note: 'Reason recorded at the facility. Not replicated nationally.',
    ),
    event(
      NationalAuditAction.federationSyncFailed,
      22,
      actorId: 'SYSTEM',
      nodeId: 'NMR-008',
      note: 'Simulated node stopped reporting.',
    ),
    event(
      NationalAuditAction.patientRecordViewed,
      35,
      actorId: 'STAFF-002',
      hospitalId: 'HOSP-001',
      note: 'Counted nationally. Record content is not replicated.',
    ),
    event(
      NationalAuditAction.hospitalAccessPolicyChanged,
      68,
      actorId: 'ANALYST-002',
      hospitalId: 'HOSP-002',
      note: 'Break-glass review window shortened to 24 hours.',
    ),
    event(
      NationalAuditAction.federationNodeRegistered,
      140,
      actorId: 'ANALYST-002',
      nodeId: 'NMR-006',
    ),
    event(
      NationalAuditAction.breakGlassAccessGranted,
      190,
      actorId: 'STAFF-004',
      hospitalId: 'HOSP-002',
      note: 'Reason recorded at the facility. Not replicated nationally.',
    ),
    event(
      NationalAuditAction.governanceReviewCompleted,
      260,
      actorId: 'ANALYST-001',
      note: 'Quarterly emergency-access review signed off.',
    ),
    event(NationalAuditAction.analystSessionStarted, 320),
  ];
}
