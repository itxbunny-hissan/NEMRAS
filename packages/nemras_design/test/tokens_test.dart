import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_design/nemras_design.dart';

void main() {
  group('NemrasColors matches the NEMRAS_UI_Design.html :root tokens', () {
    test('neutrals', () {
      expect(NemrasColors.ink, const Color(0xFF0B1F2A));
      expect(NemrasColors.ink2, const Color(0xFF143041));
      expect(NemrasColors.paper, const Color(0xFFF5F7F9));
      expect(NemrasColors.paper2, const Color(0xFFEAEEF2));
      expect(NemrasColors.line, const Color(0xFFD8DFE5));
      expect(NemrasColors.line2, const Color(0xFFE8ECF0));
      expect(NemrasColors.muted, const Color(0xFF5A6B78));
      expect(NemrasColors.muted2, const Color(0xFF8A99A6));
    });

    test('brand', () {
      expect(NemrasColors.teal, const Color(0xFF00897B));
      expect(NemrasColors.tealDeep, const Color(0xFF00574B));
      expect(NemrasColors.tealSoft, const Color(0xFFE0F2F1));
      expect(NemrasColors.cyan, const Color(0xFF0097A7));
    });

    test('status', () {
      expect(NemrasColors.green, const Color(0xFF2E7D32));
      expect(NemrasColors.amber, const Color(0xFFE08E0B));
      expect(NemrasColors.red, const Color(0xFFC62828));
      expect(NemrasColors.redDeep, const Color(0xFF8B0000));
      expect(NemrasColors.violet, const Color(0xFF5E35B1));
      expect(NemrasColors.blue, const Color(0xFF1565C0));
    });

    test('field surface', () {
      expect(NemrasColors.fieldAccent, const Color(0xFF4DD0E1));
      expect(NemrasColors.fieldAlert, const Color(0xFFFF7A7A));
      expect(
        NemrasColors.fieldShellGradient,
        <Color>[NemrasColors.ink, NemrasColors.ink2],
      );
    });

    test('a critical patient summary uses the deep red gradient', () {
      expect(
        NemrasColors.criticalSummaryGradient,
        <Color>[NemrasColors.redDeep, NemrasColors.red],
      );
    });
  });

  group('geometry tokens', () {
    test('radii match the reference components', () {
      expect(NemrasRadii.card, 18);
      expect(NemrasRadii.small, 10);
      expect(NemrasRadii.control, 12);
      expect(NemrasRadii.pill, 20);
      expect(NemrasRadii.tag, 6);
    });

    test('card padding and stack gap match .card and .app-body', () {
      expect(NemrasSpacing.cardPadding, 16);
      expect(NemrasSpacing.screenPadding, 16);
      expect(NemrasSpacing.stackGap, 14);
    });

    test('bar and bottom nav heights match .app-top and .bottom-nav', () {
      expect(NemrasTouchTargets.barHeight, 54);
      expect(NemrasTouchTargets.bottomNavHeight, 64);
      expect(NemrasTouchTargets.inputHeight, 46);
    });

    test('field targets are larger than the baseline minimum', () {
      expect(NemrasTouchTargets.field,
          greaterThan(NemrasTouchTargets.minimum));
    });

    test('reference icon buttons are smaller than an accessible target, so '
        'their painted size must be padded out when made interactive', () {
      expect(NemrasTouchTargets.iconButtonVisual,
          lessThan(NemrasTouchTargets.minimum));
      expect(NemrasTouchTargets.listIconVisual,
          lessThan(NemrasTouchTargets.minimum));
    });
  });

  group('typography', () {
    test('families are namespaced to this package so consumers resolve the '
        'bundled assets', () {
      expect(NemrasTextStyles.body.fontFamily,
          'packages/nemras_design/${NemrasFonts.ui}');
      expect(NemrasTextStyles.sectionTitle.fontFamily,
          'packages/nemras_design/${NemrasFonts.display}');
      expect(NemrasTextStyles.dataValue.fontFamily,
          'packages/nemras_design/${NemrasFonts.mono}');
    });

    test('clinical data styles use the monospace family', () {
      const mono = 'packages/nemras_design/${NemrasFonts.mono}';
      expect(NemrasTextStyles.fieldLabel.fontFamily, mono);
      expect(NemrasTextStyles.riskPill.fontFamily, mono);
      expect(NemrasTextStyles.tag.fontFamily, mono);
      expect(NemrasTextStyles.metricLabel.fontFamily, mono);
    });

    test('card title is uppercase-tracked Sora 13/700', () {
      expect(NemrasTextStyles.sectionTitle.fontSize, 13);
      expect(NemrasTextStyles.sectionTitle.fontWeight, FontWeight.w700);
      expect(NemrasTextStyles.sectionTitle.letterSpacing, closeTo(0.78, 0.001));
    });

    test('styles carry no colour so one style serves both themes', () {
      expect(NemrasTextStyles.body.color, isNull);
      expect(NemrasTextStyles.riskPill.color, isNull);
      expect(NemrasTextStyles.sectionTitle.color, isNull);
    });
  });

  group('shadows', () {
    test('the reference is a bordered design, so cards opt into elevation', () {
      expect(NemrasShadows.none, isEmpty);
      expect(NemrasShadows.card, hasLength(2));
      expect(NemrasShadows.standard, hasLength(2));
      expect(NemrasShadows.large, hasLength(2));
    });
  });
}
