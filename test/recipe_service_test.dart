import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_app/services/recipe_service.dart';
import 'package:fridge_app/services/fridge_service.dart';
import 'helpers/test_seeder.dart';

void main() {
  group('RecipeService with Fake Firebase', () {
    late RecipeService service;

    setUp(() async {
      final mocks = await TestSeeder.seedAndInjectAll();
      await TestSeeder.seedFridgeItems(mocks.firestore);

      service = RecipeService.instance;
      // FridgeService needs initialization so RecipeService can match ingredients
      await FridgeService.instance.initialize(
        seedCloudIfEmpty: false,
        forceReseed: false,
      );
    });

    test(
      'getSuggestedRecipes calculates missing ingredients based on FridgeService',
      () {
        // RecipeService has 'Fresh Basil Pesto Pasta' and 'Avocado & Kale Salad' hardcoded
        // TestSeeder adds 'Seed Milk' and 'Seed Spinach' to the fridge.

        print(
          '🔥 [Firestore Implementation Details] -> RecipeService Matches Ingredients:',
        );
        print(
          '  - The Fridge has: \${FridgeService.instance.getAllItems().map((i) => i.name).toList()}',
        );

        final suggested = service.getSuggestedRecipes();
        expect(suggested, isNotEmpty);

        final salad = suggested.firstWhere(
          (r) => r.id == 'recipe_003',
        ); // Avocado & Kale Salad

        // We don't have Avocado or Kale in the seeded fridge, so they should be missing
        expect(
          salad.missingIngredients.any((i) => i.toLowerCase().contains('kale')),
          isTrue,
        );
        expect(
          salad.missingIngredients.any(
            (i) => i.toLowerCase().contains('avocado'),
          ),
          isTrue,
        );
      },
    );
  });
}
