import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fridge_app/services/user_household_service.dart';

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
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Household',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Each user gets a default household automatically. '
                            'Use this page to rename and manage it.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        labelText: 'Household Name',
                        hintText: 'e.g. The Miller Family',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 240,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Optional notes for your household and food workflow.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
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
                                    _inviteCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _copyInviteCode,
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy',
                              ),
                              IconButton(
                                onPressed: _isSaving ? null : _rotateInviteCode,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Rotate',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 20,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveHousehold,
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
                        : const Text('Save Household'),
                  ),
                ),
              ],
            ),
    );
  }
}
