import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:stingray/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Main screen shows sign in when server configured', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://test-server:8096',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the title is present.
    expect(find.text('Stingray'), findsOneWidget);

    // Verify server URL is displayed.
    expect(find.text('http://test-server:8096'), findsOneWidget);

    // Verify main title is present.
    expect(find.text('Jellyfin Music Player'), findsOneWidget);

    // Verify the sign in button is present.
    expect(find.text('Sign In'), findsOneWidget);

    // Verify settings button is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('Shows "No server configured" when no server set', (
    WidgetTester tester,
  ) async {
    // Start with no server configured
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Should show the status initially
    expect(find.text('No server configured'), findsOneWidget);
  });

  testWidgets('Opens settings when settings button tapped', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://test-server:8096',
    });

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap settings button
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify settings screen opened
    expect(find.text('Server Settings'), findsOneWidget);
    expect(find.text('Server URL'), findsOneWidget);
  });
}
