import 'package:flutter_test/flutter_test.dart';

import 'package:signbridge/main.dart';

void main() {
  testWidgets('SignBridge app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SignBridgeApp());
    // Verify MainScreen renders with the app name
    expect(find.text('SignBridge'), findsOneWidget);
  });
}
