import 'package:flutter/material.dart';
import 'package:nemras_design/nemras_design.dart';

/// Compatibility facade over the canonical design system.
///
/// New code must import `package:nemras_design/nemras_design.dart` directly and
/// resolve colours through [NemrasColors] or [NemrasSemantics]. This class holds
/// no values of its own; it exists only so the screens written before the
/// design system landed keep compiling while they are migrated one at a time.
///
/// Because these members forward to the reference tokens, existing screens now
/// render the canonical NEMRAS palette rather than the pre-Phase-1A values.
///
/// TODO(phase-1b): delete this class once every screen imports nemras_design,
/// and remove the `deprecated_member_use_from_same_package` entry from
/// analysis_options.yaml.
@Deprecated('Import package:nemras_design/nemras_design.dart instead.')
class AppTheme {
  @Deprecated('Use NemrasColors.teal.')
  static const Color primary = NemrasColors.teal;

  @Deprecated('Use NemrasColors.tealDeep.')
  static const Color primaryDark = NemrasColors.tealDeep;

  @Deprecated('Use NemrasColors.blue.')
  static const Color accent = NemrasColors.blue;

  @Deprecated('Use NemrasSemantics.screenBackground.')
  static const Color bg = NemrasColors.paper;

  @Deprecated('Use NemrasSemantics.cardBackground.')
  static const Color surface = NemrasColors.white;

  @Deprecated('Use NemrasSemantics.textPrimary.')
  static const Color ink = NemrasColors.ink;

  @Deprecated('Use NemrasSemantics.textSecondary.')
  static const Color muted = NemrasColors.muted;

  @Deprecated('Use NemrasSemantics.critical.')
  static const Color critical = NemrasColors.red;

  @Deprecated('Use NemrasSemantics.elevated.')
  static const Color high = NemrasColors.amber;

  @Deprecated('Use NemrasSemantics.stable.')
  static const Color stable = NemrasColors.green;

  /// Forwards to [NemrasSemantics.risk], keeping the legacy fall-through to
  /// [NemrasColors.muted] for labels outside the dataset's `Risk_Score`
  /// vocabulary so current call sites behave identically.
  @Deprecated('Use NemrasSemantics.of(context).risk(label).')
  static Color riskColor(String risk) {
    const semantics = NemrasSemantics.clinicalLight;
    switch (risk) {
      case 'Critical':
      case 'Elevated':
      case 'Stable':
        return semantics.risk(risk).solid;
      default:
        return NemrasColors.muted;
    }
  }

  /// Forwards to [NemrasSemantics.severity], keeping the legacy fall-through to
  /// [NemrasColors.muted] for unrecognised severities.
  @Deprecated('Use NemrasSemantics.of(context).severity(value).')
  static Color severityColor(String severity) {
    const semantics = NemrasSemantics.clinicalLight;
    switch (severity) {
      case 'critical':
      case 'high':
      case 'info':
        return semantics.severity(severity).solid;
      default:
        return NemrasColors.muted;
    }
  }

  @Deprecated('Use nemrasClinicalLightTheme().')
  static ThemeData theme() => nemrasClinicalLightTheme();
}
