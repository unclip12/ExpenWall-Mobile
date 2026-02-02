import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/receipt_ocr_service.dart';
import '../services/item_recognition_service.dart';
import '../widgets/glass_card.dart';

/// Screen for reviewing and editing OCR results from receipt
class ReceiptReviewScreen extends StatefulWidget {
  final String imagePath;
  final String userId;

  const ReceiptReviewScreen({
    Key? key,
    required this.imagePath,
    required this.userId,
  }) : super(key: key);

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final ReceiptOCRService _ocrService = ReceiptOCRService();
  final ItemRecognitionService _itemRecognizer = ItemRecognitionService();
  
  ExtractedReceipt? _receipt;
  bool _isProcessing = true;
  String? _errorMessage;

  // Controllers for editable fields
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime? _selectedDate;

  // Image transformation
  double _imageScale = 1.0;
  int _imageRotation = 0; // 0, 90, 180, 270

  // Editable items list
  List<EditableReceiptItem> _editableItems = [];

  // Merchant suggestions
  List<ItemSuggestion> _merchantSuggestions = [];
  bool _showMerchantSuggestions = false;

  // Validation
  bool _hasValidationError = false;
  String _validationMessage = '';

  @override
  void initState() {
    super.initState();
    _processReceipt();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Process receipt image with OCR
  Future<void> _processReceipt() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final receipt = await _ocrService.scanReceipt(widget.imagePath);
      setState(() {
        _receipt = receipt;
        _isProcessing = false;

        // Initialize editable fields
        _merchantController.text = receipt.merchantName ?? '';
        _amountController.text =
            receipt.totalAmount?.toStringAsFixed(2) ?? '';
        _selectedDate = receipt.date;

        // Convert items to editable format
        _editableItems = receipt.items
            .map((item) => EditableReceiptItem(
                  name: item.name,
                  price: item.price,
                  quantity: item.quantity,
                  category: item.category,
                  subcategory: item.subcategory,
                ))
            .toList();

        _validateData();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process receipt: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// Validate total amount vs items total
  void _validateData() {
    if (_editableItems.isEmpty) {
      setState(() {
        _hasValidationError = false;
        _validationMessage = '';
      });
      return;
    }

    final itemsTotal = _editableItems.fold<double>(
        0.0, (sum, item) => sum + (item.price * item.quantity));
    final enteredTotal = double.tryParse(_amountController.text) ?? 0.0;

    final difference = (enteredTotal - itemsTotal).abs();

    if (difference > 0.01) {
      // Allow 1 paisa tolerance
      setState(() {
        _hasValidationError = true;
        _validationMessage =
            'Amount mismatch: Total ₹${enteredTotal.toStringAsFixed(2)} != Items ₹${itemsTotal.toStringAsFixed(2)}';
      });
    } else {
      setState(() {
        _hasValidationError = false;
        _validationMessage = '';
      });
    }
  }

  /// Search merchant suggestions
  void _searchMerchantSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _merchantSuggestions = [];
        _showMerchantSuggestions = false;
      });
      return;
    }

    final suggestions = _itemRecognizer.getSuggestions(query, limit: 5);
    setState(() {
      _merchantSuggestions = suggestions;
      _showMerchantSuggestions = suggestions.isNotEmpty;
    });
  }

  /// Select merchant suggestion
  void _selectMerchantSuggestion(String merchant) {
    setState(() {
      _merchantController.text = merchant;
      _showMerchantSuggestions = false;
      _merchantSuggestions = [];
    });
  }

  /// Pick date
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              surface: Colors.grey[850]!,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Add new item
  void _addNewItem() {
    setState(() {
      _editableItems.add(EditableReceiptItem(
        name: '',
        price: 0.0,
        quantity: 1,
        category: null,
        subcategory: null,
      ));
    });
    _validateData();
  }

  /// Edit item
  Future<void> _editItem(int index) async {
    final item = _editableItems[index];
    final result = await showDialog<EditableReceiptItem>(
      context: context,
      builder: (context) => _ItemEditDialog(
        item: item,
        itemRecognizer: _itemRecognizer,
      ),
    );

    if (result != null) {
      setState(() {
        _editableItems[index] = result;
        _validateData();
      });
    }
  }

  /// Delete item
  void _deleteItem(int index) {
    setState(() {
      _editableItems.removeAt(index);
      _validateData();
    });
  }

  /// Rotate image
  void _rotateImage() {
    setState(() {
      _imageRotation = (_imageRotation + 90) % 360;
    });
  }

  /// Zoom in
  void _zoomIn() {
    setState(() {
      _imageScale = math.min(_imageScale + 0.25, 3.0);
    });
  }

  /// Zoom out
  void _zoomOut() {
    setState(() {
      _imageScale = math.max(_imageScale - 0.25, 0.5);
    });
  }

  /// Reset zoom
  void _resetZoom() {
    setState(() {
      _imageScale = 1.0;
    });
  }

  /// Save receipt data and create transaction
  Future<void> _saveReceipt() async {
    if (_receipt == null) return;

    // Validate required fields
    if (_merchantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Merchant name is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_amountController.text.isEmpty ||
        (double.tryParse(_amountController.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Valid amount is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Date is required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog if there's validation error
    if (_hasValidationError) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[850],
          title: const Text(
            'Amount Mismatch',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            _validationMessage +
                '\n\nDo you want to save anyway?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    // TODO: Integrate with transaction creation (Phase 5)
    // Prepare data structure
    final receiptData = {
      'merchant': _merchantController.text,
      'amount': double.parse(_amountController.text),
      'date': _selectedDate!.toIso8601String(),
      'items': _editableItems
          .map((item) => {
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'category': item.category,
                'subcategory': item.subcategory,
              })
          .toList(),
      'imagePath': widget.imagePath,
      'confidence': _receipt!.confidence,
    };

    print('Receipt data ready for Phase 5: $receiptData');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Receipt saved! (Transaction creation in Phase 5)'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Return to previous screen
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Review & Edit Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isProcessing && _receipt != null)
            IconButton(
              onPressed: _saveReceipt,
              icon: const Icon(Icons.check_circle),
              tooltip: 'Save',
              color: Colors.green,
            ),
        ],
      ),
      body: _isProcessing
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildReviewView(),
    );
  }

  /// Build loading view
  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing receipt...',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 8),
          Text(
            '🔍 Extracting text and data',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build error view
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _processReceipt,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build review view with OCR results
  Widget _buildReviewView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt image preview with controls
          _buildImagePreviewWithControls(),
          const SizedBox(height: 16),

          // Confidence indicator
          _buildConfidenceIndicator(),
          const SizedBox(height: 16),

          // Validation warning
          if (_hasValidationError) _buildValidationWarning(),
          if (_hasValidationError) const SizedBox(height: 16),

          // Editable extracted data
          _buildEditableData(),
          const SizedBox(height: 16),

          // Items list with edit/delete
          _buildEditableItemsList(),
          const SizedBox(height: 16),

          // Raw text (collapsible)
          _buildRawTextSection(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Build image preview with zoom and rotate controls
  Widget _buildImagePreviewWithControls() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Receipt Image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.zoom_out, color: Colors.white70),
                      onPressed: _zoomOut,
                      tooltip: 'Zoom Out',
                    ),
                    Text(
                      '${(_imageScale * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: const Icon(Icons.zoom_in, color: Colors.white70),
                      onPressed: _zoomIn,
                      tooltip: 'Zoom In',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _resetZoom,
                      tooltip: 'Reset',
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.rotate_right, color: Colors.white70),
                      onPressed: _rotateImage,
                      tooltip: 'Rotate 90°',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    _imageScale = math.max(0.5, math.min(3.0, _imageScale * details.scale));
                  });
                },
                child: Transform.rotate(
                  angle: _imageRotation * math.pi / 180,
                  child: Transform.scale(
                    scale: _imageScale,
                    child: Image.file(
                      File(widget.imagePath),
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '💡 Pinch to zoom, tap rotate button to turn',
              style: TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build confidence indicator
  Widget _buildConfidenceIndicator() {
    final confidence = _receipt!.confidence;
    final color = confidence > 0.7
        ? Colors.green
        : confidence > 0.4
            ? Colors.orange
            : Colors.red;
    final label = confidence > 0.7
        ? 'High'
        : confidence > 0.4
            ? 'Medium'
            : 'Low';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.analytics_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Extraction Confidence',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${(confidence * 100).toStringAsFixed(0)}%)',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Center(
                child: Text(
                  '${(confidence * 100).toInt()}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build validation warning
  Widget _buildValidationWarning() {
    return GlassCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _validationMessage,
                style: const TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build editable data fields
  Widget _buildEditableData() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Extracted Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Merchant (with auto-suggestions)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Merchant',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _merchantController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter merchant name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: const Icon(Icons.edit, color: Colors.white54),
                  ),
                  onChanged: _searchMerchantSuggestions,
                ),
                if (_showMerchantSuggestions) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _merchantSuggestions
                          .map((suggestion) => ListTile(
                                dense: true,
                                title: Text(
                                  suggestion.itemName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Text(
                                  '${suggestion.category} > ${suggestion.subcategory}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 11),
                                ),
                                onTap: () => _selectMerchantSuggestion(
                                    suggestion.itemName),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),

            const Divider(color: Colors.white24, height: 32),

            // Date (with picker)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Date',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _selectedDate != null
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24, height: 32),

            // Amount (editable)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    suffixIcon: const Icon(Icons.edit, color: Colors.white54),
                  ),
                  onChanged: (value) => _validateData(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build editable items list
  Widget _buildEditableItemsList() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items (${_editableItems.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addNewItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_editableItems.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 48, color: Colors.white38),
                      const SizedBox(height: 8),
                      const Text(
                        'No items detected\nTap "Add Item" to add manually',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._editableItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Dismissible(
                  key: Key('item_$index'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteItem(index),
                  child: InkWell(
                    onTap: () => _editItem(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name.isEmpty
                                      ? '(Tap to edit)'
                                      : item.name,
                                  style: TextStyle(
                                    color: item.name.isEmpty
                                        ? Colors.white54
                                        : Colors.white,
                                    fontSize: 14,
                                    fontStyle: item.name.isEmpty
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                  ),
                                ),
                                if (item.category != null)
                                  Text(
                                    '${item.category}${item.subcategory != null ? ' > ${item.subcategory}' : ''}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                if (item.quantity > 1)
                                  Text(
                                    'Qty: ${item.quantity}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            if (_editableItems.isNotEmpty) ...[
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${_editableItems.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build raw text section (collapsible)
  Widget _buildRawTextSection() {
    return GlassCard(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: const Text(
            'Raw OCR Text',
            style: TextStyle(color: Colors.white),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white70,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _receipt!.rawText.isEmpty
                      ? 'No text extracted'
                      : _receipt!.rawText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EDITABLE RECEIPT ITEM MODEL
// ============================================================================

class EditableReceiptItem {
  String name;
  double price;
  int quantity;
  String? category;
  String? subcategory;

  EditableReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.category,
    this.subcategory,
  });
}

// ============================================================================
// ITEM EDIT DIALOG
// ============================================================================

class _ItemEditDialog extends StatefulWidget {
  final EditableReceiptItem item;
  final ItemRecognitionService itemRecognizer;

  const _ItemEditDialog({
    required this.item,
    required this.itemRecognizer,
  });

  @override
  State<_ItemEditDialog> createState() => _ItemEditDialogState();
}

class _ItemEditDialogState extends State<_ItemEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  String? _selectedCategory;
  String? _selectedSubcategory;
  List<ItemSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  // Available categories from ItemRecognitionService
  final Map<String, List<String>> _categories = {
    'Food & Dining': [
      'Groceries',
      'Dairy',
      'Vegetables',
      'Fruits',
      'Bakery',
      'Snacks',
      'Beverages',
      'Frozen Foods',
      'Restaurants',
      'Food Delivery',
      'Fast Food',
      'Cafes'
    ],
    'Shopping': [
      'Clothing',
      'Footwear',
      'Accessories',
      'Electronics',
      'Mobile Accessories',
      'Books & Stationery',
      'Home & Kitchen',
      'Personal Care',
      'Retail',
      'Online'
    ],
    'Transportation': ['Fuel', 'Cab/Taxi', 'Public Transport', 'Parking'],
    'Healthcare': ['Medicines', 'Pharmacy'],
    'Bills & Utilities': [
      'Electricity',
      'Water',
      'Gas',
      'Internet/Mobile',
      'Cable/DTH',
      'Insurance'
    ],
    'Entertainment': ['Movies', 'Subscriptions'],
    'Education': ['Tuition', 'Books'],
    'Health & Fitness': ['Gym'],
    'Others': ['Gifts', 'Repairs'],
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _priceController =
        TextEditingController(text: widget.item.price.toStringAsFixed(2));
    _quantityController =
        TextEditingController(text: widget.item.quantity.toString());
    _selectedCategory = widget.item.category;
    _selectedSubcategory = widget.item.subcategory;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _searchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final suggestions = widget.itemRecognizer.getSuggestions(query, limit: 10);
    setState(() {
      _suggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty;
    });
  }

  void _selectSuggestion(ItemSuggestion suggestion) {
    setState(() {
      _nameController.text = suggestion.itemName;
      _selectedCategory = suggestion.category;
      _selectedSubcategory = suggestion.subcategory;
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  void _autoDetectCategory() {
    final match = widget.itemRecognizer.recognizeItem(_nameController.text);
    if (match != null) {
      setState(() {
        _selectedCategory = match.category;
        _selectedSubcategory = match.subcategory;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✨ Auto-detected: ${match.category} > ${match.subcategory}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[850],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Item',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Item name with suggestions
              const Text(
                'Item Name',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter item name',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.orange),
                    onPressed: _autoDetectCategory,
                    tooltip: 'Auto-detect category',
                  ),
                ),
                onChanged: _searchSuggestions,
              ),

              // Suggestions
              if (_showSuggestions) ...[
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        dense: true,
                        leading: Text(
                          suggestion.emoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        title: Text(
                          suggestion.itemName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${suggestion.category} > ${suggestion.subcategory}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11),
                        ),
                        onTap: () => _selectSuggestion(suggestion),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Price and Quantity
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _priceController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            prefixText: '₹ ',
                            prefixStyle: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Qty',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _quantityController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: '1',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category
              const Text(
                'Category',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: const Text(
                  'Select category',
                  style: TextStyle(color: Colors.white54),
                ),
                items: _categories.keys
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubcategory = null; // Reset subcategory
                  });
                },
              ),

              const SizedBox(height: 16),

              // Subcategory
              if (_selectedCategory != null) ...[
                const Text(
                  'Subcategory',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  dropdownColor: Colors.grey[800],
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: const Text(
                    'Select subcategory',
                    style: TextStyle(color: Colors.white54),
                  ),
                  items: _categories[_selectedCategory]!
                      .map((subcategory) => DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final updatedItem = EditableReceiptItem(
                        name: _nameController.text,
                        price: double.tryParse(_priceController.text) ?? 0.0,
                        quantity: int.tryParse(_quantityController.text) ?? 1,
                        category: _selectedCategory,
                        subcategory: _selectedSubcategory,
                      );
                      Navigator.pop(context, updatedItem);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
