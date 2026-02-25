import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/models/units.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/user_household_service.dart';

/// In-memory receipt service with item-to-fridge matching.
///
/// When switching to Firebase, replace in-memory state with Firestore
/// reads/writes and move matching logic to a Cloud Function if needed.
class ReceiptService {
  // Singleton
  ReceiptService._();
  static final ReceiptService instance = ReceiptService._();
  static const String _rootCollection = 'households';
  static const String _storeNameLowerField = 'storeNameLower';

  FirebaseFirestore? _firestore;
  bool _firebaseEnabled = false;
  bool _isInitialized = false;

  @visibleForTesting
  void setFirestoreForTesting(FirebaseFirestore firestore) {
    _firestore = firestore;
    _firebaseEnabled = true;
    _isInitialized = true;
  }

  // ── Known category mappings ──────────────────────────────────────
  // Maps common receipt keywords → fridge categories for auto-suggestion.
  // IMPORTANT: Multi-word keywords must come FIRST so they match before
  // a single-word substring does (e.g. "ice cream" before "cream",
  // "orange juice" before "orange").
  static final Map<String, FridgeCategory> _categoryKeywords = {
    // Multi-word (checked first)
    'ice cream': FridgeCategory.iceCream,
    'hot dog': FridgeCategory.hotDog,
    'hot sauce': FridgeCategory.sauce,
    'orange juice': FridgeCategory.juice,
    'soy sauce': FridgeCategory.sauce,
    'frozen pizza': FridgeCategory.frozenPizza,
    'sweet potato': FridgeCategory.sweetPotato,
    'leafy green': FridgeCategory.leafyGreen,

    // Produce -> Specifics
    'apple': FridgeCategory.apple,
    'pear': FridgeCategory.pear,
    'orange': FridgeCategory.orange,
    'lemon': FridgeCategory.lemon,
    'banana': FridgeCategory.banana,
    'watermelon': FridgeCategory.watermelon,
    'grape': FridgeCategory.grapes,
    'strawberry': FridgeCategory.strawberry,
    'blueberry': FridgeCategory.blueberry,
    'melon': FridgeCategory.melon,
    'cherry': FridgeCategory.cherry,
    'peach': FridgeCategory.peach,
    'mango': FridgeCategory.mango,
    'pineapple': FridgeCategory.pineapple,
    'coconut': FridgeCategory.coconut,
    'kiwi': FridgeCategory.kiwi,
    'avocado': FridgeCategory.avocado,
    'tomato': FridgeCategory.tomato,
    'potato': FridgeCategory.potato,
    'carrot': FridgeCategory.carrot,
    'corn': FridgeCategory.corn,
    'pepper': FridgeCategory.bellPepper,
    'cucumber': FridgeCategory.cucumber,
    'broccoli': FridgeCategory.broccoli,
    'garlic': FridgeCategory.garlic,
    'onion': FridgeCategory.onion,
    'mushroom': FridgeCategory.mushroom,
    'eggplant': FridgeCategory.eggplant,
    'spinach': FridgeCategory.leafyGreen,
    'kale': FridgeCategory.leafyGreen,
    'lettuce': FridgeCategory.leafyGreen,
    'basil': FridgeCategory.leafyGreen,
    'herb': FridgeCategory.leafyGreen,
    'salad': FridgeCategory.vegetables,
    'veggie': FridgeCategory.vegetables,
    'fruit': FridgeCategory.fruits,
    'produce': FridgeCategory.produce,

    // Dairy & Eggs
    'milk': FridgeCategory.milk,
    'cheese': FridgeCategory.cheese,
    'butter': FridgeCategory.butter,
    'egg': FridgeCategory.egg,
    'yogurt': FridgeCategory.dairy,
    'cream': FridgeCategory.dairy,
    'dairy': FridgeCategory.dairy,

    // Meat & Seafood
    'poultry': FridgeCategory.poultry,
    'chicken': FridgeCategory.poultry,
    'turkey': FridgeCategory.poultry,
    'beef': FridgeCategory.beef,
    'steak': FridgeCategory.beef,
    'pork': FridgeCategory.meat,
    'bacon': FridgeCategory.bacon,
    'sausage': FridgeCategory.hotDog,
    'fish': FridgeCategory.fish,
    'salmon': FridgeCategory.fish,
    'shrimp': FridgeCategory.shrimp,
    'squid': FridgeCategory.squid,
    'lobster': FridgeCategory.lobster,
    'crab': FridgeCategory.crab,
    'oyster': FridgeCategory.oyster,
    'lamb': FridgeCategory.meat,
    'meat': FridgeCategory.meat,

    // Grains & Bakery
    'bread': FridgeCategory.bread,
    'croissant': FridgeCategory.croissant,
    'baguette': FridgeCategory.baguette,
    'flatbread': FridgeCategory.flatbread,
    'tortilla': FridgeCategory.flatbread,
    'pretzel': FridgeCategory.pretzel,
    'bagel': FridgeCategory.bagel,
    'pancake': FridgeCategory.pancakes,
    'waffle': FridgeCategory.waffle,
    'rice': FridgeCategory.rice,
    'pasta': FridgeCategory.pasta,
    'cereal': FridgeCategory.grains,
    'oat': FridgeCategory.grains,
    'flour': FridgeCategory.grains,
    'grains': FridgeCategory.grains,

    // Prepared Foods & Fast Food
    'pizza': FridgeCategory.pizza,
    'hamburger': FridgeCategory.hamburger,
    'burger': FridgeCategory.hamburger,
    'fries': FridgeCategory.fries,
    'sandwich': FridgeCategory.sandwich,
    'taco': FridgeCategory.taco,
    'burrito': FridgeCategory.burrito,
    'sushi': FridgeCategory.sushi,
    'bento': FridgeCategory.bento,
    'curry': FridgeCategory.curry,
    'stew': FridgeCategory.stew,
    'soup': FridgeCategory.stew,
    'dumpling': FridgeCategory.dumpling,

    // Condiments & Cooking
    'salt': FridgeCategory.salt,
    'sauce': FridgeCategory.sauce,
    'ketchup': FridgeCategory.sauce,
    'mustard': FridgeCategory.sauce,
    'dressing': FridgeCategory.sauce,
    'mayo': FridgeCategory.sauce,
    'pesto': FridgeCategory.sauce,
    'honey': FridgeCategory.honey,
    'vinegar': FridgeCategory.condiments,
    'soy': FridgeCategory.sauce,
    'condiment': FridgeCategory.condiments,

    // Snacks & Sweets
    'snack': FridgeCategory.snacks,
    'popcorn': FridgeCategory.popcorn,
    'chip': FridgeCategory.chips,
    'cracker': FridgeCategory.snacks,
    'cookie': FridgeCategory.cookie,
    'chocolate': FridgeCategory.chocolate,
    'candy': FridgeCategory.candy,
    'lollipop': FridgeCategory.lollipop,
    'cake': FridgeCategory.cake,
    'pie': FridgeCategory.pie,
    'hummus': FridgeCategory.snacks,
    'nut': FridgeCategory.snacks,
    'granola': FridgeCategory.snacks,

    // Beverages
    'water': FridgeCategory.water,
    'juice': FridgeCategory.juice,
    'soda': FridgeCategory.soda,
    'pop': FridgeCategory.soda,
    'tea': FridgeCategory.tea,
    'coffee': FridgeCategory.coffee,
    'beer': FridgeCategory.beer,
    'wine': FridgeCategory.wine,
    'liquor': FridgeCategory.liquor,
    'kombucha': FridgeCategory.beverages,
    'beverage': FridgeCategory.beverages,

    // Frozen
    'frozen': FridgeCategory.frozen,
    'ice': FridgeCategory.iceCube,

    // Catch-all
    'other': FridgeCategory.other,
  };

  // ── Sample data ──────────────────────────────────────────────────

  final List<Receipt> _receipts = [
    Receipt(
      id: 'receipt_001',
      storeName: 'Whole Foods Market',
      scanDate: DateTime(2023, 10, 24, 10, 43),
      subtotal: 17.77,
      tax: 1.42,
      total: 19.19,
      items: [
        ReceiptItem(
          id: 'ri_001',
          name: 'Whole Milk (1 Gal)',
          quantity: 1,
          unitPrice: 4.50,
          totalPrice: 4.50,
          isVerified: true,
          suggestedCategory: FridgeCategory.dairy,
          matchedFridgeItemId: 'item_010',
        ),
        ReceiptItem(
          id: 'ri_002',
          name: 'Organic Baby Spinach',
          quantity: 2,
          unitPrice: 3.99,
          totalPrice: 7.98,
          isVerified: true,
          suggestedCategory: FridgeCategory.produce,
          matchedFridgeItemId: 'item_001',
        ),
        ReceiptItem(
          id: 'ri_003',
          name: 'Large Brown Eggs (12ct)',
          quantity: 1,
          unitPrice: 5.29,
          totalPrice: 5.29,
          isVerified: true,
          suggestedCategory: FridgeCategory.dairy,
          matchedFridgeItemId: 'item_013',
        ),
        const ReceiptItem(
          id: 'ri_004',
          name: 'Unknown Item',
          quantity: 1,
          unitPrice: 0.0,
          totalPrice: 0.0,
          isUnknown: true,
        ),
      ],
    ),
  ];

  String get _activeHouseholdId => UserHouseholdService.instance.householdId;

  CollectionReference<Map<String, dynamic>> get _receiptsCollection =>
      _firestore!
          .collection(_rootCollection)
          .doc(_activeHouseholdId)
          .collection('receipts');

  Future<void> initialize({
    bool seedCloudIfEmpty = true,
    bool forceReseed = false,
  }) async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Firebase.apps.isEmpty) return;

    try {
      _firestore = FirebaseFirestore.instance;
      _firebaseEnabled = true;
      if (forceReseed) {
        await _seedCloudFromLocal(overwrite: true);
      }
      await _syncFromCloud(seedCloudIfEmpty: seedCloudIfEmpty);
    } catch (_) {
      _firebaseEnabled = false;
      _firestore = null;
    }
  }

  Future<void> refreshFromCloud() async {
    if (!_firebaseEnabled) return;
    await _syncFromCloud(seedCloudIfEmpty: false);
  }

  Future<void> _syncFromCloud({required bool seedCloudIfEmpty}) async {
    final query = await _receiptsCollection.get();

    if (query.docs.isEmpty) {
      if (seedCloudIfEmpty) {
        await _seedCloudFromLocal(overwrite: false);
      }
      return;
    }

    final cloudReceipts = _parseCloudSnapshot(query.docs)
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));

    _receipts
      ..clear()
      ..addAll(cloudReceipts);
  }

  Future<void> seedCloudFromLocal({bool overwrite = false}) async {
    if (!_firebaseEnabled) return;
    await _seedCloudFromLocal(overwrite: overwrite);
    await _syncFromCloud(seedCloudIfEmpty: false);
  }

  /// Clears all receipts from the active household collection.
  Future<void> clearCloudForActiveHousehold({
    bool clearLocalCache = true,
  }) async {
    if (_firebaseEnabled) {
      final existingDocs = await _receiptsCollection.get();
      for (var i = 0; i < existingDocs.docs.length; i += 400) {
        final batch = _firestore!.batch();
        for (final doc in existingDocs.docs.skip(i).take(400)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    if (clearLocalCache) {
      _receipts.clear();
    }
  }

  Future<void> _seedCloudFromLocal({required bool overwrite}) async {
    if (!_firebaseEnabled) return;

    final batch = _firestore!.batch();
    if (overwrite) {
      final existingDocs = await _receiptsCollection.get();
      for (final doc in existingDocs.docs) {
        batch.delete(doc.reference);
      }
    }

    for (final receipt in _receipts) {
      batch.set(
        _receiptsCollection.doc(receipt.id),
        _toFirestoreMap(receipt, includeCreatedAt: true),
      );
    }
    await batch.commit();
  }

  // ── Read operations ──────────────────────────────────────────────

  /// All stored receipts.
  List<Receipt> getAllReceipts() => List.unmodifiable(_receipts);

  /// Read all receipts directly from Firestore.
  Future<List<Receipt>> readAllFromCloud({bool refreshCache = true}) async {
    if (!_firebaseEnabled) return getAllReceipts();

    final query = await _receiptsCollection.get();
    final receipts = _parseCloudSnapshot(query.docs)
      ..sort((a, b) => b.scanDate.compareTo(a.scanDate));

    if (refreshCache) {
      _receipts
        ..clear()
        ..addAll(receipts);
    }
    return receipts;
  }

  /// Get a single receipt by ID.
  Receipt? getReceiptById(String id) {
    try {
      return _receipts.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Read a single receipt directly from Firestore.
  Future<Receipt?> readReceiptByIdFromCloud(String id) async {
    if (!_firebaseEnabled) return getReceiptById(id);

    final doc = await _receiptsCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = _normalizeReceiptMap(doc.data()!, doc.id);
    return Receipt.fromMap(data);
  }

  /// Get receipts for a specific household.
  List<Receipt> getReceiptsByHousehold(String householdId) =>
      _receipts.where((r) => r.householdId == householdId).toList();

  /// Query receipts by store name from Firestore.
  Future<List<Receipt>> queryReceiptsByStoreFromCloud(
    String storeQuery, {
    int limit = 20,
  }) async {
    final normalizedQuery = storeQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty || !_firebaseEnabled) return getAllReceipts();

    try {
      final snapshot = await _receiptsCollection
          .orderBy(_storeNameLowerField)
          .startAt([normalizedQuery])
          .endAt(['$normalizedQuery\uf8ff'])
          .limit(limit)
          .get();
      return _parseCloudSnapshot(snapshot.docs);
    } catch (_) {
      await refreshFromCloud();
      return _receipts
          .where(
            (receipt) =>
                receipt.storeName.toLowerCase().contains(normalizedQuery),
          )
          .toList();
    }
  }

  // ── Write operations ─────────────────────────────────────────────

  /// Add a new receipt.
  void addReceipt(Receipt receipt) {
    final normalizedReceipt = _normalizeForActiveHousehold(receipt);
    final index = _receipts.indexWhere(
      (existing) => existing.id == normalizedReceipt.id,
    );

    final isNewReceipt = index == -1;
    if (index == -1) {
      _receipts.add(normalizedReceipt);
    } else {
      _receipts[index] = normalizedReceipt;
    }

    if (_firebaseEnabled) {
      unawaited(
        _upsertReceipt(normalizedReceipt, includeCreatedAt: isNewReceipt),
      );
    }
  }

  /// Update a receipt (e.g., after verifying / editing items).
  void updateReceipt(Receipt updated) {
    final normalizedReceipt = _normalizeForActiveHousehold(updated);
    final index = _receipts.indexWhere((r) => r.id == normalizedReceipt.id);
    if (index != -1) {
      _receipts[index] = normalizedReceipt;
    }

    if (_firebaseEnabled) {
      unawaited(_upsertReceipt(normalizedReceipt, includeCreatedAt: false));
    }
  }

  /// Delete a receipt.
  void deleteReceipt(String id) {
    final initialLength = _receipts.length;
    _receipts.removeWhere((r) => r.id == id);
    final removed = _receipts.length < initialLength;
    if (removed && _firebaseEnabled) {
      unawaited(_deleteReceiptFromCloud(id));
    }
  }

  // ── Matching logic ───────────────────────────────────────────────

  /// Suggest a [FridgeCategory] for a receipt item name based on keywords.
  FridgeCategory suggestCategory(String itemName) {
    final lower = itemName.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return FridgeCategory.other;
  }

  /// Attempt to match a receipt item to an existing fridge item
  /// using name-similarity heuristics.
  ///
  /// Returns the matching [FridgeItem] ID, or null if no match found.
  String? findFridgeMatch(String receiptItemName) {
    final lower = receiptItemName.toLowerCase();
    final fridgeItems = FridgeService.instance.getAllItems();

    // Exact substring match
    for (final item in fridgeItems) {
      final fridgeLower = item.name.toLowerCase();
      if (fridgeLower.contains(lower) || lower.contains(fridgeLower)) {
        return item.id;
      }
    }

    // Word-level overlap: find item with most matching words
    final receiptWords = _extractWords(lower);
    String? bestMatchId;
    int bestScore = 0;

    for (final item in fridgeItems) {
      final fridgeWords = _extractWords(item.name.toLowerCase());
      int score = 0;
      for (final word in receiptWords) {
        if (fridgeWords.any((fw) => fw.contains(word) || word.contains(fw))) {
          score++;
        }
      }
      if (score > bestScore && score >= 1) {
        bestScore = score;
        bestMatchId = item.id;
      }
    }

    return bestMatchId;
  }

  /// Auto-match all unmatched items in a receipt to fridge inventory.
  /// Returns the updated receipt with matches applied.
  Receipt matchReceiptToFridge(String receiptId) {
    final receipt = getReceiptById(receiptId);
    if (receipt == null) {
      return Receipt(
        id: '',
        storeName: '',
        scanDate: DateTime.now(),
        items: [],
        subtotal: 0,
        tax: 0,
        total: 0,
        householdId: _activeHouseholdId,
      );
    }

    final updatedItems = receipt.items.map((item) {
      if (item.isMatched || item.isUnknown) return item;

      final matchId = findFridgeMatch(item.name);
      final category = suggestCategory(item.name);

      return item.copyWith(
        matchedFridgeItemId: matchId,
        suggestedCategory: category,
      );
    }).toList();

    final updated = receipt.copyWith(items: updatedItems);
    updateReceipt(updated);
    return updated;
  }

  /// Convert verified receipt items into fridge items.
  /// Returns the list of newly created [FridgeItem]s.
  List<FridgeItem> addReceiptItemsToFridge(String receiptId) {
    final receipt = getReceiptById(receiptId);
    if (receipt == null) return [];

    final fridgeService = FridgeService.instance;
    final newItems = <FridgeItem>[];

    for (final item in receipt.items) {
      if (item.isUnknown) continue;

      final matchedItem = item.matchedFridgeItemId == null
          ? null
          : fridgeService.getItemById(item.matchedFridgeItemId!);
      final category =
          item.suggestedCategory ??
          matchedItem?.category ??
          suggestCategory(item.name);

      final fridgeItem = FridgeItem(
        id: 'auto_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        name: item.name,
        category: category,
        amount: item.quantity.toDouble(),
        unit: FridgeUnit.pieces,
        expiryDate: _estimateExpiry(category),
        addedDate: DateTime.now(),
        receiptId: receiptId,
        householdId: _activeHouseholdId,
        isFrozen: item.isFrozen,
      );

      fridgeService.addItem(fridgeItem);
      newItems.add(fridgeItem);
    }

    if (newItems.isNotEmpty) {
      final updatedItems = receipt.items.map((item) {
        if (item.isUnknown) return item;
        return item.copyWith(isVerified: true);
      }).toList();
      updateReceipt(receipt.copyWith(items: updatedItems));
    }

    return newItems;
  }

  // ── Private helpers ──────────────────────────────────────────────

  /// Estimate a default expiry based on category.
  DateTime _estimateExpiry(FridgeCategory category) {
    return DateTime.now().add(Duration(days: category.defaultExpiryDays));
  }

  /// Break a string into meaningful words (>2 chars) for matching.
  List<String> _extractWords(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }

  Future<void> _upsertReceipt(
    Receipt receipt, {
    required bool includeCreatedAt,
  }) async {
    await _receiptsCollection
        .doc(receipt.id)
        .set(
          _toFirestoreMap(receipt, includeCreatedAt: includeCreatedAt),
          SetOptions(merge: true),
        );
  }

  Future<void> _deleteReceiptFromCloud(String id) async {
    await _receiptsCollection.doc(id).delete();
  }

  Map<String, dynamic> _normalizeReceiptMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final normalized = Map<String, dynamic>.from(map);
    normalized['id'] = (normalized['id'] as String?) ?? docId;
    normalized['scanDate'] = _dateToEpochMillis(normalized['scanDate']);

    final rawItems = normalized['items'];
    if (rawItems is List) {
      normalized['items'] = rawItems.asMap().entries.map((entry) {
        final raw = entry.value;
        if (raw is! Map) {
          return <String, dynamic>{
            'id': '${docId}_item_${entry.key}',
            'name': 'Unknown Item',
            'quantity': 1,
            'unitPrice': 0.0,
            'totalPrice': 0.0,
            'isUnknown': true,
          };
        }

        final itemMap = Map<String, dynamic>.from(raw);
        itemMap['id'] =
            (itemMap['id'] as String?) ?? '${docId}_item_${entry.key}';
        itemMap['unitPrice'] = _toDouble(itemMap['unitPrice']);
        itemMap['totalPrice'] = _toDouble(itemMap['totalPrice']);
        return itemMap;
      }).toList();
    }

    normalized['subtotal'] = _toDouble(normalized['subtotal']);
    normalized['tax'] = _toDouble(normalized['tax']);
    normalized['total'] = _toDouble(normalized['total']);
    return normalized;
  }

  int _dateToEpochMillis(dynamic value) {
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  List<Receipt> _parseCloudSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) {
      final data = _normalizeReceiptMap(doc.data(), doc.id);
      return Receipt.fromMap(data);
    }).toList();
  }

  Receipt _normalizeForActiveHousehold(Receipt receipt) {
    final householdId = _activeHouseholdId;
    if (receipt.householdId == householdId) return receipt;
    return receipt.copyWith(householdId: householdId);
  }

  Map<String, dynamic> _toFirestoreMap(
    Receipt receipt, {
    required bool includeCreatedAt,
  }) {
    final normalizedReceipt = _normalizeForActiveHousehold(receipt);
    final map = normalizedReceipt.toMap();
    map[_storeNameLowerField] = normalizedReceipt.storeName.toLowerCase();
    map.addAll(
      UserHouseholdService.instance.buildAuditFields(
        includeCreatedAt: includeCreatedAt,
      ),
    );
    return map;
  }
}
