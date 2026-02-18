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

    test('parses weighted produce receipt format with repeated subtotals', () {
      const rawText = '''
DATE 06/01/2016 WED
ZUCCHINI GREEN                 \$4.66
0.778kg NET @ \$5.99/kg
BANANA CAVENDISH               \$1.32
0.442kg NET @ \$2.99/kg
SPECIAL                        \$0.99
SPECIAL                        \$1.50
POTATOES BRUSHED               \$3.97
1.328kg NET @ \$2.99/kg
BROCCOLI                       \$4.84
0.808kg NET @ \$5.99/kg
BRUSSEL SPROUTS                \$5.15
0.322kg NET @ \$15.99/kg
SPECIAL                        \$0.99
GRAPES GREEN                   \$7.03
1.174kg NET @ \$5.99/kg
PEAS SNOW                      \$3.27
0.218kg NET @ \$14.99/kg
TOMATOES GRAPE                 \$2.99
LETTUCE ICEBERG                \$2.49
SUBTOTAL                      \$39.20
LOYALTY                      -15.00
SUBTOTAL                      \$24.20
TOTAL                         \$24.20
CASH                          \$50.00
CHANGE                        \$25.80
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.items.length, greaterThanOrEqualTo(10));
      expect(
        receipt.items.any((item) => item.name.contains('ZUCCHINI')),
        isTrue,
      );
      expect(
        receipt.items.any((item) => item.name.contains('BROCCOLI')),
        isTrue,
      );
      expect(
        receipt.items.any((item) => item.name.contains('LETTUCE')),
        isTrue,
      );
      expect(receipt.subtotal, closeTo(24.20, 0.001));
      expect(receipt.total, closeTo(24.20, 0.001));
      expect(receipt.tax, closeTo(0, 0.001));
    });

    test('parses item name followed by standalone amount on next line', () {
      const rawText = '''
Local Market
ORGANIC STRAWBERRIES
\$4.75
TOTAL \$4.75
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.items.length, 1);
      expect(receipt.items.first.name, 'ORGANIC STRAWBERRIES');
      expect(receipt.items.first.totalPrice, closeTo(4.75, 0.001));
      expect(receipt.total, closeTo(4.75, 0.001));
    });

    test('pairs multiple name-only lines with later standalone prices', () {
      const rawText = '''
DATE 06/01/2016 WED
ZUCCHINI GREEN
BANANA CAVENDISH
POTATOES BRUSHED
BROCCOLI
\$4.66
\$1.32
\$3.97
\$4.84
TOTAL \$14.79
''';

      final receipt = ReceiptScanService.instance.parseRecognizedText(
        rawText: rawText,
      );

      expect(receipt.items.length, 4);
      expect(receipt.items[0].name, 'ZUCCHINI GREEN');
      expect(receipt.items[0].totalPrice, closeTo(4.66, 0.001));
      expect(receipt.items[1].name, 'BANANA CAVENDISH');
      expect(receipt.items[1].totalPrice, closeTo(1.32, 0.001));
      expect(receipt.items[2].name, 'POTATOES BRUSHED');
      expect(receipt.items[2].totalPrice, closeTo(3.97, 0.001));
      expect(receipt.items[3].name, 'BROCCOLI');
      expect(receipt.items[3].totalPrice, closeTo(4.84, 0.001));
      expect(receipt.total, closeTo(14.79, 0.001));
    });
  });
}
