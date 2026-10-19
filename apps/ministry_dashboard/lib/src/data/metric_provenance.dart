import 'package:flutter/foundation.dart';

/// Where a number on this dashboard came from.
///
/// This is the same provenance model Phase 4A established for the hospital
/// operational dashboard, applied at national scale. It is declared here
/// rather than imported because `apps/ops_dashboard` is an application, not a
/// package, so nothing can import from it. Extracting a shared
/// `nemras_components` package is the right fix and is reported as debt
/// rather than done here, because it would require editing a frozen surface.
///
/// A national dashboard is the surface where a mislabelled figure does the
/// most damage: a record count presented as a national statistic invites
/// policy conclusions the data cannot support. Every metric therefore
/// declares its provenance and the UI always shows it.
enum MetricProvenance {
  /// A population aggregate computed over the whole dataset by the backend.
  ///
  /// Truthful as "records in the NEMRAS dataset matching X". Never truthful
  /// as "people in Pakistan" or "patients currently in care".
  datasetAggregate,

  /// Computed over a bounded slice the backend returns, not the population.
  datasetSample,

  /// Produced by a local demo provider. Simulated, not measured.
  demo,

  /// NEMRAS holds no source for this metric, or no endpoint exposes it.
  /// Rendered as an explicit absence rather than estimated.
  unavailable,
}

extension MetricProvenanceLabel on MetricProvenance {
  /// The badge text shown beside the value.
  String get badge {
    switch (this) {
      case MetricProvenance.datasetAggregate:
        return 'DATASET-DERIVED';
      case MetricProvenance.datasetSample:
        return 'DATASET-SAMPLE';
      case MetricProvenance.demo:
        return 'DEMO';
      case MetricProvenance.unavailable:
        return 'NOT AVAILABLE';
    }
  }

  /// A one-line explanation for the tooltip and the detail panels.
  String get explanation {
    switch (this) {
      case MetricProvenance.datasetAggregate:
        return 'Counted across the NEMRAS dataset. This is a record count, '
            'not a national population statistic.';
      case MetricProvenance.datasetSample:
        return 'Counted across a bounded slice of the dataset returned by '
            'the backend, not the whole population.';
      case MetricProvenance.demo:
        return 'Simulated by a local demo provider. No national '
            'infrastructure is connected.';
      case MetricProvenance.unavailable:
        return 'NEMRAS has no source for this figure, so none is shown.';
    }
  }

  /// True for every kind. No figure on this surface is live national
  /// telemetry, and the type system is used to say so rather than relying on
  /// each screen to remember.
  bool get isNotLiveTelemetry => true;
}

/// A single displayable national metric and its provenance.
///
/// [value] is null exactly when [provenance] is
/// [MetricProvenance.unavailable], which keeps "no value" and "a value of
/// zero" distinguishable.
@immutable
class NationalMetric {
  const NationalMetric._({
    required this.label,
    required this.value,
    required this.provenance,
    required this.basis,
    this.caption,
    this.sampleSize,
  });

  /// A population count from `GET /api/stats`.
  factory NationalMetric.datasetAggregate({
    required String label,
    required int value,
    required String basis,
    String? caption,
  }) {
    return NationalMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.datasetAggregate,
      basis: basis,
      caption: caption,
    );
  }

  /// A population figure that is not a count, such as a mean.
  factory NationalMetric.datasetMeasure({
    required String label,
    required double value,
    required String basis,
    String? caption,
  }) {
    return NationalMetric._(
      label: label,
      value: value,
      provenance: MetricProvenance.datasetAggregate,
      basis: basis,
      caption: caption,
    );
  }

  /// A count over a bounded slice, such as the highest-risk feed.
  factory NationalMetric.datasetSample({
    required String label,
    required int value,
    required String basis,
    required int sampleSize,
    String? caption,
  }) {
    return NationalMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.datasetSample,
      basis: basis,
      sampleSize: sampleSize,
      caption: caption,
    );
  }

  /// A figure produced by a local demo provider.
  factory NationalMetric.demo({
    required String label,
    required num value,
    required String basis,
    String? caption,
  }) {
    return NationalMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.demo,
      basis: basis,
      caption: caption,
    );
  }

  /// A metric NEMRAS cannot supply.
  factory NationalMetric.unavailable({
    required String label,
    required String basis,
    String? caption,
  }) {
    return NationalMetric._(
      label: label,
      value: null,
      provenance: MetricProvenance.unavailable,
      basis: basis,
      caption: caption,
    );
  }

  final String label;

  /// Null when [provenance] is [MetricProvenance.unavailable].
  final double? value;
  final MetricProvenance provenance;

  /// What the figure is counted over, in plain words.
  final String basis;
  final String? caption;

  /// Set only for [MetricProvenance.datasetSample].
  final int? sampleSize;

  bool get isAvailable => value != null;

  /// The value as displayed. Integers render without a decimal point.
  String get displayValue {
    final current = value;
    if (current == null) return 'Not available';
    if (current == current.roundToDouble()) {
      return formatCount(current.round());
    }
    return current.toStringAsFixed(1);
  }
}

/// Thousands-separated count. National figures run to five and six digits,
/// which is hard to read as a bare digit run.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
