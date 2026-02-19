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
                FridgeHeader(
                  title: 'Household Settings',
                  centerTitle: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF13EC13)),
                    onPressed: _isBusy
                        ? null
                        : () => _loadData(showLoading: false),
                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditHousehold,
        backgroundColor: const Color(0xFF13EC13),
        foregroundColor: const Color(0xFF102210),
        icon: const Icon(Icons.edit),
        label: const Text('Edit Household'),
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
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          _buildHouseholdInfoCard(),
          const SizedBox(height: 16),
          _buildInviteCodeCard(),
          const SizedBox(height: 24),
          Text(
            'MEMBERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 10),
          ..._members.map(_buildMemberTile),
          if (_members.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('No members found for this household.'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHouseholdInfoCard() {
    final name = (_household?['name'] as String?)?.trim();
    final resolvedName = (name == null || name.isEmpty) ? 'My Household' : name;
    final description = (_household?['description'] as String?)?.trim() ?? '';
    final plan = (_household?['planTier'] as String?)?.trim().toLowerCase();
    final seatCount = _members.length;
    final planLabel = plan == null || plan.isEmpty ? 'free' : plan;

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
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC13).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$seatCount member${seatCount == 1 ? '' : 's'} • ${planLabel.toUpperCase()}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_service.canManageHousehold)
                IconButton(
                  onPressed: _openEditHousehold,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF13EC13),
                  ),
                ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, style: TextStyle(color: Colors.grey[700])),
          ],
        ],
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
          const Text(
            'Invite Members',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share this code so others can join your household.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F8F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    resolvedCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyInviteCode,
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy code',
              ),
              IconButton(
                onPressed: canRotate && !_isBusy ? _rotateInviteCode : null,
                icon: const Icon(Icons.refresh),
                tooltip: 'Rotate code',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> member) {
    final memberId = (member['id'] as String?) ?? '';
    final displayName = _memberName(member);
    final role = (member['role'] as String?) ?? 'member';
    final isCurrentUser = memberId == _service.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: memberId.isEmpty ? null : () => _openMemberDetails(memberId),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF13EC13).withValues(alpha: 0.14),
          child: Text(
            _initials(displayName),
            style: const TextStyle(
              color: Color(0xFF102210),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          isCurrentUser ? '$displayName (You)' : displayName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(_roleLabel(role)),
        trailing: TextButton.icon(
          onPressed: memberId.isEmpty
              ? null
              : () => _openMemberDetails(memberId),
          icon: const Icon(Icons.admin_panel_settings_outlined, size: 18),
          label: const Text('Permissions'),
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

  String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Admin';
      default:
        return 'Member';
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
