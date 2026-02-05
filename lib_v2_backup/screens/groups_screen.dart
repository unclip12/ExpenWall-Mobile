import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class GroupsScreen extends StatefulWidget {
  final String userId;

  const GroupsScreen({super.key, required this.userId});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  late ContactService _contactService;
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _contactService.getGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    }
  }

  Future<void> _showAddEditGroupDialog([Group? group]) async {
    final nameController = TextEditingController(text: group?.name);
    final descriptionController =
        TextEditingController(text: group?.description);
    final formKey = GlobalKey<FormState>();

    // Get all contacts
    final allContacts = await _contactService.getContacts();
    if (allContacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add contacts first'),
          ),
        );
      }
      return;
    }

    final selectedMembers =
        Set<String>.from(group?.memberIds ?? []);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(group == null ? 'Create Group' : 'Edit Group'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      prefixIcon: Icon(Icons.group),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true
                        ? 'Name required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select Members (${selectedMembers.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: allContacts.length,
                        itemBuilder: (context, index) {
                          final contact = allContacts[index];
                          final isSelected =
                              selectedMembers.contains(contact.id);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(contact.name),
                            subtitle: contact.phone != null
                                ? Text(contact.phone!)
                                : null,
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  selectedMembers.add(contact.id);
                                } else {
                                  selectedMembers.remove(contact.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                if (selectedMembers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select at least one member'),
                    ),
                  );
                  return;
                }

                try {
                  if (group == null) {
                    await _contactService.createGroup(
                      name: nameController.text.trim(),
                      memberIds: selectedMembers.toList(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                    );
                  } else {
                    await _contactService.updateGroup(
                      group.copyWith(
                        name: nameController.text.trim(),
                        memberIds: selectedMembers.toList(),
                        description:
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                      ),
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            group == null ? 'Group created' : 'Group updated'),
                      ),
                    );
                    _loadGroups();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGroup(Group group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content:
            Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _contactService.deleteGroup(group.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted')),
          );
          _loadGroups();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showGroupDetails(Group group) async {
    final members = await _contactService.getGroupMembers(group.id);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ...[
              Text(
                group.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Members (${members.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...members.map((member) => ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    child: Text(member.name[0].toUpperCase()),
                  ),
                  title: Text(member.name),
                  subtitle: member.phone != null ? Text(member.phone!) : null,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddEditGroupDialog(group);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
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
                  itemCount: _groups.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return _buildGroupCard(group);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditGroupDialog(),
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: Icon(
              Icons.group,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          title: Text(
            group.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${group.memberCount} members'),
              if (group.description != null)
                Text(
                  group.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'view') {
                _showGroupDetails(group);
              } else if (value == 'edit') {
                _showAddEditGroupDialog(group);
              } else if (value == 'delete') {
                _deleteGroup(group);
              }
            },
          ),
          onTap: () => _showGroupDetails(group),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 80,
            color: Colors.grey[400],
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
            'Create groups for easy split bills',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditGroupDialog(),
            icon: const Icon(Icons.group_add),
            label: const Text('Create Group'),
          ),
        ],
      ),
    );
  }
}
