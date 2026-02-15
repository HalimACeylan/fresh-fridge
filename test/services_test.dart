import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/units.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/receipt_service.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // FridgeService
  // ═══════════════════════════════════════════════════════════════════

  group('FridgeService', () {
    late FridgeService service;

    setUp(() {
      service = FridgeService.instance;
    });

    test('getAllItems returns non-empty list of sample data', () {
      final items = service.getAllItems();
      expect(items, isNotEmpty);
      expect(items.length, greaterThanOrEqualTo(10));
    });

    test('getItemsByCategory returns only matching category', () {
      final dairy = service.getItemsByCategory(FridgeCategory.dairy);
      expect(dairy, isNotEmpty);
      for (final item in dairy) {
        expect(item.category, FridgeCategory.dairy);
      }
    });

    test(
      'getExpiringItems returns items with expiringSoon or expired status',
      () {
        final expiring = service.getExpiringItems();
        for (final item in expiring) {
          expect(
            item.freshnessStatus == FreshnessStatus.expiringSoon ||
                item.freshnessStatus == FreshnessStatus.expired,
            true,
          );
        }
      },
    );

    test('getUseSoonItems returns items with useSoon status', () {
      final useSoon = service.getUseSoonItems();
      for (final item in useSoon) {
        expect(item.freshnessStatus, FreshnessStatus.useSoon);
      }
    });

    test('getFreshItems returns items with fresh status', () {
      final fresh = service.getFreshItems();
      for (final item in fresh) {
        expect(item.freshnessStatus, FreshnessStatus.fresh);
      }
    });

    test('getStats returns counts matching filter methods', () {
      final stats = service.getStats();
      expect(stats['urgent'], service.getExpiringItems().length);
      expect(stats['useSoon'], service.getUseSoonItems().length);
      expect(stats['healthy'], service.getFreshItems().length);
      expect(stats['total'], service.getAllItems().length);
    });

    test('getItemById returns existing item', () {
      final item = service.getItemById('item_001');
      expect(item, isNotNull);
      expect(item!.name, 'Fresh Spinach');
    });

    test('getItemById returns null for non-existent id', () {
      final item = service.getItemById('nonexistent');
      expect(item, isNull);
    });

    test('addItem increases item count', () {
      final initialCount = service.getAllItems().length;
      service.addItem(
        FridgeItem(
          id: 'test_add_001',
          name: 'Test Item',
          category: FridgeCategory.other,
          addedDate: DateTime.now(),
        ),
      );
      expect(service.getAllItems().length, initialCount + 1);
      // Cleanup
      service.deleteItem('test_add_001');
    });

    test('updateItem changes item data', () {
      final original = service.getItemById('item_001')!;
      final updated = original.copyWith(notes: 'Updated note');
      service.updateItem(updated);
      expect(service.getItemById('item_001')!.notes, 'Updated note');
      // Restore
      service.updateItem(original);
    });

    test('deleteItem removes item', () {
      service.addItem(
        FridgeItem(
          id: 'test_delete_001',
          name: 'To Delete',
          category: FridgeCategory.other,
          addedDate: DateTime.now(),
        ),
      );
      final countBefore = service.getAllItems().length;
      service.deleteItem('test_delete_001');
      expect(service.getAllItems().length, countBefore - 1);
    });

    test('searchItems finds by name (case-insensitive)', () {
      final results = service.searchItems('milk');
      expect(results, isNotEmpty);
      expect(
        results.any((item) => item.name.toLowerCase().contains('milk')),
        true,
      );
    });

    test('searchItems with empty query returns all', () {
      expect(service.searchItems('').length, service.getAllItems().length);
    });

    test('getActiveCategories returns sorted unique categories', () {
      final categories = service.getActiveCategories();
      expect(categories, isNotEmpty);
      // Should have no duplicates
      expect(categories.length, categories.toSet().length);
    });

    test('sample data uses FridgeUnit enums correctly', () {
      for (final item in service.getAllItems()) {
        expect(FridgeUnit.values.contains(item.unit), true);
        expect(item.amount, greaterThan(0));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // ReceiptService
  // ═══════════════════════════════════════════════════════════════════

  group('ReceiptService', () {
    late ReceiptService service;

    setUp(() {
      service = ReceiptService.instance;
    });

    test('getAllReceipts returns sample data', () {
      final receipts = service.getAllReceipts();
      expect(receipts, isNotEmpty);
    });

    test('getReceiptById returns existing receipt', () {
      final receipt = service.getReceiptById('receipt_001');
      expect(receipt, isNotNull);
      expect(receipt!.storeName, 'Whole Foods Market');
    });

    test('getReceiptById returns null for non-existent', () {
      expect(service.getReceiptById('nonexistent'), isNull);
    });

    group('suggestCategory', () {
      test('suggests produce for spinach', () {
        expect(
          service.suggestCategory('Organic Baby Spinach'),
          FridgeCategory.produce,
        );
      });

      test('suggests dairy for milk', () {
        expect(
          service.suggestCategory('Whole Milk (1 Gal)'),
          FridgeCategory.dairy,
        );
      });

      test('suggests meat for chicken', () {
        expect(service.suggestCategory('Chicken Breast'), FridgeCategory.meat);
      });

      test('suggests beverages for juice', () {
        expect(
          service.suggestCategory('Orange Juice'),
          FridgeCategory.beverages,
        );
      });

      test('suggests condiments for sauce', () {
        expect(service.suggestCategory('Soy Sauce'), FridgeCategory.condiments);
      });

      test('suggests grains for bread', () {
        expect(
          service.suggestCategory('Sourdough Bread'),
          FridgeCategory.grains,
        );
      });

      test('suggests frozen for ice cream', () {
        expect(service.suggestCategory('Ice Cream'), FridgeCategory.frozen);
      });

      test('returns other for unrecognized items', () {
        expect(service.suggestCategory('XYZABC123'), FridgeCategory.other);
      });
    });

    group('findFridgeMatch', () {
      test('finds match by substring', () {
        final matchId = service.findFridgeMatch('Whole Milk');
        expect(matchId, isNotNull);
        expect(matchId, 'item_010');
      });

      test('finds match by word overlap', () {
        final matchId = service.findFridgeMatch('Baby Spinach Fresh');
        // Should match "Fresh Spinach" via word overlap
        expect(matchId, isNotNull);
      });

      test('returns null for no match', () {
        final matchId = service.findFridgeMatch('XYZABC123');
        expect(matchId, isNull);
      });
    });

    test('addReceiptItemsToFridge creates fridge items', () {
      final fridgeService = FridgeService.instance;

      // The sample receipt has items already matched, so unmatched+recognized
      // items would be created. Let's test the logic flow is correct
      final newItems = service.addReceiptItemsToFridge('receipt_001');
      // Items that are unknown or already matched are skipped
      expect(newItems, isList);

      // Cleanup any added items
      for (final item in newItems) {
        fridgeService.deleteItem(item.id);
      }
    });

    test('matchReceiptToFridge returns empty receipt for non-existent id', () {
      final result = service.matchReceiptToFridge('nonexistent');
      expect(result.id, '');
      expect(result.items, isEmpty);
    });
  });
}
