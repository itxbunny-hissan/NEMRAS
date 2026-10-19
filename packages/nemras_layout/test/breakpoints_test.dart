import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nemras_layout/nemras_layout.dart';

void main() {
  group('NemrasBreakpoints.fromWidth', () {
    test('classifies phone widths as compact', () {
      expect(NemrasBreakpoints.fromWidth(0), NemrasWindowSize.compact);
      expect(NemrasBreakpoints.fromWidth(360), NemrasWindowSize.compact);
      expect(NemrasBreakpoints.fromWidth(599.9), NemrasWindowSize.compact);
    });

    test('classifies tablet widths as medium', () {
      expect(NemrasBreakpoints.fromWidth(600), NemrasWindowSize.medium);
      expect(NemrasBreakpoints.fromWidth(768), NemrasWindowSize.medium);
      expect(NemrasBreakpoints.fromWidth(1023.9), NemrasWindowSize.medium);
    });

    test('classifies desktop widths as expanded', () {
      expect(NemrasBreakpoints.fromWidth(1024), NemrasWindowSize.expanded);
      expect(NemrasBreakpoints.fromWidth(1920), NemrasWindowSize.expanded);
    });

    test('boundaries are inclusive at the lower edge', () {
      expect(NemrasBreakpoints.mediumMin, 600);
      expect(NemrasBreakpoints.expandedMin, 1024);
      expect(
        NemrasBreakpoints.fromWidth(NemrasBreakpoints.mediumMin),
        NemrasWindowSize.medium,
      );
      expect(
        NemrasBreakpoints.fromWidth(NemrasBreakpoints.expandedMin),
        NemrasWindowSize.expanded,
      );
    });
  });

  group('context helpers', () {
    Future<NemrasWindowSize> resolve(WidgetTester tester, Size size) async {
      late NemrasWindowSize resolved;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              resolved = NemrasBreakpoints.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('resolve from the window width', (tester) async {
      expect(await resolve(tester, const Size(390, 844)),
          NemrasWindowSize.compact);
      expect(await resolve(tester, const Size(820, 1180)),
          NemrasWindowSize.medium);
      expect(await resolve(tester, const Size(1440, 900)),
          NemrasWindowSize.expanded);
    });

    testWidgets('only one helper is true at a time', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1440, 900)),
          child: Builder(
            builder: (context) {
              expect(NemrasBreakpoints.isCompact(context), isFalse);
              expect(NemrasBreakpoints.isMedium(context), isFalse);
              expect(NemrasBreakpoints.isExpanded(context), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('ResponsiveBuilder', () {
    setUp(() {
      // The default 800dp test viewport would clamp a wider child, so the
      // builder would never see an expanded constraint.
      final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views
          .first;
      view.physicalSize = const Size(2400, 1200);
      view.devicePixelRatio = 1.0;
      addTearDown(view.reset);
    });

    Widget harness(double width, {bool withMedium = true,
        bool withExpanded = true}) {
      return MaterialApp(
        home: Center(
          child: SizedBox(
            width: width,
            child: ResponsiveBuilder(
              compact: (_) => const Text('compact'),
              medium: withMedium ? (_) => const Text('medium') : null,
              expanded: withExpanded ? (_) => const Text('expanded') : null,
            ),
          ),
        ),
      );
    }

    testWidgets('picks the builder for the incoming constraints',
        (tester) async {
      await tester.pumpWidget(harness(360));
      expect(find.text('compact'), findsOneWidget);

      await tester.pumpWidget(harness(700));
      expect(find.text('medium'), findsOneWidget);

      await tester.pumpWidget(harness(1200));
      expect(find.text('expanded'), findsOneWidget);
    });

    testWidgets('expanded falls back to medium, then compact', (tester) async {
      await tester.pumpWidget(harness(1200, withExpanded: false));
      expect(find.text('medium'), findsOneWidget);

      await tester.pumpWidget(
        harness(1200, withExpanded: false, withMedium: false),
      );
      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets('medium falls back to compact', (tester) async {
      await tester.pumpWidget(harness(700, withMedium: false));
      expect(find.text('compact'), findsOneWidget);
    });

    testWidgets('resolves on constraints, not the window, so it works in a '
        'desktop pane', (tester) async {
      // A narrow pane inside a wide window must still lay out as compact.
      await tester.pumpWidget(harness(400));
      expect(find.text('compact'), findsOneWidget);
    });
  });
}
