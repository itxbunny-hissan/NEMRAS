import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/main.dart';
import 'package:nemras/screens/splash_screen.dart';
import 'package:nemras_design/nemras_design.dart';

void main() {
  testWidgets('App boots into the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const NemrasApp());

    expect(find.byType(NemrasApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('NEMRAS'), findsOneWidget);

    // The splash screen schedules a navigation timer. Replace the tree so
    // dispose() cancels it, otherwise the test fails with a pending timer.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Splash screen cancels its navigation timer on dispose',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox.shrink());

    // Past the 2800ms navigation delay: a cancelled timer must not fire.
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('App runs on the canonical NEMRAS design system',
      (WidgetTester tester) async {
    await tester.pumpWidget(const NemrasApp());

    final theme = Theme.of(tester.element(find.byType(SplashScreen)));

    expect(theme.extension<NemrasSemantics>(), isNotNull);
    expect(theme.extension<NemrasSemantics>()!.isField, isFalse);
    expect(theme.colorScheme.primary, NemrasColors.teal);
    expect(theme.scaffoldBackgroundColor, NemrasColors.paper);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
