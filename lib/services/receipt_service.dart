import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/models/units.dart';
import 'package:fridge_app/services/fridge_service.dart';

/// In-memory receipt service with item-to-fridge matching.
///
/// When switching to Firebase, replace in-memory state with Firestore
/// reads/writes and move matching logic to a Cloud Function if needed.
class ReceiptService {
  // Singleton
  ReceiptService._();
  static final ReceiptService instance = ReceiptService._();
  static const String _householdId = 'default';
  static const String _rootCollection = 'households';

  FirebaseFirestore? _firestore;
  bool _firebaseEnabled = false;
  bool _isInitialized = false;

  // ── Known category mappings ──────────────────────────────────────
  // Maps common receipt keywords → fridge categories for auto-suggestion.
  // IMPORTANT: Multi-word keywords must come FIRST so they match before
  // a single-word substring does (e.g. "ice cream" before "cream",
  // "orange juice" before "orange").
  static final Map<String, FridgeCategory> _categoryKeywords = {
    // Multi-word (checked first)
    'ice cream': FridgeCategory.frozen,
    'hot sauce': FridgeCategory.condiments,
    'orange juice': FridgeCategory.beverages,
    'soy sauce': FridgeCategory.condiments,

    // Produce
    'spinach': FridgeCategory.produce,
    'avocado': FridgeCategory.produce,
    'kale': FridgeCategory.produce,
    'tomato': FridgeCategory.produce,
    'lettuce': FridgeCategory.produce,
    'pepper': FridgeCategory.produce,
    'onion': FridgeCategory.produce,
    'garlic': FridgeCategory.produce,
    'potato': FridgeCategory.produce,
    'carrot': FridgeCategory.produce,
    'broccoli': FridgeCategory.produce,
    'cucumber': FridgeCategory.produce,
    'apple': FridgeCategory.produce,
    'banana': FridgeCategory.produce,
    'orange': FridgeCategory.produce,
    'lemon': FridgeCategory.produce,
    'berry': FridgeCategory.produce,
    'basil': FridgeCategory.produce,
    'herb': FridgeCategory.produce,
    'veggie': FridgeCategory.produce,
    'salad': FridgeCategory.produce,
    'mushroom': FridgeCategory.produce,

    // Dairy
    'milk': FridgeCategory.dairy,
    'cheese': FridgeCategory.dairy,
    'yogurt': FridgeCategory.dairy,
    'butter': FridgeCategory.dairy,
    'cream': FridgeCategory.dairy,
    'egg': FridgeCategory.dairy,

    // Meat & Seafood
    'chicken': FridgeCategory.meat,
    'beef': FridgeCategory.meat,
    'pork': FridgeCategory.meat,
    'salmon': FridgeCategory.meat,
    'fish': FridgeCategory.meat,
    'shrimp': FridgeCategory.meat,
    'turkey': FridgeCategory.meat,
    'sausage': FridgeCategory.meat,
    'bacon': FridgeCategory.meat,
    'steak': FridgeCategory.meat,
    'lamb': FridgeCategory.meat,

    // Beverages
    'juice': FridgeCategory.beverages,
    'water': FridgeCategory.beverages,
    'soda': FridgeCategory.beverages,
    'coffee': FridgeCategory.beverages,
    'tea': FridgeCategory.beverages,
    'kombucha': FridgeCategory.beverages,

    // Condiments
    'sauce': FridgeCategory.condiments,
    'ketchup': FridgeCategory.condiments,
    'mustard': FridgeCategory.condiments,
    'dressing': FridgeCategory.condiments,
    'mayo': FridgeCategory.condiments,
    'pesto': FridgeCategory.condiments,
    'vinegar': FridgeCategory.condiments,
    'soy': FridgeCategory.condiments,

    // Grains & Bakery
    'bread': FridgeCategory.grains,
    'pasta': FridgeCategory.grains,
    'rice': FridgeCategory.grains,
    'tortilla': FridgeCategory.grains,
    'bagel': FridgeCategory.grains,
    'cereal': FridgeCategory.grains,
    'oat': FridgeCategory.grains,
    'flour': FridgeCategory.grains,

    // Frozen
    'frozen': FridgeCategory.frozen,
    'pizza': FridgeCategory.frozen,

    // Snacks
    'chip': FridgeCategory.snacks,
    'cracker': FridgeCategory.snacks,
    'hummus': FridgeCategory.snacks,
    'nut': FridgeCategory.snacks,
    'granola': FridgeCategory.snacks,
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

  CollectionReference<Map<String, dynamic>> get _receiptsCollection =>
      _firestore!
          .collection(_rootCollection)
          .doc(_householdId)
          .collection('receipts');

  Future<void> initialize({bool seedCloudIfEmpty = true}) async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Firebase.apps.isEmpty) return;

    try {
      _firestore = FirebaseFirestore.instance;
      _firebaseEnabled = true;
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
        await _seedCloudFromLocal();
      }
      return;
    }

    final cloudReceipts = query.docs.map((doc) {
      final data = _normalizeReceiptMap(doc.data(), doc.id);
      return Receipt.fromMap(data);
    }).toList();

    _receipts
      ..clear()
      ..addAll(cloudReceipts);
  }

  Future<void> _seedCloudFromLocal() async {
    final batch = _firestore!.batch();
    for (final receipt in _receipts) {
      batch.set(_receiptsCollection.doc(receipt.id), receipt.toMap());
    }
    await batch.commit();
  }

  // ── Read operations ──────────────────────────────────────────────

  /// All stored receipts.
  List<Receipt> getAllReceipts() => List.unmodifiable(_receipts);

  /// Get a single receipt by ID.
  Receipt? getReceiptById(String id) {
    try {
      return _receipts.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get receipts for a specific household.
  List<Receipt> getReceiptsByHousehold(String householdId) =>
      _receipts.where((r) => r.householdId == householdId).toList();

  // ── Write operations ─────────────────────────────────────────────

  /// Add a new receipt.
  void addReceipt(Receipt receipt) {
    final index = _receipts.indexWhere((existing) => existing.id == receipt.id);
    if (index == -1) {
      _receipts.add(receipt);
    } else {
      _receipts[index] = receipt;
    }

    if (_firebaseEnabled) {
      unawaited(_upsertReceipt(receipt));
    }
  }

  /// Update a receipt (e.g., after verifying / editing items).
  void updateReceipt(Receipt updated) {
    final index = _receipts.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _receipts[index] = updated;
    }

    if (_firebaseEnabled) {
      unawaited(_upsertReceipt(updated));
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
      if (item.isUnknown || item.isMatched) continue;

      final category = item.suggestedCategory ?? suggestCategory(item.name);

      final fridgeItem = FridgeItem(
        id: 'auto_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        name: item.name,
        category: category,
        amount: item.quantity.toDouble(),
        unit: FridgeUnit.pieces,
        expiryDate: _estimateExpiry(category),
        addedDate: DateTime.now(),
        receiptId: receiptId,
      );

      fridgeService.addItem(fridgeItem);
      newItems.add(fridgeItem);
    }

    return newItems;
  }

  // ── Private helpers ──────────────────────────────────────────────

  /// Estimate a default expiry based on category.
  DateTime _estimateExpiry(FridgeCategory category) {
    final now = DateTime.now();
    switch (category) {
      case FridgeCategory.produce:
        return now.add(const Duration(days: 5));
      case FridgeCategory.dairy:
        return now.add(const Duration(days: 7));
      case FridgeCategory.meat:
        return now.add(const Duration(days: 3));
      case FridgeCategory.beverages:
        return now.add(const Duration(days: 14));
      case FridgeCategory.condiments:
        return now.add(const Duration(days: 60));
      case FridgeCategory.grains:
        return now.add(const Duration(days: 14));
      case FridgeCategory.frozen:
        return now.add(const Duration(days: 90));
      case FridgeCategory.snacks:
        return now.add(const Duration(days: 14));
      case FridgeCategory.other:
        return now.add(const Duration(days: 7));
    }
  }

  /// Break a string into meaningful words (>2 chars) for matching.
  List<String> _extractWords(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }

  Future<void> _upsertReceipt(Receipt receipt) async {
    await _receiptsCollection.doc(receipt.id).set(receipt.toMap());
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
}
