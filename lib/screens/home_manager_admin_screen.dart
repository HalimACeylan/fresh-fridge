import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';
import 'package:fridge_app/widgets/fridge_header.dart';

class HomeManagerAdminScreen extends StatelessWidget {
  const HomeManagerAdminScreen({super.key});

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
                FridgeHeader(
                  title: 'Household Settings',
                  centerTitle: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.save, color: Color(0xFF13EC13)),
                    onPressed: () {
                      // Save logic
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    children: [
                      // Household Info Card
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/household_bg.png',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF13EC13),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF102210),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'The Green Family',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '4 members • Premium Plan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Color(0xFF13EC13),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Family Members Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FAMILY MEMBERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.grey[400],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF13EC13).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '4/6 Seats',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102210),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildMemberCard(
                        name: 'Sarah (You)',
                        role: 'Owner & Admin',
                        imagePath: 'assets/images/sarah_profile.png',
                        isAdmin: true,
                        isCurrentUser: true,
                      ),
                      const SizedBox(height: 12),
                      _buildMemberCard(
                        name: 'James',
                        role: 'Can add items',
                        imagePath: 'assets/images/james_profile.png',
                      ),
                      const SizedBox(height: 12),
                      _buildMemberCard(
                        name: 'Leo',
                        role: 'View only',
                        imagePath: 'assets/images/leo_profile.png',
                        isGrayscale: true,
                      ),

                      const SizedBox(height: 32),

                      // Permissions Section
                      Text(
                        'GLOBAL PERMISSIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
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
                            _buildSwitchTile(
                              'Allow adding items',
                              'Everyone can add new products to the fridge list.',
                              true,
                            ),
                            const Divider(height: 1),
                            _buildSwitchTile(
                              'Member invitations',
                              'Allow members to invite new people via link.',
                              false,
                            ),
                            const Divider(height: 1),
                            _buildSwitchTile(
                              'Meal Planning edits',
                              'Members can modify the weekly meal plan.',
                              true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Danger Zone
                      const Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.vpn_key,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Transfer Ownership',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Make another member the main admin',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              bottom: 90,
              left: 24,
              right: 24,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createFamilyGroup);
                },
                icon: const Icon(Icons.person_add),
                label: const Text(
                  'Add Member',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13EC13),
                  foregroundColor: const Color(0xFF102210),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF13EC13).withOpacity(0.3),
                ),
              ),
            ),
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FridgeBottomNavigation(currentTab: FridgeTab.profile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard({
    required String name,
    required String role,
    required String imagePath,
    bool isAdmin = false,
    bool isCurrentUser = false,
    bool isGrayscale = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF13EC13).withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isCurrentUser
                  ? Border.all(color: const Color(0xFF13EC13), width: 2)
                  : null,
            ),
            child: ClipOval(
              child: ColorFiltered(
                colorFilter: isGrayscale
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: Image.asset(
                  imagePath,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  opacity: isGrayscale
                      ? const AlwaysStoppedAnimation(0.7)
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: isAdmin ? const Color(0xFF13EC13) : Colors.grey[600],
                    fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.grey, size: 20),
            )
          else
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ), // Better bg needed maybe?
                  child: const Icon(Icons.edit, color: Colors.grey, size: 20),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (v) {},
            activeColor: const Color(0xFF13EC13),
            activeTrackColor: const Color(0xFF13EC13).withOpacity(0.2),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}
