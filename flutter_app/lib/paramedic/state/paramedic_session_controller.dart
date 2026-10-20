import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../api.dart';
import '../models/paramedic_models.dart';

typedef PatientLookup = Future<PatientRecord> Function(String cnic);
typedef SessionClock = DateTime Function();

/// Owns the current demo field assignment and emergency-session context.
///
/// This is deliberately local in Phase 2A. It models the boundary a future
/// backend provider will implement without claiming real dispatch, hospital
/// notification, or authorization.
class ParamedicSessionController extends ChangeNotifier {
  ParamedicSessionController({
    PatientLookup? patientLookup,
    SessionClock? clock,
    this.profile = DemoParamedicIdentity.profile,
    this.assignment = DemoParamedicIdentity.assignment,
  })  : _patientLookup = patientLookup ?? Api.getPatient,
        _clock = clock ?? DateTime.now;

  final PatientLookup _patientLookup;
  final SessionClock _clock;

  final ParamedicProfile profile;
  final AmbulanceAssignment assignment;

  PatientRecord? _patientRecord;
  EmergencySession? _emergencySession;
  final List<EmergencyAccessAuditEvent> _auditEvents =
      <EmergencyAccessAuditEvent>[];
  bool _isLookingUp = false;
  String? _lookupError;
  int _sequence = 0;

  PatientRecord? get patientRecord => _patientRecord;
  EmergencySession? get emergencySession => _emergencySession;
  UnmodifiableListView<EmergencyAccessAuditEvent> get auditEvents =>
      UnmodifiableListView<EmergencyAccessAuditEvent>(_auditEvents);
  bool get isLookingUp => _isLookingUp;
  String? get lookupError => _lookupError;
  bool get hasActiveEmergency => _emergencySession != null;

  Future<bool> lookupAndStartEmergency(String cnic) async {
    final normalized = cnic.trim();
    if (normalized.isEmpty) {
      _lookupError = 'Enter or scan a CNIC to continue.';
      notifyListeners();
      return false;
    }

    _isLookingUp = true;
    _lookupError = null;
    notifyListeners();

    try {
      final record = await _patientLookup(normalized);
      final now = _clock().toUtc();
      final sequence = ++_sequence;
      final emergencyId =
          'EMG-${now.year}-${sequence.toString().padLeft(6, '0')}';
      final patientId = 'DEMO-PAT-${sequence.toString().padLeft(6, '0')}';

      _patientRecord = record;
      _emergencySession = EmergencySession(
        emergencyId: emergencyId,
        patientId: patientId,
        paramedicId: profile.paramedicId,
        ambulanceId: assignment.ambulanceId,
        destinationHospitalId: DemoParamedicIdentity.destinationHospitalId,
        createdAt: now,
        status: EmergencyStatus.active,
        isDemo: true,
      );
      _auditEvents.add(
        EmergencyAccessAuditEvent(
          firebaseUid: profile.firebaseUid,
          paramedicId: profile.paramedicId,
          ambulanceId: assignment.ambulanceId,
          patientId: patientId,
          emergencyId: emergencyId,
          reason: 'Emergency patient lookup',
          timestamp: now,
          isDemo: true,
        ),
      );
      return true;
    } on ApiException catch (error) {
      _lookupError = error.message;
      return false;
    } catch (_) {
      _lookupError = 'Patient lookup failed. Try again.';
      return false;
    } finally {
      _isLookingUp = false;
      notifyListeners();
    }
  }

  void updateHandoverNotes(String value) {
    final session = _emergencySession;
    if (session == null) return;
    _emergencySession = session.copyWith(handoverNotes: value);
    notifyListeners();
  }

  void prepareHandover() {
    final session = _emergencySession;
    if (session == null) return;
    _emergencySession = session.copyWith(
      status: EmergencyStatus.handoverPreparing,
    );
    notifyListeners();
  }

  void markReadyForTransport() {
    final session = _emergencySession;
    if (session == null) return;
    _emergencySession = session.copyWith(
      status: EmergencyStatus.readyForTransport,
    );
    notifyListeners();
  }

  void clearEmergency() {
    _patientRecord = null;
    _emergencySession = null;
    _lookupError = null;
    notifyListeners();
  }
}
