import 'package:flutter_test/flutter_test.dart';
import 'package:nemras/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NemrasApp());
    expect(find.byType(NemrasApp), findsOneWidget);
  });
}
