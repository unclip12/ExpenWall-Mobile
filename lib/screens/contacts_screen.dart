import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class ContactsScreen extends StatefulWidget {
  final String userId;

  const ContactsScreen({super.key, required this.userId});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  late ContactService _contactService;
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactService.getContacts();
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          return contact.name.toLowerCase().contains(query) ||
              (contact.phone?.contains(query) ?? false) ||
              (contact.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _showAddEditDialog({Contact? contact}) async {
    final isEdit = contact != null;
    final nameController = TextEditingController(text: contact?.name);
    final phoneController = TextEditingController(text: contact?.phone);
    final emailController = TextEditingController(text: contact?.email);
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Contact' : 'New Contact'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
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
                  await _contactService.updateContact(
                    contact.copyWith(
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                    ),
                  );
                } else {
                  await _contactService.createContact(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
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
            child: Text(isEdit ? 'Update' : 'Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadContacts();
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete "${contact.name}"? This will also remove them from all groups.'),
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
        await _contactService.deleteContact(contact.id);
        _loadContacts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact deleted')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Manage Groups',
            onPressed: () {
              // Navigate to groups screen
              Navigator.pushNamed(context, '/groups', arguments: widget.userId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return _buildContactCard(contact);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Text(
            contact.name[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.phone != null)
              Row(
                children: [
                  const Icon(Icons.phone, size: 14),
                  const SizedBox(width: 4),
                  Text(contact.phone!),
                ],
              ),
            if (contact.email != null)
              Row(
                children: [
                  const Icon(Icons.email, size: 14),
                  const SizedBox(width: 4),
                  Text(contact.email!),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showAddEditDialog(contact: contact);
            } else if (value == 'delete') {
              _deleteContact(contact);
            }
          },
          itemBuilder: (context) => [
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_add_alt_1,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No contacts yet'
                : 'No contacts found',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Add contacts to use in split bills'
                : 'Try a different search',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
