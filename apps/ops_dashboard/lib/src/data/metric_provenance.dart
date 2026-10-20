import 'package:flutter/foundation.dart';

/// Where a number on this dashboard came from.
///
/// The NEMRAS dataset is a corpus of patient records, not a feed of hospital
/// telemetry. An operations dashboard that renders a dataset count next to a
/// live-looking figure invites exactly the wrong reading, so every metric this
/// app displays must declare its provenance and the UI must show it.
enum MetricProvenance {
  /// A population aggregate computed over the whole dataset by the backend.
  ///
  /// Truthful as "records in the dataset matching X". Never truthful as
  /// "patients currently in this hospital".
  datasetAggregate,

  /// Computed over a bounded slice the backend returns, not the population.
  ///
  /// Carries a sample size so it can never be read as a hospital-wide figure.
  datasetSample,

  /// Produced by a local demo provider. Simulated, not measured.
  demo,

  /// NEMRAS holds no source for this metric, or the backend exposes no
  /// aggregate for it. Rendered as "Not available" rather than estimated.
  unavailable,
}

extension MetricProvenanceLabel on MetricProvenance {
  /// The badge text shown beside the value.
  String get badge {
    switch (this) {
      case MetricProvenance.datasetAggregate:
        return 'DATASET-DERIVED';
      case MetricProvenance.datasetSample:
        return 'DATASET SAMPLE';
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
            'not a live hospital figure.';
      case MetricProvenance.datasetSample:
        return 'Counted across a bounded slice of the dataset returned by '
            'the backend, not the whole population.';
      case MetricProvenance.demo:
        return 'Simulated by a local demo provider. No hospital system is '
            'connected.';
      case MetricProvenance.unavailable:
        return 'NEMRAS has no source for this figure, so none is shown.';
    }
  }

  /// True when the value must never be presented as current hospital state.
  bool get isNotLive => true;
}

/// A single displayable metric and its provenance.
///
/// [value] is null exactly when [provenance] is
/// [MetricProvenance.unavailable], which keeps "no value" and "value of zero"
/// distinguishable — a zero occupancy and an unknown occupancy are different
/// operational facts.
@immutable
class OpsMetric {
  const OpsMetric._({
    required this.label,
    required this.value,
    required this.provenance,
    required this.basis,
    this.caption,
    this.sampleSize,
  });

  /// A population count from `GET /api/stats`.
  factory OpsMetric.datasetAggregate({
    required String label,
    required int value,
    required String basis,
    String? caption,
  }) {
    return OpsMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.datasetAggregate,
      basis: basis,
      caption: caption,
    );
  }

  /// A count over a bounded slice, such as the highest-risk feed.
  factory OpsMetric.datasetSample({
    required String label,
    required int value,
    required String basis,
    required int sampleSize,
    String? caption,
  }) {
    return OpsMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.datasetSample,
      basis: basis,
      sampleSize: sampleSize,
      caption: caption,
    );
  }

  /// A figure produced by a local demo provider.
  factory OpsMetric.demo({
    required String label,
    required num value,
    required String basis,
    String? caption,
  }) {
    return OpsMetric._(
      label: label,
      value: value.toDouble(),
      provenance: MetricProvenance.demo,
      basis: basis,
      caption: caption,
    );
  }

  /// A metric NEMRAS cannot supply.
  factory OpsMetric.unavailable({
    required String label,
    required String basis,
    String? caption,
  }) {
    return OpsMetric._(
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

  /// What the figure is actually counted over, in plain words. Shown in the
  /// card so a reader never has to guess.
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

/// Thousands-separated count. The dataset is large enough that a bare digit
/// run is hard to read at a glance.
String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
