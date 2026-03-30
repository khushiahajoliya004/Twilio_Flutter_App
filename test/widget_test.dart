import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_flutter_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TwilioApp());
    expect(find.text('Twilio SMS & Calls'), findsOneWidget);
  });
}
