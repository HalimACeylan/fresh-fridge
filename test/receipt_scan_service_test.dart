import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/services/receipt_scan_service.dart';
import 'helpers/test_seeder.dart';

void main() {
  group('ReceiptScanService Parsing Accuracy', () {
    setUp(() async {
      // Need service initialized to inject householdId properly
      await TestSeeder.seedAndInjectAll();
    });

    test(
      'parseRecognizedText identifies subtotal and exact items without calling OCR',
      () {
        const mockOcrText = '''
My Fake Store
Whole Milk 4.50
Apples 2 x 1.50
Subtotal 7.50
Tax 0.50
Total 8.00
      ''';

        print(
          '🔥 [Firestore Implementation Details] -> ReceiptScanService OCR parse logic:',
        );
        print('  - Scanning raw text locally to generate Receipt object.');

        final receipt = ReceiptScanService.instance.parseRecognizedText(
          rawText: mockOcrText,
        );
        expect(receipt.storeName, 'My Fake Store');
        expect(receipt.subtotal, 7.50);
        expect(receipt.total, 8.00);

        final milk = receipt.items.firstWhere((i) => i.name == 'Whole Milk');
        expect(milk.totalPrice, 4.50);

        final apples = receipt.items.firstWhere((i) => i.name == 'Apples');
        expect(apples.quantity, 2);
        expect(apples.totalPrice, 3.00);
      },
    );
  });
}
