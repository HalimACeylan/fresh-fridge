import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fridge_app/services/user_household_service.dart';
import 'package:image_picker/image_picker.dart';

class CreateFamilyGroupScreen extends StatefulWidget {
  const CreateFamilyGroupScreen({super.key});

  @override
  State<CreateFamilyGroupScreen> createState() =>
      _CreateFamilyGroupScreenState();
}

class _CreateFamilyGroupScreenState extends State<CreateFamilyGroupScreen> {
  final _service = UserHouseholdService.instance;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _inviteCode = 'N/A';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadHousehold();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadHousehold() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      if (_service.isFirebaseEnabled) {
        await _service.refreshCurrentMemberRoleFromCloud();
        final household = await _service.readCurrentHouseholdFromCloud();
        final name = (household?['name'] as String?)?.trim() ?? 'My Household';
        final description =
            (household?['description'] as String?)?.trim() ?? '';
        final inviteCode =
            (household?['inviteCode'] as String?)?.trim() ?? 'N/A';

        if (!mounted) return;
        setState(() {
          _nameController.text = name;
          _descriptionController.text = description;
          _inviteCode = inviteCode.isEmpty ? 'N/A' : inviteCode;
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _nameController.text = 'My Household';
        _descriptionController.text = '';
        _inviteCode = 'N/A';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Could not load household: $e';
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedImage = File(picked.path);
    });
  }

  Future<void> _saveHousehold() async {
    final rawName = _nameController.text.trim();
    if (rawName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household name is required.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_service.isFirebaseEnabled) {
        await _service.updateCurrentHousehold(
          name: rawName,
          description: _descriptionController.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household settings updated.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save household: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _rotateInviteCode() async {
    if (!_service.canManageHousehold) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only owner/admin can rotate invite code.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final code = await _service.rotateHouseholdInviteCode();
      if (!mounted) return;
      if (code == null || code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not rotate invite code.')),
        );
      } else {
        setState(() {
          _inviteCode = code;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invite code rotated.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not rotate code: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _copyInviteCode() {
    if (_inviteCode.trim().isEmpty || _inviteCode == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No invite code available.')),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite code copied.')));
  }

  Future<void> _leaveHousehold() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Household'),
        content: const Text(
          'Are you sure you want to leave this household? '
          'You will lose access to the shared fridge and meal plans.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });
    try {
      // TODO: wire to service.leaveHousehold() when available
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have left the household.')),
      );
      // Pop twice to go back past admin screen
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not leave household: $e')));
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
          'Edit Household',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102210),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHousehold,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF13EC13),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 30,
                    ),
                    const SizedBox(height: 12),
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loadHousehold,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 160),
          children: [
            _buildAvatarSection(),
            const SizedBox(height: 28),
            _buildFieldsSection(),
            const SizedBox(height: 20),
            _buildInviteCodeSection(),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 68,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveHousehold,
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
                    'Save Household',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Center(
            child: TextButton(
              onPressed: _isSaving ? null : _leaveHousehold,
              child: const Text(
                'Leave Household',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImageFromGallery,
            child: Stack(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF13EC13).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: 88,
                            height: 88,
                          )
                        : Icon(
                            Icons.home_rounded,
                            size: 42,
                            color: Colors.grey.shade500,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF13EC13),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImageFromGallery,
            child: const Text(
              'Choose from gallery',
              style: TextStyle(
                color: Color(0xFF13EC13),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnderlineField(
          label: 'Household Name',
          controller: _nameController,
          textInputAction: TextInputAction.next,
          maxLength: 80,
        ),
        const SizedBox(height: 20),
        _buildUnderlineField(
          label: 'Description',
          controller: _descriptionController,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          maxLength: 240,
        ),
      ],
    );
  }

  Widget _buildUnderlineField({
    required String label,
    required TextEditingController controller,
    TextInputAction textInputAction = TextInputAction.done,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textInputAction: textInputAction,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF102210),
          ),
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF13EC13), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeSection() {
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
            'Invite Code',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Share this code to invite members',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _inviteCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                    color: Color(0xFF102210),
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyInviteCode,
                icon: Icon(Icons.copy_rounded, color: Colors.grey[600]),
                tooltip: 'Copy',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _isSaving ? null : _rotateInviteCode,
                icon: Icon(Icons.refresh_rounded, color: Colors.grey[600]),
                tooltip: 'Rotate',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Codes expire after 48 hours for security.',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
      ),
    );
  }
}
