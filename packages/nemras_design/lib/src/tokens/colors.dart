import 'package:flutter/material.dart';

/// Canonical NEMRAS colour tokens.
///
/// Transcribed from the `:root` custom-property block of
/// `NEMRAS_UI_Design.html`, the project's primary visual reference. These are
/// raw values with no semantic meaning attached; resolve colours through
/// `NemrasSemantics` wherever a surface needs light/dark awareness.
abstract final class NemrasColors {
  // Neutrals
  static const Color ink = Color(0xFF0B1F2A);
  static const Color ink2 = Color(0xFF143041);
  static const Color paper = Color(0xFFF5F7F9);
  static const Color paper2 = Color(0xFFEAEEF2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFD8DFE5);
  static const Color line2 = Color(0xFFE8ECF0);
  static const Color muted = Color(0xFF5A6B78);
  static const Color muted2 = Color(0xFF8A99A6);

  // Brand
  static const Color teal = Color(0xFF00897B);
  static const Color tealDeep = Color(0xFF00574B);
  static const Color tealSoft = Color(0xFFE0F2F1);
  static const Color cyan = Color(0xFF0097A7);
  static const Color cyanSoft = Color(0xFFE0F7FA);

  // Status
  static const Color green = Color(0xFF2E7D32);
  static const Color greenSoft = Color(0xFFE8F5E9);
  static const Color amber = Color(0xFFE08E0B);
  static const Color amberSoft = Color(0xFFFFF4DC);
  static const Color red = Color(0xFFC62828);
  static const Color redSoft = Color(0xFFFDECEA);
  static const Color redDeep = Color(0xFF8B0000);
  static const Color violet = Color(0xFF5E35B1);
  static const Color violetSoft = Color(0xFFEDE7F6);
  static const Color blue = Color(0xFF1565C0);
  static const Color blueSoft = Color(0xFFE3F2FD);

  /// Accent for the paramedic/field surface (`.paramedic-app .nav-item.active`).
  static const Color fieldAccent = Color(0xFF4DD0E1);

  /// Alert text on dark field backgrounds (`.chs .stat .val.alert`). [red] does
  /// not carry enough luminance against [ink] to stay legible.
  static const Color fieldAlert = Color(0xFFFF7A7A);

  /// Translucent overlays used by `.paramedic-app` in place of solid fills, so
  /// the shell gradient remains visible through cards and bars.
  static const Color fieldSurfaceOverlay = Color.fromRGBO(255, 255, 255, 0.06);
  static const Color fieldBarOverlay = Color.fromRGBO(255, 255, 255, 0.04);
  static const Color fieldBorderOverlay = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color fieldControlOverlay = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color fieldTextSecondary = Color.fromRGBO(255, 255, 255, 0.7);
  static const Color fieldTextTertiary = Color.fromRGBO(255, 255, 255, 0.5);

  /// `.paramedic-app` background gradient.
  static const List<Color> fieldShellGradient = <Color>[ink, ink2];

  /// `.chs` gradient for a normal patient summary card.
  static const List<Color> summaryGradient = <Color>[ink, ink2];

  /// `.chs` gradient when the patient is flagged critical.
  static const List<Color> criticalSummaryGradient = <Color>[redDeep, red];
}
