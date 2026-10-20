import 'clinical_models.dart';
import 'handover_models.dart';
import 'staff_identity.dart';

/// An in-memory [HandoverRepository] holding clearly labelled demo cases.
///
/// There is no hospital network behind this. It exists so the clinical screens
/// have the same shape of data a real transport will later supply, and every
/// case it returns carries `isDemo: true`.
///
/// The clinical snapshots use the label vocabularies that already appear in
/// `NEMRAS_Dataset.csv` (`Triage_Level`, `Risk_Score`, `Medical_Condition` and
/// so on) so nothing renders a value the design system cannot colour. The
/// patient labels and identifiers are synthetic: no real CNIC, name or record
/// is reproduced here.
class DemoHandoverRepository implements HandoverRepository {
  DemoHandoverRepository({DateTime? seedTime})
      : _cases = _seed(seedTime ?? DateTime.now().toUtc());

  final Map<String, EmergencyHandover> _cases;

  static Map<String, EmergencyHandover> _seed(DateTime now) {
    final utc = now.toUtc();
    final seeded = <EmergencyHandover>[
      EmergencyHandover(
        emergencyId: 'EMG-2026-000001',
        patientId: 'DEMO-PAT-000001',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-001',
        destinationHospitalId: DemoHospitalIdentity.hospitalId,
        announcedAt: utc.subtract(const Duration(minutes: 4)),
        status: EmergencyCaseStatus.pending,
        isDemo: true,
        handoverNotes:
            'DEMO handover note. Patient conscious on scene. Allergy '
            'confirmed verbally with a relative.',
        snapshot: const HandoverClinicalSnapshot(
          patientLabel: 'DEMO Patient 000001',
          ageLabel: '58',
          gender: 'Male',
          bloodType: 'O+',
          medicalCondition: 'Heart Disease',
          chronicCondition: 'Yes',
          medication: 'Aspirin',
          allergy: 'Penicillin',
          drugInteractionRisk: 'Yes',
          triageLevel: 'High',
          riskCategory: 'Critical',
        ),
      ),
      EmergencyHandover(
        emergencyId: 'EMG-2026-000002',
        patientId: 'DEMO-PAT-000002',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-001',
        destinationHospitalId: DemoHospitalIdentity.hospitalId,
        announcedAt: utc.subtract(const Duration(minutes: 21)),
        status: EmergencyCaseStatus.accepted,
        acceptedByStaffId: 'STAFF-001',
        isDemo: true,
        snapshot: const HandoverClinicalSnapshot(
          patientLabel: 'DEMO Patient 000002',
          ageLabel: '34',
          gender: 'Female',
          bloodType: 'A-',
          medicalCondition: 'Asthma',
          chronicCondition: 'Yes',
          medication: 'Salbutamol',
          allergy: 'None',
          drugInteractionRisk: 'No',
          triageLevel: 'Medium',
          riskCategory: 'Elevated',
        ),
      ),
      EmergencyHandover(
        emergencyId: 'EMG-2026-000003',
        patientId: 'DEMO-PAT-000003',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-001',
        destinationHospitalId: DemoHospitalIdentity.hospitalId,
        announcedAt: utc.subtract(const Duration(hours: 1, minutes: 12)),
        status: EmergencyCaseStatus.inProgress,
        acceptedByStaffId: 'STAFF-001',
        isDemo: true,
        snapshot: const HandoverClinicalSnapshot(
          patientLabel: 'DEMO Patient 000003',
          ageLabel: '27',
          gender: 'Male',
          bloodType: 'B+',
          medicalCondition: 'Fracture',
          chronicCondition: 'No',
          medication: kNotAvailable,
          allergy: 'None',
          drugInteractionRisk: 'No',
          triageLevel: 'Low',
          riskCategory: 'Stable',
        ),
      ),
    ];

    return <String, EmergencyHandover>{
      for (final handover in seeded) handover.emergencyId: handover,
    };
  }

  @override
  Future<List<EmergencyHandover>> fetchQueue({
    required String hospitalId,
  }) async {
    final queue = _cases.values
        .where((c) => c.destinationHospitalId == hospitalId)
        .toList()
      ..sort((a, b) => b.announcedAt.compareTo(a.announcedAt));
    return queue;
  }

  @override
  Future<EmergencyHandover> updateStatus({
    required String emergencyId,
    required EmergencyCaseStatus status,
    required String staffId,
  }) async {
    final existing = _cases[emergencyId];
    if (existing == null) {
      throw StateError('Unknown emergency case: $emergencyId');
    }
    final updated = existing.copyWith(
      status: status,
      acceptedByStaffId: existing.acceptedByStaffId ?? staffId,
    );
    _cases[emergencyId] = updated;
    return updated;
  }
}
