import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/contact.dart';
import '../models/group.dart';
import '../models/split_bill.dart';
import '../services/contact_service.dart';
import '../services/split_bill_service.dart';
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
  
  late ContactService _contactService;
  late SplitBillService _splitBillService;
  
  List<Contact> _allContacts = [];
  List<Group> _allGroups = [];
  List<SplitBillItem> _items = [];
  List<String> _selectedParticipantIds = [];
  String? _paidByContactId;
  SplitType _splitType = SplitType.equal;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // For custom split
  Map<String, TextEditingController> _customAmountControllers = {};
  
  // For percentage split
  Map<String, TextEditingController> _percentageControllers = {};

  @override
  void initState() {
    super.initState();
    _contactService = ContactService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _splitBillService = SplitBillService(
      localStorage: LocalStorageService(),
      contactService: _contactService,
      userId: widget.userId,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allContacts = await _contactService.getContacts();
      _allGroups = await _contactService.getGroups();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (var controller in _customAmountControllers.values) {
      controller.dispose();
    }
    for (var controller in _percentageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.total);
  }

  Map<String, double> _getCalculatedSplits() {
    if (_selectedParticipantIds.isEmpty) return {};

    switch (_splitType) {
      case SplitType.equal:
        final amountPerPerson = _totalAmount / _selectedParticipantIds.length;
        return {for (var id in _selectedParticipantIds) id: amountPerPerson};

      case SplitType.custom:
        return {
          for (var id in _selectedParticipantIds)
            id: double.tryParse(_customAmountControllers[id]?.text ?? '0') ?? 0.0
        };

      case SplitType.percentage:
        return {
          for (var id in _selectedParticipantIds)
            id: (_totalAmount *
                (double.tryParse(_percentageControllers[id]?.text ?? '0') ?? 0.0)) /
                100.0
        };
    }
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    if (_selectedParticipantIds.isEmpty) {
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

    // Validate split totals
    final splits = _getCalculatedSplits();
    final splitTotal = splits.values.fold(0.0, (a, b) => a + b);
    if ((splitTotal - _totalAmount).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Split total (₹${splitTotal.toStringAsFixed(2)}) doesn\'t match bill total (₹${_totalAmount.toStringAsFixed(2)})',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      Map<String, double>? customAmounts;
      Map<String, double>? percentages;

      if (_splitType == SplitType.custom) {
        customAmounts = splits;
      } else if (_splitType == SplitType.percentage) {
        percentages = {
          for (var id in _selectedParticipantIds)
            id: double.tryParse(_percentageControllers[id]?.text ?? '0') ?? 0.0
        };
      }

      await _splitBillService.createBill(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        totalAmount: _totalAmount,
        items: _items,
        splitType: _splitType,
        participantContactIds: _selectedParticipantIds,
        paidByContactId: _paidByContactId!,
        customAmounts: customAmounts,
        percentages: percentages,
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
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        existingItem: _items[index],
        onAdd: (item) {
          setState(() => _items[index] = item);
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Split Bill'),
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
                      _buildBasicInfo(),
                      const SizedBox(height: 16),
                      _buildItemsSection(),
                      const SizedBox(height: 16),
                      _buildParticipantsSection(),
                      const SizedBox(height: 16),
                      _buildSplitTypeSection(),
                      const SizedBox(height: 16),
                      _buildPreview(),
                      const SizedBox(height: 24),
                      _buildSaveButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBasicInfo() {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Bill Title *',
              hintText: 'e.g., Dinner at Pizza Hut',
              border: InputBorder.none,
            ),
            validator: (v) =>
                v?.trim().isEmpty ?? true ? 'Title required' : null,
          ),
          const Divider(),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: InputBorder.none,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items (₹${_totalAmount.toStringAsFixed(2)})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ],
        ),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No items added yet',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(
                  item.quantity > 1
                      ? '₹${item.price} × ${item.quantity}'
                      : '₹${item.price}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editItem(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildParticipantsSection() {
    // Simplified - will show dialog to select
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants (${_selectedParticipantIds.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people),
                title: Text(
                  _selectedParticipantIds.isEmpty
                      ? 'Select participants'
                      : '${_selectedParticipantIds.length} selected',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (context) => _SelectParticipantsDialog(
                      allContacts: _allContacts,
                      allGroups: _allGroups,
                      selectedIds: _selectedParticipantIds,
                      contactService: _contactService,
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedParticipantIds = result;
                      // Reset paid by if not in participants
                      if (_paidByContactId != null &&
                          !_selectedParticipantIds.contains(_paidByContactId)) {
                        _paidByContactId = null;
                      }
                    });
                  }
                },
              ),
              if (_selectedParticipantIds.isNotEmpty) ..[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.payment),
                  title: Text(_paidByContactId == null
                      ? 'Who paid?'
                      : _allContacts
                              .firstWhere((c) => c.id == _paidByContactId)
                              .name +
                          ' paid'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final result = await showDialog<String>(
                      context: context,
                      builder: (context) => SimpleDialog(
                        title: const Text('Who paid?'),
                        children: _selectedParticipantIds.map((id) {
                          final contact =
                              _allContacts.firstWhere((c) => c.id == id);
                          return SimpleDialogOption(
                            onPressed: () => Navigator.pop(context, id),
                            child: Text(contact.name),
                          );
                        }).toList(),
                      ),
                    );
                    if (result != null) {
                      setState(() => _paidByContactId = result);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSplitTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Type',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: SegmentedButton<SplitType>(
            segments: const [
              ButtonSegment(
                value: SplitType.equal,
                label: Text('Equal'),
                icon: Icon(Icons.people, size: 16),
              ),
              ButtonSegment(
                value: SplitType.custom,
                label: Text('Custom'),
                icon: Icon(Icons.edit, size: 16),
              ),
              ButtonSegment(
                value: SplitType.percentage,
                label: Text('%'),
                icon: Icon(Icons.percent, size: 16),
              ),
            ],
            selected: {_splitType},
            onSelectionChanged: (Set<SplitType> selected) {
              setState(() => _splitType = selected.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_selectedParticipantIds.isEmpty || _totalAmount == 0) {
      return const SizedBox.shrink();
    }

    final splits = _getCalculatedSplits();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Split Preview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ..._selectedParticipantIds.map((id) {
          final contact = _allContacts.firstWhere((c) => c.id == id);
          final amount = splits[id] ?? 0.0;

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text(contact.name)),
                if (_splitType == SplitType.custom) ..[
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: _customAmountControllers.putIfAbsent(
                        id,
                        () => TextEditingController(),
                      ),
                      decoration: const InputDecoration(
                        prefix: Text('₹'),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ] else if (_splitType == SplitType.percentage) ..[
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: _percentageControllers.putIfAbsent(
                        id,
                        () => TextEditingController(),
                      ),
                      decoration: const InputDecoration(
                        suffix: Text('%'),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('₹${amount.toStringAsFixed(2)}'),
                ] else
                  Text(
                    '₹${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveBill,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isSaving
          ? const CircularProgressIndicator()
          : const Text('Create Split Bill', style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildNoContactsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts_outlined, size: 80),
          const SizedBox(height: 16),
          const Text('No contacts yet'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add Contacts First'),
          ),
        ],
      ),
    );
  }
}

// Add Item Dialog
class _AddItemDialog extends StatefulWidget {
  final SplitBillItem? existingItem;
  final Function(SplitBillItem) onAdd;

  const _AddItemDialog({this.existingItem, required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _nameController.text = widget.existingItem!.name;
      _priceController.text = widget.existingItem!.price.toString();
      _quantityController.text = widget.existingItem!.quantity.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem == null ? 'Add Item' : 'Edit Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _quantityController,
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
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text) ?? 0.0;
            final quantity = int.tryParse(_quantityController.text) ?? 1;

            if (name.isNotEmpty && price > 0) {
              widget.onAdd(SplitBillItem(
                name: name,
                price: price,
                quantity: quantity,
              ));
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

// Select Participants Dialog
class _SelectParticipantsDialog extends StatefulWidget {
  final List<Contact> allContacts;
  final List<Group> allGroups;
  final List<String> selectedIds;
  final ContactService contactService;

  const _SelectParticipantsDialog({
    required this.allContacts,
    required this.allGroups,
    required this.selectedIds,
    required this.contactService,
  });

  @override
  State<_SelectParticipantsDialog> createState() =>
      _SelectParticipantsDialogState();
}

class _SelectParticipantsDialogState extends State<_SelectParticipantsDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Participants'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: [
            if (widget.allGroups.isNotEmpty) ..[
              const Text('Groups', style: TextStyle(fontWeight: FontWeight.bold)),
              ...widget.allGroups.map((group) {
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.memberCount} members'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        for (var id in group.memberIds) {
                          if (!_selected.contains(id)) {
                            _selected.add(id);
                          }
                        }
                      });
                    },
                    child: const Text('Add All'),
                  ),
                );
              }).toList(),
              const Divider(),
            ],
            const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.allContacts.map((contact) {
              final isSelected = _selected.contains(contact.id);
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selected.add(contact.id);
                    } else {
                      _selected.remove(contact.id);
                    }
                  });
                },
                title: Text(contact.name),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Select (${_selected.length})'),
        ),
      ],
    );
  }
}
