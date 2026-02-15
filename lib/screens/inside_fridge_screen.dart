import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';
import 'package:fridge_app/widgets/fridge_header.dart';

class InsideFridgeScreen extends StatelessWidget {
  const InsideFridgeScreen({super.key});

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
                _buildSearchBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    children: [
                      _buildStatsGrid(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Use Immediately',
                        'View all',
                        isUrgent: true,
                      ),
                      const SizedBox(height: 12),
                      _buildUrgentItem(
                        context,
                        icon: '🥬',
                        name: 'Fresh Spinach',
                        expiry: 'Exp. Today',
                        detail: 'Packaged Bag (250g)',
                        progress: 0.95,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      _buildUrgentItem(
                        context,
                        icon: '🥛',
                        name: 'Whole Milk',
                        expiry: 'Exp. 2 Days',
                        detail: 'Half Gallon',
                        progress: 0.8,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Dairy & Eggs',
                        '5 items',
                        isUrgent: false,
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: [
                          _buildGridItem(
                            context,
                            '🧀',
                            'Cheddar Block',
                            'Fresh (7 days)',
                            0.6,
                            const Color(0xFF13EC13),
                          ),
                          _buildGridItem(
                            context,
                            '🥚',
                            'Large Eggs',
                            '10 remaining',
                            0.85,
                            const Color(0xFF13EC13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Produce',
                        '8 items',
                        isUrgent: false,
                      ),
                      const SizedBox(height: 12),
                      _buildListItem(
                        context,
                        '🥕',
                        'Carrots',
                        'Bag of 6 • Added 3 days ago',
                        'Good',
                        0.7,
                        const Color(0xFF13EC13),
                      ),
                      const SizedBox(height: 12),
                      _buildListItem(
                        context,
                        '🥑',
                        'Avocados',
                        '2 pcs • Ripe',
                        'Use Soon',
                        0.4,
                        Colors.amber,
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
              bottom: 90, // Adjusted for bottom nav height
              right: 24,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.scanReceipt);
                },
                backgroundColor: const Color(0xFF13EC13),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return FridgeHeader(
      title: 'Inside My Fridge',
      subtitle: 'Inventory Management',
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TextField(
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.grey),
          hintText: 'Find ingredients...',
          border: InputBorder.none,
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF13EC13).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF13EC13), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildStatCard(
            color: Colors.red[50]!,
            borderColor: Colors.red[100]!,
            icon: Icons.warning,
            iconColor: Colors.red,
            badgeColor: Colors.red[100]!,
            badgeTextColor: Colors.red,
            badge: 'Urgent',
            count: '3',
            label: 'Expiring soon',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            color: Colors.amber[50]!,
            borderColor: Colors.amber[100]!,
            icon: Icons.schedule,
            iconColor: Colors.amber,
            badgeColor: Colors.amber[100]!,
            badgeTextColor: Colors.amber[800]!,
            badge: 'Use Soon',
            count: '5',
            label: 'Use this week',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            color: const Color(0xFF13EC13).withOpacity(0.1),
            borderColor: const Color(0xFF13EC13).withOpacity(0.2),
            icon: Icons.inventory_2,
            iconColor: const Color(0xFF13EC13),
            badgeColor: const Color(0xFF13EC13).withOpacity(0.2),
            badgeTextColor: Colors.green,
            badge: 'Healthy',
            count: '24',
            label: 'Total fresh items',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required Color badgeTextColor,
    required String badge,
    required String count,
    required String label,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String action, {
    required bool isUrgent,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          action,
          style: TextStyle(
            fontSize: 12,
            color: isUrgent ? Colors.red : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentItem(
    BuildContext context, {
    required String icon,
    required String name,
    required String expiry,
    required String detail,
    required double progress,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.foodItemDetails);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        expiry,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: color,
                      backgroundColor: Colors.grey[200],
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () {
                // Delete action placeholder
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    String icon,
    String name,
    String subtitle,
    double progress,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.foodItemDetails);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[50],
              radius: 24,
              child: Text(icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(subtitle, style: TextStyle(fontSize: 10, color: color)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                color: color,
                backgroundColor: Colors.grey[200],
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    String icon,
    String name,
    String subtitle,
    String status,
    double progress,
    Color statusColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.foodItemDetails);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 48,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: statusColor,
                      backgroundColor: Colors.grey[200],
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return const FridgeBottomNavigation(currentTab: FridgeTab.fridge);
  }
}
