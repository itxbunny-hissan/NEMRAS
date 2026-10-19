import 'package:flutter/foundation.dart';

import 'clinical_models.dart';

/// Where an incoming emergency case has got to inside the hospital.
///
/// [pending] through [completed] are hospital-side states. They describe what
/// this hospital has done with the case, not an ambulance's physical position:
/// NEMRAS has no GPS, telemetry or ETA source.
enum EmergencyCaseStatus {
  /// Announced by the field but not yet picked up by clinical staff.
  pending,

  /// A clinician has accepted responsibility for the case.
  accepted,

  /// The patient is being treated.
  inProgress,

  /// Treatment finished and the encounter was closed.
  completed,
}

extension EmergencyCaseStatusLabel on EmergencyCaseStatus {
  String get label {
    switch (this) {
      case EmergencyCaseStatus.pending:
        return 'PENDING';
      case EmergencyCaseStatus.accepted:
        return 'ACCEPTED';
      case EmergencyCaseStatus.inProgress:
        return 'IN PROGRESS';
      case EmergencyCaseStatus.completed:
        return 'COMPLETED';
    }
  }

  String get description {
    switch (this) {
      case EmergencyCaseStatus.pending:
        return 'Announced by the field. Not yet accepted by clinical staff.';
      case EmergencyCaseStatus.accepted:
        return 'Accepted by clinical staff. Awaiting arrival or assessment.';
      case EmergencyCaseStatus.inProgress:
        return 'Patient is under active treatment in this hospital.';
      case EmergencyCaseStatus.completed:
        return 'Encounter closed. No further clinical action pending.';
    }
  }

  /// The single forward transition allowed from this state, or null when the
  /// case is finished.
  EmergencyCaseStatus? get next {
    switch (this) {
      case EmergencyCaseStatus.pending:
        return EmergencyCaseStatus.accepted;
      case EmergencyCaseStatus.accepted:
        return EmergencyCaseStatus.inProgress;
      case EmergencyCaseStatus.inProgress:
        return EmergencyCaseStatus.completed;
      case EmergencyCaseStatus.completed:
        return null;
    }
  }

  /// The label for the button that performs [next].
  String? get advanceActionLabel {
    switch (this) {
      case EmergencyCaseStatus.pending:
        return 'Accept case';
      case EmergencyCaseStatus.accepted:
        return 'Start treatment';
      case EmergencyCaseStatus.inProgress:
        return 'Complete encounter';
      case EmergencyCaseStatus.completed:
        return null;
    }
  }
}

/// The clinical snapshot a paramedic hands to the hospital.
///
/// Only fields NEMRAS actually records are modelled. Everything the dataset
/// does not carry — vitals, laboratory values, ICD codes — is absent rather
/// than filled with a plausible number.
@immutable
class HandoverClinicalSnapshot {
  const HandoverClinicalSnapshot({
    required this.patientLabel,
    required this.ageLabel,
    required this.gender,
    required this.bloodType,
    required this.medicalCondition,
    required this.chronicCondition,
    required this.medication,
    required this.allergy,
    required this.drugInteractionRisk,
    required this.triageLevel,
    required this.riskCategory,
  });

  /// A display label, never a CNIC. Demo cases carry a synthetic label.
  final String patientLabel;
  final String ageLabel;
  final String gender;
  final String bloodType;
  final String medicalCondition;
  final String chronicCondition;
  final String medication;
  final String allergy;
  final String drugInteractionRisk;

  /// `High` / `Medium` / `Low` from `Triage_Level`.
  final String triageLevel;

  /// `Critical` / `Elevated` / `Stable` from `Risk_Score`.
  ///
  /// A categorical label, not a clinically validated probability.
  final String riskCategory;

  bool get hasRecordedAllergy =>
      allergy != kNotAvailable && allergy.toLowerCase() != 'none';

  bool get hasDrugInteractionFlag => drugInteractionRisk.toLowerCase() == 'yes';

  bool get hasChronicCondition => chronicCondition.toLowerCase() == 'yes';
}

/// An emergency handover as the hospital receives it.
///
/// This mirrors the `EmergencySession` the Phase 2A paramedic shell builds, so
/// a later integration can map one onto the other without reshaping the
/// hospital UI. Nothing here implies a live network connection.
@immutable
class EmergencyHandover {
  const EmergencyHandover({
    required this.emergencyId,
    required this.patientId,
    required this.paramedicId,
    required this.ambulanceId,
    required this.destinationHospitalId,
    required this.announcedAt,
    required this.status,
    required this.snapshot,
    required this.isDemo,
    this.handoverNotes = '',
    this.acceptedByStaffId,
  });

  final String emergencyId;
  final String patientId;
  final String paramedicId;
  final String ambulanceId;
  final String destinationHospitalId;

  /// When the field announced the case, in UTC.
  final DateTime announcedAt;
  final EmergencyCaseStatus status;
  final HandoverClinicalSnapshot snapshot;

  /// True for every Phase 3A case. The UI must surface this.
  final bool isDemo;

  /// Free text written by the paramedic. Empty when none was recorded.
  final String handoverNotes;

  /// Set once a clinician accepts the case.
  final String? acceptedByStaffId;

  bool get hasHandoverNotes => handoverNotes.trim().isNotEmpty;

  EmergencyHandover copyWith({
    EmergencyCaseStatus? status,
    String? handoverNotes,
    String? acceptedByStaffId,
  }) {
    return EmergencyHandover(
      emergencyId: emergencyId,
      patientId: patientId,
      paramedicId: paramedicId,
      ambulanceId: ambulanceId,
      destinationHospitalId: destinationHospitalId,
      announcedAt: announcedAt,
      status: status ?? this.status,
      snapshot: snapshot,
      isDemo: isDemo,
      handoverNotes: handoverNotes ?? this.handoverNotes,
      acceptedByStaffId: acceptedByStaffId ?? this.acceptedByStaffId,
    );
  }
}

/// The boundary a real paramedic-to-hospital transport will implement.
///
/// Phase 3A ships only [DemoHandoverRepository]. A later phase can add a
/// backend-backed implementation without touching the screens, which depend on
/// this interface rather than on the demo class.
abstract interface class HandoverRepository {
  /// Cases announced to [hospitalId], newest first.
  Future<List<EmergencyHandover>> fetchQueue({required String hospitalId});

  /// Records a status change and returns the updated case.
  Future<EmergencyHandover> updateStatus({
    required String emergencyId,
    required EmergencyCaseStatus status,
    required String staffId,
  });
}
