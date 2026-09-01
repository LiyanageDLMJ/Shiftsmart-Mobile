// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shiftsmart/main.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';

void main() {
  test('timezone-less server timestamps are not forced to UTC', () {
    final parsed = parseServerDateTime('2026-08-20 09:00:00');

    expect(parsed, isNotNull);
    expect(parsed!.year, 2026);
    expect(parsed.month, 8);
    expect(parsed.day, 20);
    expect(parsed.hour, 9);
    expect(parsed.minute, 0);
    expect(parsed.isUtc, isFalse);
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
