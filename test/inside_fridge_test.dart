import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/screens/inside_fridge_screen.dart';
import 'package:fridge_app/services/fridge_service.dart';

void main() {
  testWidgets('Inside Fridge Screen loads correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InsideFridgeScreen()));

    // ── Header ──────────────────────────────────────────────────────
    expect(find.text('Inside My Fridge'), findsOneWidget);
    expect(find.text('Inventory Management'), findsOneWidget);

    // ── Search Bar ──────────────────────────────────────────────────
    expect(find.text('Find ingredients...'), findsOneWidget);

    // ── Stat badge labels ───────────────────────────────────────────
    expect(find.text('Urgent'), findsOneWidget);
    expect(find.text('Use Soon'), findsOneWidget);
    expect(find.text('Healthy'), findsOneWidget);

    // ── Stat count labels ───────────────────────────────────────────
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.text('Use this week'), findsOneWidget);
    expect(find.text('Total fresh items'), findsOneWidget);

    // ── Bottom Navigation ───────────────────────────────────────────
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Fridge'), findsOneWidget);
    expect(find.text('Cook'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // ── FAB ─────────────────────────────────────────────────────────
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Inside Fridge Screen shows urgent section heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InsideFridgeScreen()));

    final urgentItems = FridgeService.instance.getExpiringItems();

    if (urgentItems.isNotEmpty) {
      expect(find.text('Use Immediately'), findsOneWidget);
      // Verify the urgent items count label is displayed
      expect(find.text('${urgentItems.length} items'), findsWidgets);
    }
  });

  testWidgets('Inside Fridge Screen shows category sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: InsideFridgeScreen()));

    // Check at least a few known items from the sample data are present
    // (they may be off-screen, so we just verify the widget tree contains them)
    final allItems = FridgeService.instance.getAllItems();
    expect(allItems.isNotEmpty, true);

    // Verify the first item in the list (Fresh Spinach) is rendered
    // It should appear either in urgent or category section
    expect(find.text(allItems.first.name), findsWidgets);
  });
}
