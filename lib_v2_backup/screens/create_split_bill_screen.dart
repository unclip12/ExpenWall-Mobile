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
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late SplitBillService _splitBillService;
  late ContactService _contactService;

  SplitType _splitType = SplitType.equal;
  List<SplitBillItem> _items = [];
  List<Contact> _availableContacts = [];
  List<Contact> _selectedParticipants = [];
  String? _paidByContactId;

  // For custom/percentage splits
  Map<String, TextEditingController> _customControllers = {};
  Map<String, double> _customAmounts = {};
  Map<String, double> _percentages = {};

  bool _isLoading = true;
  bool _isSaving = false;

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
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final contacts = await _contactService.getContacts();
      setState(() {
        _availableContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addItem() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                setState(() {
                  _items.add(SplitBillItem(
                    name: nameController.text,
                    price: double.parse(priceController.text),
                    quantity: int.tryParse(quantityController.text) ?? 1,
                  ));
                  // Update amount if all items entered
                  final total = _items.fold(0.0, (sum, item) => sum + item.total);
                  _amountController.text = total.toStringAsFixed(2);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _selectParticipants() async {
    final groups = await _contactService.getGroups();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Participants'),
          content: SizedBox(
            width: double.maxFinite,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Contacts'),
                      Tab(text: 'Groups'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        // Contacts tab
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: _availableContacts.length,
                          itemBuilder: (context, index) {
                            final contact = _availableContacts[index];
                            final isSelected = _selectedParticipants
                                .any((p) => p.id == contact.id);

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(contact.name),
                              subtitle: contact.phone != null
                                  ? Text(contact.phone!)
                                  : null,
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    _selectedParticipants.add(contact);
                                  } else {
                                    _selectedParticipants
                                        .removeWhere((p) => p.id == contact.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        // Groups tab
                        ListView.builder(
                          shrinkWrap: true,
                          itemCount: groups.length,
                          itemBuilder: (context, index) {
                            final group = groups[index];

                            return ListTile(
                              leading: const Icon(Icons.group),
                              title: Text(group.name),
                              subtitle: Text('${group.memberCount} members'),
                              trailing: ElevatedButton(
                                onPressed: () async {
                                  final members = await _contactService
                                      .getGroupMembers(group.id);
                                  setDialogState(() {
                                    for (var member in members) {
                                      if (!_selectedParticipants
                                          .any((p) => p.id == member.id)) {
                                        _selectedParticipants.add(member);
                                      }
                                    }
                                  });
                                },
                                child: const Text('Add All'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );

    setState(() {
      // Initialize custom controllers for new participants
      _updateCustomControllers();
    });
  }

  void _updateCustomControllers() {
    // Clean up old controllers
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    _customControllers.clear();

    // Create new controllers for current participants
    for (var participant in _selectedParticipants) {
      _customControllers[participant.id] = TextEditingController();
    }
  }

  double _calculateEqualShare() {
    if (_selectedParticipants.isEmpty || _amountController.text.isEmpty) {
      return 0.0;
    }
    final total = double.tryParse(_amountController.text) ?? 0.0;
    return total / _selectedParticipants.length;
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select participants')),
      );
      return;
    }

    if (_paidByContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select who paid')),
      );
      return;
    }

    // Validate custom split
    if (_splitType == SplitType.custom) {
      for (var participant in _selectedParticipants) {
        final amount = double.tryParse(
            _customControllers[participant.id]?.text ?? '');
        if (amount == null || amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Enter valid amount for ${participant.name}')),
          );
          return;
        }
        _customAmounts[participant.id] = amount;
      }

      // Check if total matches
      final customTotal = _customAmounts.values.fold(0.0, (a, b) => a + b);
      final billTotal = double.parse(_amountController.text);
      if ((customTotal - billTotal).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Split total (₹${customTotal.toStringAsFixed(2)}) doesn\'t match bill total (₹${billTotal.toStringAsFixed(2)})'),
          ),
        );
        return;
      }
    }

    // Validate percentage split
    if (_splitType == SplitType.percentage) {
      for (var participant in _selectedParticipants) {
        final percentage = double.tryParse(
            _customControllers[participant.id]?.text ?? '');
        if (percentage == null || percentage <= 0 || percentage > 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Enter valid percentage for ${participant.name}')),
          );
          return;
        }
        _percentages[participant.id] = percentage;
      }

      // Check if total is 100
      final totalPercentage = _percentages.values.fold(0.0, (a, b) => a + b);
      if ((totalPercentage - 100.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Percentages must add up to 100% (currently ${totalPercentage.toStringAsFixed(1)}%)'),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await _splitBillService.createBill(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        totalAmount: double.parse(_amountController.text),
        items: _items,
        splitType: _splitType,
        participantContactIds: _selectedParticipants.map((p) => p.id).toList(),
        paidByContactId: _paidByContactId!,
        customAmounts: _splitType == SplitType.custom ? _customAmounts : null,
        percentages: _splitType == SplitType.percentage ? _percentages : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Split bill created!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  // Basic Info
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Title *',
                              prefixIcon: Icon(Icons.title),
                              hintText: 'Dinner at Restaurant',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v?.trim().isEmpty == true
                                ? 'Title required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              prefixIcon: Icon(Icons.notes),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            decoration: const InputDecoration(
                              labelText: 'Total Amount *',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            validator: (v) {
                              if (v?.trim().isEmpty == true) {
                                return 'Amount required';
                              }
                              final amount = double.tryParse(v!);
                              if (amount == null || amount <= 0) {
                                return 'Enter valid amount';
                              }
                              return null;
                            },
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
                                'Items (Optional)',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _addItem,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Item'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No items added',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ..._items.map((item) => ListTile(
                                dense: true,
                                title: Text(item.name),
                                subtitle: Text(
                                  '₹${item.price.toStringAsFixed(2)} × ${item.quantity}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₹${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20),
                                      onPressed: () {
                                        setState(() => _items.remove(item));
                                      },
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Participants
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Participants (${_selectedParticipants.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _selectParticipants,
                                icon: const Icon(Icons.person_add, size: 18),
                                label: const Text('Select'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedParticipants.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No participants selected',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ..._selectedParticipants.map((participant) {
                            return Chip(
                              avatar: CircleAvatar(
                                child:
                                    Text(participant.name[0].toUpperCase()),
                              ),
                              label: Text(participant.name),
                              onDeleted: () {
                                setState(() {
                                  _selectedParticipants.remove(participant);
                                  _customControllers[participant.id]?.dispose();
                                  _customControllers.remove(participant.id);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Split Type & Calculator
                  if (_selectedParticipants.isNotEmpty) ...[
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Split Type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<SplitType>(
                              segments: const [
                                ButtonSegment(
                                  value: SplitType.equal,
                                  label: Text('Equal'),
                                  icon: Icon(Icons.people),
                                ),
                                ButtonSegment(
                                  value: SplitType.custom,
                                  label: Text('Custom'),
                                  icon: Icon(Icons.edit),
                                ),
                                ButtonSegment(
                                  value: SplitType.percentage,
                                  label: Text('%'),
                                  icon: Icon(Icons.percent),
                                ),
                              ],
                              selected: {_splitType},
                              onSelectionChanged: (Set<SplitType> selected) {
                                setState(() => _splitType = selected.first);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Split calculator
                            if (_splitType == SplitType.equal) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(
                                'Each person pays: ₹${_calculateEqualShare().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ] else if (_splitType == SplitType.custom) ...[
                              const Divider(),
                              const Text('Enter amount for each person:'),
                              const SizedBox(height: 8),
                              ..._selectedParticipants.map((participant) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(participant.name),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _customControllers[
                                              participant.id],
                                          decoration: const InputDecoration(
                                            prefixText: '₹',
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ] else if (_splitType == SplitType.percentage) ...[
                              const Divider(),
                              const Text('Enter percentage for each person:'),
                              const SizedBox(height: 8),
                              ..._selectedParticipants.map((participant) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(participant.name),
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: _customControllers[
                                              participant.id],
                                          decoration: const InputDecoration(
                                            suffixText: '%',
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Who Paid
                    GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Who Paid?',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _paidByContactId,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.account_balance_wallet),
                                hintText: 'Select who paid',
                              ),
                              items: _selectedParticipants.map((contact) {
                                return DropdownMenuItem(
                                  value: contact.id,
                                  child: Text(contact.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _paidByContactId = value);
                              },
                              validator: (v) =>
                                  v == null ? 'Please select' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _createBill,
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Create Split Bill',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
