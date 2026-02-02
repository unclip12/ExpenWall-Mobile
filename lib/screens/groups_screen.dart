import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/contact.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'contacts_screen.dart';

class GroupsScreen extends StatefulWidget {
  final String userId;

  const GroupsScreen({super.key, required this.userId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _localStorageService = LocalStorageService();
  
  List<Group> _groups = [];
  List<Contact> _allContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _localStorageService.loadGroups(widget.userId);
      final contacts = await _localStorageService.loadContacts(widget.userId);
      setState(() {
        _groups = groups;
        _allContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading groups: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveGroups() async {
    await _localStorageService.saveGroups(widget.userId, _groups);
  }

  Future<void> _addGroup() async {
    if (_allContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add contacts first'),
          action: SnackBarAction(
            label: 'Add Contacts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactsScreen(userId: widget.userId),
                ),
              ).then((_) => _loadData());
            },
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push<Group>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGroupScreen(
          userId: widget.userId,
          allContacts: _allContacts,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _groups.add(result);
      });
      await _saveGroups();
    }
  }

  Future<void> _editGroup(Group group) async {
    final result = await Navigator.push<Group>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditGroupScreen(
          userId: widget.userId,
          group: group,
          allContacts: _allContacts,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _groups.indexWhere((g) => g.id == result.id);
        if (index != -1) {
          _groups[index] = result;
        }
      });
      await _saveGroups();
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _groups.removeWhere((g) => g.id == group.id);
      });
      await _saveGroups();
    }
  }

  List<Contact> _getGroupMembers(Group group) {
    return _allContacts.where((c) => group.memberIds.contains(c.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return _buildGroupCard(group);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGroup,
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    final members = _getGroupMembers(group);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: group.color,
          child: const Icon(Icons.group, color: Colors.white),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${group.memberCount} members'),
            if (group.description != null && group.description!.isNotEmpty)
              Text(
                group.description!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (members.isNotEmpty) ..[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: members.take(5).map((member) {
                  return Chip(
                    label: Text(
                      member.name,
                      style: const TextStyle(fontSize: 10),
                    ),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteGroup(group),
        ),
        onTap: () => _editGroup(group),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create groups like "Roommates" or "Family"',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addGroup,
            icon: const Icon(Icons.group_add),
            label: const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}

// Add/Edit Group Screen
class AddEditGroupScreen extends StatefulWidget {
  final String userId;
  final Group? group;
  final List<Contact> allContacts;

  const AddEditGroupScreen({
    super.key,
    required this.userId,
    this.group,
    required this.allContacts,
  });

  @override
  State<AddEditGroupScreen> createState() => _AddEditGroupScreenState();
}

class _AddEditGroupScreenState extends State<AddEditGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  late Color _selectedColor;
  late Set<String> _selectedMemberIds;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _descriptionController.text = widget.group!.description ?? '';
      _selectedColor = widget.group!.color;
      _selectedMemberIds = Set.from(widget.group!.memberIds);
    } else {
      _selectedColor = GroupColors.presets[0];
      _selectedMemberIds = {};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final group = widget.group != null
        ? widget.group!.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            colorValue: _selectedColor.value,
            memberIds: _selectedMemberIds.toList(),
            updatedAt: DateTime.now(),
          )
        : Group.create(
            userId: widget.userId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            color: _selectedColor,
            memberIds: _selectedMemberIds.toList(),
          );

    Navigator.pop(context, group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group == null ? 'Create Group' : 'Edit Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Name
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Roommates, Family, College Friends...',
                      prefixIcon: Icon(Icons.group),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'People I share apartment with...',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Color Picker
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Group Color',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: GroupColors.presets.map((color) {
                      final isSelected = _selectedColor.value == color.value;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Members Selection
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Members',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${_selectedMemberIds.length} selected',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.allContacts.isEmpty)
                    const Text(
                      'No contacts available. Please add contacts first.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    ...widget.allContacts.map((contact) {
                      final isSelected = _selectedMemberIds.contains(contact.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(contact.name),
                        subtitle: contact.phone != null ? Text(contact.phone!) : null,
                        secondary: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            contact.initials,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedMemberIds.add(contact.id);
                            } else {
                              _selectedMemberIds.remove(contact.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
