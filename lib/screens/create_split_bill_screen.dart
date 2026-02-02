import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/split_bill.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class CreateSplitBillScreen extends StatefulWidget {
  final String userId;

  const CreateSplitBillScreen({super.key, required this.userId});

  @override
  State<CreateSplitBillScreen> createState() => _CreateSplitBillScreenState();
}

class _CreateSplitBillScreenState extends State<CreateSplitBillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  late SplitBillService _splitBillService;
  late ContactService _contactService;

  List<SplitBillItem> _items = [];
  List<Contact> _allContacts = [];
  List<Group> _allGroups = [];
  Set<String> _selectedParticipantIds = {};
  String? _paidByContactId;
  SplitType _splitType = SplitType.equal;
  Map<String, double> _customAmounts = {};
  Map<String, double> _percentages = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _splitBillService = SplitBillService(
      localStorage: LocalStorageService(),
      contactService: ContactService(
        localStorage: LocalStorageService(),
        userId: widget.userId,
      ),
      userId: widget.userId,
    );
    _contactService = ContactService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadContacts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _contactService.getContacts();
      final groups = await _contactService.getGroups();
      setState(() {
        _allContacts = contacts;
        _allGroups = groups;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading contacts: $e')),
        );
      }
    }
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();
        final quantityController = TextEditingController(text: '1');
        final formKey = GlobalKey<FormState>();

        return AlertDialog(
          title: const Text('Add Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name *'),
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    prefixText: '₹',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Required';
                    final price = double.tryParse(v!);
                    if (price == null || price <= 0) return 'Invalid price';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final qty = int.tryParse(v ?? '1');
                    if (qty == null || qty < 1) return 'Must be at least 1';
                    return null;
                  },
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    _items.add(SplitBillItem(
                      name: nameController.text.trim(),
                      price: double.parse(priceController.text),
                      quantity: int.parse(quantityController.text),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _selectParticipants() {
    showDialog(
      context: context,
      builder: (context) {
        final selected = Set<String>.from(_selectedParticipantIds);
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Select Participants'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_allGroups.isNotEmpty) ..[
                    const Text(
                      'Groups',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    ...List<ListTile>.from(_allGroups.map((group) => ListTile(
                          title: Text(group.name),
                          subtitle: Text('${group.memberCount} members'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setDialogState(() {
                                selected.addAll(group.memberIds);
                              });
                            },
                            child: const Text('Add All'),
                          ),
                        ))),
                    const Divider(),
                  ],
                  const Text(
                    'Contacts',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (_allContacts.isEmpty)
                    const Text('No contacts available')
                  else
                    ...List<CheckboxListTile>.from(_allContacts.map((contact) =>
                        CheckboxListTile(
                          value: selected.contains(contact.id),
                          title: Text(contact.name),
                          subtitle:
                              contact.phone != null ? Text(contact.phone!) : null,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                selected.add(contact.id);
                              } else {
                                selected.remove(contact.id);
                              }
                            });
                          },
                        ))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedParticipantIds = selected;
                    // Reset split calculations if participants changed
                    _customAmounts.clear();
                    _percentages.clear();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _configureSplit() {
    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select participants first')),
      );
      return;
    }

    if (_totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _SplitCalculatorDialog(
        totalAmount: _totalAmount,
        participants: _allContacts
            .where((c) => _selectedParticipantIds.contains(c.id))
            .toList(),
        splitType: _splitType,
        customAmounts: _customAmounts,
        percentages: _percentages,
        onSave: (type, custom, percent) {
          setState(() {
            _splitType = type;
            _customAmounts = custom;
            _percentages = percent;
          });
        },
      ),
    );
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item')),
      );
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant')),
      );
      return;
    }

    if (_paidByContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select who paid')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _splitBillService.createBill(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        totalAmount: _totalAmount,
        items: _items,
        splitType: _splitType,
        participantContactIds: _selectedParticipantIds.toList(),
        paidByContactId: _paidByContactId!,
        customAmounts: _splitType == SplitType.custom ? _customAmounts : null,
        percentages: _splitType == SplitType.percentage ? _percentages : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Split bill created!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedParticipants = _allContacts
        .where((c) => _selectedParticipantIds.contains(c.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Split Bill'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Basic info
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Bill Title *',
                              hintText: 'e.g., Dinner at restaurant',
                            ),
                            validator: (v) =>
                                v?.trim().isEmpty == true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            decoration: const InputDecoration(
                              labelText: 'Description (optional)',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Items
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Items',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Item'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_items.isEmpty)
                            const Text('No items added', style: TextStyle(color: Colors.grey))
                          else
                            ...List<ListTile>.from(_items.asMap().entries.map((entry) {
                              final item = entry.value;
                              return ListTile(
                                dense: true,
                                title: Text(item.name),
                                subtitle: Text(
                                    '₹${item.price} × ${item.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _items.removeAt(entry.key);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            })),
                          if (_items.isNotEmpty) ..[
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '₹${_totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Participants
                  GlassCard(
                    child: ListTile(
                      title: const Text('Participants'),
                      subtitle: Text(
                        _selectedParticipantIds.isEmpty
                            ? 'No participants selected'
                            : '${_selectedParticipantIds.length} selected',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectParticipants,
                    ),
                  ),

                  if (selectedParticipants.isNotEmpty) ..[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: selectedParticipants
                          .map((c) => Chip(label: Text(c.name)))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Split configuration
                  GlassCard(
                    child: ListTile(
                      title: const Text('Split Type'),
                      subtitle: Text(_getSplitTypeText()),
                      trailing: const Icon(Icons.calculator),
                      onTap: _configureSplit,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Who paid
                  GlassCard(
                    child: Column(
                      children: [
                        const ListTile(
                          title: Text('Who Paid?'),
                        ),
                        ...selectedParticipants.map((contact) => RadioListTile<String>(
                              value: contact.id,
                              groupValue: _paidByContactId,
                              title: Text(contact.name),
                              onChanged: (value) {
                                setState(() => _paidByContactId = value);
                              },
                            )),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Create button
                  ElevatedButton(
                    onPressed: _createBill,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text(
                      'Create Split Bill',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getSplitTypeText() {
    switch (_splitType) {
      case SplitType.equal:
        return 'Split Equally';
      case SplitType.custom:
        return 'Custom Amounts';
      case SplitType.percentage:
        return 'Split by Percentage';
    }
  }
}

// Continuing in next file due to size...
