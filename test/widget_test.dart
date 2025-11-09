import 'package:flutter_test/flutter_test.dart';

import 'package:stingray/main.dart';

void main() {
  testWidgets('Health check UI smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title is present.
    expect(find.text('Stingray'), findsOneWidget);

    // Verify initial status text is present.
    expect(find.text('Jellyfin Server Status:'), findsOneWidget);
    expect(find.text('Not checked'), findsOneWidget);

    // Verify the button is present.
    expect(find.text('Check Health'), findsOneWidget);
  });
}
