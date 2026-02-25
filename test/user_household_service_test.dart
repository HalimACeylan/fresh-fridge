import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/services/user_household_service.dart';
import 'helpers/test_seeder.dart';

void main() {
  group('UserHouseholdService with Fake Firebase', () {
    late UserHouseholdService service;

    setUp(() async {
      await TestSeeder.seedAndInjectAll();
      service = UserHouseholdService.instance;
      await service.initialize();
    });

    test('initialize loads seeded user and household', () async {
      await service.initialize();
      expect(service.isAuthenticated, isTrue);
      expect(service.userId, TestSeeder.testUserId);
      expect(service.householdId, TestSeeder.testHouseholdId);
      expect(service.isOwner, isTrue);
    });

    test('readCurrentUserFromCloud returns expected user map', () async {
      print(
        '🔥 [Firestore Implementation Details] -> readCurrentUserFromCloud:',
      );
      print('  - Reading from path: users/\${TestSeeder.testUserId}');

      final userMap = await service.readCurrentUserFromCloud();
      expect(userMap, isNotNull);
      expect(userMap!['email'], TestSeeder.testUserEmail);
    });

    test(
      'readCurrentHouseholdFromCloud returns expected household map',
      () async {
        await service.initialize(); // Ensure householdId is populated

        print(
          '🔥 [Firestore Implementation Details] -> readCurrentHouseholdFromCloud:',
        );
        print(
          '  - Reading from path: households/\${TestSeeder.testHouseholdId}',
        );

        final householdMap = await service.readCurrentHouseholdFromCloud();
        expect(householdMap, isNotNull);
        expect(householdMap!['name'], 'Test Household');
      },
    );

    test('updateHouseholdMemberRole blocks non-admins', () async {
      // Create a scenario where the current user is NOT an admin/owner
      final nonAdminMocks = await TestSeeder.seedAndInjectAll();

      // We must initialize to set _householdId correctly
      await service.initialize();

      // Demote the test user to 'member' for this test specifically
      await nonAdminMocks.firestore
          .collection('households')
          .doc(TestSeeder.testHouseholdId)
          .collection('members')
          .doc(TestSeeder.testUserId)
          .update({'role': 'member'});

      // Re-initialize to pick up the new role
      await service.refreshCurrentMemberRoleFromCloud();

      expect(service.isOwner, isFalse);
      expect(service.isAdmin, isFalse);

      print(
        '🔥 [Firestore Implementation Details] -> Security Rule Validation: updateHouseholdMemberRole',
      );
      print('  - Attempting role update as a basic member (should fail).');

      expect(
        () => service.updateHouseholdMemberRole(
          memberUserId: 'some_other_user',
          role: 'admin',
        ),
        throwsStateError,
      );
    });
  });
}
