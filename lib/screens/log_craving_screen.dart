import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/craving.dart';
import '../models/transaction.dart';
import '../services/craving_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_input_field.dart';

class LogCravingScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onSaved;

  const LogCravingScreen({
    super.key,
    required this.userId,
    this.onSaved,
  });

  @override
  State<LogCravingScreen> createState() => _LogCravingScreenState();
}

class _LogCravingScreenState extends State<LogCravingScreen> with SingleTickerProviderStateMixin {
  final CravingService _cravingService = CravingService();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  
  CravingStatus? _selectedStatus;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _merchantController = TextEditingController();
  final _merchantAreaController = TextEditingController();
  final _notesController = TextEditingController();
  
  Category? _selectedCategory;
  final List<CravingItem> _items = [];
  double _totalAmount = 0.0;
  bool _isLoading = false;

  // Common merchant names
  final List<String> _merchantSuggestions = [
    'Zomato',
    'Swiggy',
    'Uber Eats',
    'Amazon',
    'Flipkart',
    'Local Restaurant',
    'Street Vendor',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _merchantController.dispose();
    _merchantAreaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() {
            _items.add(item);
            _calculateTotal();
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _totalAmount = _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> _saveCraving() async {
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select whether you resisted or gave in')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedStatus == CravingStatus.gaveIn && _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final craving = Craving(
        id: '',
        userId: widget.userId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        status: _selectedStatus!,
        timestamp: DateTime.now(),
        items: _selectedStatus == CravingStatus.gaveIn ? _items : [],
        merchant: _selectedStatus == CravingStatus.gaveIn && _merchantController.text.trim().isNotEmpty
            ? _merchantController.text.trim()
            : null,
        merchantArea: _selectedStatus == CravingStatus.gaveIn && _merchantAreaController.text.trim().isNotEmpty
            ? _merchantAreaController.text.trim()
            : null,
        totalAmount: _selectedStatus == CravingStatus.gaveIn ? _totalAmount : 0.0,
        category: _selectedCategory,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await _cravingService.addCraving(craving);

      if (mounted) {
        // Show success animation
        _showSuccessAnimation();
        
        // Call callback
        widget.onSaved?.call();
        
        // Close after animation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessAnimation() {
    final isResisted = _selectedStatus == CravingStatus.resisted;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: isResisted ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isResisted ? Icons.check_circle : Icons.restaurant,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isResisted ? 'Great Job! 💪' : 'Logged! 😋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isResisted && _totalAmount > 0)
                      Text(
                        'Saved ₹${_totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Log Craving',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Status Selection
                  const Text(
                    'Did you resist or give in?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusButton(
                          CravingStatus.resisted,
                          '💪 Resisted',
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusButton(
                          CravingStatus.gaveIn,
                          '😋 Gave In',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Craving Name
                  GlassInputField(
                    controller: _nameController,
                    label: 'What did you crave?',
                    hintText: 'e.g., Ice cream, Biryani, Pizza',
                    prefixIcon: Icons.restaurant_menu,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter what you craved';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  GlassInputField(
                    controller: _descriptionController,
                    label: 'Description (optional)',
                    hintText: 'Any details about the craving',
                    prefixIcon: Icons.description,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  GlassInputField(
                    type: GlassInputType.dropdown,
                    label: 'Category (optional)',
                    prefixIcon: Icons.category,
                    dropdownValue: _selectedCategory?.label,
                    dropdownItems: Category.values.map((c) => c.label).toList(),
                    onDropdownChanged: (value) {
                      setState(() {
                        _selectedCategory = Category.values.firstWhere(
                          (c) => c.label == value,
                          orElse: () => Category.other,
                        );
                      });
                    },
                  ),

                  // Gave In Details
                  if (_selectedStatus == CravingStatus.gaveIn) ...<Widget>[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Merchant
                    GlassInputField(
                      controller: _merchantController,
                      label: 'Merchant',
                      hintText: 'Where did you buy from?',
                      prefixIcon: Icons.store,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _merchantSuggestions.map((merchant) {
                        return ChoiceChip(
                          label: Text(merchant),
                          selected: _merchantController.text == merchant,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _merchantController.text = merchant;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Merchant Area
                    GlassInputField(
                      controller: _merchantAreaController,
                      label: 'Location/Area (optional)',
                      hintText: 'e.g., MG Road, Koramangala',
                      prefixIcon: Icons.location_on,
                    ),
                    const SizedBox(height: 24),

                    // Items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Item'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_items.isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No items added yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_items.length, (index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                if (item.emoji != null)
                                  Text('${item.emoji} ', style: const TextStyle(fontSize: 20)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}x @ ₹${item.pricePerUnit.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeItem(index),
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    if (_items.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 12),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${_totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 24),

                  // Notes
                  GlassInputField(
                    controller: _notesController,
                    label: 'Notes (optional)',
                    hintText: 'Any additional notes',
                    prefixIcon: Icons.note,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  // Save Button
                  GlassButton(
                    onPressed: _isLoading ? null : _saveCraving,
                    style: GlassButtonStyle.button,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Craving'),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(CravingStatus status, String label, Color color) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(CravingItem) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _emojiController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    final item = CravingItem(
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      pricePerUnit: double.parse(_priceController.text),
      emoji: _emojiController.text.trim().isEmpty ? null : _emojiController.text.trim(),
    );

    widget.onAdd(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  hintText: 'e.g., Ice cream',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji (optional)',
                  hintText: '🍦',
                ),
                maxLength: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null || int.parse(value) < 1) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price per unit',
                        prefixText: '₹',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
          onPressed: _saveItem,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
