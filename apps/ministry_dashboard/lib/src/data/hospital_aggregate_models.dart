import 'package:flutter/foundation.dart';

/// The exact phrase shown when hospital-level national aggregation is asked
/// for and no endpoint can supply it.
const String kHospitalAggregationUnavailable =
    'Hospital-level national aggregation requires an aggregate backend '
    'endpoint.';

/// One hospital's aggregate contribution to the national picture.
///
/// Deliberately counts only. There is no field here for a patient, because a
/// national network view needs to know how much a facility contributes, not
/// who it treated. There is also no province or region field: the dataset
/// records none, and adding one would invite a fabricated value.
@immutable
class HospitalAggregate {
  const HospitalAggregate({
    required this.hospitalName,
    required this.recordCount,
    required this.emergencyRecords,
    required this.criticalRiskRecords,
    required this.isDemo,
  });

  /// The `Hospital` value as recorded. Free text, with no location attached.
  final String hospitalName;

  final int recordCount;
  final int emergencyRecords;
  final int criticalRiskRecords;
  final bool isDemo;

  /// Share of this facility's records that are emergency admissions.
  double get emergencyFraction =>
      recordCount <= 0 ? 0 : (emergencyRecords / recordCount).clamp(0.0, 1.0);
}

/// Why a hospital network view is empty, so the UI can distinguish "no
/// endpoint" from "endpoint returned nothing" from "endpoint failed".
enum HospitalAggregateAvailability {
  /// No backend route aggregates by hospital. The expected state in Phase 5A.
  noEndpoint,

  /// An endpoint exists and returned rows.
  available,

  /// An endpoint exists and returned no rows.
  empty,
}

/// The result of asking for hospital-level national aggregation.
@immutable
class HospitalNetworkSummary {
  const HospitalNetworkSummary({
    required this.availability,
    required this.hospitals,
    required this.reason,
  });

  /// The Phase 5A result: the aggregation is not available from any route.
  const HospitalNetworkSummary.noEndpoint()
      : availability = HospitalAggregateAvailability.noEndpoint,
        hospitals = const <HospitalAggregate>[],
        reason = kHospitalAggregationUnavailable;

  final HospitalAggregateAvailability availability;
  final List<HospitalAggregate> hospitals;

  /// Displayable explanation. Always populated, including on success, so the
  /// panel can state its provenance either way.
  final String reason;

  bool get isAvailable =>
      availability == HospitalAggregateAvailability.available &&
      hospitals.isNotEmpty;

  bool get hasNoEndpoint =>
      availability == HospitalAggregateAvailability.noEndpoint;

  int get facilityCount => hospitals.length;

  int get totalRecords =>
      hospitals.fold(0, (sum, hospital) => sum + hospital.recordCount);
}

/// The read boundary for hospital-level national aggregation.
///
/// Phase 5A ships only [UnavailableHospitalAggregateRepository]. The
/// interface exists so a future aggregate endpoint can be dropped in behind
/// it without reshaping the Hospital Network screen, and so the screen can be
/// tested against a populated implementation today.
abstract interface class HospitalAggregateRepository {
  Future<HospitalNetworkSummary> fetchNetworkSummary();
}

/// Reports that no endpoint can supply hospital-level aggregation.
///
/// This is the honest Phase 5A implementation. `Hospital` is a dataset
/// column, but `GET /api/stats` does not group by it, and the alternative —
/// paging every record into the browser to group client-side — is forbidden
/// and would be a privacy regression regardless.
class UnavailableHospitalAggregateRepository
    implements HospitalAggregateRepository {
  const UnavailableHospitalAggregateRepository();

  @override
  Future<HospitalNetworkSummary> fetchNetworkSummary() async =>
      const HospitalNetworkSummary.noEndpoint();
}
