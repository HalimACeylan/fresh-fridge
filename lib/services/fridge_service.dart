import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/units.dart';

/// In-memory fridge service pre-populated with sample data.
///
/// Designed with the same interface that a Firebase-backed implementation
/// would expose, making migration straightforward:
///   - Replace the `_items` list with Firestore queries.
///   - Replace `addItem` / `updateItem` / `deleteItemById` with doc writes.
class FridgeService {
  // Singleton
  FridgeService._();
  static final FridgeService instance = FridgeService._();

  // ── Sample data ──────────────────────────────────────────────────

  final List<FridgeItem> _items = [
    // ── Produce ────────────────────────────────────────────────────
    FridgeItem(
      id: 'item_001',
      name: 'Fresh Spinach',
      category: FridgeCategory.produce,
      amount: 250,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 0)),
      addedDate: DateTime.now().subtract(const Duration(days: 3)),
      imageUrl: 'assets/images/spinach.png',
      notes: 'Packaged Bag',
    ),
    FridgeItem(
      id: 'item_002',
      name: 'Organic Avocados',
      category: FridgeCategory.produce,
      amount: 3,
      unit: FridgeUnit.pieces,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
      imageUrl: 'assets/images/avocado.png',
    ),
    FridgeItem(
      id: 'item_003',
      name: 'Mixed Veggies',
      category: FridgeCategory.produce,
      amount: 400,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FridgeItem(
      id: 'item_004',
      name: 'Kale',
      category: FridgeCategory.produce,
      amount: 1,
      unit: FridgeUnit.pieces,
      expiryDate: DateTime.now().add(const Duration(days: 4)),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
      notes: '1 bunch',
    ),
    FridgeItem(
      id: 'item_005',
      name: 'Fresh Basil',
      category: FridgeCategory.produce,
      amount: 30,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FridgeItem(
      id: 'item_006',
      name: 'Bell Peppers',
      category: FridgeCategory.produce,
      amount: 3,
      unit: FridgeUnit.pieces,
      expiryDate: DateTime.now().add(const Duration(days: 6)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
    FridgeItem(
      id: 'item_007',
      name: 'Cherry Tomatoes',
      category: FridgeCategory.produce,
      amount: 300,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 5)),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),

    // ── Dairy ──────────────────────────────────────────────────────
    FridgeItem(
      id: 'item_010',
      name: 'Whole Milk',
      category: FridgeCategory.dairy,
      amount: 1,
      unit: FridgeUnit.gallons,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
      addedDate: DateTime.now().subtract(const Duration(days: 5)),
      notes: 'Opened',
    ),
    FridgeItem(
      id: 'item_011',
      name: 'Greek Yogurt',
      category: FridgeCategory.dairy,
      amount: 500,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 10)),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
    ),
    FridgeItem(
      id: 'item_012',
      name: 'Cheddar Cheese',
      category: FridgeCategory.dairy,
      amount: 200,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 14)),
      addedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FridgeItem(
      id: 'item_013',
      name: 'Large Brown Eggs',
      category: FridgeCategory.dairy,
      amount: 12,
      unit: FridgeUnit.pieces,
      expiryDate: DateTime.now().add(const Duration(days: 12)),
      addedDate: DateTime.now().subtract(const Duration(days: 3)),
      notes: '12ct carton',
    ),

    // ── Meat & Seafood ─────────────────────────────────────────────
    FridgeItem(
      id: 'item_020',
      name: 'Salmon Fillet',
      category: FridgeCategory.meat,
      amount: 400,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 0)),
      addedDate: DateTime.now().subtract(const Duration(days: 2)),
      notes: 'Raw, 2 fillets',
    ),
    FridgeItem(
      id: 'item_021',
      name: 'Chicken Breast',
      category: FridgeCategory.meat,
      amount: 800,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 1)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
      notes: '4 pieces',
    ),

    // ── Beverages ──────────────────────────────────────────────────
    FridgeItem(
      id: 'item_030',
      name: 'Orange Juice',
      category: FridgeCategory.beverages,
      amount: 1000,
      unit: FridgeUnit.milliliters,
      expiryDate: DateTime.now().add(const Duration(days: 8)),
      addedDate: DateTime.now().subtract(const Duration(days: 4)),
    ),

    // ── Condiments ─────────────────────────────────────────────────
    FridgeItem(
      id: 'item_040',
      name: 'Soy Sauce',
      category: FridgeCategory.condiments,
      amount: 500,
      unit: FridgeUnit.milliliters,
      expiryDate: DateTime.now().add(const Duration(days: 90)),
      addedDate: DateTime.now().subtract(const Duration(days: 30)),
    ),
    FridgeItem(
      id: 'item_041',
      name: 'Pesto Sauce',
      category: FridgeCategory.condiments,
      amount: 200,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      addedDate: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // ── Grains & Bakery ────────────────────────────────────────────
    FridgeItem(
      id: 'item_050',
      name: 'Sourdough Bread',
      category: FridgeCategory.grains,
      amount: 1,
      unit: FridgeUnit.pieces,
      expiryDate: DateTime.now().add(const Duration(days: 3)),
      addedDate: DateTime.now().subtract(const Duration(days: 1)),
      notes: '1 loaf',
    ),
    FridgeItem(
      id: 'item_051',
      name: 'Pasta',
      category: FridgeCategory.grains,
      amount: 500,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 180)),
      addedDate: DateTime.now().subtract(const Duration(days: 10)),
      notes: '2 packs',
    ),

    // ── Frozen ─────────────────────────────────────────────────────
    FridgeItem(
      id: 'item_060',
      name: 'Frozen Berries',
      category: FridgeCategory.frozen,
      amount: 500,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 60)),
      addedDate: DateTime.now().subtract(const Duration(days: 7)),
    ),
    FridgeItem(
      id: 'item_061',
      name: 'Ice Cream',
      category: FridgeCategory.frozen,
      amount: 1000,
      unit: FridgeUnit.milliliters,
      expiryDate: DateTime.now().add(const Duration(days: 90)),
      addedDate: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // ── Snacks ─────────────────────────────────────────────────────
    FridgeItem(
      id: 'item_070',
      name: 'Hummus',
      category: FridgeCategory.snacks,
      amount: 250,
      unit: FridgeUnit.grams,
      expiryDate: DateTime.now().add(const Duration(days: 6)),
      addedDate: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // ── Read operations ──────────────────────────────────────────────

  /// All items in the fridge.
  List<FridgeItem> getAllItems() => List.unmodifiable(_items);

  /// Items filtered by category.
  List<FridgeItem> getItemsByCategory(FridgeCategory category) =>
      _items.where((item) => item.category == category).toList();

  /// Items expiring within 2 days (urgent).
  List<FridgeItem> getExpiringItems() => _items
      .where(
        (item) =>
            item.freshnessStatus == FreshnessStatus.expiringSoon ||
            item.freshnessStatus == FreshnessStatus.expired,
      )
      .toList();

  /// Items expiring within 3–7 days.
  List<FridgeItem> getUseSoonItems() => _items
      .where((item) => item.freshnessStatus == FreshnessStatus.useSoon)
      .toList();

  /// Fresh items (> 7 days until expiry).
  List<FridgeItem> getFreshItems() => _items
      .where((item) => item.freshnessStatus == FreshnessStatus.fresh)
      .toList();

  /// Get a single item by ID.
  FridgeItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Stats ────────────────────────────────────────────────────────

  /// Returns a map with counts for UI stat cards.
  Map<String, int> getStats() {
    return {
      'urgent': getExpiringItems().length,
      'useSoon': getUseSoonItems().length,
      'healthy': getFreshItems().length,
      'total': _items.length,
    };
  }

  /// Available categories that currently have items.
  List<FridgeCategory> getActiveCategories() {
    final categories = _items.map((item) => item.category).toSet().toList();
    categories.sort((a, b) => a.index.compareTo(b.index));
    return categories;
  }

  // ── Write operations ─────────────────────────────────────────────

  /// Add a new item to the fridge.
  void addItem(FridgeItem item) {
    _items.add(item);
  }

  /// Update an existing item.
  void updateItem(FridgeItem updated) {
    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index != -1) {
      _items[index] = updated;
    }
  }

  bool _deleteItemInternal(String id) {
    final initialLength = _items.length;
    _items.removeWhere((item) => item.id == id);
    return _items.length < initialLength;
  }

  /// Remove an item by ID.
  void deleteItem(String id) {
    _deleteItemInternal(id);
  }

  /// Async delete API kept intentionally for future Firebase writes.
  Future<bool> deleteItemById(String id) {
    return Future.value(_deleteItemInternal(id));
  }

  /// Search items by name (case-insensitive).
  List<FridgeItem> searchItems(String query) {
    if (query.isEmpty) return getAllItems();
    final lower = query.toLowerCase();
    return _items
        .where((item) => item.name.toLowerCase().contains(lower))
        .toList();
  }
}
