import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/user_household_service.dart';

class JoinOrCreateHouseholdScreen extends StatefulWidget {
  const JoinOrCreateHouseholdScreen({super.key});

  @override
  State<JoinOrCreateHouseholdScreen> createState() =>
      _JoinOrCreateHouseholdScreenState();
}

class _JoinOrCreateHouseholdScreenState
    extends State<JoinOrCreateHouseholdScreen> {
  final _service = UserHouseholdService.instance;

  // ------- Create flow -------
  bool _showCreate = false;
  final _createNameController = TextEditingController();
  bool _isCreating = false;

  // ------- Join flow -------
  bool _showJoin = false;
  final _joinCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _createNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  // ---- Create ----
  Future<void> _createHousehold() async {
    final name = _createNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a household name.')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (_service.isFirebaseEnabled) {
        await _service.updateCurrentHousehold(name: name, description: '');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Household created!')));
      Navigator.pushReplacementNamed(context, AppRoutes.homeManagerAdmin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create household: $e')));
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  // ---- Join ----
  Future<void> _joinHousehold() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code.')),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      if (_service.isFirebaseEnabled) {
        // Query Firestore to find the household matching this invite code
        final query = await FirebaseFirestore.instance
            .collection('households')
            .where('inviteCode', isEqualTo: code)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No household found with that code.')),
          );
          setState(() => _isJoining = false);
          return;
        }

        final householdId = query.docs.first.id;
        await _service.joinHousehold(householdId, inviteCode: code);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Joined household!')));
      Navigator.pushReplacementNamed(context, AppRoutes.homeManagerAdmin);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not join household: $e')));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'GET STARTED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.5,
            color: Color(0xFF102210),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102210),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
        child: Column(
          children: [
            // Hero illustration
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF13EC13).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.kitchen_rounded,
                size: 38,
                color: Color(0xFF13EC13),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Kitchen,\nShared.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102210),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Organize your fridge inventory and plan meals with your family in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // ---- CREATE SECTION ----
            _SectionCard(
              onTap: () => setState(() {
                _showCreate = !_showCreate;
                if (_showCreate) _showJoin = false;
              }),
              iconData: Icons.home_work_rounded,
              iconColor: const Color(0xFF13EC13),
              iconBg: const Color(0xFF13EC13),
              title: 'New Household',
              subtitle: 'Start fresh and invite others later',
            ),
            const SizedBox(height: 12),

            // Expandable create form
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _showCreate ? _buildCreateForm() : const SizedBox.shrink(),
            ),

            FilledButton(
              onPressed: _isCreating
                  ? null
                  : () {
                      if (!_showCreate) {
                        setState(() {
                          _showCreate = true;
                          _showJoin = false;
                        });
                      } else {
                        _createHousehold();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF13EC13),
                foregroundColor: const Color(0xFF102210),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create a New Household',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // ---- JOIN SECTION ----
            _SectionCard(
              onTap: () => setState(() {
                _showJoin = !_showJoin;
                if (_showJoin) _showCreate = false;
              }),
              iconData: Icons.group_rounded,
              iconColor: Colors.white,
              iconBg: const Color(0xFF1A1A2E),
              title: 'Join Existing',
              subtitle: 'Enter a code from a family member',
            ),
            const SizedBox(height: 12),

            // Expandable join form
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: _showJoin ? _buildJoinForm() : const SizedBox.shrink(),
            ),

            FilledButton(
              onPressed: _isJoining
                  ? null
                  : () {
                      if (!_showJoin) {
                        setState(() {
                          _showJoin = true;
                          _showCreate = false;
                        });
                      } else {
                        _joinHousehold();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Join a Household',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),

            const SizedBox(height: 28),
            // Invite link footer
            GestureDetector(
              onTap: () {
                setState(() {
                  _showJoin = true;
                  _showCreate = false;
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'I have an invite link',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 15, color: Colors.grey[600]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _createNameController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _createHousehold(),
          autofocus: true,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Household Name',
            hintText: 'e.g. The Miller Family',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF13EC13), width: 2),
            ),
            prefixIcon: const Icon(Icons.home_outlined),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: TextField(
          controller: _joinCodeController,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _joinHousehold(),
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            labelText: 'Invite Code',
            hintText: 'e.g. HK8-92L',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 2),
            ),
            prefixIcon: const Icon(Icons.key_outlined),
          ),
        ),
      ),
    );
  }
}

// ---- Reusable section header card ----
class _SectionCard extends StatelessWidget {
  final VoidCallback onTap;
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;

  const _SectionCard({
    required this.onTap,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg.withValues(
                  alpha: iconBg == const Color(0xFF1A1A2E) ? 1.0 : 0.15,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF102210),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
