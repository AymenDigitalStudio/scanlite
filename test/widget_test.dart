import 'package:flutter_test/flutter_test.dart';
import 'package:scanlite/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanApp());
    expect(find.text('ScanLite'), findsOneWidget);
  });
}
