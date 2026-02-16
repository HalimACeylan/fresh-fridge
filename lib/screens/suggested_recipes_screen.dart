import 'package:flutter/material.dart';
import 'package:fridge_app/models/recipe.dart'; // Import Recipe model
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/recipe_service.dart'; // Import RecipeService
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';
import 'package:fridge_app/widgets/fridge_header.dart';

class SuggestedRecipesScreen extends StatefulWidget {
  const SuggestedRecipesScreen({super.key});

  @override
  State<SuggestedRecipesScreen> createState() => _SuggestedRecipesScreenState();
}

class _SuggestedRecipesScreenState extends State<SuggestedRecipesScreen> {
  late List<Recipe> _recipes;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    setState(() {
      _recipes = RecipeService.instance.getSuggestedRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                _buildFilters(),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: _recipes.length + 1, // +1 for footer text
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      if (index == _recipes.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Showing top matches for your inventory.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      final recipe = _recipes[index];
                      return _buildRecipeCard(context, recipe);
                    },
                  ),
                ),
              ],
            ),
            // Bottom Nav and FAB
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FridgeHeader(
      superTitle: 'BASED ON YOUR FRIDGE',
      title: 'Suggested Recipes',
      trailing: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.fridgeGrid);
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.kitchen_outlined, color: Colors.grey),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC13),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All Matches', true),
          const SizedBox(width: 12),
          _buildFilterChip('Under 30 min', false),
          const SizedBox(width: 12),
          _buildFilterChip('Vegetarian', false),
          const SizedBox(width: 12),
          _buildFilterChip('Asian', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF13EC13) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF13EC13) : Colors.grey[200]!,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF13EC13).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.grey[600],
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.recipePreparation,
          arguments: recipe, // Pass recipe object
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (recipe.imageUrl != null &&
                    recipe.imageUrl!.startsWith('http'))
                  Image.network(
                    recipe.imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                else if (recipe.imageUrl != null)
                  Image.asset(
                    recipe.imageUrl!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bookmark_border,
                      color: Color(0xFF13EC13),
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: recipe.missingIngredients.isEmpty
                          ? const Color(0xFF13EC13)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          recipe.missingIngredients.isEmpty
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color: recipe.missingIngredients.isEmpty
                              ? Colors.black
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            recipe.missingIngredients.isEmpty
                                ? 'You have all ingredients'
                                : 'Missing ${recipe.missingIngredients.length} item: ${recipe.missingIngredients.join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: recipe.missingIngredients.isEmpty
                                  ? Colors.black
                                  : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${recipe.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      recipe.description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildIconText(Icons.schedule, recipe.prepTime),
                      const SizedBox(width: 24),
                      if (recipe.calories.isNotEmpty) ...[
                        _buildIconText(
                          Icons.local_fire_department,
                          recipe.calories,
                        ),
                        const SizedBox(width: 24),
                      ],
                      if (recipe.type.isNotEmpty)
                        _buildIconText(Icons.restaurant_menu, recipe.type),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF13EC13),
        ), // Using primary color for icons as per HTML
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return const FridgeBottomNavigation(currentTab: FridgeTab.cook);
  }
}
