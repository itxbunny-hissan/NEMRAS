import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radii.dart';
import '../tokens/touch_targets.dart';
import '../tokens/typography.dart';
import 'component_styles.dart';
import 'nemras_semantics.dart';

/// The clinical light theme used by the patient surface and, later, by the
/// hospital and ministry surfaces.
///
/// No `inputDecorationTheme` is declared yet: every existing text field
/// supplies its own `InputDecoration`, and a theme-level `focusedBorder` would
/// override those. Input styling arrives with the shared field primitive.
ThemeData nemrasClinicalLightTheme() {
  const semantics = NemrasSemantics.clinicalLight;
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: NemrasColors.teal,
      onPrimary: NemrasColors.white,
      primaryContainer: NemrasColors.tealSoft,
      onPrimaryContainer: NemrasColors.tealDeep,
      secondary: NemrasColors.blue,
      onSecondary: NemrasColors.white,
      secondaryContainer: NemrasColors.blueSoft,
      onSecondaryContainer: NemrasColors.blue,
      surface: NemrasColors.white,
      onSurface: NemrasColors.ink,
      onSurfaceVariant: NemrasColors.muted,
      error: NemrasColors.red,
      onError: NemrasColors.white,
      errorContainer: NemrasColors.redSoft,
      onErrorContainer: NemrasColors.redDeep,
      outline: NemrasColors.line,
      outlineVariant: NemrasColors.line2,
    ),
    scaffoldBackgroundColor: semantics.screenBackground,
    canvasColor: semantics.screenBackground,
    textTheme: NemrasTextStyles.textTheme(
      primary: semantics.textPrimary,
      secondary: semantics.textSecondary,
    ),
    iconTheme: const IconThemeData(color: NemrasColors.ink),
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
        bottom: BorderSide(color: NemrasColors.line2),
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
      indicatorColor: NemrasColors.tealSoft,
      inactiveColor: NemrasColors.muted2,
      height: NemrasTouchTargets.bottomNavHeight,
      iconSize: NemrasTouchTargets.navIconSize,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: nemrasPrimaryButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.minimum,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: nemrasPrimaryButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.minimum,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: nemrasGhostButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.minimum,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: nemrasTextButtonStyle(
        semantics,
        minHeight: NemrasTouchTargets.minimum,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: semantics.accent,
      linearTrackColor: NemrasColors.paper2,
      circularTrackColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NemrasColors.ink,
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
