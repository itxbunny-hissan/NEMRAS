import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_design/nemras_design.dart';

void main() {
  group('clinical light theme', () {
    final theme = nemrasClinicalLightTheme();

    test('is light and uses the reference paper background', () {
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, NemrasColors.paper);
    });

    test('primary is the reference teal, not the pre-Phase-1A teal', () {
      expect(theme.colorScheme.primary, NemrasColors.teal);
      expect(theme.colorScheme.primary, isNot(const Color(0xFF0E7C7B)));
    });

    test('cards are bordered and flat', () {
      expect(theme.cardTheme.elevation, 0);
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, NemrasRadii.cardBorder);
      expect(shape.side.color, NemrasColors.line2);
    });

    test('app bar matches .app-top', () {
      expect(theme.appBarTheme.toolbarHeight, NemrasTouchTargets.barHeight);
      expect(theme.appBarTheme.backgroundColor, NemrasColors.white);
      expect(theme.appBarTheme.elevation, 0);
    });

    test('bottom navigation matches .bottom-nav', () {
      expect(
        theme.navigationBarTheme.height,
        NemrasTouchTargets.bottomNavHeight,
      );
      expect(theme.navigationBarTheme.backgroundColor, NemrasColors.white);
    });

    test('carries NemrasSemantics', () {
      expect(theme.extension<NemrasSemantics>(), isNotNull);
      expect(theme.extension<NemrasSemantics>()!.isField, isFalse);
    });
  });

  group('field dark theme', () {
    final theme = nemrasFieldDarkTheme();

    test('is dark and uses the field accent as primary', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, NemrasColors.fieldAccent);
      expect(theme.colorScheme.onPrimary, NemrasColors.ink);
    });

    test('scaffold is the shell gradient start colour', () {
      expect(theme.scaffoldBackgroundColor, NemrasColors.ink);
    });

    test('field controls meet the larger touch target', () {
      final style = theme.elevatedButtonTheme.style!;
      final size = style.minimumSize!.resolve(<WidgetState>{});
      expect(size!.height, NemrasTouchTargets.field);
    });

    test('carries field NemrasSemantics', () {
      final semantics = theme.extension<NemrasSemantics>();
      expect(semantics, isNotNull);
      expect(semantics!.isField, isTrue);
      expect(semantics.accent, NemrasColors.fieldAccent);
    });
  });

  group('clinical status mapping', () {
    const light = NemrasSemantics.clinicalLight;
    const field = NemrasSemantics.fieldDark;

    test('Risk_Score labels map to the reference risk pill colours', () {
      expect(light.risk('Critical').solid, NemrasColors.red);
      expect(light.risk('Elevated').solid, NemrasColors.amber);
      expect(light.risk('Stable').solid, NemrasColors.green);
    });

    test('risk pills are a solid fill with a light foreground', () {
      expect(light.risk('Critical').onSolid, NemrasColors.white);
      expect(light.risk('Stable').onSolid, NemrasColors.white);
    });

    test('an unknown or absent risk label does not read as a clinical state',
        () {
      expect(light.risk(null).solid, NemrasColors.blue);
      expect(light.risk('not-a-label').solid, NemrasColors.blue);
    });

    test('Triage_Level labels map to High/Medium/Low', () {
      expect(light.triage('High').solid, NemrasColors.red);
      expect(light.triage('Medium').solid, NemrasColors.amber);
      expect(light.triage('Low').solid, NemrasColors.green);
    });

    test('backend alert severities map to the alert palette', () {
      expect(light.severity('critical').solid, NemrasColors.red);
      expect(light.severity('high').solid, NemrasColors.amber);
      expect(light.severity('info').solid, NemrasColors.blue);
    });

    test('Drug_Interaction_Risk is binary because the dataset records only '
        'Yes/No and carries no severity grading', () {
      expect(light.drugInteraction(present: true).solid, NemrasColors.red);
      expect(light.drugInteraction(present: false).solid, NemrasColors.green);
    });

    test('a recorded allergy is always a hard contraindication', () {
      expect(light.allergy.solid, NemrasColors.red);
    });

    test('Chronic_Condition is binary', () {
      expect(light.chronicCondition(present: true).solid, NemrasColors.amber);
      expect(light.chronicCondition(present: false).solid, NemrasColors.green);
    });

    test('medications use the advisory violet', () {
      expect(light.medication.solid, NemrasColors.violet);
    });

    test('the field surface keeps the same semantics but brightens the '
        'foreground so alerts stay legible on dark', () {
      expect(field.risk('Critical').solid, NemrasColors.red);
      expect(field.risk('Critical').onSoft, NemrasColors.fieldAlert);
      expect(light.risk('Critical').onSoft, NemrasColors.red);
    });
  });

  group('NemrasSemantics extension contract', () {
    test('copyWith overrides only what it is given', () {
      const base = NemrasSemantics.clinicalLight;
      final copy = base.copyWith(accent: NemrasColors.violet);
      expect(copy.accent, NemrasColors.violet);
      expect(copy.cardBackground, base.cardBackground);
      expect(copy.critical, base.critical);
    });

    test('lerp interpolates between the two surfaces', () {
      const light = NemrasSemantics.clinicalLight;
      const field = NemrasSemantics.fieldDark;
      expect(light.lerp(field, 0).screenBackground, light.screenBackground);
      expect(light.lerp(field, 1).screenBackground, field.screenBackground);
      expect(light.lerp(field, 1).isField, isTrue);
      expect(light.lerp(field, 0).isField, isFalse);
    });

    test('lerp ignores a foreign extension', () {
      const light = NemrasSemantics.clinicalLight;
      expect(light.lerp(null, 0.5), light);
    });
  });

  group('NemrasSemantics.of', () {
    testWidgets('resolves from the clinical theme', (tester) async {
      late NemrasSemantics resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasClinicalLightTheme(),
          home: Builder(
            builder: (context) {
              resolved = NemrasSemantics.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.isField, isFalse);
      expect(resolved.accent, NemrasColors.teal);
    });

    testWidgets('resolves from the field theme', (tester) async {
      late NemrasSemantics resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: nemrasFieldDarkTheme(),
          home: Builder(
            builder: (context) {
              resolved = NemrasSemantics.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.isField, isTrue);
      expect(resolved.accent, NemrasColors.fieldAccent);
    });
  });
}
