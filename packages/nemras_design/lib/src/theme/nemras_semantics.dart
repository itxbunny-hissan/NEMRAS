import 'package:flutter/material.dart';

import '../tokens/colors.dart';

/// A status colour in its three reference forms: the solid fill used by
/// `.risk-pill`, the soft background used by `.tag` and `.chip`, and the
/// foreground that sits on that soft background.
@immutable
class NemrasStatusColor {
  const NemrasStatusColor({
    required this.solid,
    required this.soft,
    required this.onSoft,
    required this.onSolid,
  });

  final Color solid;
  final Color soft;
  final Color onSoft;
  final Color onSolid;

  static NemrasStatusColor lerp(
    NemrasStatusColor a,
    NemrasStatusColor b,
    double t,
  ) {
    return NemrasStatusColor(
      solid: Color.lerp(a.solid, b.solid, t)!,
      soft: Color.lerp(a.soft, b.soft, t)!,
      onSoft: Color.lerp(a.onSoft, b.onSoft, t)!,
      onSolid: Color.lerp(a.onSolid, b.onSolid, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NemrasStatusColor &&
      other.solid == solid &&
      other.soft == soft &&
      other.onSoft == onSoft &&
      other.onSolid == onSolid;

  @override
  int get hashCode => Object.hash(solid, soft, onSoft, onSolid);
}

/// Surface and status colours that Material's [ColorScheme] cannot express,
/// resolved per theme so the same widget renders correctly on the patient
/// clinical surface and the paramedic field surface.
@immutable
class NemrasSemantics extends ThemeExtension<NemrasSemantics> {
  const NemrasSemantics({
    required this.isField,
    required this.screenBackground,
    required this.cardBackground,
    required this.cardBorder,
    required this.barBackground,
    required this.barBorder,
    required this.controlBackground,
    required this.inputBackground,
    required this.inputBorder,
    required this.inputBorderActive,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textPlaceholder,
    required this.accent,
    required this.onAccent,
    required this.critical,
    required this.elevated,
    required this.stable,
    required this.informational,
    required this.advisory,
    required this.shellGradient,
    required this.summaryGradient,
    required this.criticalSummaryGradient,
  });

  /// True for the paramedic/field theme. Widgets should branch on a semantic
  /// token wherever possible and use this only for genuinely surface-specific
  /// behaviour such as enlarged touch targets.
  final bool isField;

  final Color screenBackground;
  final Color cardBackground;
  final Color cardBorder;
  final Color barBackground;
  final Color barBorder;
  final Color controlBackground;
  final Color inputBackground;
  final Color inputBorder;
  final Color inputBorderActive;
  final Color divider;

  final Color textPrimary;
  final Color textSecondary;
  final Color textPlaceholder;

  final Color accent;
  final Color onAccent;

  final NemrasStatusColor critical;
  final NemrasStatusColor elevated;
  final NemrasStatusColor stable;
  final NemrasStatusColor informational;

  /// Neutral-but-notable state. Carries the reference's violet, which is
  /// defined in `:root` but left unassigned to a specific clinical meaning;
  /// NEMRAS uses it for medication listings.
  final NemrasStatusColor advisory;

  final List<Color> shellGradient;
  final List<Color> summaryGradient;
  final List<Color> criticalSummaryGradient;

  static NemrasSemantics of(BuildContext context) {
    final semantics = Theme.of(context).extension<NemrasSemantics>();
    assert(
      semantics != null,
      'NemrasSemantics is missing. Build the app theme with '
      'nemrasClinicalLightTheme() or nemrasFieldDarkTheme().',
    );
    return semantics ?? clinicalLight;
  }

  /// Maps a `Risk_Score` label to its colours.
  ///
  /// `Risk_Score` is a categorical label carried in the dataset, not a model
  /// probability, so callers must not render it as a numeric score.
  NemrasStatusColor risk(String? label) {
    switch (label) {
      case 'Critical':
        return critical;
      case 'Elevated':
        return elevated;
      case 'Stable':
        return stable;
      default:
        return informational;
    }
  }

  /// Maps a `Triage_Level` label.
  NemrasStatusColor triage(String? label) {
    switch (label) {
      case 'High':
        return critical;
      case 'Medium':
        return elevated;
      case 'Low':
        return stable;
      default:
        return informational;
    }
  }

  /// Maps an alert severity emitted by the NEMRAS backend.
  NemrasStatusColor severity(String? value) {
    switch (value) {
      case 'critical':
        return critical;
      case 'high':
        return elevated;
      case 'info':
        return informational;
      default:
        return informational;
    }
  }

  /// `Drug_Interaction_Risk` is recorded only as `Yes` or `No`. The dataset
  /// carries no severity grading, so this is deliberately binary.
  NemrasStatusColor drugInteraction({required bool present}) =>
      present ? critical : stable;

  /// A recorded allergy is a hard contraindication regardless of allergen.
  NemrasStatusColor get allergy => critical;

  /// `Chronic_Condition` is recorded only as `Yes` or `No`.
  NemrasStatusColor chronicCondition({required bool present}) =>
      present ? elevated : stable;

  /// Active medication listings.
  NemrasStatusColor get medication => advisory;

  static const NemrasSemantics clinicalLight = NemrasSemantics(
    isField: false,
    screenBackground: NemrasColors.paper,
    cardBackground: NemrasColors.white,
    cardBorder: NemrasColors.line2,
    barBackground: NemrasColors.white,
    barBorder: NemrasColors.line2,
    controlBackground: NemrasColors.paper,
    inputBackground: NemrasColors.white,
    inputBorder: NemrasColors.line,
    inputBorderActive: NemrasColors.teal,
    divider: NemrasColors.line2,
    textPrimary: NemrasColors.ink,
    textSecondary: NemrasColors.muted,
    textPlaceholder: NemrasColors.muted2,
    accent: NemrasColors.teal,
    onAccent: NemrasColors.white,
    critical: NemrasStatusColor(
      solid: NemrasColors.red,
      soft: NemrasColors.redSoft,
      onSoft: NemrasColors.red,
      onSolid: NemrasColors.white,
    ),
    elevated: NemrasStatusColor(
      solid: NemrasColors.amber,
      soft: NemrasColors.amberSoft,
      onSoft: NemrasColors.amber,
      onSolid: NemrasColors.white,
    ),
    stable: NemrasStatusColor(
      solid: NemrasColors.green,
      soft: NemrasColors.greenSoft,
      onSoft: NemrasColors.green,
      onSolid: NemrasColors.white,
    ),
    informational: NemrasStatusColor(
      solid: NemrasColors.blue,
      soft: NemrasColors.blueSoft,
      onSoft: NemrasColors.blue,
      onSolid: NemrasColors.white,
    ),
    advisory: NemrasStatusColor(
      solid: NemrasColors.violet,
      soft: NemrasColors.violetSoft,
      onSoft: NemrasColors.violet,
      onSolid: NemrasColors.white,
    ),
    shellGradient: <Color>[NemrasColors.paper, NemrasColors.paper],
    summaryGradient: NemrasColors.summaryGradient,
    criticalSummaryGradient: NemrasColors.criticalSummaryGradient,
  );

  static const NemrasSemantics fieldDark = NemrasSemantics(
    isField: true,
    screenBackground: NemrasColors.ink,
    cardBackground: NemrasColors.fieldSurfaceOverlay,
    cardBorder: NemrasColors.fieldBorderOverlay,
    barBackground: NemrasColors.fieldBarOverlay,
    barBorder: NemrasColors.fieldBorderOverlay,
    controlBackground: NemrasColors.fieldControlOverlay,
    inputBackground: NemrasColors.fieldSurfaceOverlay,
    inputBorder: Color.fromRGBO(255, 255, 255, 0.15),
    inputBorderActive: NemrasColors.fieldAccent,
    divider: NemrasColors.fieldBorderOverlay,
    textPrimary: NemrasColors.white,
    textSecondary: NemrasColors.fieldTextSecondary,
    textPlaceholder: NemrasColors.fieldTextTertiary,
    accent: NemrasColors.fieldAccent,
    onAccent: NemrasColors.ink,
    critical: NemrasStatusColor(
      solid: NemrasColors.red,
      soft: Color.fromRGBO(198, 40, 40, 0.18),
      onSoft: NemrasColors.fieldAlert,
      onSolid: NemrasColors.white,
    ),
    elevated: NemrasStatusColor(
      solid: NemrasColors.amber,
      soft: Color.fromRGBO(224, 142, 11, 0.18),
      onSoft: Color(0xFFFFC266),
      onSolid: NemrasColors.ink,
    ),
    stable: NemrasStatusColor(
      solid: NemrasColors.green,
      soft: Color.fromRGBO(46, 125, 50, 0.18),
      onSoft: Color(0xFF8BD68F),
      onSolid: NemrasColors.white,
    ),
    informational: NemrasStatusColor(
      solid: NemrasColors.fieldAccent,
      soft: Color.fromRGBO(77, 208, 225, 0.12),
      onSoft: NemrasColors.fieldAccent,
      onSolid: NemrasColors.ink,
    ),
    advisory: NemrasStatusColor(
      solid: NemrasColors.violet,
      soft: Color.fromRGBO(94, 53, 177, 0.22),
      onSoft: Color(0xFFBFA8E8),
      onSolid: NemrasColors.white,
    ),
    shellGradient: NemrasColors.fieldShellGradient,
    summaryGradient: NemrasColors.summaryGradient,
    criticalSummaryGradient: NemrasColors.criticalSummaryGradient,
  );

  @override
  NemrasSemantics copyWith({
    bool? isField,
    Color? screenBackground,
    Color? cardBackground,
    Color? cardBorder,
    Color? barBackground,
    Color? barBorder,
    Color? controlBackground,
    Color? inputBackground,
    Color? inputBorder,
    Color? inputBorderActive,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textPlaceholder,
    Color? accent,
    Color? onAccent,
    NemrasStatusColor? critical,
    NemrasStatusColor? elevated,
    NemrasStatusColor? stable,
    NemrasStatusColor? informational,
    NemrasStatusColor? advisory,
    List<Color>? shellGradient,
    List<Color>? summaryGradient,
    List<Color>? criticalSummaryGradient,
  }) {
    return NemrasSemantics(
      isField: isField ?? this.isField,
      screenBackground: screenBackground ?? this.screenBackground,
      cardBackground: cardBackground ?? this.cardBackground,
      cardBorder: cardBorder ?? this.cardBorder,
      barBackground: barBackground ?? this.barBackground,
      barBorder: barBorder ?? this.barBorder,
      controlBackground: controlBackground ?? this.controlBackground,
      inputBackground: inputBackground ?? this.inputBackground,
      inputBorder: inputBorder ?? this.inputBorder,
      inputBorderActive: inputBorderActive ?? this.inputBorderActive,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textPlaceholder: textPlaceholder ?? this.textPlaceholder,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      critical: critical ?? this.critical,
      elevated: elevated ?? this.elevated,
      stable: stable ?? this.stable,
      informational: informational ?? this.informational,
      advisory: advisory ?? this.advisory,
      shellGradient: shellGradient ?? this.shellGradient,
      summaryGradient: summaryGradient ?? this.summaryGradient,
      criticalSummaryGradient:
          criticalSummaryGradient ?? this.criticalSummaryGradient,
    );
  }

  @override
  NemrasSemantics lerp(ThemeExtension<NemrasSemantics>? other, double t) {
    if (other is! NemrasSemantics) return this;
    return NemrasSemantics(
      isField: t < 0.5 ? isField : other.isField,
      screenBackground:
          Color.lerp(screenBackground, other.screenBackground, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      barBackground: Color.lerp(barBackground, other.barBackground, t)!,
      barBorder: Color.lerp(barBorder, other.barBorder, t)!,
      controlBackground:
          Color.lerp(controlBackground, other.controlBackground, t)!,
      inputBackground: Color.lerp(inputBackground, other.inputBackground, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputBorderActive:
          Color.lerp(inputBorderActive, other.inputBorderActive, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      critical: NemrasStatusColor.lerp(critical, other.critical, t),
      elevated: NemrasStatusColor.lerp(elevated, other.elevated, t),
      stable: NemrasStatusColor.lerp(stable, other.stable, t),
      informational:
          NemrasStatusColor.lerp(informational, other.informational, t),
      advisory: NemrasStatusColor.lerp(advisory, other.advisory, t),
      shellGradient: _lerpGradient(shellGradient, other.shellGradient, t),
      summaryGradient:
          _lerpGradient(summaryGradient, other.summaryGradient, t),
      criticalSummaryGradient: _lerpGradient(
        criticalSummaryGradient,
        other.criticalSummaryGradient,
        t,
      ),
    );
  }

  static List<Color> _lerpGradient(List<Color> a, List<Color> b, double t) {
    if (a.length != b.length) return t < 0.5 ? a : b;
    return <Color>[
      for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!,
    ];
  }
}
