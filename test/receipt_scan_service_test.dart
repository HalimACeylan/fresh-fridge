import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/services/receipt_scan_service.dart';

void main() {
  group('ReceiptScanService.parseRecognizedText', () {
    test('parses store, items, and totals from receipt text', () {
      const rawText = '''
Whole Foods Market
Organic Baby Spinach 3.99
Whole Milk 4.50
Tax 0.68
Total 9.17
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.storeName, 'Whole Foods Market');
      expect(receipt.items.length, 2);
      expect(receipt.subtotal, closeTo(8.49, 0.001));
      expect(receipt.tax, closeTo(0.68, 0.001));
      expect(receipt.total, closeTo(9.17, 0.001));
      expect(
        receipt.items.any((item) => item.name.contains('Spinach')),
        isTrue,
      );
    });

    test('parses quantity x price line format', () {
      const rawText = '''
Test Store
Chicken Breast 2 x 5.00
Subtotal 10.00
Tax 0.80
Total 10.80
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.items.length, 1);
      expect(receipt.items.first.quantity, 2);
      expect(receipt.items.first.unitPrice, closeTo(5.00, 0.001));
      expect(receipt.items.first.totalPrice, closeTo(10.00, 0.001));
      expect(receipt.total, closeTo(10.80, 0.001));
    });

    test('adds unknown fallback item when no line items are detected', () {
      const rawText = '''
My Store
Thank you for shopping
Date 10/20/2025
Total 20.50
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.items.length, 1);
      expect(receipt.items.first.isUnknown, isTrue);
      expect(receipt.total, closeTo(20.50, 0.001));
    });
  });
}
