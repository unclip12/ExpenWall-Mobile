import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/receipt_ocr_service.dart';
import '../services/item_recognition_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction.dart';

/// Screen to review and edit OCR-extracted receipt data before saving
class ReceiptReviewScreen extends StatefulWidget {
  final String userId;
  final String imagePath;
  final ExtractedReceipt extractedReceipt;

  const ReceiptReviewScreen({
    super.key,
    required this.userId,
    required this.imagePath,
    required this.extractedReceipt,
  });

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late List<ReceiptItem> _items;

  String _selectedCategory = 'Shopping';
  String _selectedSubcategory = 'Retail';
  bool _isSaving = false;
  bool _showImage = true;

  final ItemRecognitionService _itemRecognitionService =
      ItemRecognitionService();

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  /// Initialize form fields from extracted receipt
  void _initializeFields() {
    _merchantController = TextEditingController(
      text: widget.extractedReceipt.merchantName ?? '',
    );
    _amountController = TextEditingController(
      text: widget.extractedReceipt.totalAmount?.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController();
    _selectedDate = widget.extractedReceipt.date ?? DateTime.now();
    _items = List.from(widget.extractedReceipt.items);

    // Try to determine category from merchant or items
    _autoDetermineCategory();
  }

  /// Auto-determine category based on merchant name or items
  void _autoDetermineCategory() {
    // Try merchant recognition first
    if (widget.extractedReceipt.merchantName != null) {
      final match = _itemRecognitionService
          .recognizeMerchant(widget.extractedReceipt.merchantName!);
      if (match != null && match.confidence > 0.5) {
        _selectedCategory = match.category;
        _selectedSubcategory = match.subcategory;
        return;
      }
    }

    // Try from most common item category
    if (_items.isNotEmpty) {
      final categoryCounts = <String, int>{};
      for (final item in _items) {
        if (item.category != null) {
          categoryCounts[item.category!] =
              (categoryCounts[item.category!] ?? 0) + 1;
        }
      }

      if (categoryCounts.isNotEmpty) {
        final mostCommonCategory = categoryCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        _selectedCategory = mostCommonCategory;

        // Find matching subcategory from items
        final itemWithCategory =
            _items.firstWhere((item) => item.category == mostCommonCategory);
        if (itemWithCategory.subcategory != null) {
          _selectedSubcategory = itemWithCategory.subcategory!;
        }
      }
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Save transaction
  Future<void> _saveTransaction() async {
    // Validate amount
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showErrorDialog('Please enter a valid amount');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final transactionService = TransactionService();

      // Create transaction
      final transaction = Transaction(
        id: '',
        userId: widget.userId,
        type: 'expense',
        amount: amount,
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        date: _selectedDate,
        merchant: _merchantController.text.isNotEmpty
            ? _merchantController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        paymentMethod: 'Cash', // Default
        receiptImagePath: widget.imagePath,
        tags: ['receipt-scan'],
      );

      await transactionService.createTransaction(transaction, widget.userId);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Transaction saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to home (pop all camera screens)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('Error saving transaction: $e');
      _showErrorDialog('Failed to save transaction: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 12),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          // Toggle image view
          IconButton(
            icon: Icon(_showImage ? Icons.image : Icons.image_not_supported),
            onPressed: () {
              setState(() {
                _showImage = !_showImage;
              });
            },
            tooltip: _showImage ? 'Hide Image' : 'Show Image',
          ),

          // Save button
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveTransaction,
            tooltip: 'Save Transaction',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Receipt image preview
            if (_showImage) _buildImagePreview(),

            // Confidence indicator
            _buildConfidenceIndicator(),

            // Edit form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant name
                  _buildTextField(
                    controller: _merchantController,
                    label: 'Merchant Name',
                    icon: Icons.store,
                    hint: 'Enter merchant name',
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  _buildTextField(
                    controller: _amountController,
                    label: 'Total Amount',
                    icon: Icons.currency_rupee,
                    hint: '0.00',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  _buildDateField(),
                  const SizedBox(height: 16),

                  // Category & Subcategory
                  _buildCategoryField(),
                  const SizedBox(height: 16),

                  // Notes
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    icon: Icons.notes,
                    hint: 'Add notes...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Extracted items (if any)
                  if (_items.isNotEmpty) _buildItemsList(),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveTransaction,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving
                          ? 'Saving...'
                          : 'Save Transaction'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build image preview
  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showFullImage,
      child: Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey.shade900,
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Show full image in dialog
  void _showFullImage() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.file(File(widget.imagePath)),
        ),
      ),
    );
  }

  /// Build confidence indicator
  Widget _buildConfidenceIndicator() {
    final confidence = widget.extractedReceipt.confidence;
    Color color;
    String label;

    if (confidence >= 0.7) {
      color = Colors.green;
      label = 'High Confidence';
    } else if (confidence >= 0.4) {
      color = Colors.orange;
      label = 'Medium Confidence';
    } else {
      color = Colors.red;
      label = 'Low Confidence';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label (${(confidence * 100).toStringAsFixed(0)}%)',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            'Please verify the data',
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Build date field
  Widget _buildDateField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        child: Text(
          DateFormat('dd MMM yyyy').format(_selectedDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  /// Pick date
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Build category field
  Widget _buildCategoryField() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _selectedSubcategory,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Build items list
  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Extracted Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final item = _items[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: item.category != null
                  ? Text('${item.category} > ${item.subcategory}')
                  : null,
              trailing: Text(
                '₹${item.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items Total:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_items.fold<double>(0, (sum, item) => sum + item.price).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
