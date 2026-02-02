import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../models/group.dart';
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
  List<Contact> _allContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final groups = await _contactService.getGroups();
      final contacts = await _contactService.getContacts();
      setState(() {
        _groups = groups;
        _allContacts = contacts;
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

  Future<void> _showAddEditDialog({Group? group}) async {
    final isEdit = group != null;
    final nameController = TextEditingController(text: group?.name);
    final descController = TextEditingController(text: group?.description);
    final formKey = GlobalKey<FormState>();
    final selectedMembers = Set<String>.from(group?.memberIds ?? []);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Group' : 'New Group'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group Name *',
                      prefixIcon: Icon(Icons.group),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Members',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_allContacts.isEmpty)
                    const Text(
                      'No contacts available. Add contacts first.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _allContacts[index];
                          final isSelected = selectedMembers.contains(contact.id);
                          return CheckboxListTile(
                            dense: true,
                            value: isSelected,
                            title: Text(contact.name),
                            subtitle: contact.phone != null ? Text(contact.phone!) : null,
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                try {
                  if (isEdit) {
                    await _contactService.updateGroup(
                      group.copyWith(
                        name: nameController.text.trim(),
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        memberIds: selectedMembers.toList(),
                      ),
                    );
                  } else {
                    await _contactService.createGroup(
                      name: nameController.text.trim(),
                      memberIds: selectedMembers.toList(),
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                  }
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Delete group "${group.name}"?'),
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

    if (confirmed == true) {
      try {
        await _contactService.deleteGroup(group.id);
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted')),
          );
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null) ..[
              Text(
                group.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(),
            ],
            const Text(
              'Members:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              const Text('No members', style: TextStyle(color: Colors.grey))
            else
              ...members.map((contact) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text(contact.name),
                      ],
                    ),
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
              _showAddEditDialog(group: group);
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
                  padding: const EdgeInsets.all(16),
                  itemCount: _groups.length,
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    return _buildGroupCard(group);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_allContacts.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add contacts first before creating groups'),
              ),
            );
          } else {
            _showAddEditDialog();
          }
        },
        child: const Icon(Icons.group_add),
      ),
    );
  }

  Widget _buildGroupCard(Group group) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: Icon(
            Icons.group,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description != null)
              Text(
                group.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                const Icon(Icons.people, size: 14),
                const SizedBox(width: 4),
                Text('${group.memberCount} members'),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              _showGroupDetails(group);
            } else if (value == 'edit') {
              _showAddEditDialog(group: group);
            } else if (value == 'delete') {
              _deleteGroup(group);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showGroupDetails(group),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_add,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No groups yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create groups for easy split bill management',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
