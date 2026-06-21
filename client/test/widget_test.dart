import 'package:flutter_test/flutter_test.dart';
import 'package:battlefield_client/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BattlefieldApp());
    expect(find.byType(BattlefieldApp), findsOneWidget);
  });
}
