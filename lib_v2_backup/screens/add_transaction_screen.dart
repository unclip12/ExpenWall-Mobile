import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../widgets/glass_card.dart';
import '../utils/category_icons.dart';

class AddTransactionScreen extends StatefulWidget {
  final Function(Transaction) onSave;
  final Transaction? initialData;

  const AddTransactionScreen({
    super.key,
    required this.onSave,
    this.initialData,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TransactionType _type = TransactionType.expense;
  Category _category = Category.other;
  String? _subcategory;
  DateTime _selectedDate = DateTime.now();
  List<TransactionItem> _items = [];
  bool _isSubmitting = false;
  bool _showItemsForm = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();

    if (widget.initialData != null) {
      _merchantController.text = widget.initialData!.merchant;
      _amountController.text = widget.initialData!.amount.toString();
      _notesController.text = widget.initialData!.notes ?? '';
      _type = widget.initialData!.type;
      _category = widget.initialData!.category;
      _subcategory = widget.initialData!.subcategory;
      _selectedDate = widget.initialData!.date;
      _items = widget.initialData!.items ?? [];
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final transaction = Transaction(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _category,
        subcategory: _subcategory,
        type: _type,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _items.isEmpty ? null : _items,
        currency: 'INR',
      );

      await widget.onSave(transaction);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? 'New Transaction' : 'Edit Transaction'),
        actions: [
          if (_showItemsForm)
            TextButton.icon(
              onPressed: () => setState(() => _showItemsForm = false),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (!_showItemsForm) ..._buildMainForm() else ..._buildItemsForm(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  List<Widget> _buildMainForm() {
    return [
      // Merchant
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Merchant / Shop / Person',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantController,
              decoration: InputDecoration(
                hintText: 'DMart, Rapido, Coffee Shop...',
                prefixIcon: const Icon(Icons.storefront),
                suffixIcon: Icon(
                  Icons.auto_awesome,
                  color: _merchantController.text.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Amount
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                hintText: '0.00',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v?.trim().isEmpty == true) return 'Required';
                if (double.tryParse(v!) == null || double.parse(v) <= 0) {
                  return 'Invalid amount';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Type
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    'Expense',
                    TransactionType.expense,
                    Icons.arrow_upward,
                    const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    'Income',
                    TransactionType.income,
                    Icons.arrow_downward,
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Category
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category>(
              value: _category,
              decoration: InputDecoration(
                prefixIcon: Text(
                  CategoryIcons.getIcon(_category),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              items: Category.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(CategoryIcons.getIcon(cat),
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text(cat.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _category = val!),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Subcategory (optional)
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subcategory (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _subcategory,
              decoration: const InputDecoration(
                hintText: 'e.g., Breakfast, Taxi, Movie',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (v) => _subcategory = v.trim().isEmpty ? null : v.trim(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Date
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Items button
      GlassCard(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(
            _items.isEmpty ? 'Add Items (Optional)' : '${_items.length} items added',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: _items.isNotEmpty
              ? Text(
                  'Total: ₹${_items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}',
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _showItemsForm = true),
        ),
      ),
      const SizedBox(height: 16),

      // Notes
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
                hintText: 'Any additional details...',
                prefixIcon: Icon(Icons.note_outlined),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildItemsForm() {
    return [
      const Text(
        'Transaction Items',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        'Add individual items from this purchase',
        style: TextStyle(color: Colors.grey[600]),
      ),
      const SizedBox(height: 20),
      ..._items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildItemCard(index, item);
      }).toList(),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    ];
  }

  Widget _buildItemCard(int index, TransactionItem item) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.name,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    isDense: true,
                  ),
                  onChanged: (v) => _items[index] = TransactionItem(
                    name: v,
                    price: item.price,
                    quantity: item.quantity,
                    brand: item.brand,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.brand,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    isDense: true,
                  ),
                  onChanged: (v) => _items[index] = TransactionItem(
                    name: item.name,
                    price: item.price,
                    quantity: item.quantity,
                    brand: v.isEmpty ? null : v,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() => _items.removeAt(index)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _items[index] = TransactionItem(
                    name: item.name,
                    price: item.price,
                    quantity: int.tryParse(v) ?? 1,
                    brand: item.brand,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item.price.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixText: '₹',
                    isDense: true,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) => _items[index] = TransactionItem(
                    name: item.name,
                    price: double.tryParse(v) ?? 0,
                    quantity: item.quantity,
                    brand: item.brand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
      String label, TransactionType type, IconData icon, Color color) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : null,
          color: isSelected ? null : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    setState(() {
      _items.add(TransactionItem(
        name: '',
        price: 0,
        quantity: 1,
      ));
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }
}
