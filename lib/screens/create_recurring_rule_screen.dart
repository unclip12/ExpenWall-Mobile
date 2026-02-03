import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/recurring_rule.dart';
import '../models/transaction.dart';
import '../services/recurring_bill_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class CreateRecurringRuleScreen extends StatefulWidget {
  final String userId;
  final RecurringRule? existingRule; // null for create, populated for edit

  const CreateRecurringRuleScreen({
    super.key,
    required this.userId,
    this.existingRule,
  });

  @override
  State<CreateRecurringRuleScreen> createState() => _CreateRecurringRuleScreenState();
}

class _CreateRecurringRuleScreenState extends State<CreateRecurringRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  late RecurringBillService _recurringService;

  // Form fields
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _frequencyValueController = TextEditingController(text: '1');

  Category _selectedCategory = Category.other;
  String? _selectedSubcategory;
  TransactionType _transactionType = TransactionType.expense;
  FrequencyUnit _frequencyUnit = FrequencyUnit.months;
  DateTime _startDate = DateTime.now();
  DateTime? _nextOccurrence;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 5, minute: 0);

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringBillService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );

    // Load existing rule data if editing
    if (widget.existingRule != null) {
      final rule = widget.existingRule!;
      _nameController.text = rule.name;
      _amountController.text = rule.amount.toString();
      _notesController.text = rule.notes ?? '';
      _frequencyValueController.text = rule.frequencyValue.toString();
      _selectedCategory = rule.category as Category;
      _selectedSubcategory = rule.subcategory;
      _transactionType = rule.type;
      _frequencyUnit = rule.frequencyUnit;
      _startDate = rule.startDate;
      _nextOccurrence = rule.nextOccurrence;
      _notificationTime = TimeOfDay(
        hour: rule.notificationHour,
        minute: rule.notificationMinute,
      );
    }

    // Calculate initial next occurrence
    _calculateNextOccurrence();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _frequencyValueController.dispose();
    super.dispose();
  }

  void _calculateNextOccurrence() {
    if (_frequencyValueController.text.isEmpty) return;

    final value = int.tryParse(_frequencyValueController.text) ?? 1;
    final calculated = RecurringRule.calculateNextOccurrence(
      _startDate,
      value,
      _frequencyUnit,
    );

    setState(() {
      _nextOccurrence = calculated;
    });
  }

  Future<void> _saveRule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final value = int.parse(_frequencyValueController.text);
      final amount = double.parse(_amountController.text);

      if (widget.existingRule == null) {
        // Create new rule
        final newRule = RecurringRule.create(
          userId: widget.userId,
          name: _nameController.text,
          amount: amount,
          category: _selectedCategory.label,
          subcategory: _selectedSubcategory,
          type: _transactionType,
          frequencyValue: value,
          frequencyUnit: _frequencyUnit,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          notificationHour: _notificationTime.hour,
          notificationMinute: _notificationTime.minute,
        );

        await _recurringService.createRule(newRule);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Recurring rule created!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Update existing rule
        final updatedRule = widget.existingRule!.copyWith(
          name: _nameController.text,
          amount: amount,
          category: _selectedCategory.label,
          subcategory: _selectedSubcategory,
          type: _transactionType,
          frequencyValue: value,
          frequencyUnit: _frequencyUnit,
          startDate: _startDate,
          nextOccurrence: _nextOccurrence,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          notificationHour: _notificationTime.hour,
          notificationMinute: _notificationTime.minute,
        );

        await _recurringService.updateRule(updatedRule);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Recurring rule updated!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteRule() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: const Text('Are you sure you want to delete this recurring rule?'),
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

    if (confirmed == true && widget.existingRule != null) {
      await _recurringService.deleteRule(widget.existingRule!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Rule deleted'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingRule != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Recurring Rule' : 'Add Recurring Rule'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteRule,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            GlassCard(
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Netflix Subscription',
                  prefixIcon: Icon(Icons.label),
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            GlassCard(
              child: TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: InputBorder.none,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Type (Expense/Income)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                    child: Text(
                      'Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: const Text('Expense'),
                          value: TransactionType.expense,
                          groupValue: _transactionType,
                          onChanged: (value) {
                            setState(() => _transactionType = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<TransactionType>(
                          title: const Text('Income'),
                          value: TransactionType.income,
                          groupValue: _transactionType,
                          onChanged: (value) {
                            setState(() => _transactionType = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Frequency
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Frequency',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Every', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _frequencyValueController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) => _calculateNextOccurrence(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final num = int.tryParse(value);
                              if (num == null || num < 1) {
                                return 'Min 1';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<FrequencyUnit>(
                            value: _frequencyUnit,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            items: FrequencyUnit.values.map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _frequencyUnit = value!);
                              _calculateNextOccurrence();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Start Date
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('MMM d, y').format(_startDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _startDate = date);
                    _calculateNextOccurrence();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Next Due Date (Auto-calculated with manual override)
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'Next Due Date',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _nextOccurrence != null
                          ? DateFormat('MMM d, y').format(_nextOccurrence!)
                          : 'Not calculated',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _nextOccurrence ?? _startDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          setState(() => _nextOccurrence = date);
                        }
                      },
                      child: const Text('Override'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Notification Time
            GlassCard(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Notification Time'),
                subtitle: Text(_notificationTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _notificationTime,
                  );
                  if (time != null) {
                    setState(() => _notificationTime = time);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            GlassCard(
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes...',
                  prefixIcon: Icon(Icons.note),
                  border: InputBorder.none,
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? 'Update Rule' : 'Create Rule',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
