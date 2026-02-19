import 'package:cloud_firestore/cloud_firestore.dart';
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

      setState(() {
        _member = cloudMember;
        _selectedRole = cloudMember['role'] as String? ?? 'member';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load member details: $e';
      });
    }
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
            child: const Text('Remove'),
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
    final member = _member;
    final role = (member?['role'] as String?)?.toLowerCase() ?? 'member';
    final selectedRole = _selectedRole ?? role;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(title: const Text('Member Details'), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState()
          : member == null
          ? _buildErrorState(message: 'Member not found.')
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileCard(member),
                const SizedBox(height: 16),
                _buildPermissionCard(role: selectedRole),
                const SizedBox(height: 16),
                if (_canManageMember) ...[
                  _buildRoleSelector(selectedRole),
                  const SizedBox(height: 16),
                ],
                if (!_canManageMember)
                  const Text(
                    'You can view this member, but only owner/admin can change permissions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                const SizedBox(height: 24),
                if (_canManageMember)
                  FilledButton(
                    onPressed: _isSaving ? null : _saveRole,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF13EC13),
                      foregroundColor: const Color(0xFF102210),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Permissions'),
                  ),
                const SizedBox(height: 12),
                if (_canManageMember)
                  OutlinedButton.icon(
                    onPressed: _isSaving ? null : _removeMember,
                    icon: const Icon(Icons.person_remove_alt_1),
                    label: const Text('Remove Member'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
              ],
            ),
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

  Widget _buildProfileCard(Map<String, dynamic> member) {
    final name = _memberDisplayName(member);
    final email = (member['email'] as String?)?.trim();
    final roleLabel = _roleLabel((member['role'] as String?) ?? 'member');
    final initials = _initials(name);
    final joinedText = _formatJoinedAt(member['joinedAt']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF13EC13).withValues(alpha: 0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF102210),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isCurrentUser ? '$name (You)' : name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(email, style: TextStyle(color: Colors.grey[700])),
                ],
                if (joinedText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Joined $joinedText',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard({required String role}) {
    final canManageMembers = role == 'owner' || role == 'admin';
    final canManageBilling = role == 'owner';

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
            'Permissions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPermissionRow(
            label: 'Can add/edit fridge items',
            enabled: true,
          ),
          _buildPermissionRow(
            label: 'Can manage members',
            enabled: canManageMembers,
          ),
          _buildPermissionRow(
            label: 'Can manage billing',
            enabled: canManageBilling,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({required String label, required bool enabled}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.remove_circle_outline,
            color: enabled ? const Color(0xFF13EC13) : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(String selectedRole) {
    final options = _roleOptions;
    final safeSelection = options.contains(selectedRole)
        ? selectedRole
        : options.first;

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
            'Role Access',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: safeSelection,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Role',
            ),
            items: options
                .map(
                  (role) => DropdownMenuItem<String>(
                    value: role,
                    child: Text(_roleLabel(role)),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedRole = value;
                    });
                  },
          ),
        ],
      ),
    );
  }

  String _memberDisplayName(Map<String, dynamic> member) {
    final displayName = (member['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = (member['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    return member['id'] as String? ?? 'Member';
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

  String _initials(String value) {
    final parts = value
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  String? _formatJoinedAt(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is DateTime) {
      date = raw;
    } else if (raw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (date == null) return null;
    final month = _monthAbbr(date.month);
    return '$month ${date.day}, ${date.year}';
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return 'N/A';
    return months[month - 1];
  }
}
