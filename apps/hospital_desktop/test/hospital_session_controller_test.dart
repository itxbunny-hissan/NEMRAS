import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_desktop/src/data/audit_models.dart';
import 'package:hospital_desktop/src/data/clinical_models.dart';
import 'package:hospital_desktop/src/data/demo_handover_repository.dart';
import 'package:hospital_desktop/src/data/handover_models.dart';
import 'package:hospital_desktop/src/data/staff_identity.dart';
import 'package:hospital_desktop/src/state/hospital_session_controller.dart';

import 'support/fake_backend.dart';

HospitalSessionController buildController({
  int patientStatus = 200,
  int chatStatus = 200,
  Map<String, dynamic>? patient,
  bool offline = false,
  DateTime? now,
}) {
  final clock = now ?? DateTime.utc(2026, 10, 4, 9, 30);
  return HospitalSessionController(
    apiClient: offline
        ? offlineApiClient()
        : fakeApiClient(
            patientStatus: patientStatus,
            chatStatus: chatStatus,
            patient: patient,
          ),
    handoverRepository: DemoHandoverRepository(seedTime: clock),
    auditRepository: InMemoryAuditRepository(),
    clock: () => clock,
  );
}

void main() {
  group('demo staff session', () {
    test('starting a session records a demo staff identity', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(controller.isSignedIn, isFalse);

      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      expect(controller.isSignedIn, isTrue);
      expect(controller.staff!.staffId, 'STAFF-001');
      expect(controller.staff!.hospitalId, 'HOSP-001');
      expect(controller.staff!.isDemo, isTrue);
      expect(controller.hospital.hospitalId, 'HOSP-001');
    });

    test('each role resolves to its own labelled demo profile', () {
      for (final role in ClinicalRole.values) {
        final profile = DemoHospitalIdentity.forRole(role);
        expect(profile.role, role);
        expect(profile.isDemo, isTrue);
      }
    });

    test('ending a session clears clinical context', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');
      controller.selectCase('EMG-2026-000001');
      expect(controller.record, isNotNull);
      expect(controller.selectedCase, isNotNull);

      controller.endSession();

      expect(controller.isSignedIn, isFalse);
      expect(controller.record, isNull);
      expect(controller.selectedCase, isNull);
      expect(controller.recordState, LoadState.idle);
    });
  });

  group('patient lookup', () {
    test('a successful lookup exposes only recorded fields', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      final found = await controller.lookUpPatient('00000-0000001-0');

      expect(found, isTrue);
      expect(controller.recordState, LoadState.ready);
      expect(controller.record!.summary.medicalCondition, 'Heart Disease');
      expect(controller.record!.summary.riskScore, 'Critical');
      expect(controller.record!.alerts, hasLength(2));
      expect(controller.accessBasis, RecordAccessBasis.clinicalSearch);
      expect(controller.isBreakGlassAccess, isFalse);
    });

    test('a missing discharge date reads as unavailable, not as a value',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.lookUpPatient('00000-0000001-0');

      expect(controller.record!.summary.dischargeDate, kNotAvailable);
    });

    test('a 404 leaves the record empty and surfaces a safe message',
        () async {
      final controller = buildController(patientStatus: 404);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      final found = await controller.lookUpPatient('00000-0000009-9');

      expect(found, isFalse);
      expect(controller.recordState, LoadState.failed);
      expect(controller.record, isNull);
      expect(controller.recordError, contains('No patient record found'));
      // The backend's own detail echoes the requested CNIC, so it must not
      // be forwarded to the UI.
      expect(controller.recordError, isNot(contains('00000-0000009-9')));
    });

    test('a blank CNIC fails without reaching the backend', () async {
      final controller = buildController(offline: true);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      final found = await controller.lookUpPatient('   ');

      expect(found, isFalse);
      expect(controller.recordError, 'Enter a CNIC to search.');
    });

    test('a transport failure marks the backend unreachable', () async {
      final controller = buildController(offline: true);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      final found = await controller.lookUpPatient('00000-0000001-0');

      expect(found, isFalse);
      expect(controller.recordState, LoadState.failed);
      expect(controller.backendReachable, isFalse);
    });

    test('lookup is refused when no clinician is signed in', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      expect(await controller.lookUpPatient('00000-0000001-0'), isFalse);
      expect(controller.record, isNull);
    });
  });

  group('emergency handover queue', () {
    test('loads the demo cases for this hospital, newest first', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      expect(controller.queueState, LoadState.ready);
      expect(controller.queue, hasLength(3));
      expect(controller.queue.first.emergencyId, 'EMG-2026-000001');
      expect(
        controller.queue.every(
          (c) => c.destinationHospitalId == 'HOSP-001',
        ),
        isTrue,
      );
    });

    test('every demo case is labelled as demo', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);

      expect(controller.queue.every((c) => c.isDemo), isTrue);
    });

    test('carries the paramedic handover context the field app produces',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);

      final first = controller.queue.first;
      expect(first.paramedicId, 'PARA-001');
      expect(first.ambulanceId, 'NEMRAS-AMB-001');
      expect(first.snapshot.triageLevel, 'High');
      expect(first.snapshot.riskCategory, 'Critical');
      expect(first.snapshot.hasRecordedAllergy, isTrue);
      expect(first.hasHandoverNotes, isTrue);
    });

    test('pending count reflects the queue rather than a fixed literal',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);

      expect(controller.pendingCaseCount, 1);
      expect(controller.openCases, hasLength(3));
    });

    test('selecting and clearing a case moves the detail pane', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.nurse);

      expect(controller.selectedCase, isNull);
      controller.selectCase('EMG-2026-000002');
      expect(controller.selectedCase!.emergencyId, 'EMG-2026-000002');
      controller.clearSelectedCase();
      expect(controller.selectedCase, isNull);
    });
  });

  group('emergency status transitions', () {
    test('a case advances pending to accepted to in progress to completed',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      EmergencyCaseStatus statusOf(String id) =>
          controller.queue.firstWhere((c) => c.emergencyId == id).status;

      expect(statusOf('EMG-2026-000001'), EmergencyCaseStatus.pending);

      expect(await controller.advanceCase('EMG-2026-000001'), isTrue);
      expect(statusOf('EMG-2026-000001'), EmergencyCaseStatus.accepted);

      expect(await controller.advanceCase('EMG-2026-000001'), isTrue);
      expect(statusOf('EMG-2026-000001'), EmergencyCaseStatus.inProgress);

      expect(await controller.advanceCase('EMG-2026-000001'), isTrue);
      expect(statusOf('EMG-2026-000001'), EmergencyCaseStatus.completed);
    });

    test('a completed case cannot advance further', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      for (var i = 0; i < 3; i++) {
        await controller.advanceCase('EMG-2026-000003');
      }
      expect(
        controller.queue
            .firstWhere((c) => c.emergencyId == 'EMG-2026-000003')
            .status,
        EmergencyCaseStatus.completed,
      );
      expect(await controller.advanceCase('EMG-2026-000003'), isFalse);
    });

    test('accepting a case records the accepting clinician', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await controller.advanceCase('EMG-2026-000001');

      expect(
        controller.queue
            .firstWhere((c) => c.emergencyId == 'EMG-2026-000001')
            .acceptedByStaffId,
        'STAFF-001',
      );
    });

    test('an unknown case id is rejected', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      expect(await controller.advanceCase('EMG-9999-999999'), isFalse);
    });

    test('a completed case leaves the open list but stays in the queue',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.advanceCase('EMG-2026-000003');
      expect(controller.openCases, hasLength(2));
      expect(controller.queue, hasLength(3));
    });

    test('the status model declares one forward transition per state', () {
      expect(
        EmergencyCaseStatus.pending.next,
        EmergencyCaseStatus.accepted,
      );
      expect(
        EmergencyCaseStatus.accepted.next,
        EmergencyCaseStatus.inProgress,
      );
      expect(
        EmergencyCaseStatus.inProgress.next,
        EmergencyCaseStatus.completed,
      );
      expect(EmergencyCaseStatus.completed.next, isNull);
      expect(EmergencyCaseStatus.completed.advanceActionLabel, isNull);
    });
  });

  group('audit events', () {
    test('starting a session writes one demo audit event', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      expect(controller.auditEvents, hasLength(1));
      expect(
        controller.auditEvents.single.action,
        ClinicalAuditAction.staffSessionStarted,
      );
      expect(controller.auditEvents.single.isDemo, isTrue);
    });

    test('an ordinary record view is audited without the CNIC', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.lookUpPatient('00000-0000001-0');

      final event = controller.auditEvents.first;
      expect(event.action, ClinicalAuditAction.patientRecordViewed);
      expect(event.subjectReference, isNotNull);
      expect(event.subjectReference, isNot(contains('00000-0000001')));
      expect(event.reason, isNull);
    });

    test('no audit entry carries a CNIC, name or clinical field', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');
      await controller.advanceCase('EMG-2026-000001');
      controller.recordMedicationReview();

      for (final event in controller.auditEvents) {
        final serialised = <String?>[
          event.staffId,
          event.hospitalId,
          event.subjectReference,
          event.emergencyId,
          event.reason,
        ].whereType<String>().join(' | ');

        expect(serialised, isNot(contains('00000-0000001-0')));
        expect(serialised, isNot(contains('Test Subject One')));
        expect(serialised, isNot(contains('Heart Disease')));
        expect(serialised, isNot(contains('Penicillin')));
      }
    });

    test('each status transition writes its own audit action', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      await controller.advanceCase('EMG-2026-000001');
      await controller.advanceCase('EMG-2026-000001');
      await controller.advanceCase('EMG-2026-000001');

      final actions = controller.auditEvents.map((e) => e.action).toList();
      expect(actions, contains(ClinicalAuditAction.emergencyCaseAccepted));
      expect(
        actions,
        contains(ClinicalAuditAction.emergencyTreatmentStarted),
      );
      expect(
        actions,
        contains(ClinicalAuditAction.emergencyEncounterCompleted),
      );
    });

    test('a transition audit carries the emergency id', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.advanceCase('EMG-2026-000002');

      final event = controller.auditEvents.first;
      expect(event.emergencyId, 'EMG-2026-000002');
      expect(event.subjectReference, 'DEMO-PAT-000002');
    });

    test('newest events come first', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');

      expect(
        controller.auditEvents.first.action,
        ClinicalAuditAction.patientRecordViewed,
      );
      expect(
        controller.auditEvents.last.action,
        ClinicalAuditAction.staffSessionStarted,
      );
    });
  });

  group('break-glass access', () {
    test('a blank reason is refused and nothing is audited', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);
      final auditedBefore = controller.auditEvents.length;

      final found = await controller.lookUpPatient(
        '00000-0000001-0',
        basis: RecordAccessBasis.breakGlass,
        breakGlassReason: '   ',
      );

      expect(found, isFalse);
      expect(controller.record, isNull);
      expect(
        controller.recordError,
        'Break-glass access requires a recorded reason.',
      );
      expect(controller.auditEvents, hasLength(auditedBefore));
      expect(controller.breakGlassEventCount, 0);
    });

    test('a missing reason is refused', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      final found = await controller.lookUpPatient(
        '00000-0000001-0',
        basis: RecordAccessBasis.breakGlass,
      );

      expect(found, isFalse);
      expect(controller.breakGlassEventCount, 0);
    });

    test('a recorded reason opens the record and writes one audit event',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.emergencyPhysician);

      final found = await controller.lookUpPatient(
        '00000-0000001-0',
        basis: RecordAccessBasis.breakGlass,
        breakGlassReason: '  Unconscious patient, no consent obtainable.  ',
      );

      expect(found, isTrue);
      expect(controller.isBreakGlassAccess, isTrue);
      expect(
        controller.breakGlassReason,
        'Unconscious patient, no consent obtainable.',
      );
      expect(controller.breakGlassEventCount, 1);

      final event = controller.auditEvents.first;
      expect(event.action, ClinicalAuditAction.breakGlassAccess);
      expect(event.action.isEmergencyAccess, isTrue);
      expect(event.reason, 'Unconscious patient, no consent obtainable.');
      expect(event.isDemo, isTrue);
    });

    test('an ordinary lookup afterwards drops the break-glass marking',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.lookUpPatient(
        '00000-0000001-0',
        basis: RecordAccessBasis.breakGlass,
        breakGlassReason: 'Emergency',
      );
      expect(controller.isBreakGlassAccess, isTrue);

      await controller.lookUpPatient('00000-0000001-0');

      expect(controller.isBreakGlassAccess, isFalse);
      expect(controller.breakGlassReason, isNull);
      // The earlier override stays in the audit.
      expect(controller.breakGlassEventCount, 1);
    });
  });

  group('clinical assistant', () {
    test('a question and its grounded reply are both recorded', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');

      await controller.askAssistant('What allergies are recorded?');

      expect(controller.assistantTranscript, hasLength(2));
      expect(
        controller.assistantTranscript.first.kind,
        AssistantTurnKind.question,
      );
      expect(
        controller.assistantTranscript.last.kind,
        AssistantTurnKind.answer,
      );
      expect(
        controller.auditEvents.first.action,
        ClinicalAuditAction.assistantQuerySubmitted,
      );
    });

    test('the assistant refuses to answer with no record in context',
        () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);

      await controller.askAssistant('What allergies are recorded?');

      expect(controller.assistantTranscript, isEmpty);
    });

    test('a backend failure is shown as a failed turn, not as an answer',
        () async {
      final controller = buildController(chatStatus: 500);
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');

      await controller.askAssistant('What allergies are recorded?');

      expect(controller.assistantTranscript, hasLength(2));
      expect(
        controller.assistantTranscript.last.kind,
        AssistantTurnKind.failure,
      );
      // A failed query must not be audited as a successful one.
      expect(
        controller.auditEvents
            .where((e) => e.action ==
                ClinicalAuditAction.assistantQuerySubmitted),
        isEmpty,
      );
      expect(controller.assistantBusy, isFalse);
    });

    test('opening a new record clears the previous transcript', () async {
      final controller = buildController();
      addTearDown(controller.dispose);
      await controller.startDemoSession(ClinicalRole.doctor);
      await controller.lookUpPatient('00000-0000001-0');
      await controller.askAssistant('What allergies are recorded?');
      expect(controller.assistantTranscript, isNotEmpty);

      await controller.lookUpPatient('00000-0000001-0');

      expect(controller.assistantTranscript, isEmpty);
    });
  });

  group('backend reachability', () {
    test('a reachable backend is reported as reachable', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.probeBackend();

      expect(controller.backendReachable, isTrue);
    });

    test('an unreachable backend is reported rather than thrown', () async {
      final controller = buildController(offline: true);
      addTearDown(controller.dispose);

      await controller.probeBackend();

      expect(controller.backendReachable, isFalse);
    });

    test('overview load failure keeps the state failed with a message',
        () async {
      final controller = buildController(offline: true);
      addTearDown(controller.dispose);

      await controller.refreshOverview();

      expect(controller.overviewState, LoadState.failed);
      expect(controller.overviewError, isNotNull);
      expect(controller.stats, isNull);
    });

    test('overview load success exposes dataset counts', () async {
      final controller = buildController();
      addTearDown(controller.dispose);

      await controller.refreshOverview();

      expect(controller.overviewState, LoadState.ready);
      expect(controller.stats!.totalPatients, 1000);
      expect(controller.stats!.countFor(controller.stats!.riskScore,
          'Critical'), 100);
      expect(controller.stats!.averageAgeLabel, '44.2');
      expect(controller.highestRisk, hasLength(1));
    });
  });
}
