import 'dart:collection';

import 'package:flutter/foundation.dart';

/// What a clinical audit event records.
enum ClinicalAuditAction {
  staffSessionStarted,
  staffSessionEnded,
  patientRecordViewed,
  breakGlassAccess,
  emergencyCaseAccepted,
  emergencyTreatmentStarted,
  emergencyEncounterCompleted,
  medicationSafetyReviewed,
  assistantQuerySubmitted,
}

extension ClinicalAuditActionLabel on ClinicalAuditAction {
  String get label {
    switch (this) {
      case ClinicalAuditAction.staffSessionStarted:
        return 'Staff session started';
      case ClinicalAuditAction.staffSessionEnded:
        return 'Staff session ended';
      case ClinicalAuditAction.patientRecordViewed:
        return 'Patient record viewed';
      case ClinicalAuditAction.breakGlassAccess:
        return 'Break-glass access';
      case ClinicalAuditAction.emergencyCaseAccepted:
        return 'Emergency case accepted';
      case ClinicalAuditAction.emergencyTreatmentStarted:
        return 'Emergency treatment started';
      case ClinicalAuditAction.emergencyEncounterCompleted:
        return 'Emergency encounter completed';
      case ClinicalAuditAction.medicationSafetyReviewed:
        return 'Medication safety reviewed';
      case ClinicalAuditAction.assistantQuerySubmitted:
        return 'Clinical assistant query';
    }
  }

  /// Break-glass is the only action the UI treats as exceptional.
  bool get isEmergencyAccess => this == ClinicalAuditAction.breakGlassAccess;
}

/// A single audit entry.
///
/// Deliberately carries no CNIC, patient name, medical field, ID token or
/// free-text clinical content. [subjectReference] is a NEMRAS-side
/// pseudonymous identifier such as `DEMO-PAT-000001`, never a real identifier.
@immutable
class ClinicalAuditEvent {
  const ClinicalAuditEvent({
    required this.action,
    required this.staffId,
    required this.hospitalId,
    required this.timestamp,
    required this.isDemo,
    this.subjectReference,
    this.emergencyId,
    this.reason,
  });

  final ClinicalAuditAction action;
  final String staffId;
  final String hospitalId;

  /// UTC.
  final DateTime timestamp;

  /// True for every Phase 3A event. Nothing here is a production audit record.
  final bool isDemo;

  /// Pseudonymous reference to the subject of the action, when there is one.
  final String? subjectReference;
  final String? emergencyId;

  /// The justification a clinician typed. Required for break-glass access.
  final String? reason;
}

/// The boundary a backend-backed audit log will implement.
///
/// Phase 3A ships only [InMemoryAuditRepository]. A later phase can post these
/// events to an append-only backend store without changing the screens.
abstract interface class AuditRepository {
  /// Newest first.
  List<ClinicalAuditEvent> get events;

  void record(ClinicalAuditEvent event);
}

/// A session-scoped audit log.
///
/// Entries live only as long as the process. This is not a durable or
/// tamper-evident audit trail, and the UI says so.
class InMemoryAuditRepository implements AuditRepository {
  final List<ClinicalAuditEvent> _events = <ClinicalAuditEvent>[];

  @override
  UnmodifiableListView<ClinicalAuditEvent> get events =>
      UnmodifiableListView<ClinicalAuditEvent>(_events);

  @override
  void record(ClinicalAuditEvent event) => _events.insert(0, event);
}
