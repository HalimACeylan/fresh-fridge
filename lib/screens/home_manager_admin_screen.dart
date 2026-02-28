import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fridge_app/routes.dart';
import 'package:fridge_app/services/user_household_service.dart';
import 'package:fridge_app/widgets/fridge_bottom_navigation.dart';
import 'package:fridge_app/widgets/fridge_header.dart';

class HomeManagerAdminScreen extends StatefulWidget {
  const HomeManagerAdminScreen({super.key});

  @override
  State<HomeManagerAdminScreen> createState() => _HomeManagerAdminScreenState();
}

class _HomeManagerAdminScreenState extends State<HomeManagerAdminScreen> {
  final _service = UserHouseholdService.instance;

  bool _isLoading = true;
  bool _isBusy = false;
  String? _errorMessage;
  Map<String, dynamic>? _household;
  List<Map<String, dynamic>> _members = const [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      if (_service.isFirebaseEnabled) {
        await _service.refreshCurrentMemberRoleFromCloud();
        final household = await _service.readCurrentHouseholdFromCloud();
        final members = await _service.queryHouseholdMembersFromCloud(
          limit: 120,
        );

        if (!mounted) return;
        setState(() {
          _household = household;
          _members = members;
          _isLoading = false;
          _errorMessage = null;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _household = {
          'name': 'My Household',
          'description': '',
          'inviteCode': 'N/A',
          'planTier': 'free',
          'memberCount': 1,
        };
        _members = [
          {
            'id': _service.userId,
            'displayName': 'You',
            'role': 'owner',
            'status': 'active',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load household settings: $e';
      });
    }
  }

  Future<void> _openEditHousehold() async {
    final updated = await Navigator.pushNamed(context, AppRoutes.editHousehold);
    if (!mounted) return;
    if (updated == true) {
      await _loadData(showLoading: false);
    }
  }

  Future<void> _openMemberDetails(String memberId) async {
    final updated = await Navigator.pushNamed(
      context,
      AppRoutes.householdMemberDetails,
      arguments: <String, dynamic>{'memberId': memberId},
    );
    if (!mounted) return;
    if (updated == true) {
      await _loadData(showLoading: false);
    }
  }

  Future<void> _rotateInviteCode() async {
    if (_isBusy || !_service.canManageHousehold) return;
    setState(() {
      _isBusy = true;
    });
    try {
      final code = await _service.rotateHouseholdInviteCode();
      if (!mounted) return;
      if (code == null || code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only owner/admin can rotate invite code.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invite code rotated.')));
      }
      await _loadData(showLoading: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not rotate code: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _copyInviteCode() {
    final code = (_household?['inviteCode'] as String?)?.trim();
    if (code == null || code.isEmpty || code == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invite code available.')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite code copied.')));
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
                // No refresh button — pull-to-refresh handles it
                const FridgeHeader(
                  title: 'Household Settings',
                  centerTitle: true,
                ),
                Expanded(child: _buildBody()),
              ],
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 30),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          _buildHouseholdInfoCard(),
          const SizedBox(height: 16),
          _buildInviteCodeCard(),
          const SizedBox(height: 24),
          _buildMembersSection(),
        ],
      ),
    );
  }

  Widget _buildHouseholdInfoCard() {
    final name = (_household?['name'] as String?)?.trim();
    final resolvedName = (name == null || name.isEmpty) ? 'My Household' : name;
    final plan = (_household?['planTier'] as String?)?.trim().toLowerCase();
    final seatCount = _members.length;
    final planLabel = (plan == null || plan.isEmpty) ? 'free' : plan;

    return GestureDetector(
      onTap: _openEditHousehold,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF13EC13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolvedName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$seatCount member${seatCount == 1 ? '' : 's'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF13EC13,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          planLabel.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF0DA80D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeCard() {
    final code = (_household?['inviteCode'] as String?)?.trim();
    final resolvedCode = (code == null || code.isEmpty) ? 'N/A' : code;
    final canRotate = _service.canManageHousehold && resolvedCode != 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC13).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  size: 18,
                  color: Color(0xFF0DA80D),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Invite Members',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Share this unique code to let others join your kitchen.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    resolvedCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _InviteActionButton(
                icon: Icons.copy_rounded,
                tooltip: 'Copy code',
                onTap: _copyInviteCode,
              ),
              const SizedBox(width: 8),
              _InviteActionButton(
                icon: Icons.share_outlined,
                tooltip: 'Share code',
                onTap: _copyInviteCode,
              ),
            ],
          ),
          if (canRotate) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _isBusy ? null : _rotateInviteCode,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Rotate code',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMBERS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.grey[500],
              ),
            ),
            if (_service.canManageHousehold)
              GestureDetector(
                onTap: _openEditHousehold,
                child: const Text(
                  'Manage all',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF13EC13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_members.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('No members found for this household.'),
          )
        else
          ..._members.map(_buildMemberTile),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final memberId = (member['id'] as String?) ?? '';
    final displayName = _memberName(member);
    final role = (member['role'] as String?) ?? 'member';
    final isCurrentUser = memberId == _service.userId;
    final isOwner = role.toLowerCase() == 'owner';
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar with online dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(
                    0xFF13EC13,
                  ).withValues(alpha: 0.14),
                  child: Text(
                    _initials(displayName),
                    style: const TextStyle(
                      color: Color(0xFF102210),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF13EC13),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Name + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isCurrentUser ? '$displayName (You)' : displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isOwner || isAdmin) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(
                                    0xFF13EC13,
                                  ).withValues(alpha: 0.15)
                                : Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isOwner
                                  ? const Color(0xFF0DA80D)
                                  : Colors.blue[700],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _roleSubtitle(role),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Permissions button
            if (memberId.isNotEmpty)
              GestureDetector(
                onTap: () => _openMemberDetails(memberId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Permissions',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey[600],
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

  String _memberName(Map<String, dynamic> member) {
    final displayName = (member['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = (member['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return (member['id'] as String?) ?? 'Member';
  }

  String _roleSubtitle(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Full access';
      case 'admin':
        return 'Admin access';
      default:
        return 'Standard access';
    }
  }

  String _initials(String input) {
    final parts = input
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}

class _InviteActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _InviteActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F8F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey[700]),
        ),
      ),
    );
  }
}
