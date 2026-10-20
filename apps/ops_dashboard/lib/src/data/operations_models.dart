import 'package:flutter/foundation.dart';

import 'metric_provenance.dart';

/// Placeholder for any field NEMRAS does not hold.
const String kNotAvailable = 'Not available';

String _text(dynamic value) {
  if (value == null) return kNotAvailable;
  final text = value.toString().trim();
  return text.isEmpty ? kNotAvailable : text;
}

/// A named count within a breakdown, with its share of the total.
@immutable
class DistributionEntry {
  const DistributionEntry({
    required this.label,
    required this.count,
    required this.total,
  });

  final String label;
  final int count;
  final int total;

  double get fraction => total <= 0 ? 0 : (count / total).clamp(0.0, 1.0);

  /// One decimal place. The dataset is large, so whole percentages hide real
  /// differences between categories.
  String get percentLabel =>
      total <= 0 ? kNotAvailable : '${(fraction * 100).toStringAsFixed(1)}%';
}

/// A categorical breakdown and where it came from.
@immutable
class OpsDistribution {
  const OpsDistribution({
    required this.title,
    required this.counts,
    required this.provenance,
    required this.basis,
  });

  /// A breakdown NEMRAS cannot supply.
  const OpsDistribution.unavailable({
    required this.title,
    required this.basis,
  })  : counts = const <String, int>{},
        provenance = MetricProvenance.unavailable;

  final String title;
  final Map<String, int> counts;
  final MetricProvenance provenance;
  final String basis;

  bool get isAvailable =>
      provenance != MetricProvenance.unavailable && counts.isNotEmpty;

  int get total => counts.values.fold(0, (sum, value) => sum + value);

  int countFor(String label) => counts[label] ?? 0;

  /// Entries largest first, optionally truncated.
  List<DistributionEntry> entries({int? limit}) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slice = limit == null ? sorted : sorted.take(limit);
    final overall = total;
    return <DistributionEntry>[
      for (final entry in slice)
        DistributionEntry(
          label: entry.key,
          count: entry.value,
          total: overall,
        ),
    ];
  }

  /// Entries in a fixed order, so clinical scales read High/Medium/Low rather
  /// than largest-first.
  List<DistributionEntry> entriesInOrder(List<String> order) {
    final overall = total;
    return <DistributionEntry>[
      for (final label in order)
        if (counts.containsKey(label))
          DistributionEntry(
            label: label,
            count: counts[label]!,
            total: overall,
          ),
    ];
  }
}

/// Population aggregates from `GET /api/stats`.
///
/// Every field is a count of dataset records. None of it is live hospital
/// state, and nothing here describes beds, staffing or capacity because the
/// dataset records none of those.
@immutable
class OpsPopulationStats {
  const OpsPopulationStats({
    required this.totalRecords,
    required this.averageAge,
    required this.riskScore,
    required this.triageLevel,
    required this.medicalCondition,
    required this.admissionType,
    required this.chronicCondition,
    required this.drugInteractionRisk,
  });

  factory OpsPopulationStats.fromJson(Map<String, dynamic> json) {
    final total = json['total_patients'];
    final average = json['avg_age'];
    return OpsPopulationStats(
      totalRecords: total is num ? total.toInt() : 0,
      averageAge: average is num ? average.toDouble() : null,
      riskScore: _counts(json['risk_score']),
      triageLevel: _counts(json['triage_level']),
      medicalCondition: _counts(json['medical_condition']),
      admissionType: _counts(json['admission_type']),
      chronicCondition: _counts(json['chronic_condition']),
      drugInteractionRisk: _counts(json['drug_interaction_risk']),
    );
  }

  static Map<String, int> _counts(dynamic value) {
    if (value is! Map) return const <String, int>{};
    return <String, int>{
      for (final entry in value.entries)
        if (entry.value is num)
          entry.key.toString(): (entry.value as num).toInt(),
    };
  }

  final int totalRecords;
  final double? averageAge;
  final Map<String, int> riskScore;
  final Map<String, int> triageLevel;
  final Map<String, int> medicalCondition;
  final Map<String, int> admissionType;
  final Map<String, int> chronicCondition;
  final Map<String, int> drugInteractionRisk;

  String get averageAgeLabel =>
      averageAge == null ? kNotAvailable : averageAge!.toStringAsFixed(1);

  int get emergencyAdmissionRecords => admissionType['Emergency'] ?? 0;
  int get criticalRiskRecords => riskScore['Critical'] ?? 0;
  int get elevatedRiskRecords => riskScore['Elevated'] ?? 0;
  int get highTriageRecords => triageLevel['High'] ?? 0;
  int get chronicRecords => chronicCondition['Yes'] ?? 0;
  int get interactionFlaggedRecords => drugInteractionRisk['Yes'] ?? 0;
}

/// One row of the highest-risk feed from `GET /api/dashboard/critical`.
///
/// The endpoint sorts the dataset by risk tier and returns the top N, so a
/// collection of these is a bounded sample and never a hospital census.
@immutable
class RiskFeedRow {
  const RiskFeedRow({
    required this.cnic,
    required this.age,
    required this.medicalCondition,
    required this.triageLevel,
    required this.riskScore,
    required this.admissionType,
    required this.hospital,
  });

  factory RiskFeedRow.fromJson(Map<String, dynamic> json) {
    final rawAge = json['Age'];
    return RiskFeedRow(
      cnic: _text(json['CNIC']),
      age: rawAge is num ? rawAge.toInt() : null,
      medicalCondition: _text(json['Medical_Condition']),
      triageLevel: _text(json['Triage_Level']),
      riskScore: _text(json['Risk_Score']),
      admissionType: _text(json['Admission_Type']),
      hospital: _text(json['Hospital']),
    );
  }

  /// Retained because the endpoint returns it, but never rendered: an
  /// operations dashboard has no need of a patient identifier. See
  /// [caseReference].
  final String cnic;
  final int? age;
  final String medicalCondition;
  final String triageLevel;
  final String riskScore;
  final String admissionType;
  final String hospital;

  String get ageLabel => age == null ? kNotAvailable : '$age';

  /// A non-identifying reference for the operations tables.
  ///
  /// Operations staff need to count and triage workload, not identify
  /// individuals, so the CNIC is reduced to its last four digits.
  String get caseReference {
    final digits = cnic.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return 'CASE-****';
    return 'CASE-****${digits.substring(digits.length - 4)}';
  }
}

/// The highest-risk feed plus the size of the slice it came from.
@immutable
class RiskFeed {
  const RiskFeed({required this.rows, required this.requestedLimit});

  final List<RiskFeedRow> rows;

  /// The limit asked of the backend, so the UI can say "top N of the dataset"
  /// rather than implying a total.
  final int requestedLimit;

  int get length => rows.length;

  /// Counts a field across the slice. Sample-scoped, never population-scoped.
  Map<String, int> countBy(String Function(RiskFeedRow row) selector) {
    final counts = <String, int>{};
    for (final row in rows) {
      final key = selector(row);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

/// Dataset-wide and sample-scoped operational figures, together.
@immutable
class OperationsSnapshot {
  const OperationsSnapshot({
    required this.stats,
    required this.riskFeed,
    required this.capturedAt,
  });

  final OpsPopulationStats stats;
  final RiskFeed riskFeed;

  /// When these figures were read, in UTC. Surfaced as data freshness rather
  /// than as a live clock, because nothing here streams.
  final DateTime capturedAt;
}

/// The backend reachability of this dashboard's data source.
enum OpsBackendStatus { unknown, reachable, unreachable, degraded }

extension OpsBackendStatusLabel on OpsBackendStatus {
  String get label {
    switch (this) {
      case OpsBackendStatus.unknown:
        return 'NOT CHECKED';
      case OpsBackendStatus.reachable:
        return 'DATA SOURCE REACHABLE';
      case OpsBackendStatus.unreachable:
        return 'DATA SOURCE UNREACHABLE';
      case OpsBackendStatus.degraded:
        return 'DATA SOURCE DEGRADED';
    }
  }

  String get detail {
    switch (this) {
      case OpsBackendStatus.unknown:
        return 'The NEMRAS API has not been probed yet.';
      case OpsBackendStatus.reachable:
        return 'The NEMRAS API answered and reports a loaded dataset.';
      case OpsBackendStatus.unreachable:
        return 'The NEMRAS API did not answer. Dataset figures are '
            'unavailable.';
      case OpsBackendStatus.degraded:
        return 'The NEMRAS API answered but reports no dataset loaded.';
    }
  }
}

/// An operational alert raised for the administrator.
///
/// Phase 4A derives these from figures the dashboard already has, with
/// explicit rules. They are not the output of a model, and none of them
/// observes hospital equipment.
enum OpsAlertSeverity { critical, warning, info }

@immutable
class OpsAlert {
  const OpsAlert({
    required this.title,
    required this.detail,
    required this.severity,
    required this.provenance,
  });

  final String title;
  final String detail;
  final OpsAlertSeverity severity;
  final MetricProvenance provenance;
}

/// The read boundary for operational figures.
///
/// Phase 4A ships [BackendOperationsRepository] over the existing FastAPI
/// routes. A future implementation can serve the same interface from a
/// streaming source without reshaping any screen.
abstract interface class OperationsRepository {
  /// Reads the dataset aggregates and the highest-risk slice.
  Future<OperationsSnapshot> fetchSnapshot({int riskFeedLimit});

  /// Probes the data source. Returns a status rather than throwing, because
  /// callers only use it to drive the status indicator.
  Future<OpsBackendStatus> probeStatus();
}
