import 'package:flutter/material.dart';

/// Font families used across NEMRAS.
///
/// Static `.ttf` assets are declared in this package's `pubspec.yaml`.
/// JetBrains Mono Medium and SemiBold are registered at Flutter weights 500
/// and 600. Their upstream OS/2.usWeightClass values remain 436 and 472.
abstract final class NemrasFonts {
  static const String package = 'nemras_design';

  /// Display and headings. Expected weights: 600, 700, 800.
  static const String display = 'Sora';

  /// Body and interface text. Expected weights: 400, 500, 600, 700.
  static const String ui = 'Inter';

  /// Clinical data, identifiers, metrics, timestamps and micro-labels.
  /// Expected weights: 400, 500, 600.
  static const String mono = 'JetBrainsMono';
}

/// Canonical NEMRAS text styles, transcribed from `NEMRAS_UI_Design.html`.
///
/// Styles carry no colour; the active theme or widget applies it so the same
/// style works on both the clinical light and field dark surfaces.
abstract final class NemrasTextStyles {
  static const TextStyle _display = TextStyle(
    fontFamily: NemrasFonts.display,
    package: NemrasFonts.package,
  );
  static const TextStyle _ui = TextStyle(
    fontFamily: NemrasFonts.ui,
    package: NemrasFonts.package,
  );
  static const TextStyle _mono = TextStyle(
    fontFamily: NemrasFonts.mono,
    package: NemrasFonts.package,
  );

  // Display — `.page-h h1`, `.chs .name`, `.kpi .kpi-v`
  static final TextStyle pageTitle = _display.copyWith(
    fontSize: 46,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.92,
  );
  static final TextStyle summaryName = _display.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static final TextStyle metricValue = _display.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.52,
  );

  // Headings — `.app-top .title`, `.card-title`, `.alert-box h4`
  static final TextStyle screenTitle = _display.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.16,
  );
  static final TextStyle sectionTitle = _display.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.78,
  );
  static final TextStyle alertTitle = _display.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

  // Body — `html,body`, `.alert-box p`, `.audit-line .b .t`
  static final TextStyle body = _ui.copyWith(fontSize: 14, height: 1.5);
  static final TextStyle bodySmall = _ui.copyWith(fontSize: 12, height: 1.5);
  static final TextStyle bodyCaption = _ui.copyWith(fontSize: 11, height: 1.45);
  static final TextStyle listTitle = _ui.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Controls — `.btn`, `.chip`, `.bottom-nav .nav-item`
  static final TextStyle button = _ui.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle chip = _ui.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static final TextStyle navLabel = _ui.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
  static final TextStyle inputPlaceholder = _ui.copyWith(fontSize: 14);

  // Clinical data — `.field .input`, `.field label`, `.risk-pill`, `.tag`
  static final TextStyle dataValue = _mono.copyWith(fontSize: 14);
  static final TextStyle fieldLabel = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );
  static final TextStyle riskPill = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
  static final TextStyle tag = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
  );
  static final TextStyle metricLabel = _mono.copyWith(
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.08,
  );
  static final TextStyle metricDelta = _mono.copyWith(fontSize: 10);
  static final TextStyle screenSubtitle = _mono.copyWith(
    fontSize: 9,
    letterSpacing: 0.9,
  );
  static final TextStyle dataCaption = _mono.copyWith(fontSize: 10);
  static final TextStyle badge = _mono.copyWith(
    fontSize: 9,
    fontWeight: FontWeight.w600,
  );

  /// Maps the NEMRAS styles onto Material's text slots so widgets that read
  /// `Theme.of(context).textTheme` inherit the design system.
  static TextTheme textTheme({
    required Color primary,
    required Color secondary,
  }) {
    return TextTheme(
      displayLarge: pageTitle.copyWith(color: primary),
      displayMedium: metricValue.copyWith(fontSize: 36, color: primary),
      displaySmall: metricValue.copyWith(color: primary),
      headlineLarge: summaryName.copyWith(fontSize: 24, color: primary),
      headlineMedium: summaryName.copyWith(color: primary),
      headlineSmall: screenTitle.copyWith(fontSize: 18, color: primary),
      titleLarge: screenTitle.copyWith(color: primary),
      titleMedium: sectionTitle.copyWith(fontSize: 14, color: primary),
      titleSmall: sectionTitle.copyWith(color: primary),
      bodyLarge: body.copyWith(color: primary),
      bodyMedium: body.copyWith(color: primary),
      bodySmall: bodySmall.copyWith(color: secondary),
      labelLarge: button.copyWith(color: primary),
      labelMedium: chip.copyWith(color: primary),
      labelSmall: fieldLabel.copyWith(color: secondary),
    );
  }
}
