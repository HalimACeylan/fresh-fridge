import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';

class FoodItemDetailsScreen extends StatelessWidget {
  const FoodItemDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          // Hero Image Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC8JZQC4bB6CVudTjhTYvb9T1pCj_ZfEwGFO2gRSwsGPkGY668jjC8yr43-8T258hCLkrxJb7jpjaLS_8qk_T-wzgvPVxIPqXNrWEN8PR10QTJzCRco0tLw2T-OmWl-IH9-LsnGkdQgSVqD_Yy5FyHFnJO_3PalKKq1UgsKbzEKMggFOITiG9uO3MEwN94TVnJGO2NarkTrsddkLzvPLjWj2ERK2hQ2MljhWpBPPWG6uNH00hkRiNw6Feqe_6I6T5ufsSFLk9Awdr64',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Header Navigation
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBlurButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        _buildBlurButton(icon: Icons.edit, onTap: () {}),
                        const SizedBox(width: 8),
                        _buildBlurButton(
                          icon: Icons.delete_outline,
                          color: Colors.red[300],
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Hero Content (Title & Stock)
          Positioned(
            top: 180,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Organic Avocados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13EC13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'In Stock: 3',
                        style: TextStyle(
                          color: Color(0xFF102210),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Produce • Purchased Oct 24',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Main Content Scrollable Area
          Positioned.fill(
            top: 260,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Freshness Status Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Freshness',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Expires in 4 days',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: 0.7,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF13EC13),
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Good',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Use Soon',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Expired',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF13EC13,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Added 2 days ago',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      text: 'via ',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Carrefour Receipt',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        TextSpan(text: ' scan'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nutritional Info
                    const Text(
                      'NUTRITION (PER 100G)',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildNutrientCard('Cals', '160'),
                        const SizedBox(width: 8),
                        _buildNutrientCard('Fat', '15g'),
                        const SizedBox(width: 8),
                        _buildNutrientCard('Carbs', '9g'),
                        const SizedBox(width: 8),
                        _buildNutrientCard('Prot', '2g'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Linked Source
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'LINKED SOURCE',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.recentScanResults,
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF13EC13),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Receipt #4022',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Carrefour Market • Oct 24, 2023',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Recipe Suggestions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Use it up!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.suggestedRecipes,
                            );
                          },
                          child: const Row(
                            children: [
                              Text(
                                'Search all recipes',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Recipes with Avocados',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      clipBehavior: Clip.none,
                      child: Row(
                        children: [
                          _buildRecipeCard(
                            context,
                            'Classic Avocado Toast',
                            '4.8 (120 reviews)',
                            '10m',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuAlOrhDFsRSJdzo4Zx8Broi2qW3JKx79TKcuKpNhkiwyRB7l3nOqODUxfCkQgGPEidlUNQ9Xqn_K8C8xd_7JfGO6sVGPA5aEpXDxIq_iLsEHpY2nJurLZAyolK30rL95KqCoaf9M3gFTk9CSlnO141ugrS1ylKBa7SXPvXBFnN74n16zJMYbLWTeZO5JxZ-5UU5cH6MY_AmV5L5PQ8X-Kw8HyYX59a8t7GNBTGFgcUc1s54ydmnKNlsFIAMKCahdfo_qPBDD6Qk7YJZ',
                          ),
                          const SizedBox(width: 16),
                          _buildRecipeCard(
                            context,
                            'Spicy Guacamole',
                            '4.9 (85 reviews)',
                            '15m',
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuClWTrhsvkT6ccRnbNV8ZZJUjdKqFuYZi5zFqJ3ImK-KayJHP6aRZQvKSX36huGRi8lpzCE5JlqeE53buIH4S67pNtb1MGDvMiZ_9jI2aOrqAQvOjLbaeT4KCxV7kGDLk9UE_YsQqnzXKSuhHxK7cg8xknh8DbXNF5TYe1ywxFcy0-DVJUfcMGGM6lBFdzu61tAHX68NKRRo8aLoV-AYB4OGnye6UQXz9Wh7p6Lz8jxNtaxnF8yNs7PHytka66Sc0lpLPaTF-WtQsWa',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Floating Action Button
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: () {},
              backgroundColor: const Color(0xFF102210),
              child: const Icon(Icons.shopping_basket, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.white),
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(
    BuildContext context,
    String title,
    String rating,
    String time,
    String imageUrl,
  ) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFF13EC13), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.recipePreparation);
                  },
                  icon: const Icon(Icons.restaurant_menu, size: 16),
                  label: const Text('Cook Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF13EC13),
                    foregroundColor: const Color(0xFF102210),
                    minimumSize: const Size(double.infinity, 36),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
