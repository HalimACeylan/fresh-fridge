import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/receipt.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/receipt_service.dart';
import 'helpers/test_seeder.dart';

void main() {
  group('ReceiptService with Fake Firebase', () {
    late ReceiptService service;

    setUp(() async {
      final mocks = await TestSeeder.seedAndInjectAll();
      await TestSeeder.seedFridgeItems(mocks.firestore);

      service = ReceiptService.instance;
      await service.initialize(seedCloudIfEmpty: false, forceReseed: false);
      await FridgeService.instance.initialize(
        seedCloudIfEmpty: false,
        forceReseed: false,
      );
    });

    test(
      'addReceipt creates new receipt in local cache and fake firestore',
      () async {
        final newReceipt = Receipt(
          id: 'test_receipt_001',
          storeName: 'Test Market',
          scanDate: DateTime.now(),
          subtotal: 10.0,
          tax: 1.0,
          total: 11.0,
          items: [
            ReceiptItem(
              id: 'ri_001',
              name: 'Test Milk',
              quantity: 1,
              unitPrice: 5.0,
              totalPrice: 5.0,
              isVerified: true,
              suggestedCategory: FridgeCategory.dairy,
            ),
          ],
        );

        print('🔥 [Firestore Implementation Details] -> addReceipt:');
        print(
          '  - Writing to path: households/\${TestSeeder.testHouseholdId}/receipts/test_receipt_001',
        );
        print('  - Data: \${newReceipt.toMap()}');

        service.addReceipt(newReceipt);

        final localFetch = service.getReceiptById('test_receipt_001');
        expect(localFetch, isNotNull);
        expect(localFetch!.storeName, 'Test Market');

        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Allow async upsert to resolve
        final cloudItems = await service.readAllFromCloud(refreshCache: false);
        expect(cloudItems.any((r) => r.id == 'test_receipt_001'), isTrue);
      },
    );

    test('addReceiptItemsToFridge adds items to FridgeService', () {
      final newReceipt = Receipt(
        id: 'test_receipt_002',
        storeName: 'Test Produce Market',
        scanDate: DateTime.now(),
        subtotal: 10.0,
        tax: 0.0,
        total: 10.0,
        items: [
          ReceiptItem(
            id: 'ri_001',
            name: 'Organic Kale',
            quantity: 1,
            unitPrice: 5.0,
            totalPrice: 5.0,
            isVerified: false,
            suggestedCategory: FridgeCategory.produce,
          ),
        ],
      );
      service.addReceipt(newReceipt);

      print(
        '🔥 [Firestore Implementation Details] -> addReceiptItemsToFridge:',
      );
      print(
        '  - Triggering FridgeService.addItem for \${newReceipt.items.length} items from Receipt: \${newReceipt.id}',
      );

      final newFridgeItems = service.addReceiptItemsToFridge(
        'test_receipt_002',
      );
      expect(newFridgeItems.length, 1);
      expect(newFridgeItems.first.name, 'Organic Kale');

      // Verify the item is in FridgeService local cache
      final fridgeItemFetch = FridgeService.instance
          .getAllItems()
          .where((i) => i.name == 'Organic Kale')
          .toList();
      expect(fridgeItemFetch, isNotEmpty);
    });

    test('findFridgeMatch matches receipt item to fridge item', () {
      // TestSeeder adds 'Seed Milk' to FridgeService
      final matchId = service.findFridgeMatch('Milk (Seed)');
      expect(matchId, isNotNull);
      expect(matchId, 'seed_item_1'); // The ID used in test_seeder.dart
    });
  });
}
