import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/units.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'helpers/test_seeder.dart';

void main() {
  group('FridgeService with Fake Firebase', () {
    late FridgeService service;

    setUp(() async {
      // 1. Seed Firebase and Inject
      final mocks = await TestSeeder.seedAndInjectAll();

      service = FridgeService.instance;
      // We must clear the local cache explicitly before re-initializing
      await service.clearCloudForActiveHousehold(clearLocalCache: true);

      await TestSeeder.seedFridgeItems(mocks.firestore);
      await service.initialize(seedCloudIfEmpty: false, forceReseed: false);
      await service
          .refreshFromCloud(); // Force load seeded items into local cache
    });

    test('getAllItems returns seeded data', () {
      final items = service.getAllItems();
      expect(items, isNotEmpty);
      expect(items.length, 2);
      expect(items.any((i) => i.name == 'Seed Milk'), isTrue);
    });

    test('addItem creates new item in Fake Firestore and local cache', () async {
      final newItem = FridgeItem(
        id: 'test_add_001',
        name: 'Test Apples',
        category: FridgeCategory.produce,
        amount: 5,
        unit: FridgeUnit.pieces,
        addedDate: DateTime.now(),
      );

      print('🔥 [Firestore Implementation Details] -> addItem:');
      print(
        '  - Writing to path: households/\${TestSeeder.testHouseholdId}/fridge_items/test_add_001',
      );
      print('  - Data: \${newItem.toMap()}');

      service.addItem(newItem);

      // Verify Local
      final localFetch = service.getItemById('test_add_001');
      expect(localFetch, isNotNull);
      expect(localFetch!.name, 'Test Apples');

      // Verify Cloud (wait for async write)
      await Future.delayed(
        const Duration(milliseconds: 100),
      ); // Allow async upsert to resolve
      final cloudItems = await service.readAllFromCloud(refreshCache: false);
      expect(cloudItems.any((i) => i.id == 'test_add_001'), isTrue);
    });

    test('updateItem modifies data', () async {
      final item = service.getItemById('seed_item_1')!;
      final updated = item.copyWith(notes: 'Updated note via test');

      print('🔥 [Firestore Implementation Details] -> updateItem:');
      print(
        '  - Updating path: households/\${TestSeeder.testHouseholdId}/fridge_items/seed_item_1',
      );
      print('  - newData: \${updated.toMap()}');

      service.updateItem(updated);

      expect(
        service.getItemById('seed_item_1')!.notes,
        'Updated note via test',
      );
    });

    test('deleteItem removes item', () async {
      expect(service.getItemById('seed_item_1'), isNotNull);

      print('🔥 [Firestore Implementation Details] -> deleteItem:');
      print(
        '  - Deleting doc: households/\${TestSeeder.testHouseholdId}/fridge_items/seed_item_1',
      );

      service.deleteItem('seed_item_1');

      expect(service.getItemById('seed_item_1'), isNull);
    });

    test('getExpiringItems includes expired items from seeder', () {
      final expiring = service.getExpiringItems();
      expect(expiring, isNotEmpty);
      expect(
        expiring.any((i) => i.name == 'Seed Spinach'),
        isTrue,
      ); // Seed Spinach is set to expired
    });
  });
}
