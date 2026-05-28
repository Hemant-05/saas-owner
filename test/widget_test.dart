import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_owner_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QRCafeOwnerApp());
    expect(find.byType(QRCafeOwnerApp), findsOneWidget);
  });
}
