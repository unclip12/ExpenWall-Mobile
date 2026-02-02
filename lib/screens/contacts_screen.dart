import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart' as phone;
import '../models/contact.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class ContactsScreen extends StatefulWidget {
  final String userId;

  const ContactsScreen({super.key, required this.userId});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _localStorageService = LocalStorageService();
  final _searchController = TextEditingController();
  
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _localStorageService.loadContacts(widget.userId);
      contacts.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((c) {
          return c.name.toLowerCase().contains(query) ||
              (c.phone?.toLowerCase().contains(query) ?? false) ||
              (c.email?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _saveContacts() async {
    await _localStorageService.saveContacts(widget.userId, _contacts);
  }

  Future<void> _addContact() async {
    final result = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _contacts.add(result);
        _contacts.sort((a, b) => a.name.compareTo(b.name));
        _filteredContacts = _contacts;
      });
      await _saveContacts();
    }
  }

  Future<void> _editContact(Contact contact) async {
    final result = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditContactScreen(
          userId: widget.userId,
          contact: contact,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        final index = _contacts.indexWhere((c) => c.id == result.id);
        if (index != -1) {
          _contacts[index] = result;
          _contacts.sort((a, b) => a.name.compareTo(b.name));
          _onSearchChanged();
        }
      });
      await _saveContacts();
    }
  }

  Future<void> _deleteContact(Contact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
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
        _contacts.removeWhere((c) => c.id == contact.id);
        _onSearchChanged();
      });
      await _saveContacts();
    }
  }

  Future<void> _importFromPhone() async {
    // Check permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts permission denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get phone contacts
      final phoneContacts = await phone.ContactsService.getContacts();
      
      if (mounted) Navigator.pop(context); // Close loading

      if (phoneContacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No contacts found')),
          );
        }
        return;
      }

      // Show selection dialog
      final selected = await showDialog<List<phone.Contact>>(
        context: context,
        builder: (context) => _PhoneContactsDialog(contacts: phoneContacts.toList()),
      );

      if (selected == null || selected.isEmpty) return;

      // Convert and add
      int imported = 0;
      for (final phoneContact in selected) {
        final name = phoneContact.displayName ?? 'Unknown';
        
        // Check if already exists
        if (_contacts.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
          continue;
        }

        final newContact = Contact.create(
          userId: widget.userId,
          name: name,
          phone: phoneContact.phones?.isNotEmpty == true
              ? phoneContact.phones!.first.value
              : null,
          email: phoneContact.emails?.isNotEmpty == true
              ? phoneContact.emails!.first.value
              : null,
          source: ContactSource.phone,
        );

        _contacts.add(newContact);
        imported++;
      }

      if (imported > 0) {
        setState(() {
          _contacts.sort((a, b) => a.name.compareTo(b.name));
          _onSearchChanged();
        });
        await _saveContacts();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $imported contacts'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            icon: const Icon(Icons.phone_android),
            onPressed: _importFromPhone,
            tooltip: 'Import from Phone',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
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
                  child: _filteredContacts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        onPressed: _addContact,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            contact.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(contact.displayInfo),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.source == ContactSource.phone)
              const Icon(Icons.phone_android, size: 16, color: Colors.grey),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteContact(contact),
            ),
          ],
        ),
        onTap: () => _editContact(contact),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.person_off : Icons.search_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No contacts yet'
                : 'No contacts found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Add contacts to use in split bills'
                : 'Try a different search term',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (_searchQuery.isEmpty) ..[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addContact,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Contact'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _importFromPhone,
              icon: const Icon(Icons.phone_android),
              label: const Text('Import from Phone'),
            ),
          ],
        ],
      ),
    );
  }
}

// Add/Edit Contact Screen
class AddEditContactScreen extends StatefulWidget {
  final String userId;
  final Contact? contact;

  const AddEditContactScreen({
    super.key,
    required this.userId,
    this.contact,
  });

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameController.text = widget.contact!.name;
      _phoneController.text = widget.contact!.phone ?? '';
      _emailController.text = widget.contact!.email ?? '';
      _notesController.text = widget.contact!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final contact = widget.contact != null
        ? widget.contact!.copyWith(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            updatedAt: DateTime.now(),
          )
        : Contact.create(
            userId: widget.userId,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

    Navigator.pop(context, contact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.contact == null ? 'Add Contact' : 'Edit Contact'),
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
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Name',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'John Doe',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phone (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: '+91 98765 43210',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'john@example.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Roommate, College friend, etc.',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Phone Contacts Selection Dialog
class _PhoneContactsDialog extends StatefulWidget {
  final List<phone.Contact> contacts;

  const _PhoneContactsDialog({required this.contacts});

  @override
  State<_PhoneContactsDialog> createState() => _PhoneContactsDialogState();
}

class _PhoneContactsDialogState extends State<_PhoneContactsDialog> {
  final Set<phone.Contact> _selected = {};
  String _searchQuery = '';

  List<phone.Contact> get _filtered {
    if (_searchQuery.isEmpty) return widget.contacts;
    final query = _searchQuery.toLowerCase();
    return widget.contacts.where((c) {
      return (c.displayName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contacts'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final contact = _filtered[index];
                  final isSelected = _selected.contains(contact);
                  return CheckboxListTile(
                    title: Text(contact.displayName ?? 'Unknown'),
                    subtitle: contact.phones?.isNotEmpty == true
                        ? Text(contact.phones!.first.value ?? '')
                        : null,
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(contact);
                        } else {
                          _selected.remove(contact);
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: Text('Import (${_selected.length})'),
        ),
      ],
    );
  }
}
