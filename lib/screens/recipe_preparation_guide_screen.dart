import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';

class RecipePreparationGuideScreen extends StatelessWidget {
  const RecipePreparationGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          // Custom Scroll View for Header and Content
          CustomScrollView(
            slivers: [
              // Hero Header
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.transparent,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDEZ9BG0PoFgOCOOvHCcEQalnxwd9oPMILGyry_3HggvsmxwD0zOrSeBJ_aiw4PA1TBaiTf0aP7drfBV0RXKAvqUKIc5H_HtJz3XBgGvugISglFqG4JUcPjEQuVXR1DAVExUwoQG13HoxXmMHNfqyetXRSqBeSt02NmN7lpJyMCwsDm2REK6L0Q7Kpk21mYUWO1wUFbOWM8RU5ZjZ5BdOGfmUxJ-qvGW-BYfOdkdysSTInL_Z_q5xJJQCSC8QbLFcKC4YfmgTzl-tVS',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 40, // Space for overlap
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF13EC13),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'VEGETARIAN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Creamy Basil Pesto Pasta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                _HeaderInfoItem(
                                  icon: Icons.schedule,
                                  text: '25 min',
                                ),
                                SizedBox(width: 16),
                                _HeaderInfoItem(
                                  icon: Icons.restaurant,
                                  text: '4 Servings',
                                ),
                                SizedBox(width: 16),
                                _HeaderInfoItem(
                                  icon: Icons.local_fire_department,
                                  text: '420 kcal',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F8F6),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(
                    0,
                    -20,
                    0,
                  ), // Overlap effect
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ingredients Section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Ingredients',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF13EC13,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      '5/7 In Fridge',
                                      style: TextStyle(
                                        color: Color(0xFF102210),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const _IngredientItem(
                                name: 'Fresh Basil',
                                amount: '2 cups, packed',
                                inFridge: true,
                              ),
                              const SizedBox(height: 12),
                              const _IngredientItem(
                                name: 'Parmesan Cheese',
                                amount: '1/2 cup, grated',
                                inFridge: true,
                              ),
                              const SizedBox(height: 12),
                              const _IngredientItem(
                                name: 'Pine Nuts',
                                amount: '1/3 cup',
                                inFridge: false,
                              ),
                              const SizedBox(height: 12),
                              const _IngredientItem(
                                name: 'Garlic Cloves',
                                amount: '3 large cloves',
                                inFridge: true,
                              ),
                              const SizedBox(height: 12),
                              const _IngredientItem(
                                name: 'Extra Virgin Olive Oil',
                                amount: '1/2 cup',
                                inFridge: false,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.insideFridge,
                                    );
                                  },
                                  icon: const Text('View Full Inventory'),
                                  label: const Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF102210),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Instructions Section
                        const Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _InstructionStep(
                          stepNumber: 1,
                          title: 'Toast the nuts',
                          description:
                              'In a small skillet over medium-low heat, toast the pine nuts, stirring often, until fragrant and golden, about 3 to 5 minutes. Watch carefully so they don\'t burn.',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuCAalnXGC0OWdAThN8GDvz_vgIhgPcQDu4ik0hheIJNZ4WZMY2cHi79JYS5lRIn5sQq6pmSemf9iasEjr7qc5VZm3oMOFvg7NyBHhAuP4OXNEZe9YBzx-j2MG12XViLP7WNROCYny7RW21NWztR1gGJClAvZH9woQYj_8ojBnzA3ZHXUyD6LOHNimDpUCLht6Feb7CZ9SIWYT9ci5MOkLVqNOPuMIq1tDtEOTHYUqdL46fqfd34I7Yyxd0zRB77E8_4qjH98e61yZBG',
                        ),
                        const _InstructionStep(
                          stepNumber: 2,
                          title: 'Blend ingredients',
                          description:
                              'Combine basil, garlic, and cooled pine nuts in a food processor. Pulse a few times until coarsely chopped.',
                          imageUrl:
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuAnDt84rtHEOSWF9ZG8IQ8BAijqrzEiAkSzuGwMhgAuBITyQFhDQgJ1FT6ZRLd8p_a1ntid_uhrsW2arhlbXkSvd8vIlXqhgupDnp_amh2lNvTxHroMJ2JAX0xccJqHZ8WRSAjOd3uTkNWOY-_PLGNA-7RR85YNkaXzM1wBIWdtrTwseqBp1u5uphVImHnScdtvT7oMpyPOV2UCAoKTN7kIyfjLHj4L6TJKYU5RzlSK54RVI3H3yvMjxB3x1ulmcEvyo5aC1RPddDlo',
                        ),
                        const _InstructionStep(
                          stepNumber: 3,
                          title: 'Add oil and cheese',
                          description:
                              'With the motor running, slowly stream in the olive oil. Add the parmesan cheese and pulse just until combined. Season with salt and pepper to taste.',
                          isLast: true,
                        ),
                        const SizedBox(
                          height: 100,
                        ), // Space for floating footer
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Sticky Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 40,
                bottom: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC13),
                  foregroundColor: const Color(0xFF102210),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFF13EC13).withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled),
                    const SizedBox(width: 8),
                    const Text(
                      'Start Cooking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '25:00',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeaderInfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF13EC13), size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IngredientItem extends StatelessWidget {
  final String name;
  final String amount;
  final bool inFridge;

  const _IngredientItem({
    required this.name,
    required this.amount,
    required this.inFridge,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: inFridge ? 1.0 : 0.75,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: inFridge
                  ? const Color(0xFF13EC13).withOpacity(0.2)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              inFridge ? Icons.check : Icons.shopping_cart,
              size: 16,
              color: inFridge ? const Color(0xFF102210) : Colors.grey[400],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  amount,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (inFridge)
            const Text(
              'In Fridge',
              style: TextStyle(
                color: Color(0xFF102210),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Need to Buy',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isLast;

  const _InstructionStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.imageUrl,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isLast ? Colors.white : Colors.black,
                  border: isLast
                      ? Border.all(color: Colors.grey[300]!, width: 2)
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      color: isLast ? Colors.grey[500] : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey[200],
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
