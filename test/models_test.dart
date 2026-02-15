import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/models/recipe.dart';
import 'package:fridge_app/models/units.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // FridgeItem
  // ═══════════════════════════════════════════════════════════════════

  group('FridgeItem', () {
    late FridgeItem item;

    setUp(() {
      item = FridgeItem(
        id: 'test_001',
        name: 'Test Milk',
        category: FridgeCategory.dairy,
        amount: 1,
        unit: FridgeUnit.gallons,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
      );
    });

    test('toMap and fromMap round-trip preserves all fields', () {
      final map = item.toMap();
      final restored = FridgeItem.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.category, item.category);
      expect(restored.amount, item.amount);
      expect(restored.unit, item.unit);
      expect(restored.householdId, item.householdId);
    });

    test('freshnessStatus returns fresh for items > 7 days out', () {
      final freshItem = item.copyWith(
        expiryDate: DateTime.now().add(const Duration(days: 10)),
      );
      expect(freshItem.freshnessStatus, FreshnessStatus.fresh);
    });

    test('freshnessStatus returns useSoon for items 3-7 days out', () {
      final useSoonItem = item.copyWith(
        expiryDate: DateTime.now().add(const Duration(days: 5)),
      );
      expect(useSoonItem.freshnessStatus, FreshnessStatus.useSoon);
    });

    test('freshnessStatus returns expiringSoon for items <= 2 days', () {
      final expiringItem = item.copyWith(
        expiryDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(expiringItem.freshnessStatus, FreshnessStatus.expiringSoon);
    });

    test('freshnessStatus returns expired for past dates', () {
      final expiredItem = item.copyWith(
        expiryDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(expiredItem.freshnessStatus, FreshnessStatus.expired);
    });

    test('freshnessStatus returns fresh when no expiry set', () {
      final noExpiryItem = FridgeItem(
        id: 'test_002',
        name: 'No Expiry',
        category: FridgeCategory.other,
        addedDate: DateTime.now(),
      );
      expect(noExpiryItem.freshnessStatus, FreshnessStatus.fresh);
    });

    test('expiryDisplayText shows correct text', () {
      final now = DateTime.now();
      // Start of today to avoid Duration edge cases
      final startOfToday = DateTime(now.year, now.month, now.day);

      final today = item.copyWith(expiryDate: startOfToday);
      expect(today.expiryDisplayText, contains('today'));

      // Use a date that's guaranteed to be 1 full day ahead
      final tomorrowDate = DateTime(
        now.year,
        now.month,
        now.day + 1,
        now.hour + 1,
      );
      final tomorrow = item.copyWith(expiryDate: tomorrowDate);
      expect(tomorrow.expiryDisplayText, contains('tomorrow'));

      final fiveDaysDate = DateTime(
        now.year,
        now.month,
        now.day + 5,
        now.hour + 1,
      );
      final fiveDays = item.copyWith(expiryDate: fiveDaysDate);
      expect(fiveDays.expiryDisplayText, contains('days left'));

      final expired = item.copyWith(
        expiryDate: DateTime.now().subtract(const Duration(days: 3)),
      );
      expect(expired.expiryDisplayText, contains('Expired'));
    });

    test('amountDisplay formats correctly', () {
      expect(item.amountDisplay, '1 gal');

      final gramsItem = item.copyWith(amount: 250, unit: FridgeUnit.grams);
      expect(gramsItem.amountDisplay, '250 g');
    });

    test('amountInMetric converts gallons to ml', () {
      final metric = item.amountInMetric;
      expect(metric, isNotNull);
      expect(metric!, closeTo(3785.41, 1));
    });

    test('amountInImperial converts grams to oz', () {
      final gramsItem = item.copyWith(amount: 100, unit: FridgeUnit.grams);
      final imperial = gramsItem.amountInImperial;
      expect(imperial, isNotNull);
      expect(imperial!, closeTo(3.527, 0.01));
    });

    test('copyWith preserves unchanged fields', () {
      final copy = item.copyWith(name: 'Updated Name');
      expect(copy.name, 'Updated Name');
      expect(copy.id, item.id);
      expect(copy.category, item.category);
      expect(copy.amount, item.amount);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // FridgeCategory
  // ═══════════════════════════════════════════════════════════════════

  group('FridgeCategory', () {
    test('has 9 categories (no leftover)', () {
      expect(FridgeCategory.values.length, 9);
    });

    test('label and emoji are non-empty for all categories', () {
      for (final cat in FridgeCategory.values) {
        expect(cat.label.isNotEmpty, true);
        expect(cat.emoji.isNotEmpty, true);
        expect(cat.displayName.contains(cat.label), true);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Receipt & ReceiptItem
  // ═══════════════════════════════════════════════════════════════════

  group('Receipt', () {
    late Receipt receipt;

    setUp(() {
      receipt = Receipt(
        id: 'r_001',
        storeName: 'Test Store',
        scanDate: DateTime(2024, 1, 15, 10, 30),
        subtotal: 20.0,
        tax: 2.0,
        total: 22.0,
        items: [
          const ReceiptItem(
            id: 'ri_1',
            name: 'Milk',
            quantity: 1,
            unitPrice: 4.50,
            totalPrice: 4.50,
            isVerified: true,
            matchedFridgeItemId: 'item_010',
          ),
          const ReceiptItem(
            id: 'ri_2',
            name: 'Eggs',
            quantity: 1,
            unitPrice: 5.29,
            totalPrice: 5.29,
            isVerified: false,
          ),
          const ReceiptItem(
            id: 'ri_3',
            name: 'Unknown',
            quantity: 1,
            unitPrice: 0.0,
            totalPrice: 0.0,
            isUnknown: true,
          ),
        ],
      );
    });

    test('toMap and fromMap round-trip', () {
      final map = receipt.toMap();
      final restored = Receipt.fromMap(map);

      expect(restored.id, receipt.id);
      expect(restored.storeName, receipt.storeName);
      expect(restored.items.length, 3);
      expect(restored.total, 22.0);
    });

    test('verifiedItems returns only verified', () {
      expect(receipt.verifiedItems.length, 1);
      expect(receipt.verifiedItems.first.name, 'Milk');
    });

    test('unmatchedItems returns items without fridge match', () {
      expect(receipt.unmatchedItems.length, 2); // Eggs + Unknown
    });

    test('unknownItems returns only unknown', () {
      expect(receipt.unknownItems.length, 1);
      expect(receipt.unknownItems.first.name, 'Unknown');
    });

    test('recognizedCount excludes unknown items', () {
      expect(receipt.recognizedCount, 2);
    });

    test('ReceiptItem.isMatched works', () {
      expect(receipt.items[0].isMatched, true);
      expect(receipt.items[1].isMatched, false);
    });

    test('ReceiptItem copyWith preserves fields', () {
      final copy = receipt.items[1].copyWith(isVerified: true);
      expect(copy.isVerified, true);
      expect(copy.name, 'Eggs');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Recipe
  // ═══════════════════════════════════════════════════════════════════

  group('Recipe', () {
    test('hasAllIngredients when no missing', () {
      const recipe = Recipe(
        id: 'rec_1',
        title: 'Salad',
        ingredients: ['lettuce', 'tomato', 'cucumber'],
        missingIngredients: [],
      );
      expect(recipe.hasAllIngredients, true);
      expect(recipe.matchPercentage, 1.0);
    });

    test('matchPercentage calculated correctly', () {
      const recipe = Recipe(
        id: 'rec_2',
        title: 'Pasta',
        ingredients: ['pasta', 'sauce', 'cheese', 'basil'],
        missingIngredients: ['basil'],
      );
      expect(recipe.hasAllIngredients, false);
      expect(recipe.matchPercentage, 0.75);
    });

    test('toMap and fromMap round-trip', () {
      const recipe = Recipe(
        id: 'rec_3',
        title: 'Smoothie',
        description: 'Berry smoothie',
        rating: 4.5,
        prepTime: '5 min',
        calories: '180 kcal',
        type: 'Drink',
        ingredients: ['berries', 'yogurt', 'banana'],
        missingIngredients: ['banana'],
      );

      final map = recipe.toMap();
      final restored = Recipe.fromMap(map);

      expect(restored.title, 'Smoothie');
      expect(restored.rating, 4.5);
      expect(restored.ingredients.length, 3);
      expect(restored.missingIngredients.length, 1);
    });
  });
}
