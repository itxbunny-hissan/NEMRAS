import 'package:flutter/material.dart';

import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';
import 'nemras_semantics.dart';

/// `.btn.btn-primary`
ButtonStyle nemrasPrimaryButtonStyle(
  NemrasSemantics semantics, {
  required double minHeight,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: semantics.accent,
    foregroundColor: semantics.onAccent,
    disabledBackgroundColor: semantics.accent.withValues(alpha: 0.5),
    disabledForegroundColor: semantics.onAccent.withValues(alpha: 0.8),
    textStyle: NemrasTextStyles.button,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: NemrasSpacing.xxl,
      vertical: NemrasSpacing.l,
    ),
    minimumSize: Size(0, minHeight),
    shape: const RoundedRectangleBorder(
      borderRadius: NemrasRadii.controlBorder,
    ),
  );
}

/// `.btn.btn-ghost`
ButtonStyle nemrasGhostButtonStyle(
  NemrasSemantics semantics, {
  required double minHeight,
}) {
  return OutlinedButton.styleFrom(
    foregroundColor: semantics.textPrimary,
    textStyle: NemrasTextStyles.button,
    padding: const EdgeInsets.symmetric(
      horizontal: NemrasSpacing.xxl,
      vertical: NemrasSpacing.l,
    ),
    minimumSize: Size(0, minHeight),
    side: BorderSide(color: semantics.inputBorder),
    shape: const RoundedRectangleBorder(
      borderRadius: NemrasRadii.controlBorder,
    ),
  );
}

ButtonStyle nemrasTextButtonStyle(
  NemrasSemantics semantics, {
  required double minHeight,
}) {
  return TextButton.styleFrom(
    foregroundColor: semantics.accent,
    textStyle: NemrasTextStyles.button,
    minimumSize: Size(0, minHeight),
  );
}

/// `.bottom-nav`
NavigationBarThemeData nemrasNavigationBarTheme(
  NemrasSemantics semantics, {
  required Color indicatorColor,
  required Color inactiveColor,
  required double height,
  required double iconSize,
}) {
  return NavigationBarThemeData(
    backgroundColor: semantics.barBackground,
    surfaceTintColor: Colors.transparent,
    indicatorColor: indicatorColor,
    height: height,
    elevation: 0,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return NemrasTextStyles.navLabel.copyWith(
        color: selected ? semantics.accent : inactiveColor,
      );
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      final selected = states.contains(WidgetState.selected);
      return IconThemeData(
        size: iconSize,
        color: selected ? semantics.accent : inactiveColor,
      );
    }),
  );
}
