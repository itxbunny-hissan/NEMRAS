import 'package:flutter/foundation.dart';

import 'metric_provenance.dart';

/// Placeholder for any field NEMRAS does not hold.
const String kNotAvailable = 'Not available';

/// The phrase shown wherever a time series is requested but cannot be built.
const String kTrendUnavailable =
    'Trend unavailable from current aggregate API';

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

  /// One decimal place. At national scale a whole percentage hides real
  /// differences between categories.
  String get percentLabel =>
      total <= 0 ? kNotAvailable : '${(fraction * 100).toStringAsFixed(1)}%';
}

/// A categorical breakdown and where it came from.
@immutable
class NationalDistribution {
  const NationalDistribution({
    required this.title,
    required this.counts,
    required this.provenance,
    required this.basis,
  });

  /// A breakdown NEMRAS cannot supply.
  const NationalDistribution.unavailable({
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

  /// The share of the total held by [label], or null when unavailable.
  double? fractionFor(String label) {
    if (!isAvailable || total <= 0) return null;
    return (countFor(label) / total).clamp(0.0, 1.0);
  }

  /// Entries largest first, optionally truncated.
  List<DistributionEntry> entries({int? limit}) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final slice = limit == null ? sorted : sorted.take(limit);
    final overall = total;
    return <DistributionEntry>[
      for (final entry in slice)
        DistributionEntry(label: entry.key, count: entry.value, total: overall),
    ];
  }

  /// Entries in a fixed order, so ordinal scales read High/Medium/Low rather
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

  /// How many distinct categories the breakdown holds.
  int get categoryCount => counts.length;
}

/// Population aggregates from `GET /api/stats`.
///
/// Every field is a count of records in `NEMRAS_Dataset.csv`. None of it is a
/// national population statistic, and nothing here is broken down by
/// geography, because the endpoint exposes no geographic field and the
/// dataset holds none.
@immutable
class NationalStats {
  const NationalStats({
    required this.totalRecords,
    required this.averageAge,
    required this.riskScore,
    required this.triageLevel,
    required this.medicalCondition,
    required this.admissionType,
    required this.chronicCondition,
    required this.drugInteractionRisk,
  });

  factory NationalStats.fromJson(Map<String, dynamic> json) {
    final total = json['total_patients'];
    final average = json['avg_age'];
    return NationalStats(
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

  /// The dataset mean of `Age`. The only non-count figure the endpoint
  /// returns, and the only age statistic available: there are no age bands.
  final double? averageAge;

  final Map<String, int> riskScore;
  final Map<String, int> triageLevel;
  final Map<String, int> medicalCondition;
  final Map<String, int> admissionType;
  final Map<String, int> chronicCondition;
  final Map<String, int> drugInteractionRisk;

  String get averageAgeLabel =>
      averageAge == null ? kNotAvailable : averageAge!.toStringAsFixed(1);

  int get emergencyRecords => admissionType['Emergency'] ?? 0;
  int get urgentRecords => admissionType['Urgent'] ?? 0;
  int get electiveRecords => admissionType['Elective'] ?? 0;
  int get criticalRiskRecords => riskScore['Critical'] ?? 0;
  int get elevatedRiskRecords => riskScore['Elevated'] ?? 0;
  int get stableRiskRecords => riskScore['Stable'] ?? 0;
  int get highTriageRecords => triageLevel['High'] ?? 0;
  int get chronicRecords => chronicCondition['Yes'] ?? 0;
  int get interactionFlaggedRecords => drugInteractionRisk['Yes'] ?? 0;

  /// Records whose admission type is anything other than emergency.
  ///
  /// Derived by subtraction rather than by summing the other keys, so an
  /// admission type the dataset gains later is still counted.
  int get nonEmergencyRecords => totalRecords - emergencyRecords;

  /// How many distinct conditions the dataset records.
  int get conditionVariety => medicalCondition.length;
}

/// One row of the highest-risk feed from `GET /api/dashboard/critical`.
///
/// The endpoint returns patient-level rows including CNIC and name. This
/// model deliberately drops both: a national surface has no authorised use
/// for either, so they are never parsed, never stored and never rendered.
/// What survives is the categorical clinical fields a national aggregate
/// needs.
@immutable
class RiskSampleRow {
  const RiskSampleRow({
    required this.age,
    required this.medicalCondition,
    required this.triageLevel,
    required this.riskScore,
    required this.admissionType,
  });

  factory RiskSampleRow.fromJson(Map<String, dynamic> json) {
    final rawAge = json['Age'];
    return RiskSampleRow(
      age: rawAge is num ? rawAge.toInt() : null,
      medicalCondition: _text(json['Medical_Condition']),
      triageLevel: _text(json['Triage_Level']),
      riskScore: _text(json['Risk_Score']),
      admissionType: _text(json['Admission_Type']),
    );
  }

  final int? age;
  final String medicalCondition;

  /// `High` / `Medium` / `Low` from `Triage_Level`.
  final String triageLevel;

  /// `Critical` / `Elevated` / `Stable` from `Risk_Score`.
  ///
  /// A categorical dataset label. It is not a model output and carries no
  /// probability, so it must never be rendered as a percentage.
  final String riskScore;

  final String admissionType;

  String get ageLabel => age == null ? kNotAvailable : '$age';
}

/// The highest-risk slice plus the size of the request that produced it.
@immutable
class RiskSample {
  const RiskSample({required this.rows, required this.requestedLimit});

  final List<RiskSampleRow> rows;

  /// The limit asked of the backend, so the UI can say "top N of the
  /// dataset" rather than implying a total.
  final int requestedLimit;

  int get length => rows.length;

  bool get isEmpty => rows.isEmpty;

  /// Counts a field across the slice. Sample-scoped, never population-scoped.
  Map<String, int> countBy(String Function(RiskSampleRow row) selector) {
    final counts = <String, int>{};
    for (final row in rows) {
      final key = selector(row);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

/// Dataset-wide and sample-scoped national figures, together.
@immutable
class NationalSnapshot {
  const NationalSnapshot({
    required this.stats,
    required this.riskSample,
    required this.capturedAt,
  });

  final NationalStats stats;
  final RiskSample riskSample;

  /// When these figures were read, in UTC. Surfaced as data freshness rather
  /// than as a live clock, because nothing here streams.
  final DateTime capturedAt;
}

/// The reachability of the national data source.
enum NationalDataSourceStatus { unknown, reachable, unreachable, degraded }

extension NationalDataSourceStatusLabel on NationalDataSourceStatus {
  String get label {
    switch (this) {
      case NationalDataSourceStatus.unknown:
        return 'NOT CHECKED';
      case NationalDataSourceStatus.reachable:
        return 'AGGREGATE API REACHABLE';
      case NationalDataSourceStatus.unreachable:
        return 'AGGREGATE API UNREACHABLE';
      case NationalDataSourceStatus.degraded:
        return 'AGGREGATE API DEGRADED';
    }
  }

  String get detail {
    switch (this) {
      case NationalDataSourceStatus.unknown:
        return 'The NEMRAS aggregate API has not been probed yet.';
      case NationalDataSourceStatus.reachable:
        return 'The NEMRAS aggregate API answered and reports a loaded '
            'dataset.';
      case NationalDataSourceStatus.unreachable:
        return 'The NEMRAS aggregate API did not answer. National figures '
            'are unavailable.';
      case NationalDataSourceStatus.degraded:
        return 'The NEMRAS aggregate API answered but reports no dataset '
            'loaded.';
    }
  }
}

/// A governance or data-quality warning raised for the analyst.
///
/// Derived by fixed rules from figures the dashboard already holds. These are
/// rules, not model output, and none of them observes national
/// infrastructure.
enum NationalAlertSeverity { critical, warning, info }

@immutable
class NationalAlert {
  const NationalAlert({
    required this.title,
    required this.detail,
    required this.severity,
    required this.provenance,
  });

  final String title;
  final String detail;
  final NationalAlertSeverity severity;
  final MetricProvenance provenance;
}

/// The read boundary for national aggregate figures.
///
/// Phase 5A ships [BackendNationalRepository] over the existing aggregate
/// routes. A future implementation can serve the same interface from a
/// national index or a FHIR store without reshaping any screen.
abstract interface class NationalRepository {
  /// Reads the dataset aggregates and the highest-risk slice.
  Future<NationalSnapshot> fetchSnapshot({int riskSampleLimit});

  /// Probes the data source. Returns a status rather than throwing, because
  /// callers only use it to drive the status indicator.
  Future<NationalDataSourceStatus> probeStatus();
}
