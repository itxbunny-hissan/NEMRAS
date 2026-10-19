import 'package:flutter/foundation.dart';

import 'operations_models.dart';

/// Where an incoming emergency case has got to inside the hospital.
///
/// The names mirror `EmergencyCaseStatus` in the Hospital Clinical Desktop so
/// a future shared package can map the two one-for-one. These are hospital
/// workflow states and say nothing about an ambulance's physical position:
/// NEMRAS has no GPS, telemetry or ETA source.
enum HandoverStatus {
  /// Announced by the field, not yet accepted by clinical staff.
  incoming,

  /// A clinician has accepted responsibility for the case.
  accepted,

  /// The patient is under active treatment.
  inProgress,

  /// Encounter closed.
  completed,
}

extension HandoverStatusLabel on HandoverStatus {
  String get label {
    switch (this) {
      case HandoverStatus.incoming:
        return 'INCOMING';
      case HandoverStatus.accepted:
        return 'ACCEPTED';
      case HandoverStatus.inProgress:
        return 'IN PROGRESS';
      case HandoverStatus.completed:
        return 'COMPLETED';
    }
  }

  /// What the operations reader should take from this state.
  String get operationalMeaning {
    switch (this) {
      case HandoverStatus.incoming:
        return 'Awaiting clinical acceptance. Counts towards pending '
            'handovers.';
      case HandoverStatus.accepted:
        return 'Accepted by clinical staff. Awaiting arrival or assessment.';
      case HandoverStatus.inProgress:
        return 'Under active treatment. Occupies clinical capacity.';
      case HandoverStatus.completed:
        return 'Closed. No further operational action.';
    }
  }

  /// True when the case still needs someone to act on it.
  bool get isPending => this == HandoverStatus.incoming;

  /// True when the case is consuming clinical capacity right now.
  bool get isActive =>
      this == HandoverStatus.accepted || this == HandoverStatus.inProgress;
}

/// One handover as the operations dashboard sees it.
///
/// Deliberately thinner than the clinical desktop's `EmergencyHandover`: an
/// operations reader needs triage weight, destination and workflow state, not
/// a clinical snapshot. Patient identity is reduced to a non-identifying
/// [caseReference] and no CNIC is carried on this object at all.
@immutable
class HandoverMonitorEntry {
  const HandoverMonitorEntry({
    required this.emergencyId,
    required this.caseReference,
    required this.triageLevel,
    required this.riskCategory,
    required this.paramedicId,
    required this.ambulanceId,
    required this.destinationHospitalId,
    required this.destinationWard,
    required this.announcedAt,
    required this.status,
    required this.isDemo,
    this.acceptedByStaffId,
  });

  final String emergencyId;

  /// A masked operational reference, never a patient identifier.
  final String caseReference;

  /// `High` / `Medium` / `Low`, matching the dataset's `Triage_Level`.
  final String triageLevel;

  /// `Critical` / `Elevated` / `Stable`, matching `Risk_Score`.
  ///
  /// A categorical label, not a validated probability.
  final String riskCategory;

  final String paramedicId;
  final String ambulanceId;
  final String destinationHospitalId;

  /// The receiving area. Demo-only: NEMRAS records no bed assignment.
  final String destinationWard;

  /// When the field announced the case, in UTC.
  final DateTime announcedAt;
  final HandoverStatus status;

  /// True for every Phase 4A entry. The UI must surface this.
  final bool isDemo;

  final String? acceptedByStaffId;

  String get acceptedByLabel => acceptedByStaffId ?? kNotAvailable;

  /// How long the case has been open, from [announcedAt] to [now].
  ///
  /// [now] is passed in rather than read from the clock so the value is
  /// deterministic in tests and so no widget holds a ticking timer.
  Duration waitingFor(DateTime now) =>
      now.toUtc().difference(announcedAt).isNegative
          ? Duration.zero
          : now.toUtc().difference(announcedAt);

  String waitingLabel(DateTime now) {
    final elapsed = waitingFor(now);
    final minutes = elapsed.inMinutes;
    if (minutes < 60) return '${minutes}m';
    final hours = elapsed.inHours;
    return '${hours}h ${minutes - hours * 60}m';
  }
}

/// Counts by workflow state, for the monitor header and the Overview KPIs.
@immutable
class HandoverTally {
  const HandoverTally({
    required this.incoming,
    required this.accepted,
    required this.inProgress,
    required this.completed,
    required this.isDemo,
  });

  factory HandoverTally.from(
    List<HandoverMonitorEntry> entries, {
    required bool isDemo,
  }) {
    int count(HandoverStatus status) =>
        entries.where((entry) => entry.status == status).length;
    return HandoverTally(
      incoming: count(HandoverStatus.incoming),
      accepted: count(HandoverStatus.accepted),
      inProgress: count(HandoverStatus.inProgress),
      completed: count(HandoverStatus.completed),
      isDemo: isDemo,
    );
  }

  final int incoming;
  final int accepted;
  final int inProgress;
  final int completed;
  final bool isDemo;

  int get total => incoming + accepted + inProgress + completed;

  /// Cases still awaiting clinical acceptance.
  int get pending => incoming;

  /// Cases consuming clinical capacity.
  int get active => accepted + inProgress;
}

/// The read boundary for handover state.
///
/// Phase 4A ships only a demo implementation. The interface is shaped so a
/// later transport — polling, SSE or a WebSocket — can serve it without any
/// screen changing, but no such transport exists yet and the dashboard is not
/// connected to the clinical desktop at runtime.
abstract interface class HandoverMonitorRepository {
  /// Cases announced to [hospitalId], newest first.
  Future<List<HandoverMonitorEntry>> fetchHandovers({
    required String hospitalId,
  });
}
