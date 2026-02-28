import 'package:flutter/material.dart';
import 'package:fridge_app/services/user_household_service.dart';

class HouseholdMemberDetailsScreen extends StatefulWidget {
  const HouseholdMemberDetailsScreen({super.key});

  @override
  State<HouseholdMemberDetailsScreen> createState() =>
      _HouseholdMemberDetailsScreenState();
}

class _HouseholdMemberDetailsScreenState
    extends State<HouseholdMemberDetailsScreen> {
  final _service = UserHouseholdService.instance;

  bool _didReadArgs = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _memberId;
  Map<String, dynamic>? _member;
  String? _selectedRole;
  String? _loadError;

  // Toggle-based permissions (UI only; synced from role)
  bool _canAddItems = true;
  bool _canEditInventory = true;
  bool _canMealPlan = false;
  bool _canInviteMembers = false;

  static const List<String> _ownerRoleOptions = ['member', 'admin', 'owner'];
  static const List<String> _adminRoleOptions = ['member'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    _readRouteArguments();
    _loadMember();
  }

  void _readRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _memberId = args.trim().isEmpty ? null : args.trim();
      return;
    }
    if (args is Map) {
      final map = Map<String, dynamic>.from(args);
      final fromId = map['memberId'] as String?;
      final fromMember = map['member'];
      if (fromMember is Map) {
        _member = Map<String, dynamic>.from(fromMember);
        _memberId = (_member?['id'] as String?)?.trim();
      }
      if ((_memberId == null || _memberId!.isEmpty) &&
          fromId != null &&
          fromId.trim().isNotEmpty) {
        _memberId = fromId.trim();
      }
    }
  }

  Future<void> _loadMember() async {
    final memberId = _memberId;
    if (memberId == null || memberId.isEmpty) {
      setState(() {
        _isLoading = false;
        _loadError = 'Member id is missing.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _service.refreshCurrentMemberRoleFromCloud();
      final cloudMember = await _service.readHouseholdMemberFromCloud(memberId);
      if (!mounted) return;
      if (cloudMember == null) {
        setState(() {
          _member = null;
          _isLoading = false;
          _loadError = 'Member not found.';
        });
        return;
      }

      final role = (cloudMember['role'] as String?)?.toLowerCase() ?? 'member';
      setState(() {
        _member = cloudMember;
        _selectedRole = role;
        _isLoading = false;
        _syncPermissionsFromRole(role);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load member details: $e';
      });
    }
  }

  void _syncPermissionsFromRole(String role) {
    final r = role.toLowerCase();
    _canAddItems = true;
    _canEditInventory = r == 'owner' || r == 'admin';
    _canMealPlan = r == 'owner' || r == 'admin';
    _canInviteMembers = r == 'owner';
  }

  bool get _isCurrentUser => _memberId == _service.userId;

  bool get _canManageMember {
    if (!_service.canManageMembers || _isCurrentUser || _member == null) {
      return false;
    }
    final targetRole = (_member!['role'] as String?)?.toLowerCase() ?? 'member';
    if (_service.isOwner) return true;
    return _service.isAdmin && targetRole == 'member';
  }

  List<String> get _roleOptions {
    if (_service.isOwner) return _ownerRoleOptions;
    if (_service.isAdmin) return _adminRoleOptions;
    return const [];
  }

  Future<void> _saveRole() async {
    final member = _member;
    final memberId = _memberId;
    final selectedRole = _selectedRole;
    if (member == null ||
        memberId == null ||
        selectedRole == null ||
        !_canManageMember) {
      return;
    }

    final currentRole = (member['role'] as String?)?.toLowerCase() ?? 'member';
    if (currentRole == selectedRole.toLowerCase()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No role changes to save.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateHouseholdMemberRole(
        memberUserId: memberId,
        role: selectedRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member permissions updated.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not update member: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _removeMember() async {
    if (!_canManageMember || _member == null || _memberId == null) return;

    final displayName = _memberDisplayName(_member!);
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $displayName from this household?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldRemove != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.removeHouseholdMember(_memberId!);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Member removed.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not remove member: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: const Text(
          'Member Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102210),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState()
          : _member == null
          ? _buildErrorState(message: 'Member not found.')
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final member = _member!;
    final role =
        (_selectedRole ?? (member['role'] as String?))?.toLowerCase() ??
        'member';

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            _buildAvatarHeader(member),
            const SizedBox(height: 24),
            if (_canManageMember) ...[
              _buildRoleSection(role),
              const SizedBox(height: 16),
            ],
            _buildPermissionsSection(),
            const SizedBox(height: 24),
            if (_canManageMember) _buildDangerZone(),
            const SizedBox(height: 8),
            if (!_canManageMember)
              Text(
                'You can view this member, but only owner/admin can change permissions.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
          ],
        ),
        if (_canManageMember)
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: FilledButton(
              onPressed: _isSaving ? null : _saveRole,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF13EC13),
                foregroundColor: const Color(0xFF102210),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save Permissions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarHeader(Map<String, dynamic> member) {
    final name = _memberDisplayName(member);
    final email = (member['email'] as String?)?.trim();
    final initials = _initials(name);

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFF13EC13).withValues(alpha: 0.2),
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFF102210),
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isCurrentUser ? '$name (You)' : name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102210),
          ),
        ),
        if (email != null && email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildRoleSection(String selectedRole) {
    final options = _roleOptions;
    if (options.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HOUSEHOLD ROLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final idx = entry.key;
              final roleOpt = entry.value;
              final isSelected = selectedRole == roleOpt;
              final isLast = idx == options.length - 1;

              return GestureDetector(
                onTap: _isSaving
                    ? null
                    : () => setState(() {
                        _selectedRole = roleOpt;
                        _syncPermissionsFromRole(roleOpt);
                      }),
                child: Container(
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF13EC13).withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _roleIcon(roleOpt),
                        size: 20,
                        color: isSelected
                            ? const Color(0xFF0DA80D)
                            : Colors.grey[500],
                      ),
                    ),
                    title: Text(
                      _roleLabel(roleOpt),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF102210)
                            : Colors.grey[700],
                      ),
                    ),
                    subtitle: Text(
                      _roleDescription(roleOpt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF13EC13),
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            color: Colors.grey[300],
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERMISSIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildPermissionToggle(
                title: 'Can Add Items',
                subtitle: 'Allow adding new groceries to fridge',
                value: _canAddItems,
                onChanged: _canManageMember
                    ? (v) => setState(() => _canAddItems = v)
                    : null,
              ),
              _buildDivider(),
              _buildPermissionToggle(
                title: 'Can Edit Inventory',
                subtitle: 'Update quantities and expiration dates',
                value: _canEditInventory,
                onChanged: _canManageMember
                    ? (v) => setState(() => _canEditInventory = v)
                    : null,
              ),
              _buildDivider(),
              _buildPermissionToggle(
                title: 'Can Meal Plan',
                subtitle: 'Create and edit family meal schedules',
                value: _canMealPlan,
                onChanged: _canManageMember
                    ? (v) => setState(() => _canMealPlan = v)
                    : null,
              ),
              _buildDivider(),
              _buildPermissionToggle(
                title: 'Can Invite Members',
                subtitle: 'Generate and share household codes',
                value: _canInviteMembers,
                onChanged: _canManageMember
                    ? (v) => setState(() => _canInviteMembers = v)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF13EC13),
            activeTrackColor: const Color(0xFF13EC13).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildDangerZone() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _removeMember,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_remove_alt_1_outlined,
                color: Colors.red,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Remove from Household',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The member will no longer have access to the shared fridge inventory and meal plans.',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState({String? message}) {
    final text = message ?? _loadError ?? 'Something went wrong.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loadMember, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  IconData _roleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Icons.admin_panel_settings_rounded;
      case 'admin':
        return Icons.manage_accounts_rounded;
      default:
        return Icons.person_rounded;
    }
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

  String _roleDescription(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Full household control';
      case 'admin':
        return 'Manage members & content';
      default:
        return 'Standard household access';
    }
  }

  String _memberDisplayName(Map<String, dynamic> member) {
    final displayName = (member['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final email = (member['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return member['id'] as String? ?? 'Member';
  }

  String _initials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }
}
