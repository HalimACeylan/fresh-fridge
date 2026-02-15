import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/screens/inside_fridge_screen.dart';

void main() {
  testWidgets('Inside Fridge Screen loads correctly', (
    WidgetTester tester,
  ) async {
    // Build the InsideFridgeScreen wrapped in a MaterialApp because it uses Scaffold/Theme
    await tester.pumpWidget(const MaterialApp(home: InsideFridgeScreen()));

    // Verify Title
    expect(find.text('Inside My Fridge'), findsOneWidget);
    expect(find.text('Inventory Management'), findsOneWidget);

    // Verify Search Bar
    expect(find.text('Find ingredients...'), findsOneWidget);

    // Verify Stats
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Fridge'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify FAB
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
