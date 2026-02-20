import 'package:fridge_app/models/fridge_item.dart';

/// A single line-item parsed from a scanned receipt.
class ReceiptItem {
  final String id;
  final String name;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isVerified;
  final bool isUnknown;
  final bool isFrozen;

  /// ID of the fridge item this receipt item was matched to (if any).
  final String? matchedFridgeItemId;

  /// Category suggestion based on OCR + heuristics.
  final FridgeCategory? suggestedCategory;

  const ReceiptItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    required this.unitPrice,
    required this.totalPrice,
    this.isVerified = false,
    this.isUnknown = false,
    this.isFrozen = false,
    this.matchedFridgeItemId,
    this.suggestedCategory,
  });

  // ── Computed ─────────────────────────────────────────────────────

  /// Whether this item has been matched to a fridge item.
  bool get isMatched => matchedFridgeItemId != null;

  // ── Serialization ────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'isVerified': isVerified,
      'isUnknown': isUnknown,
      'isFrozen': isFrozen,
      'matchedFridgeItemId': matchedFridgeItemId,
      'suggestedCategory': suggestedCategory?.name,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      totalPrice: (map['totalPrice'] as num).toDouble(),
      isVerified: map['isVerified'] as bool? ?? false,
      isUnknown: map['isUnknown'] as bool? ?? false,
      isFrozen: map['isFrozen'] as bool? ?? false,
      matchedFridgeItemId: map['matchedFridgeItemId'] as String?,
      suggestedCategory: map['suggestedCategory'] != null
          ? FridgeCategory.values.firstWhere(
              (c) => c.name == map['suggestedCategory'],
              orElse: () => FridgeCategory.other,
            )
          : null,
    );
  }

  ReceiptItem copyWith({
    String? id,
    String? name,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    bool? isVerified,
    bool? isUnknown,
    bool? isFrozen,
    String? matchedFridgeItemId,
    FridgeCategory? suggestedCategory,
  }) {
    return ReceiptItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      isVerified: isVerified ?? this.isVerified,
      isUnknown: isUnknown ?? this.isUnknown,
      isFrozen: isFrozen ?? this.isFrozen,
      matchedFridgeItemId: matchedFridgeItemId ?? this.matchedFridgeItemId,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
    );
  }

  @override
  String toString() =>
      'ReceiptItem(id: $id, name: $name, qty: $quantity, total: \$$totalPrice)';
}

/// A scanned receipt containing line-items and totals.
class Receipt {
  final String id;
  final String storeName;
  final DateTime scanDate;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String? imageUrl;
  final String householdId;

  const Receipt({
    required this.id,
    required this.storeName,
    required this.scanDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.imageUrl,
    this.householdId = 'default',
  });

  // ── Computed ─────────────────────────────────────────────────────

  /// Items the user has verified as correct.
  List<ReceiptItem> get verifiedItems =>
      items.where((item) => item.isVerified).toList();

  /// Items not yet matched to fridge inventory.
  List<ReceiptItem> get unmatchedItems =>
      items.where((item) => !item.isMatched).toList();

  /// Items flagged as unknown / unrecognized by OCR.
  List<ReceiptItem> get unknownItems =>
      items.where((item) => item.isUnknown).toList();

  /// Number of items successfully recognized.
  int get recognizedCount => items.where((item) => !item.isUnknown).length;

  // ── Serialization ────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
      'scanDate': scanDate.millisecondsSinceEpoch,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'imageUrl': imageUrl,
      'householdId': householdId,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'] as String,
      storeName: map['storeName'] as String,
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scanDate'] as int),
      items: (map['items'] as List)
          .map((item) => ReceiptItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      imageUrl: map['imageUrl'] as String?,
      householdId: map['householdId'] as String? ?? 'default',
    );
  }

  Receipt copyWith({
    String? id,
    String? storeName,
    DateTime? scanDate,
    List<ReceiptItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? imageUrl,
    String? householdId,
  }) {
    return Receipt(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      scanDate: scanDate ?? this.scanDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
      householdId: householdId ?? this.householdId,
    );
  }

  @override
  String toString() =>
      'Receipt(id: $id, store: $storeName, items: ${items.length}, total: \$$total)';
}
