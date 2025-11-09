import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stingray/settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Settings screen displays correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('Server Settings'), findsOneWidget);
    expect(find.text('Server URL'), findsOneWidget);
    expect(find.text('Save Settings'), findsOneWidget);
  });

  testWidgets('Settings screen loads saved server URL', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'server_url': 'http://test-server:8096',
    });

    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.pumpAndSettle();

    final textField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(textField.controller?.text, 'http://test-server:8096');
  });

  testWidgets('Settings screen validates empty URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.tap(find.text('Save Settings'));
    await tester.pump();

    expect(find.text('Please enter a server URL'), findsOneWidget);
  });

  testWidgets('Settings screen validates URL format', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.enterText(find.byType(TextFormField), 'invalid-url');
    await tester.tap(find.text('Save Settings'));
    await tester.pump();

    expect(
      find.text('URL must start with http:// or https://'),
      findsOneWidget,
    );
  });

  testWidgets('Settings screen saves valid URL', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    await tester.enterText(find.byType(TextFormField), 'http://my-server:8096');
    await tester.tap(find.text('Save Settings'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('server_url'), 'http://my-server:8096');
  });
}
