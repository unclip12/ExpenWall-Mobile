import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../models/recurring_rule.dart';
import '../screens/receipt_review_screen.dart';
import '../widgets/glass_card.dart';
import '../utils/category_icons.dart';
import '../utils/indian_currency_formatter.dart';
import '../services/local_storage_service.dart';
import '../services/recurring_bill_service.dart';
import '../services/item_recognition_service.dart';
import 'receipt_camera_screen.dart';

class AddTransactionScreenV2 extends StatefulWidget {
  final Function(Transaction) onSave;
  final Transaction? initialData;
  final String userId;

  const AddTransactionScreenV2({
    super.key,
    required this.onSave,
    this.initialData,
    required this.userId,
  });

  @override
  State<AddTransactionScreenV2> createState() => _AddTransactionScreenV2State();
}

class _AddTransactionScreenV2State extends State<AddTransactionScreenV2>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _merchantFocusNode = FocusNode();
  final _localStorageService = LocalStorageService();
  final _itemRecognitionService = ItemRecognitionService();
  late final RecurringBillService _recurringService;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  TransactionType _type = TransactionType.expense;
  Category _category = Category.other;
  String? _subcategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _paymentMethod = 'Cash';
  List<TransactionItem> _items = [];
  bool _isSubmitting = false;
  bool _showItemsForm = false;
  bool _showMerchantSuggestions = false;
  List<String> _merchantSuggestions = [];
  List<Transaction> _previousTransactions = [];
  RecurringRule? _matchingRecurringRule;
  
  String? _receiptImagePath;
  Map<String, dynamic>? _receiptData;
  bool _hasReceiptData = false;

  int? _editingItemIndex;
  final _itemNameController = TextEditingController();
  final _itemBrandController = TextEditingController();
  final _itemQuantityController = TextEditingController();
  final _itemPriceController = TextEditingController();
  final _itemNameFocusNode = FocusNode();
  bool _showItemSuggestions = false;
  List<ItemSuggestion> _itemSuggestions = [];

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringBillService(
      localStorage: _localStorageService,
      userId: widget.userId,
    );
    
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

    _loadPreviousTransactions();
    _merchantController.addListener(_onMerchantChanged);
    _merchantFocusNode.addListener(_onMerchantFocusChanged);
    _itemNameController.addListener(_onItemNameChanged);
    _itemNameFocusNode.addListener(_onItemNameFocusChanged);

    if (widget.initialData != null) {
      _merchantController.text = widget.initialData!.merchant;
      _amountController.text = widget.initialData!.amount.toString();
      _notesController.text = widget.initialData!.notes ?? '';
      _type = widget.initialData!.type;
      _category = widget.initialData!.category;
      _subcategory = widget.initialData!.subcategory;
      _selectedDate = widget.initialData!.date;
      _selectedTime = TimeOfDay.fromDateTime(widget.initialData!.date);
      _items = widget.initialData!.items ?? [];
      _receiptImagePath = widget.initialData!.receiptImagePath;
      _receiptData = widget.initialData!.receiptData;
      _hasReceiptData = _receiptImagePath != null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _merchantFocusNode.dispose();
    _itemNameController.dispose();
    _itemBrandController.dispose();
    _itemQuantityController.dispose();
    _itemPriceController.dispose();
    _itemNameFocusNode.dispose();
    super.dispose();
  }

  // NEW: Calculate total from all items
  double _calculateItemsTotal() {
    if (_items.isEmpty) return 0.0;
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // NEW: Auto-fill amount from items total
  void _autoFillFromItems() {
    final total = _calculateItemsTotal();
    setState(() {
      _amountController.text = total.toStringAsFixed(2);
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _loadPreviousTransactions() async {
    try {
      final transactions = await _localStorageService.loadTransactions(widget.userId);
      setState(() {
        _previousTransactions = transactions;
      });
    } catch (e) {
      print('Error loading previous transactions: $e');
    }
  }

  void _onMerchantChanged() {
    final query = _merchantController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showMerchantSuggestions = false;
        _merchantSuggestions = [];
        _matchingRecurringRule = null;
      });
      return;
    }

    _checkForRecurringRule(query);

    final allMerchants = _previousTransactions
        .map((t) => t.merchant)
        .toSet()
        .where((m) => m.toLowerCase().contains(query))
        .toList();

    allMerchants.sort((a, b) {
      final aCount = _previousTransactions.where((t) => t.merchant == a).length;
      final bCount = _previousTransactions.where((t) => t.merchant == b).length;
      return bCount.compareTo(aCount);
    });

    setState(() {
      _merchantSuggestions = allMerchants.take(5).toList();
      _showMerchantSuggestions = _merchantSuggestions.isNotEmpty;
    });

    if (_merchantSuggestions.isNotEmpty) {
      final exactMatch = _previousTransactions
          .where((t) => t.merchant.toLowerCase() == query)
          .toList();
      if (exactMatch.isNotEmpty) {
        final mostCommon = exactMatch.first;
        setState(() {
          _category = mostCommon.category;
          _subcategory = mostCommon.subcategory;
        });
      }
    }
  }

  void _onItemNameChanged() {
    final query = _itemNameController.text.trim();
    if (query.length < 2) {
      setState(() {
        _showItemSuggestions = false;
        _itemSuggestions = [];
      });
      return;
    }

    final suggestions = _itemRecognitionService.getSuggestions(query);
    
    setState(() {
      _itemSuggestions = suggestions.take(10).toList();
      _showItemSuggestions = _itemSuggestions.isNotEmpty;
    });
  }

  void _onItemNameFocusChanged() {
    if (!_itemNameFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showItemSuggestions = false;
          });
        }
      });
    }
  }

  void _selectItemSuggestion(ItemSuggestion match) {
    setState(() {
      _itemNameController.text = match.itemName;
      _showItemSuggestions = false;
      
      if (match.category.isNotEmpty) {
        try {
          _category = Category.values.firstWhere(
            (c) => c.label.toLowerCase() == match.category.toLowerCase(),
            orElse: () => _category,
          );
        } catch (e) {
          // Keep current category
        }
      }
      
      if (match.subcategory.isNotEmpty) {
        _subcategory = match.subcategory;
      }
    });
  }

  Future<void> _checkForRecurringRule(String merchantName) async {
    final matchingRule = await _recurringService.findMatchingRule(merchantName);
    if (matchingRule != null) {
      setState(() {
        _matchingRecurringRule = matchingRule;
      });
    } else {
      setState(() {
        _matchingRecurringRule = null;
      });
    }
  }

  void _onMerchantFocusChanged() {
    if (!_merchantFocusNode.hasFocus) {
      setState(() {
        _showMerchantSuggestions = false;
      });
    }
  }

  void _selectMerchant(String merchant) {
    _merchantController.text = merchant;
    setState(() {
      _showMerchantSuggestions = false;
    });

    final previousTx = _previousTransactions
        .where((t) => t.merchant == merchant)
        .toList();
    if (previousTx.isNotEmpty) {
      final mostRecent = previousTx.first;
      setState(() {
        _category = mostRecent.category;
        _subcategory = mostRecent.subcategory;
        _type = mostRecent.type;
      });
    }
  }

  Future<void> _openReceiptScanner() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptCameraScreen(
          userId: widget.userId,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['merchant'] != null) {
          _merchantController.text = result['merchant'];
        }

        if (result['amount'] != null) {
          _amountController.text = result['amount'].toString();
        }

        if (result['date'] != null) {
          _selectedDate = result['date'];
        }

        if (result['items'] != null) {
          final receiptItems = result['items'] as List<EditableReceiptItem>;
          _items = receiptItems.map((item) {
            return TransactionItem(
              name: item.name,
              price: item.price,
              quantity: item.quantity,
              brand: null,
            );
          }).toList();
        }

        _receiptImagePath = result['receiptImagePath'];
        _receiptData = result['receiptData'];
        _hasReceiptData = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Receipt data imported successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_matchingRecurringRule != null) {
      final isRecurringPayment = await _showRecurringRuleDialog();
      
      if (isRecurringPayment == null) return;
      
      if (isRecurringPayment) {
        await _linkToRecurringRule();
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _category,
        subcategory: _subcategory,
        type: _type,
        date: dateTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _items.isEmpty ? null : _items,
        currency: 'INR',
        receiptImagePath: _receiptImagePath,
        receiptData: _receiptData,
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

  Future<bool?> _showRecurringRuleDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.repeat,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Recurring Bill Detected'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have a recurring bill for:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _matchingRecurringRule!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    IndianCurrencyFormatter.format(_matchingRecurringRule!.amount),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _matchingRecurringRule!.getFrequencyText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Is this the same payment?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No, Different Payment'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('Yes, Same Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkToRecurringRule() async {
    setState(() => _isSubmitting = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final transaction = Transaction(
        id: widget.initialData?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.userId,
        merchant: _merchantController.text.trim(),
        amount: double.parse(_amountController.text),
        category: _category,
        subcategory: _subcategory,
        type: _type,
        date: dateTime,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _items.isEmpty ? null : _items,
        currency: 'INR',
        receiptImagePath: _receiptImagePath,
        receiptData: _receiptData,
      );

      await widget.onSave(transaction);
      await _recurringService.linkTransactionToRule(
        transaction.id,
        _matchingRecurringRule!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Linked to recurring bill'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
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
            )
          else
            IconButton(
              onPressed: _openReceiptScanner,
              icon: const Icon(Icons.document_scanner),
              tooltip: 'Scan Receipt',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          const SizedBox(width: 8),
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
                if (_hasReceiptData) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt Attached',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Data imported from scanned receipt',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
      // Items section with total display
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
                  'Total: ${IndianCurrencyFormatter.format(_calculateItemsTotal())}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _showItemsForm = true),
        ),
      ),
      const SizedBox(height: 16),

      // Merchant
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Merchant / Shop / Person',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openReceiptScanner,
                  icon: const Icon(Icons.document_scanner, size: 18),
                  label: const Text('Scan'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantController,
              focusNode: _merchantFocusNode,
              decoration: InputDecoration(
                hintText: 'DMart, Rapido, Coffee Shop...',
                prefixIcon: const Icon(Icons.storefront),
                suffixIcon: _matchingRecurringRule != null
                    ? Icon(
                        Icons.repeat,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : _merchantController.text.isNotEmpty
                        ? Icon(
                            Icons.auto_awesome,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
            ),
            if (_matchingRecurringRule != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Matches recurring bill: ${_matchingRecurringRule!.name}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_showMerchantSuggestions && _merchantSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: _merchantSuggestions.map((merchant) {
                    final txCount = _previousTransactions
                        .where((t) => t.merchant == merchant)
                        .length;
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(merchant),
                      subtitle: Text('Used $txCount ${txCount == 1 ? 'time' : 'times'}'),
                      onTap: () => _selectMerchant(merchant),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Payment Method
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.payment),
              ),
              items: ['Cash', 'Card', 'UPI', 'Wallet', 'Bank Transfer', 'Other']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _paymentMethod = val!),
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
                  child: _buildAnimatedTypeButton(
                    'Spent',
                    TransactionType.expense,
                    Icons.trending_up,
                    const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAnimatedTypeButton(
                    'Received',
                    TransactionType.income,
                    Icons.trending_down,
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
              decoration: const InputDecoration(
                prefixIcon: null,
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

      // Date & Time
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
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
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedTime.format(context),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Subcategory
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

      // Amount with auto-fill button
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (_items.isNotEmpty)
                  TextButton.icon(
                    onPressed: _autoFillFromItems,
                    icon: const Icon(Icons.calculate, size: 16),
                    label: const Text('Auto-fill', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
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
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Items total: ${IndianCurrencyFormatter.format(_calculateItemsTotal())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
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

  Widget _buildAnimatedTypeButton(
    String label,
    TransactionType type,
    IconData icon,
    Color color,
  ) {
    final isSelected = _type == type;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () => setState(() => _type = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: isSelected ? 1 : 0),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, -2 * value),
                    child: Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      size: 20 + (4 * value),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: isSelected ? 15 : 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      
      if (_editingItemIndex != null) ..._buildItemEditForm(),
      
      ..._items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildItemCard(index, item);
      }).toList(),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _startAddingItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    ];
  }

  List<Widget> _buildItemEditForm() {
    return [
      GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingItemIndex == _items.length ? 'Add New Item' : 'Edit Item',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _itemNameController,
              focusNode: _itemNameFocusNode,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'Start typing... (e.g., chicken)',
                prefixIcon: Icon(Icons.shopping_cart),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            if (_showItemSuggestions && _itemSuggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _itemSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _itemSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: Text(
                        suggestion.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text(suggestion.itemName),
                      subtitle: Text(
                        '${suggestion.category}${suggestion.subcategory.isNotEmpty ? ' • ${suggestion.subcategory}' : ''}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                        '${(suggestion.similarity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      onTap: () => _selectItemSuggestion(suggestion),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _itemBrandController,
              decoration: const InputDecoration(
                labelText: 'Brand (Optional)',
                prefixIcon: Icon(Icons.branding_watermark),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _itemQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _itemPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixText: '₹',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelEditingItem,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saveEditingItem,
                    child: const Text('Save Item'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  void _startAddingItem() {
    setState(() {
      _editingItemIndex = _items.length;
      _itemNameController.clear();
      _itemBrandController.clear();
      _itemQuantityController.text = '1';
      _itemPriceController.text = '';
    });
    _itemNameFocusNode.requestFocus();
  }

  void _startEditingItem(int index) {
    final item = _items[index];
    setState(() {
      _editingItemIndex = index;
      _itemNameController.text = item.name;
      _itemBrandController.text = item.brand ?? '';
      _itemQuantityController.text = item.quantity.toString();
      _itemPriceController.text = item.price.toString();
    });
  }

  void _cancelEditingItem() {
    setState(() {
      _editingItemIndex = null;
      _itemNameController.clear();
      _itemBrandController.clear();
      _itemQuantityController.clear();
      _itemPriceController.clear();
      _showItemSuggestions = false;
    });
  }

  void _saveEditingItem() {
    if (_itemNameController.text.trim().isEmpty ||
        _itemPriceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter item name and price')),
      );
      return;
    }

    final newItem = TransactionItem(
      name: _itemNameController.text.trim(),
      brand: _itemBrandController.text.trim().isEmpty
          ? null
          : _itemBrandController.text.trim(),
      quantity: int.tryParse(_itemQuantityController.text) ?? 1,
      price: double.tryParse(_itemPriceController.text) ?? 0,
    );

    setState(() {
      if (_editingItemIndex == _items.length) {
        _items.add(newItem);
      } else {
        _items[_editingItemIndex!] = newItem;
      }
      _cancelEditingItem();
    });
  }

  Widget _buildItemCard(int index, TransactionItem item) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.brand != null)
                  Text(
                    item.brand!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} x ${IndianCurrencyFormatter.format(item.price)} = ${IndianCurrencyFormatter.format(item.quantity * item.price)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _startEditingItem(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () => setState(() => _items.removeAt(index)),
          ),
        ],
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

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }
}
