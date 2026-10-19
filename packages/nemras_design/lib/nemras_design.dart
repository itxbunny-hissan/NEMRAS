/// Canonical NEMRAS design system: colour tokens, typography, spacing, radii,
/// shadows, touch targets, semantic clinical status colours and the two
/// application themes.
///
/// Values are transcribed from `NEMRAS_UI_Design.html`, the project's primary
/// visual reference. This package is the single source of truth; no other
/// package should declare raw design values.
library;

export 'src/theme/clinical_light_theme.dart';
export 'src/theme/component_styles.dart';
export 'src/theme/field_dark_theme.dart';
export 'src/theme/nemras_semantics.dart';
export 'src/tokens/colors.dart';
export 'src/tokens/radii.dart';
export 'src/tokens/shadows.dart';
export 'src/tokens/spacing.dart';
export 'src/tokens/touch_targets.dart';
export 'src/tokens/typography.dart';
