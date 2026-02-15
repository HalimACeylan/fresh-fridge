import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';

enum FridgeTab { scan, fridge, cook, profile }

class FridgeBottomNavigation extends StatelessWidget {
  final FridgeTab currentTab;

  const FridgeBottomNavigation({super.key, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            Icons.qr_code_scanner,
            'Scan',
            FridgeTab.scan,
            AppRoutes.scanReceipt,
          ),
          _buildNavItem(
            context,
            Icons.kitchen_outlined,
            'Fridge',
            FridgeTab.fridge,
            AppRoutes.fridgeGrid,
          ),
          _buildNavItem(
            context,
            Icons.restaurant_menu,
            'Cook',
            FridgeTab.cook,
            AppRoutes.suggestedRecipes,
          ),
          _buildNavItem(
            context,
            Icons.person_outline,
            'Profile',
            FridgeTab.profile,
            AppRoutes.homeManagerAdmin,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    FridgeTab tab,
    String route,
  ) {
    final bool isActive = currentTab == tab;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          // If we are navigating to Scan, we might want to push it
          // But for main tabs, we usually want to replace the route or pop until we find it
          // For simplicity in this app structure, we'll pushNamed (or pushReplacementNamed to avoid stack buildup)
          // Given the user flow, pushNamed is safer for now to avoid losing history if they want back,
          // but for a main tab bar, usually you don't want back buttons.
          // Let's use pushReplacementNamed to keep the stack clean for main tabs.
          Navigator.pushReplacementNamed(context, route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Column(
              children: [
                if (isActive)
                  Container(
                    width: 12,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13EC13).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF13EC13) : Colors.grey,
                  shadows: isActive
                      ? [const Shadow(color: Color(0xFF13EC13), blurRadius: 8)]
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
