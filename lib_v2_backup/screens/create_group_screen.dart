import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../widgets/glass_card.dart';

class CreateGroupScreen extends StatefulWidget {
  final String userId;
  final ContactService contactService;
  final Group? existingGroup;

  const CreateGroupScreen({
    super.key,
    required this.userId,
    required this.contactService,
    this.existingGroup,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<Contact> _allContacts = [];
  List<String> _selectedMemberIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool get isEditing => widget.existingGroup != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allContacts = await widget.contactService.getContacts();

      if (isEditing) {
        _nameController.text = widget.existingGroup!.name;
        _descriptionController.text = widget.existingGroup!.description ?? '';
        _selectedMemberIds = List.from(widget.existingGroup!.memberIds);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      if (isEditing) {
        // Update existing
        final updated = widget.existingGroup!.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          memberIds: _selectedMemberIds,
        );
        await widget.contactService.updateGroup(updated);
      } else {
        // Create new
        await widget.contactService.createGroup(
          name: name,
          memberIds: _selectedMemberIds,
          description: description.isEmpty ? null : description,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Group updated' : 'Group created',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleMember(String contactId) {
    setState(() {
      if (_selectedMemberIds.contains(contactId)) {
        _selectedMemberIds.remove(contactId);
      } else {
        _selectedMemberIds.add(contactId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Group' : 'Create Group'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allContacts.isEmpty
              ? _buildNoContactsState()
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Group icon
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          child: const Icon(
                            Icons.groups,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name field
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Group Name *',
                            hintText: 'e.g., College Friends, Roommates',
                            prefixIcon: Icon(Icons.group),
                            border: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Group name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Brief description',
                            prefixIcon: Icon(Icons.notes),
                            border: InputBorder.none,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Members section
                      Text(
                        'Select Members (${_selectedMemberIds.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),

                      // Member list
                      ..._allContacts.map((contact) {
                        final isSelected =
                            _selectedMemberIds.contains(contact.id);
                        return GlassCard(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggleMember(contact.id),
                            title: Text(contact.name),
                            subtitle: contact.phone != null
                                ? Text(contact.phone!)
                                : null,
                            secondary: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: Text(
                                contact.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 32),

                      // Save button
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveGroup,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'Update Group' : 'Create Group',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoContactsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Contacts Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Add contacts first before creating groups',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
