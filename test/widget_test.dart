// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:mobile_v2/main.dart';

void main() {
  setUpAll(() async {
    // Initialize environment variables with mock values
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(
      fileInput: '''
      API_HOST=localhost
      API_PORT=8000
      WS_HOST=localhost
      WS_PORT=8080
      AI_SERVER_HOST=localhost
      AI_SERVER_PORT=5000
      ROBOT_SPEED=0.5
    ''',
    );
  });

  testWidgets('App starts without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify app starts without crashing
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
