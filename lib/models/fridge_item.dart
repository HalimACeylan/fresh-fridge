import 'package:fridge_app/models/units.dart';

/// Categories for fridge items — aligned with what can be scanned from receipts.
enum FridgeCategory {
  produce,
  dairy,
  meat,
  beverages,
  condiments,
  grains,
  frozen,
  snacks,
  other;

  String get label {
    switch (this) {
      case FridgeCategory.produce:
        return 'Produce';
      case FridgeCategory.dairy:
        return 'Dairy';
      case FridgeCategory.meat:
        return 'Meat & Seafood';
      case FridgeCategory.beverages:
        return 'Beverages';
      case FridgeCategory.condiments:
        return 'Condiments';
      case FridgeCategory.grains:
        return 'Grains & Bakery';
      case FridgeCategory.frozen:
        return 'Frozen';
      case FridgeCategory.snacks:
        return 'Snacks';
      case FridgeCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FridgeCategory.produce:
        return '🥕';
      case FridgeCategory.dairy:
        return '🥛';
      case FridgeCategory.meat:
        return '🥩';
      case FridgeCategory.beverages:
        return '🥤';
      case FridgeCategory.condiments:
        return '🫙';
      case FridgeCategory.grains:
        return '🌾';
      case FridgeCategory.frozen:
        return '❄️';
      case FridgeCategory.snacks:
        return '🍿';
      case FridgeCategory.other:
        return '📦';
    }
  }

  String get displayName => '$emoji $label';
}

/// Freshness status computed from the expiry date.
enum FreshnessStatus {
  fresh,
  useSoon,
  expiringSoon,
  expired;

  String get label {
    switch (this) {
      case FreshnessStatus.fresh:
        return 'Fresh';
      case FreshnessStatus.useSoon:
        return 'Use Soon';
      case FreshnessStatus.expiringSoon:
        return 'Expiring Soon';
      case FreshnessStatus.expired:
        return 'Expired';
    }
  }
}

/// Core domain model representing an item stored in the fridge.
///
/// Price is intentionally omitted — spending data will be derived from
/// linked receipts via [receiptId] in the future.
///
/// [amount] + [unit] represent quantity using the standardized unit system:
///   - Weight: grams (g) / ounces (oz)
///   - Volume: milliliters (ml) / gallons (gal)
///   - Countable: pieces (pcs)
class FridgeItem {
  final String id;
  final String name;
  final FridgeCategory category;
  final double amount;
  final FridgeUnit unit;
  final DateTime? expiryDate;
  final DateTime addedDate;
  final String? imageUrl;
  final String? notes;
  final String? receiptId;
  final String householdId;

  const FridgeItem({
    required this.id,
    required this.name,
    required this.category,
    this.amount = 1,
    this.unit = FridgeUnit.pieces,
    this.expiryDate,
    required this.addedDate,
    this.imageUrl,
    this.notes,
    this.receiptId,
    this.householdId = 'default',
  });

  // ── Computed properties ──────────────────────────────────────────

  /// Days remaining until expiry. Null if no expiry set.
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// Freshness derived from days until expiry.
  FreshnessStatus get freshnessStatus {
    final days = daysUntilExpiry;
    if (days == null) return FreshnessStatus.fresh;
    if (days < 0) return FreshnessStatus.expired;
    if (days <= 2) return FreshnessStatus.expiringSoon;
    if (days <= 7) return FreshnessStatus.useSoon;
    return FreshnessStatus.fresh;
  }

  /// Human-readable expiry string for the UI.
  String get expiryDisplayText {
    final days = daysUntilExpiry;
    if (days == null) return 'No expiry';
    if (days < 0) return 'Expired ${-days} day${-days == 1 ? '' : 's'} ago';
    if (days == 0) return 'Expires today';
    if (days == 1) return 'Expires tomorrow';
    return '$days days left';
  }

  /// Formatted amount with unit (e.g. "250 g", "1 gal", "3 pcs").
  String get amountDisplay => UnitConverter.format(amount, unit);

  /// Amount converted to metric base unit (grams or ml).
  /// Returns null for pieces.
  double? get amountInMetric => UnitConverter.toMetric(amount, unit);

  /// Amount converted to imperial unit (oz or gal).
  /// Returns null for pieces.
  double? get amountInImperial => UnitConverter.toImperial(amount, unit);

  // ── Serialization (Firebase-ready) ───────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'amount': amount,
      'unit': unit.name,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'addedDate': addedDate.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'notes': notes,
      'receiptId': receiptId,
      'householdId': householdId,
    };
  }

  factory FridgeItem.fromMap(Map<String, dynamic> map) {
    return FridgeItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: FridgeCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => FridgeCategory.other,
      ),
      amount: (map['amount'] as num?)?.toDouble() ?? 1,
      unit: FridgeUnit.values.firstWhere(
        (u) => u.name == map['unit'],
        orElse: () => FridgeUnit.pieces,
      ),
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] as int)
          : null,
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['addedDate'] as int),
      imageUrl: map['imageUrl'] as String?,
      notes: map['notes'] as String?,
      receiptId: map['receiptId'] as String?,
      householdId: map['householdId'] as String? ?? 'default',
    );
  }

  // ── Copy helper ──────────────────────────────────────────────────

  FridgeItem copyWith({
    String? id,
    String? name,
    FridgeCategory? category,
    double? amount,
    FridgeUnit? unit,
    DateTime? expiryDate,
    DateTime? addedDate,
    String? imageUrl,
    String? notes,
    String? receiptId,
    String? householdId,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      addedDate: addedDate ?? this.addedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      receiptId: receiptId ?? this.receiptId,
      householdId: householdId ?? this.householdId,
    );
  }

  @override
  String toString() =>
      'FridgeItem(id: $id, name: $name, ${amountDisplay}, category: ${category.label})';
}
