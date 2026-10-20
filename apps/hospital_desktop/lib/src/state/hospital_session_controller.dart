import 'package:flutter/foundation.dart';

import '../data/audit_models.dart';
import '../data/clinical_api_client.dart';
import '../data/clinical_models.dart';
import '../data/demo_handover_repository.dart';
import '../data/handover_models.dart';
import '../data/staff_identity.dart';

typedef SessionClock = DateTime Function();

/// How a patient record was reached.
enum RecordAccessBasis {
  /// Reached through an ordinary clinical search.
  clinicalSearch,

  /// Reached through break-glass, with a recorded justification.
  breakGlass,
}

/// Where a loaded value is in its lifecycle, so screens can render the four
/// states the brief requires rather than conflating empty with loading.
enum LoadState { idle, loading, ready, failed }

/// Owns everything the clinical desktop needs for one staff session: the demo
/// staff identity, the emergency queue, the patient record in view, the
/// assistant transcript and the audit log.
///
/// Phase 3A keeps this local and synchronous-looking on purpose. It models the
/// boundary a backend-backed provider will implement without claiming real
/// authorisation, real dispatch or a real hospital network.
class HospitalSessionController extends ChangeNotifier {
  HospitalSessionController({
    ClinicalApiClient? apiClient,
    HandoverRepository? handoverRepository,
    AuditRepository? auditRepository,
    SessionClock? clock,
    this.hospital = DemoHospitalIdentity.hospital,
  })  : _api = apiClient ?? ClinicalApiClient(),
        _handovers = handoverRepository ?? DemoHandoverRepository(),
        _audit = auditRepository ?? InMemoryAuditRepository(),
        _clock = clock ?? DateTime.now;

  final ClinicalApiClient _api;
  final HandoverRepository _handovers;
  final AuditRepository _audit;
  final SessionClock _clock;

  final HospitalIdentity hospital;

  // --- Staff session ---------------------------------------------------

  HospitalStaffProfile? _staff;

  HospitalStaffProfile? get staff => _staff;
  bool get isSignedIn => _staff != null;

  /// Starts a clearly labelled demo session.
  ///
  /// This performs no authentication. Production sign-in must go through
  /// Firebase Authentication and the backend, which stays the security
  /// boundary; a second authentication architecture is deliberately not
  /// introduced here.
  Future<void> startDemoSession(ClinicalRole role) async {
    final profile = DemoHospitalIdentity.forRole(role);
    _staff = profile;
    _recordAudit(
      action: ClinicalAuditAction.staffSessionStarted,
      staffId: profile.staffId,
    );
    notifyListeners();
    await refreshQueue();
    await refreshOverview();
  }

  void endSession() {
    final profile = _staff;
    if (profile != null) {
      _recordAudit(
        action: ClinicalAuditAction.staffSessionEnded,
        staffId: profile.staffId,
      );
    }
    _staff = null;
    _record = null;
    _recordState = LoadState.idle;
    _recordError = null;
    _accessBasis = null;
    _breakGlassReason = null;
    _selectedEmergencyId = null;
    _assistantTranscript.clear();
    notifyListeners();
  }

  // --- Backend reachability -------------------------------------------

  bool? _backendReachable;

  /// Null until probed. Drives the top-bar system-status indicator.
  bool? get backendReachable => _backendReachable;

  Future<void> probeBackend() async {
    _backendReachable = await _api.ping();
    notifyListeners();
  }

  // --- Clinical overview ----------------------------------------------

  LoadState _overviewState = LoadState.idle;
  ClinicalPopulationStats? _stats;
  List<CriticalPatientRow> _highestRisk = const <CriticalPatientRow>[];
  String? _overviewError;

  LoadState get overviewState => _overviewState;
  ClinicalPopulationStats? get stats => _stats;
  List<CriticalPatientRow> get highestRisk => _highestRisk;
  String? get overviewError => _overviewError;

  Future<void> refreshOverview() async {
    _overviewState = LoadState.loading;
    _overviewError = null;
    notifyListeners();
    try {
      final stats = await _api.fetchStats();
      final highestRisk = await _api.fetchHighestRisk();
      _stats = stats;
      _highestRisk = highestRisk;
      _overviewState = LoadState.ready;
      _backendReachable = true;
    } on ClinicalApiException catch (error) {
      _overviewError = error.message;
      _overviewState = LoadState.failed;
      if (error.isConnectivityIssue) _backendReachable = false;
    } finally {
      notifyListeners();
    }
  }

  // --- Emergency queue ------------------------------------------------

  LoadState _queueState = LoadState.idle;
  List<EmergencyHandover> _queue = const <EmergencyHandover>[];
  String? _queueError;
  String? _selectedEmergencyId;

  LoadState get queueState => _queueState;
  List<EmergencyHandover> get queue => _queue;
  String? get queueError => _queueError;

  /// Cases still needing clinical action.
  List<EmergencyHandover> get openCases => _queue
      .where((c) => c.status != EmergencyCaseStatus.completed)
      .toList(growable: false);

  int get pendingCaseCount =>
      _queue.where((c) => c.status == EmergencyCaseStatus.pending).length;

  EmergencyHandover? get selectedCase {
    final id = _selectedEmergencyId;
    if (id == null) return null;
    for (final handover in _queue) {
      if (handover.emergencyId == id) return handover;
    }
    return null;
  }

  Future<void> refreshQueue() async {
    _queueState = LoadState.loading;
    _queueError = null;
    notifyListeners();
    try {
      _queue = await _handovers.fetchQueue(hospitalId: hospital.hospitalId);
      _queueState = LoadState.ready;
      if (_selectedEmergencyId != null && selectedCase == null) {
        _selectedEmergencyId = null;
      }
    } on Object catch (_) {
      _queueError = 'The emergency queue could not be loaded.';
      _queueState = LoadState.failed;
    } finally {
      notifyListeners();
    }
  }

  void selectCase(String emergencyId) {
    _selectedEmergencyId = emergencyId;
    notifyListeners();
  }

  void clearSelectedCase() {
    _selectedEmergencyId = null;
    notifyListeners();
  }

  /// Moves the selected case one step forward and audits the transition.
  ///
  /// Returns false when the case is already complete or no clinician is
  /// signed in, so the caller does not have to re-derive that.
  Future<bool> advanceCase(String emergencyId) async {
    final profile = _staff;
    if (profile == null) return false;

    EmergencyHandover? current;
    for (final handover in _queue) {
      if (handover.emergencyId == emergencyId) current = handover;
    }
    if (current == null) return false;

    final next = current.status.next;
    if (next == null) return false;

    final updated = await _handovers.updateStatus(
      emergencyId: emergencyId,
      status: next,
      staffId: profile.staffId,
    );
    _queue = <EmergencyHandover>[
      for (final handover in _queue)
        if (handover.emergencyId == emergencyId) updated else handover,
    ];
    _recordAudit(
      action: _auditActionForStatus(next),
      staffId: profile.staffId,
      subjectReference: updated.patientId,
      emergencyId: updated.emergencyId,
    );
    notifyListeners();
    return true;
  }

  static ClinicalAuditAction _auditActionForStatus(EmergencyCaseStatus status) {
    switch (status) {
      case EmergencyCaseStatus.accepted:
        return ClinicalAuditAction.emergencyCaseAccepted;
      case EmergencyCaseStatus.inProgress:
        return ClinicalAuditAction.emergencyTreatmentStarted;
      case EmergencyCaseStatus.completed:
        return ClinicalAuditAction.emergencyEncounterCompleted;
      case EmergencyCaseStatus.pending:
        return ClinicalAuditAction.emergencyCaseAccepted;
    }
  }

  // --- Patient record -------------------------------------------------

  LoadState _recordState = LoadState.idle;
  PatientClinicalRecord? _record;
  String? _recordError;
  RecordAccessBasis? _accessBasis;
  String? _breakGlassReason;

  LoadState get recordState => _recordState;
  PatientClinicalRecord? get record => _record;
  String? get recordError => _recordError;
  RecordAccessBasis? get accessBasis => _accessBasis;

  /// The justification recorded for the current break-glass access, if any.
  String? get breakGlassReason => _breakGlassReason;

  bool get isBreakGlassAccess => _accessBasis == RecordAccessBasis.breakGlass;

  /// Looks up a record by CNIC.
  ///
  /// [breakGlassReason] must be non-blank when [basis] is
  /// [RecordAccessBasis.breakGlass]; the lookup is refused otherwise so a
  /// reason can never be skipped.
  Future<bool> lookUpPatient(
    String cnic, {
    RecordAccessBasis basis = RecordAccessBasis.clinicalSearch,
    String? breakGlassReason,
  }) async {
    final profile = _staff;
    if (profile == null) return false;

    final normalized = cnic.trim();
    if (normalized.isEmpty) {
      _recordError = 'Enter a CNIC to search.';
      _recordState = LoadState.failed;
      notifyListeners();
      return false;
    }

    final reason = breakGlassReason?.trim() ?? '';
    if (basis == RecordAccessBasis.breakGlass && reason.isEmpty) {
      _recordError = 'Break-glass access requires a recorded reason.';
      _recordState = LoadState.failed;
      notifyListeners();
      return false;
    }

    _recordState = LoadState.loading;
    _recordError = null;
    notifyListeners();

    try {
      final record = await _api.fetchPatient(normalized);
      _record = record;
      _recordState = LoadState.ready;
      _accessBasis = basis;
      _breakGlassReason =
          basis == RecordAccessBasis.breakGlass ? reason : null;
      _backendReachable = true;
      _assistantTranscript.clear();

      if (basis == RecordAccessBasis.breakGlass) {
        _recordAudit(
          action: ClinicalAuditAction.breakGlassAccess,
          staffId: profile.staffId,
          subjectReference: _subjectReference(record.summary.cnic),
          reason: reason,
        );
      } else {
        _recordAudit(
          action: ClinicalAuditAction.patientRecordViewed,
          staffId: profile.staffId,
          subjectReference: _subjectReference(record.summary.cnic),
        );
      }
      return true;
    } on ClinicalApiException catch (error) {
      _recordError = error.message;
      _recordState = LoadState.failed;
      if (error.isConnectivityIssue) _backendReachable = false;
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearRecord() {
    _record = null;
    _recordState = LoadState.idle;
    _recordError = null;
    _accessBasis = null;
    _breakGlassReason = null;
    _assistantTranscript.clear();
    notifyListeners();
  }

  /// Records that the medication panel was reviewed for the loaded record.
  void recordMedicationReview() {
    final profile = _staff;
    final current = _record;
    if (profile == null || current == null) return;
    _recordAudit(
      action: ClinicalAuditAction.medicationSafetyReviewed,
      staffId: profile.staffId,
      subjectReference: _subjectReference(current.summary.cnic),
    );
    notifyListeners();
  }

  // --- Clinical assistant ----------------------------------------------

  final List<AssistantTurn> _assistantTranscript = <AssistantTurn>[];
  bool _assistantBusy = false;

  List<AssistantTurn> get assistantTranscript =>
      List<AssistantTurn>.unmodifiable(_assistantTranscript);
  bool get assistantBusy => _assistantBusy;

  /// Sends a question to the backend's record-grounded responder.
  ///
  /// The responder is rule-based and scoped to the loaded record. It is not a
  /// trained clinical model and the transcript must be labelled accordingly.
  Future<void> askAssistant(String question) async {
    final profile = _staff;
    final current = _record;
    final text = question.trim();
    if (profile == null || current == null || text.isEmpty) return;

    _assistantTranscript.add(AssistantTurn.question(text, _clock().toUtc()));
    _assistantBusy = true;
    notifyListeners();

    try {
      final reply = await _api.askGroundedResponder(
        cnic: current.summary.cnic,
        message: text,
      );
      _assistantTranscript.add(
        AssistantTurn.answer(reply, _clock().toUtc()),
      );
      _recordAudit(
        action: ClinicalAuditAction.assistantQuerySubmitted,
        staffId: profile.staffId,
        subjectReference: _subjectReference(current.summary.cnic),
      );
    } on ClinicalApiException catch (error) {
      _assistantTranscript.add(
        AssistantTurn.failure(error.message, _clock().toUtc()),
      );
      if (error.isConnectivityIssue) _backendReachable = false;
    } finally {
      _assistantBusy = false;
      notifyListeners();
    }
  }

  // --- Audit ------------------------------------------------------------

  List<ClinicalAuditEvent> get auditEvents => _audit.events;

  int get breakGlassEventCount =>
      _audit.events.where((e) => e.action.isEmergencyAccess).length;

  void _recordAudit({
    required ClinicalAuditAction action,
    required String staffId,
    String? subjectReference,
    String? emergencyId,
    String? reason,
  }) {
    _audit.record(
      ClinicalAuditEvent(
        action: action,
        staffId: staffId,
        hospitalId: hospital.hospitalId,
        timestamp: _clock().toUtc(),
        isDemo: true,
        subjectReference: subjectReference,
        emergencyId: emergencyId,
        reason: reason,
      ),
    );
  }

  /// Reduces a CNIC to a non-identifying reference for the audit log.
  ///
  /// A real audit store must use a keyed HMAC computed server-side, as
  /// `backend/identity_store.py` already does. This is a display-only
  /// placeholder and is not a privacy control.
  static String _subjectReference(String cnic) {
    final digits = cnic.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'PAT-REF-****';
    return 'PAT-REF-****${digits.substring(digits.length - 4)}';
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

/// One entry in the assistant transcript.
enum AssistantTurnKind { question, answer, failure }

@immutable
class AssistantTurn {
  const AssistantTurn({
    required this.kind,
    required this.text,
    required this.timestamp,
  });

  factory AssistantTurn.question(String text, DateTime at) =>
      AssistantTurn(kind: AssistantTurnKind.question, text: text,
          timestamp: at);

  factory AssistantTurn.answer(String text, DateTime at) =>
      AssistantTurn(kind: AssistantTurnKind.answer, text: text, timestamp: at);

  factory AssistantTurn.failure(String text, DateTime at) =>
      AssistantTurn(kind: AssistantTurnKind.failure, text: text,
          timestamp: at);

  final AssistantTurnKind kind;
  final String text;
  final DateTime timestamp;
}
