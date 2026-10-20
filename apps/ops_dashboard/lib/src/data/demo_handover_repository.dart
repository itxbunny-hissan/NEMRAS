import 'handover_models.dart';

/// A fixed set of DEMO handovers.
///
/// These entries are shaped to match what the Phase 3A Hospital Clinical
/// Desktop and the Phase 2A paramedic shell produce, including the
/// `EMG-YYYY-NNNNNN` identifier format and the `PARA-001` / `NEMRAS-AMB-001`
/// demo ids, so a future integration maps onto the same fields.
///
/// Nothing streams. The dashboard and the clinical desktop are not connected
/// through an event bus, a queue or a shared store in this phase; each holds
/// its own demo provider. The matching identifiers show the intended
/// integration shape, not an existing link.
class DemoHandoverRepository implements HandoverMonitorRepository {
  DemoHandoverRepository({DateTime? now})
      : _now = (now ?? DateTime.now()).toUtc();

  final DateTime _now;

  @override
  Future<List<HandoverMonitorEntry>> fetchHandovers({
    required String hospitalId,
  }) async {
    final entries = <HandoverMonitorEntry>[
      HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000001',
        caseReference: 'CASE-****0001',
        triageLevel: 'High',
        riskCategory: 'Critical',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-001',
        destinationHospitalId: hospitalId,
        destinationWard: 'Emergency',
        announcedAt: _now.subtract(const Duration(minutes: 8)),
        status: HandoverStatus.incoming,
        isDemo: true,
      ),
      HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000002',
        caseReference: 'CASE-****0002',
        triageLevel: 'High',
        riskCategory: 'Critical',
        paramedicId: 'PARA-002',
        ambulanceId: 'NEMRAS-AMB-004',
        destinationHospitalId: hospitalId,
        destinationWard: 'Cardiac ICU',
        announcedAt: _now.subtract(const Duration(minutes: 22)),
        status: HandoverStatus.accepted,
        isDemo: true,
        acceptedByStaffId: 'STAFF-001',
      ),
      HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000003',
        caseReference: 'CASE-****0003',
        triageLevel: 'Medium',
        riskCategory: 'Elevated',
        paramedicId: 'PARA-001',
        ambulanceId: 'NEMRAS-AMB-002',
        destinationHospitalId: hospitalId,
        destinationWard: 'General Medicine',
        announcedAt: _now.subtract(const Duration(minutes: 47)),
        status: HandoverStatus.inProgress,
        isDemo: true,
        acceptedByStaffId: 'STAFF-002',
      ),
      HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000004',
        caseReference: 'CASE-****0004',
        triageLevel: 'Low',
        riskCategory: 'Stable',
        paramedicId: 'PARA-003',
        ambulanceId: 'NEMRAS-AMB-003',
        destinationHospitalId: hospitalId,
        destinationWard: 'General Medicine',
        announcedAt: _now.subtract(const Duration(minutes: 96)),
        status: HandoverStatus.completed,
        isDemo: true,
        acceptedByStaffId: 'STAFF-002',
      ),
      HandoverMonitorEntry(
        emergencyId: 'EMG-2026-000005',
        caseReference: 'CASE-****0005',
        triageLevel: 'Medium',
        riskCategory: 'Elevated',
        paramedicId: 'PARA-004',
        ambulanceId: 'NEMRAS-AMB-005',
        destinationHospitalId: hospitalId,
        destinationWard: 'Emergency',
        announcedAt: _now.subtract(const Duration(minutes: 3)),
        status: HandoverStatus.incoming,
        isDemo: true,
      ),
    ]..sort((a, b) => b.announcedAt.compareTo(a.announcedAt));

    return entries;
  }
}

/// A repository with no handovers, for exercising the empty state.
class EmptyHandoverRepository implements HandoverMonitorRepository {
  const EmptyHandoverRepository();

  @override
  Future<List<HandoverMonitorEntry>> fetchHandovers({
    required String hospitalId,
  }) async =>
      const <HandoverMonitorEntry>[];
}
