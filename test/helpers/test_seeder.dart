import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fridge_app/models/fridge_item.dart';
import 'package:fridge_app/models/units.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'package:fridge_app/services/receipt_service.dart';
import 'package:fridge_app/services/recipe_service.dart';
import 'package:fridge_app/services/user_household_service.dart';

/// Seeder utility to populate Fake Firebase instances with standardized test data,
/// fulfilling `.clinerules` requirement #6 (Include Seeding Elements).
class TestSeeder {
  static const String testUserId = 'test_user_123';
  static const String testHouseholdId = 'test_household_456';
  static const String testUserEmail = 'test@example.com';

  /// Creates and seeds fake auth and firestore instances, injects them into
  /// the services, and returns them for use in tests.
  static Future<({MockFirebaseAuth auth, FakeFirebaseFirestore firestore})>
  seedAndInjectAll() async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: testUserId,
        email: testUserEmail,
        displayName: 'Test User',
      ),
      signedIn: true,
    );
    final firestore = FakeFirebaseFirestore();

    // 1. Seed Household & User Data (to satisfy Zero Trust / Least Privilege requirements)
    await firestore.collection('users').doc(testUserId).set({
      'uid': testUserId,
      'email': testUserEmail,
      'primaryHouseholdId': testHouseholdId,
      'role': 'owner',
    });

    await firestore.collection('households').doc(testHouseholdId).set({
      'id': testHouseholdId,
      'name': 'Test Household',
      'ownerUserId': testUserId,
      'inviteCode': 'TST-1234',
    });

    await firestore
        .collection('households')
        .doc(testHouseholdId)
        .collection('members')
        .doc(testUserId)
        .set({'userId': testUserId, 'role': 'owner', 'status': 'active'});

    // 2. Inject into Services
    UserHouseholdService.instance.setAuthAndFirestoreForTesting(
      auth: auth,
      firestore: firestore,
      testUserId: testUserId,
      testHouseholdId: testHouseholdId,
    );
    FridgeService.instance.setFirestoreForTesting(firestore);
    ReceiptService.instance.setFirestoreForTesting(firestore);
    RecipeService.instance.setFirestoreForTesting(firestore);

    print('🌱 [TestSeeder] DB Seeded and Services Injected');
    print('  - User: $testUserId');
    print('  - Household: $testHouseholdId');

    return (auth: auth, firestore: firestore);
  }

  /// Seeds a few standard fridge items to the fake database.
  static Future<void> seedFridgeItems(FakeFirebaseFirestore firestore) async {
    final fridgeRef = firestore
        .collection('households')
        .doc(testHouseholdId)
        .collection('fridge_items');

    final items = [
      FridgeItem(
        id: 'seed_item_1',
        name: 'Seed Milk',
        category: FridgeCategory.dairy,
        amount: 1,
        unit: FridgeUnit.gallons,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        addedDate: DateTime.now(),
        householdId: testHouseholdId,
      ),
      FridgeItem(
        id: 'seed_item_2',
        name: 'Seed Spinach',
        category: FridgeCategory.produce,
        amount: 200,
        unit: FridgeUnit.grams,
        expiryDate: DateTime.now().subtract(const Duration(days: 1)), // Expired
        addedDate: DateTime.now().subtract(const Duration(days: 7)),
        householdId: testHouseholdId,
      ),
    ];

    for (final item in items) {
      final map = item.toMap();
      map['nameLower'] = item.name.toLowerCase();
      await fridgeRef.doc(item.id).set(map);
    }
    await FridgeService.instance.refreshFromCloud();

    print('🌱 [TestSeeder] Seeded ${items.length} fridge items.');
  }
}
