import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';
import '../widgets/glass_card.dart';

class CreateContactScreen extends StatefulWidget {
  final String userId;
  final ContactService contactService;
  final Contact? existingContact;

  const CreateContactScreen({
    super.key,
    required this.userId,
    required this.contactService,
    this.existingContact,
  });

  @override
  State<CreateContactScreen> createState() => _CreateContactScreenState();
}

class _CreateContactScreenState extends State<CreateContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isSaving = false;

  bool get isEditing => widget.existingContact != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.existingContact!.name;
      _phoneController.text = widget.existingContact!.phone ?? '';
      _emailController.text = widget.existingContact!.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();
      final email = _emailController.text.trim();

      if (isEditing) {
        // Update existing
        final updated = widget.existingContact!.copyWith(
          name: name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
        );
        await widget.contactService.updateContact(updated);
      } else {
        // Create new
        await widget.contactService.createContact(
          name: name,
          phone: phone.isEmpty ? null : phone,
          email: email.isEmpty ? null : email,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Contact updated' : 'Contact added',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Contact' : 'Add Contact'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar preview
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _nameController.text.isNotEmpty
                      ? _nameController.text[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Name field (required)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter contact name',
                  prefixIcon: Icon(Icons.person),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Update avatar
              ),
            ),
            const SizedBox(height: 16),

            // Phone field (optional)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone),
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
                    if (digitsOnly.length < 10) {
                      return 'Enter a valid phone number';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Email field (optional)
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email address',
                  prefixIcon: Icon(Icons.email),
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),

            // Info text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '* Required field\nAt least one of phone or email is recommended',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveContact,
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Contact' : 'Add Contact',
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
}
