import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/touch_targets.dart';
import '../tokens/typography.dart';
import 'component_styles.dart';
import 'nemras_semantics.dart';

/// The dark field theme for the paramedic surface (`.paramedic-app`).
///
/// Surfaces are deliberately translucent so the shell gradient reads through
/// them, and interactive targets use [NemrasTouchTargets.field] because these
/// controls are operated one-handed, often gloved, under time pressure.
///
/// Defined now so both surfaces share one token contract. The paramedic
/// screens themselves are not part of this phase.
ThemeData nemrasFieldDarkTheme() {
  const semantics = NemrasSemantics.fieldDark;
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: NemrasColors.fieldAccent,
      onPrimary: NemrasColors.ink,
      primaryContainer: NemrasColors.ink2,
      onPrimaryContainer: NemrasColors.fieldAccent,
      secondary: NemrasColors.cyan,
      onSecondary: NemrasColors.white,
      surface: NemrasColors.ink,
      onSurface: NemrasColors.white,
      onSurfaceVariant: NemrasColors.fieldTextSecondary,
      error: NemrasColors.red,
      onError: NemrasColors.white,
      errorContainer: NemrasColors.redDeep,
      onErrorContainer: NemrasColors.fieldAlert,
      outline: NemrasColors.fieldBorderOverlay,
      outlineVariant: NemrasColors.fieldBorderOverlay,
    ),
    scaffoldBackgroundColor: semantics.screenBackground,
    canvasColor: semantics.screenBackground,
    textTheme: NemrasTextStyles.textTheme(
      primary: semantics.textPrimary,
      secondary: semantics.textSecondary,
    ),
    iconTheme: const IconThemeData(color: NemrasColors.white),
    appBarTheme: AppBarTheme(
      backgroundColor: semantics.barBackground,
      foregroundColor: semantics.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: NemrasTouchTargets.barHeight,
      titleTextStyle: NemrasTextStyles.screenTitle.copyWith(
        color: semantics.textPrimary,
      ),
      shape: const Border(
        bottom: BorderSide(color: NemrasColors.fieldBorderOverlay),
      ),
    ),
    cardTheme: CardThemeData(
      color: semantics.cardBackground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: NemrasRadii.cardBorder,
        side: BorderSide(color: semantics.cardBorder),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: semantics.divider,
      thickness: 1,
    ),
    navigationBarTheme: nemrasNavigationBarTheme(
      semantics,
      indicatorColor: const Color.fromRGBO(77, 208, 225, 0.12),
      inactiveColor: NemrasColors.fieldTextTertiary,
      height: NemrasTouchTargets.bottomNavHeight,
      iconSize: NemrasTouchTargets.navIconSize,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: nemrasPrimaryButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.field,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: nemrasPrimaryButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.field,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: nemrasGhostButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.field,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: nemrasTextButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.field,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: semantics.accent,
      linearTrackColor: NemrasColors.fieldBorderOverlay,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NemrasColors.ink2,
      contentTextStyle: NemrasTextStyles.bodySmall.copyWith(
        color: NemrasColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(
        borderRadius: NemrasRadii.controlBorder,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[semantics],
  );
}
