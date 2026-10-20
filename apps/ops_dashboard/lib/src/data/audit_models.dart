import 'package:flutter/foundation.dart';

import 'operations_models.dart';

/// The kinds of event the compliance screens report on.
///
/// The clinical values mirror `ClinicalAuditAction` in the Hospital Clinical
/// Desktop so one audit vocabulary covers both surfaces.
enum OpsAuditAction {
  sessionStarted,
  sessionEnded,
  dashboardViewed,
  operationalDataRefreshed,
  reportExportRequested,
  patientRecordViewed,
  breakGlassAccessGranted,
  emergencyCaseAccepted,
  emergencyCaseCompleted,
  settingsViewed,
}

extension OpsAuditActionLabel on OpsAuditAction {
  String get label {
    switch (this) {
      case OpsAuditAction.sessionStarted:
        return 'Session started';
      case OpsAuditAction.sessionEnded:
        return 'Session ended';
      case OpsAuditAction.dashboardViewed:
        return 'Dashboard viewed';
      case OpsAuditAction.operationalDataRefreshed:
        return 'Operational data refreshed';
      case OpsAuditAction.reportExportRequested:
        return 'Report export requested';
      case OpsAuditAction.patientRecordViewed:
        return 'Patient record viewed';
      case OpsAuditAction.breakGlassAccessGranted:
        return 'Break-glass access granted';
      case OpsAuditAction.emergencyCaseAccepted:
        return 'Emergency case accepted';
      case OpsAuditAction.emergencyCaseCompleted:
        return 'Emergency case completed';
      case OpsAuditAction.settingsViewed:
        return 'Settings viewed';
    }
  }

  /// True for events that bypassed or widened normal access control. These
  /// must be reviewable on their own, which is what break-glass auditing is
  /// for.
  bool get isEmergencyAccess =>
      this == OpsAuditAction.breakGlassAccessGranted;

  /// True for events that touched a patient record rather than an aggregate.
  bool get touchesPatientData =>
      this == OpsAuditAction.patientRecordViewed ||
      this == OpsAuditAction.breakGlassAccessGranted;
}

/// A single audit entry.
///
/// [subjectReference] is a masked reference, never a CNIC. A production audit
/// store must derive it with a server-side keyed HMAC so an entry cannot be
/// reversed to an identity by anyone holding the log.
@immutable
class OpsAuditEvent {
  const OpsAuditEvent({
    required this.action,
    required this.staffId,
    required this.hospitalId,
    required this.timestamp,
    required this.isDemo,
    this.subjectReference,
    this.emergencyId,
    this.reason,
  });

  final OpsAuditAction action;
  final String staffId;
  final String hospitalId;

  /// UTC. Stored UTC and formatted at the edge, so a log read in a different
  /// timezone is still unambiguous.
  final DateTime timestamp;
  final bool isDemo;

  /// Masked patient reference, present only for patient-scoped actions.
  final String? subjectReference;
  final String? emergencyId;

  /// The justification recorded for a break-glass access.
  final String? reason;

  String get subjectLabel => subjectReference ?? kNotAvailable;
  String get reasonLabel => reason ?? kNotAvailable;
  bool get hasReason => (reason ?? '').trim().isNotEmpty;
}

/// How the compliance screens narrow the log.
enum AuditFilter {
  all,
  emergencyAccess,
  patientAccess,
  operationalActivity,
}

extension AuditFilterLabel on AuditFilter {
  String get label {
    switch (this) {
      case AuditFilter.all:
        return 'All events';
      case AuditFilter.emergencyAccess:
        return 'Emergency access';
      case AuditFilter.patientAccess:
        return 'Patient access';
      case AuditFilter.operationalActivity:
        return 'Operational activity';
    }
  }

  bool matches(OpsAuditEvent event) {
    switch (this) {
      case AuditFilter.all:
        return true;
      case AuditFilter.emergencyAccess:
        return event.action.isEmergencyAccess;
      case AuditFilter.patientAccess:
        return event.action.touchesPatientData;
      case AuditFilter.operationalActivity:
        return !event.action.touchesPatientData;
    }
  }
}

/// The write-and-read boundary for the audit trail.
///
/// A production NEMRAS must persist this server-side: an audit log the client
/// owns is one the client can edit. Phase 4A keeps it in memory so the
/// compliance screens have something real to render.
abstract interface class AuditRepository {
  Future<void> record(OpsAuditEvent event);

  /// Newest first, optionally narrowed.
  Future<List<OpsAuditEvent>> fetchEvents({
    required String hospitalId,
    AuditFilter filter,
  });
}

/// An in-memory audit trail.
class InMemoryAuditRepository implements AuditRepository {
  InMemoryAuditRepository({List<OpsAuditEvent> seed = const <OpsAuditEvent>[]})
      : _events = List<OpsAuditEvent>.of(seed);

  final List<OpsAuditEvent> _events;

  @override
  Future<void> record(OpsAuditEvent event) async {
    // Inserted at the front so the list stays newest-first without a sort on
    // every read.
    _events.insert(0, event);
  }

  @override
  Future<List<OpsAuditEvent>> fetchEvents({
    required String hospitalId,
    AuditFilter filter = AuditFilter.all,
  }) async {
    return _events
        .where((event) => event.hospitalId == hospitalId)
        .where(filter.matches)
        .toList(growable: false);
  }

  int get length => _events.length;
}

/// A seeded demo trail, so Compliance and Audit Trail are not empty on boot.
///
/// The entries describe plausible administrative activity and carry staff ids
/// from the demo identity set. They are labelled demo and record nothing that
/// actually happened.
List<OpsAuditEvent> demoAuditSeed({
  required String hospitalId,
  DateTime? now,
}) {
  final base = (now ?? DateTime.now()).toUtc();
  OpsAuditEvent event(
    OpsAuditAction action,
    int minutesAgo, {
    String staffId = 'STAFF-001',
    String? subjectReference,
    String? emergencyId,
    String? reason,
  }) {
    return OpsAuditEvent(
      action: action,
      staffId: staffId,
      hospitalId: hospitalId,
      timestamp: base.subtract(Duration(minutes: minutesAgo)),
      isDemo: true,
      subjectReference: subjectReference,
      emergencyId: emergencyId,
      reason: reason,
    );
  }

  return <OpsAuditEvent>[
    event(OpsAuditAction.operationalDataRefreshed, 4, staffId: 'ADMIN-001'),
    event(
      OpsAuditAction.breakGlassAccessGranted,
      11,
      subjectReference: 'PAT-REF-****0001',
      emergencyId: 'EMG-2026-000001',
      reason: 'Unconscious patient, no consent obtainable.',
    ),
    event(
      OpsAuditAction.emergencyCaseAccepted,
      22,
      emergencyId: 'EMG-2026-000002',
    ),
    event(
      OpsAuditAction.patientRecordViewed,
      31,
      staffId: 'STAFF-002',
      subjectReference: 'PAT-REF-****0003',
    ),
    event(OpsAuditAction.dashboardViewed, 38, staffId: 'ADMIN-002'),
    event(
      OpsAuditAction.emergencyCaseCompleted,
      96,
      staffId: 'STAFF-002',
      emergencyId: 'EMG-2026-000004',
    ),
    event(OpsAuditAction.sessionStarted, 120, staffId: 'ADMIN-001'),
  ];
}
