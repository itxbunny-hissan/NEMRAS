import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/app.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PortfolioApp());
    await tester.pump();
  }

  testWidgets('states the product, the demo boundary, and the team', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));

    expect(find.text('NEMRAS'), findsWidgets);
    expect(
      find.text('National Emergency Medical Record Access System'),
      findsWidgets,
    );
    expect(find.text('FYP DEMO'), findsOneWidget);
    expect(find.text('NOT A PRODUCTION DEPLOYMENT'), findsOneWidget);
    expect(find.textContaining('Trained ML, an LLM, and RAG remain planned'), findsOneWidget);
    expect(find.text('Current demo / rule-based'), findsOneWidget);
    expect(find.text('Trained risk model'), findsWidgets);
    expect(find.text('RAG'), findsWidgets);
    expect(find.text('LLM'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.headingLevel == 1,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Semantics || widget.properties.headingLevel != 2) {
          return false;
        }
        final child = widget.child;
        return child is Text && child.data == 'NEMRAS';
      }),
      findsNothing,
    );
    expect(find.text('Explore System'), findsOneWidget);
    expect(find.text('Architecture'), findsWidgets);
    expect(find.text('Kashaf Sajjad'), findsOneWidget);
    expect(find.text('Mirza Hissan Baig'), findsOneWidget);
    expect(find.text('Azka Ashraf'), findsOneWidget);
    expect(find.text('Muhammad Manshah'), findsOneWidget);
    expect(find.text('BS Data Science, Batch 2023–2027'), findsWidgets);
    expect(find.text('64,182'), findsOneWidget);
    expect(find.textContaining('not an LLM and not RAG'), findsWidgets);
    expect(find.textContaining('No speech service'), findsWidgets);
    expect(find.text('GET /api/v1/me/identity'), findsNothing);
    expect(find.textContaining('GET /api/v1/me/identity'), findsWidgets);
    expect(find.text('Proposed'), findsWidgets);
    expect(find.text('Planned'), findsWidgets);

    expect(find.textContaining('Emerson'), findsNothing);
    expect(find.textContaining('OCR'), findsNothing);
    expect(find.textContaining('Kafka'), findsNothing);
    expect(find.textContaining('Pinecone'), findsNothing);
    expect(find.textContaining('Prof.'), findsNothing);
  });

  testWidgets('Explore System scrolls to the five surfaces', (tester) async {
    await pumpAt(tester, const Size(1280, 800));
    await tester.scrollUntilVisible(find.text('Explore System'), 300);
    await tester.tap(find.text('Explore System'));
    await tester.pumpAndSettle();
    expect(find.text('Five NEMRAS surfaces'), findsOneWidget);
  });

  testWidgets('compact and desktop layouts build without overflow', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Open section index'), findsOneWidget);

    await tester.tap(find.byTooltip('Open section index'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('03  Architecture'));
    await tester.pumpAndSettle();
    expect(find.text('Federated data plane'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await pumpAt(tester, const Size(1280, 900));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Open section index'), findsNothing);
  });

  testWidgets('tablet uses the section menu and desktop keeps every label', (
    tester,
  ) async {
    for (final size in const <Size>[
      Size(768, 1024),
      Size(834, 1112),
    ]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Open section index'), findsOneWidget);
      expect(find.text('Showcase'), findsNothing);
    }

    for (final size in const <Size>[
      Size(1024, 768),
      Size(1280, 800),
      Size(1440, 900),
      Size(390, 844),
    ]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
    }

    await pumpAt(tester, const Size(1024, 768));
    expect(find.byTooltip('Open section index'), findsNothing);
    expect(find.text('Showcase'), findsWidgets);
    expect(find.text('Flutter clients'), findsOneWidget);
    expect(find.text('FIELD'), findsOneWidget);
    expect(find.text('PATIENT CONTEXT'), findsOneWidget);
  });

  testWidgets('homepage follows the public reference without a live case', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));

    expect(
      find.text(
        'The emergency medical record that follows the patient, not the hospital.',
      ),
      findsOneWidget,
    );
    expect(find.text('NO LIVE DISPATCH CASE'), findsOneWidget);
    expect(find.text('Not available'), findsWidgets);
    expect(find.text('Not recorded'), findsOneWidget);
    expect(find.textContaining('AMB-'), findsNothing);
    expect(find.textContaining('70%'), findsNothing);
    expect(find.textContaining('SHA-256'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              'Opening a live case is not available',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              'Verifying a certificate chain is not available',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.text('Platform and modules'));
    await tester.pumpAndSettle();
    expect(find.text('Five NEMRAS surfaces'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('How it works'),
      -400,
    );
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();
    expect(find.text('Federated data plane'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Project case study'),
      -400,
    );
    await tester.tap(find.text('Project case study'));
    await tester.pumpAndSettle();
    expect(find.text('Project status'), findsOneWidget);

    expect(find.textContaining('Zainab'), findsNothing);
    expect(find.textContaining('118/74'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              'Opening Patient / Paramedic is not available from this page',
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('homepage fits 320 and 390 widths', (tester) async {
    for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Opening a live case is not available'),
        300,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text(
          'Opening Patient / Paramedic is not available from this page',
        ),
        400,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('golden hour trajectory stays disconnected from live dispatch', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));
    await tester.scrollUntilVisible(find.text('How it works'), 300);
    await tester.tap(find.text('How it works'));
    await tester.pumpAndSettle();

    expect(
      find.text('How NEMRAS coordinates the golden hour'),
      findsOneWidget,
    );
    expect(find.text('Field dispatch'), findsOneWidget);
    expect(
      find.textContaining('No responder or vehicle registry is connected'),
      findsOneWidget,
    );
    expect(find.text('Verification stream'), findsOneWidget);
    expect(find.text('Federation bus'), findsOneWidget);
    expect(find.textContaining('NADRA'), findsNothing);
    expect(find.textContaining('TLS'), findsNothing);
    expect(find.textContaining('WORM'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              'Replaying a live trajectory is not available',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.scrollUntilVisible(find.text('Return to homepage'), 400);
    await tester.tap(find.text('Return to homepage'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The emergency medical record that follows the patient, not the hospital.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Open project status'), 400);
    await tester.tap(find.text('Open project status'));
    await tester.pumpAndSettle();
    expect(find.text('Project status'), findsOneWidget);
  });

  testWidgets('golden hour trajectory fits 320 and 390 widths', (tester) async {
    for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Replaying a live trajectory is not available'),
        400,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('case study lists built surfaces and no thesis file', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));
    await tester.scrollUntilVisible(find.text('Project case study'), 300);
    await tester.tap(find.text('Project case study'));
    await tester.pumpAndSettle();

    expect(find.text('Academic case study'), findsOneWidget);
    expect(
      find.textContaining('No thesis file is attached to this page.'),
      findsOneWidget,
    );
    expect(find.textContaining('Patient · Demo'), findsOneWidget);
    expect(find.textContaining('National / Ministry · Demo'), findsOneWidget);
    expect(find.text('Kashaf Sajjad'), findsOneWidget);
    expect(find.textContaining('Emerson'), findsNothing);
    expect(find.textContaining('Prof.'), findsNothing);
    expect(find.textContaining('ISO'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(
              FilledButton,
              'Downloading a thesis is not available',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.widgetWithText(
              OutlinedButton,
              'A numbered screen ledger is not available',
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.scrollUntilVisible(find.text('Review product frames'), 300);
    await tester.tap(find.text('Review product frames'));
    await tester.pumpAndSettle();
    expect(find.text('Product showcase'), findsOneWidget);
  });

  testWidgets('case study fits 320 and 390 widths', (tester) async {
    for (final size in const <Size>[Size(320, 640), Size(390, 844)]) {
      await pumpAt(tester, size);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Downloading a thesis is not available'),
        400,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
