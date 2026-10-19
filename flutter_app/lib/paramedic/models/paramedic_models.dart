import 'package:flutter/foundation.dart';

/// A staff identity resolved from Firebase in production.
///
/// The Phase 2A instance is explicitly synthetic and grants no backend
/// authorization. CNIC is never used as a paramedic identifier.
@immutable
class ParamedicProfile {
  const ParamedicProfile({
    required this.firebaseUid,
    required this.paramedicId,
    required this.displayLabel,
    required this.isDemo,
  });

  final String firebaseUid;
  final String paramedicId;
  final String displayLabel;
  final bool isDemo;
}

enum AssignmentStatus { active, paused, offShift }

@immutable
class AmbulanceAssignment {
  const AmbulanceAssignment({
    required this.ambulanceId,
    required this.shiftLabel,
    required this.status,
    required this.isDemo,
  });

  final String ambulanceId;
  final String shiftLabel;
  final AssignmentStatus status;
  final bool isDemo;
}

enum EmergencyStatus {
  active,
  handoverPreparing,
  readyForTransport,
  closed,
}

/// Context shared by the field shell and a future Hospital Clinical App.
@immutable
class EmergencySession {
  const EmergencySession({
    required this.emergencyId,
    required this.patientId,
    required this.paramedicId,
    required this.ambulanceId,
    required this.destinationHospitalId,
    required this.createdAt,
    required this.status,
    required this.isDemo,
    this.handoverNotes = '',
  });

  final String emergencyId;
  final String patientId;
  final String paramedicId;
  final String ambulanceId;
  final String destinationHospitalId;
  final DateTime createdAt;
  final EmergencyStatus status;
  final bool isDemo;
  final String handoverNotes;

  EmergencySession copyWith({
    String? destinationHospitalId,
    EmergencyStatus? status,
    String? handoverNotes,
  }) {
    return EmergencySession(
      emergencyId: emergencyId,
      patientId: patientId,
      paramedicId: paramedicId,
      ambulanceId: ambulanceId,
      destinationHospitalId:
          destinationHospitalId ?? this.destinationHospitalId,
      createdAt: createdAt,
      status: status ?? this.status,
      isDemo: isDemo,
      handoverNotes: handoverNotes ?? this.handoverNotes,
    );
  }
}

/// Local Phase 2A representation of a future backend audit event.
///
/// It intentionally carries only synthetic identifiers and a reason—never a
/// CNIC, patient name, token, medical field, or handover note.
@immutable
class EmergencyAccessAuditEvent {
  const EmergencyAccessAuditEvent({
    required this.firebaseUid,
    required this.paramedicId,
    required this.ambulanceId,
    required this.patientId,
    required this.emergencyId,
    required this.reason,
    required this.timestamp,
    required this.isDemo,
  });

  final String firebaseUid;
  final String paramedicId;
  final String ambulanceId;
  final String patientId;
  final String emergencyId;
  final String reason;
  final DateTime timestamp;
  final bool isDemo;
}

abstract final class DemoParamedicIdentity {
  static const ParamedicProfile profile = ParamedicProfile(
    firebaseUid: 'DEMO-PARAMEDIC-UID',
    paramedicId: 'PARA-001',
    displayLabel: 'Demo Paramedic',
    isDemo: true,
  );

  static const AmbulanceAssignment assignment = AmbulanceAssignment(
    ambulanceId: 'NEMRAS-AMB-001',
    shiftLabel: 'DEMO SHIFT A',
    status: AssignmentStatus.active,
    isDemo: true,
  );

  static const String destinationHospitalId = 'HOSP-001';
}
