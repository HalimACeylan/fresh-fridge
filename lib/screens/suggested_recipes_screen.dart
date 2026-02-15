import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';
import 'package:fridge_app/widgets/fridge_header.dart';

class SuggestedRecipesScreen extends StatelessWidget {
  const SuggestedRecipesScreen({super.key});

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
                _buildHeader(),
                _buildFilters(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    children: [
                      _buildRecipeCard(
                        context,
                        title: 'Fresh Basil Pesto Pasta',
                        description:
                            'A quick and aromatic pasta dish utilizing that fresh basil sitting in your crisper drawer. Perfect for a light dinner.',
                        imagePath: 'assets/images/pesto_pasta.png',
                        rating: 4.8,
                        time: '15 min',
                        kcal: '420 kcal',
                        type: 'Italian',
                        missingItems: [],
                      ),
                      const SizedBox(height: 24),
                      _buildRecipeCard(
                        context,
                        title: 'Spicy Chicken Stir-fry',
                        description: '',
                        imagePath: 'assets/images/chicken_stir_fry.png',
                        rating: 4.5,
                        time: '30 min',
                        kcal: '550 kcal',
                        type: '',
                        missingItems: ['Soy Sauce'],
                      ),
                      const SizedBox(height: 24),
                      _buildCompactRecipeCard(
                        context,
                        title: 'Avocado & Kale Salad',
                        subtitle: 'Use up: 2 Avocados, Kale',
                        imagePath: 'assets/images/avocado_salad.png',
                        time: '10 min',
                        missingItems: ['Dressing'],
                      ),
                      const SizedBox(height: 24),
                      _buildRecipeCard(
                        context,
                        title: 'Homemade Flatbread Pizza',
                        description: '',
                        imagePath: 'assets/images/pizza.png',
                        rating: 4.9,
                        time: '25 min',
                        kcal: '600 kcal',
                        type: '',
                        missingItems: [],
                      ),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Showing top matches for your inventory.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    ],
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
            Positioned(
              bottom: 90,
              right: 24,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.fridgeGrid);
                },
                backgroundColor: Colors
                    .black, // Different accent here based on HTML? HTML has black bg for FAB on screen 3
                child: const Icon(Icons.add, color: Color(0xFF13EC13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FridgeHeader(
      superTitle: 'BASED ON YOUR FRIDGE',
      title: 'Suggested Recipes',
      trailing: Stack(
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

  Widget _buildRecipeCard(
    BuildContext context, {
    required String title,
    required String description,
    required String imagePath,
    required double rating,
    required String time,
    required String kcal,
    required String type,
    required List<String> missingItems,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.recipePreparation);
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
                Image.asset(
                  imagePath,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
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
                      color: missingItems.isEmpty
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
                          missingItems.isEmpty
                              ? Icons.check_circle
                              : Icons.warning,
                          size: 16,
                          color: missingItems.isEmpty
                              ? Colors.black
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          missingItems.isEmpty
                              ? 'You have all ingredients'
                              : 'Missing ${missingItems.length} item: ${missingItems.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: missingItems.isEmpty
                                ? Colors.black
                                : Colors.grey[700],
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
                          title,
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
                            '$rating',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildIconText(Icons.schedule, time),
                      const SizedBox(width: 24),
                      if (kcal.isNotEmpty) ...[
                        _buildIconText(Icons.local_fire_department, kcal),
                        const SizedBox(width: 24),
                      ],
                      if (type.isNotEmpty)
                        _buildIconText(Icons.restaurant_menu, type),
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

  Widget _buildCompactRecipeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String imagePath,
    required String time,
    required List<String> missingItems,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.recipePreparation);
      },
      child: Container(
        height: 140,
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
        child: Row(
          children: [
            Image.asset(imagePath, width: 140, height: 140, fit: BoxFit.cover),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Missing ${missingItems[0]}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          time,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
