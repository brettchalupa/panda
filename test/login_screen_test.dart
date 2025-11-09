import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingray/login_screen.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(serverUrl: 'http://test-server:8096'),
      ),
    );

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign in to Jellyfin'), findsOneWidget);
    expect(find.text('http://test-server:8096'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Login screen validates empty username', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(serverUrl: 'http://test-server:8096'),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your username'), findsOneWidget);
  });

  testWidgets('Login screen validates empty password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(serverUrl: 'http://test-server:8096'),
      ),
    );

    // Enter username but no password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'testuser',
    );
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
