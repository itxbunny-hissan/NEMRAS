import 'package:flutter/material.dart';

/// NEMRAS clinical theme - light, calm, medical-trust.
/// Teal/blue conveys clinical trust; amber/red reserved strictly for alerts.
class AppTheme {
  static const Color primary = Color(0xFF0E7C7B);    // clinical teal
  static const Color primaryDark = Color(0xFF0A5A59);
  static const Color accent = Color(0xFF1565C0);     // trust blue
  static const Color bg = Color(0xFFF4F7F8);         // soft clinical grey
  static const Color surface = Colors.white;
  static const Color ink = Color(0xFF14323B);        // deep slate text
  static const Color muted = Color(0xFF6B8089);

  // Severity colors
  static const Color critical = Color(0xFFD32F2F);
  static const Color high = Color(0xFFF57C00);
  static const Color stable = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1565C0);

  static Color riskColor(String risk) {
    switch (risk) {
      case 'Critical':
        return critical;
      case 'Elevated':
        return high;
      case 'Stable':
        return stable;
      default:
        return muted;
    }
  }

  static Color severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return critical;
      case 'high':
        return high;
      case 'info':
        return info;
      default:
        return muted;
    }
  }

  static ThemeData theme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: 'Roboto',
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2EAEC)),
        ),
      ),
    );
  }
}
