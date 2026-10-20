/// What NEMRAS can and cannot say about geography.
///
/// This exists as a module rather than as a sentence in a widget because the
/// rule it encodes is the easiest one on this surface to break by accident. A
/// national dashboard invites a province map, and the NEMRAS dataset has no
/// field that supports one: no province, no district, no coordinates, and no
/// region. The three plausible shortcuts are all wrong:
///
///   * CNIC prefixes do encode a registration district in the real NADRA
///     scheme, but the NEMRAS CNICs are synthetic, and even real ones record
///     where a person registered rather than where they were treated.
///   * The `Hospital` column is a free-text name with no location attached,
///     and inferring a province from a hospital's name is guessing.
///   * `Insurance_Provider` and `Doctor` carry no geography either.
///
/// So the honest output is an explicit absence. [GeographicAvailability]
/// states that absence once, and every screen that would otherwise show a map
/// or a regional breakdown renders it.
abstract final class GeographicAvailability {
  /// The exact phrase this phase is required to display.
  static const String notice =
      'Geographic breakdown: Not available in current dataset';

  /// Why, in one paragraph, for the panel body.
  static const String explanation =
      'The NEMRAS dataset records no province, district, region or '
      'coordinate for any patient or hospital, and no backend endpoint '
      'exposes a geographic aggregate. Nothing on this dashboard is broken '
      'down by location, because any such breakdown would have to be '
      'invented.';

  /// The specific inferences that are refused, listed in the UI so the
  /// refusal reads as a decision rather than an oversight.
  static const List<({String source, String reason})> refusedInferences =
      <({String source, String reason})>[
    (
      source: 'CNIC prefix',
      reason: 'Encodes a registration district, not a place of treatment, '
          'and the NEMRAS identifiers are synthetic.',
    ),
    (
      source: 'Hospital name',
      reason: 'The Hospital column is free text with no location attached. '
          'Matching names to provinces would be guesswork.',
    ),
    (
      source: 'Insurance provider',
      reason: 'Carries no geographic scope in the dataset.',
    ),
    (
      source: 'Doctor name',
      reason: 'Carries no practice location in the dataset.',
    ),
  ];

  /// What a real geographic view would need, so the gap is actionable.
  static const List<({String requirement, String detail})> requirements =
      <({String requirement, String detail})>[
    (
      requirement: 'Facility registry',
      detail: 'Each hospital mapped to a verified province and district by '
          'an authoritative registry.',
    ),
    (
      requirement: 'Encounter location',
      detail: 'The treating facility recorded per encounter, not per '
          'patient.',
    ),
    (
      requirement: 'Aggregate-only endpoint',
      detail: 'Counts returned already grouped by region, with small cells '
          'suppressed so individuals cannot be re-identified.',
    ),
    (
      requirement: 'Population denominators',
      detail: 'Census population per region, without which a regional count '
          'cannot become a rate.',
    ),
  ];

  /// Province and territory names that must never be rendered with a figure
  /// beside them on this surface.
  ///
  /// Held here so the privacy and honesty tests can assert against the same
  /// list the implementation is written against, rather than a copy that can
  /// drift.
  static const List<String> forbiddenRegionLabels = <String>[
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu and Kashmir',
  ];
}
