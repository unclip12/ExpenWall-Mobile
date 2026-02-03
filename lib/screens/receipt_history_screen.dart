import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'transaction_details_screen.dart';

/// Screen for browsing receipt history
class ReceiptHistoryScreen extends StatefulWidget {
  final String userId;
  final List<Transaction> transactions;
  final Function(String)? onTransactionTap;

  const ReceiptHistoryScreen({
    Key? key,
    required this.userId,
    required this.transactions,
    this.onTransactionTap,
  }) : super(key: key);

  @override
  State<ReceiptHistoryScreen> createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Transaction> _filteredTransactions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date'; // date, amount, merchant
  bool _sortAscending = false;
  bool _isLoading = true;
  Map<String, File?> _receiptImages = {};

  @override
  void initState() {
    super.initState();
    _loadReceiptTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load transactions with receipts
  Future<void> _loadReceiptTransactions() async {
    setState(() => _isLoading = true);

    // Filter transactions that have receipts
    final receipts = widget.transactions
        .where((t) => t.receiptImagePath != null)
        .toList();

    // Load receipt images
    for (final transaction in receipts) {
      if (transaction.receiptImagePath != null) {
        try {
          final image = await _localStorageService.getReceiptImage(
            transaction.receiptImagePath!,
          );
          _receiptImages[transaction.id] = image;
        } catch (e) {
          _receiptImages[transaction.id] = null;
        }
      }
    }

    setState(() {
      _filteredTransactions = receipts;
      _isLoading = false;
    });
    _applyFiltersAndSort();
  }

  /// Apply filters and sorting
  void _applyFiltersAndSort() {
    setState(() {
      // Start with all transactions with receipts
      var filtered = widget.transactions
          .where((t) => t.receiptImagePath != null)
          .toList();

      // Apply search filter
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        filtered = filtered.where((t) =>
          t.merchant.toLowerCase().contains(query) ||
          (t.notes?.toLowerCase().contains(query) ?? false)
        ).toList();
      }

      // Apply date range filter
      if (_startDate != null) {
        filtered = filtered.where((t) =>
          t.date.isAfter(_startDate!) || t.date.isAtSameMomentAs(_startDate!)
        ).toList();
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          23,
          59,
          59,
        );
        filtered = filtered.where((t) =>
          t.date.isBefore(endOfDay) || t.date.isAtSameMomentAs(endOfDay)
        ).toList();
      }

      // Apply sorting
      switch (_sortBy) {
        case 'date':
          filtered.sort((a, b) => _sortAscending
              ? a.date.compareTo(b.date)
              : b.date.compareTo(a.date));
          break;
        case 'amount':
          filtered.sort((a, b) => _sortAscending
              ? a.amount.compareTo(b.amount)
              : b.amount.compareTo(a.amount));
          break;
        case 'merchant':
          filtered.sort((a, b) => _sortAscending
              ? a.merchant.compareTo(b.merchant)
              : b.merchant.compareTo(a.merchant));
          break;
      }

      _filteredTransactions = filtered;
    });
  }

  /// Pick date range
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFiltersAndSort();
    }
  }

  /// Clear filters
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _startDate = null;
      _endDate = null;
    });
    _applyFiltersAndSort();
  }

  /// Delete receipt
  Future<void> _deleteReceipt(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt?'),
        content: const Text(
          'This will delete the receipt image but keep the transaction.',
        ),
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

    if (confirm == true && transaction.receiptImagePath != null) {
      try {
        await _localStorageService.deleteReceiptImage(
          transaction.receiptImagePath!,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt deleted'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload
        await _loadReceiptTransactions();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting receipt: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Calculate statistics
  Map<String, dynamic> _calculateStats() {
    return {
      'total': _filteredTransactions.length,
      'totalAmount': _filteredTransactions.fold<double>(
        0.0,
        (sum, t) => sum + t.amount,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Receipt History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'Date Range',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = false;
                }
              });
              _applyFiltersAndSort();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: _sortBy == 'date' ? Colors.blue : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Date'),
                    if (_sortBy == 'date')
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(
                      Icons.currency_rupee,
                      size: 18,
                      color: _sortBy == 'amount' ? Colors.blue : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Amount'),
                    if (_sortBy == 'amount')
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'merchant',
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      size: 18,
                      color: _sortBy == 'merchant' ? Colors.blue : Colors.white54,
                    ),
                    const SizedBox(width: 8),
                    Text('Sort by Merchant'),
                    if (_sortBy == 'merchant')
                      Icon(
                        _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _applyFiltersAndSort(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by merchant...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: _searchController.text.isNotEmpty ||
                        _startDate != null ||
                        _endDate != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: _clearFilters,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Date range chip
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Chip(
                label: Text(
                  '${DateFormat('dd MMM').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _applyFiltersAndSort();
                },
              ),
            ),

          // Statistics
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${stats['total']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Receipts',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ),
                    Column(
                      children: [
                        Text(
                          '₹${stats['totalAmount'].toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Amount',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Receipt list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildReceiptGrid(),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.white24,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty ||
                    _startDate != null ||
                    _endDate != null
                ? 'No receipts found'
                : 'No receipts yet',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty ||
                    _startDate != null ||
                    _endDate != null
                ? 'Try adjusting your filters'
                : 'Scan receipts to see them here',
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build receipt grid
  Widget _buildReceiptGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        final receiptImage = _receiptImages[transaction.id];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailsScreen(
                  transaction: transaction,
                  userId: widget.userId,
                ),
              ),
            );
          },
          onLongPress: () => _deleteReceipt(transaction),
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receipt image
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: receiptImage != null
                        ? Image.file(
                            receiptImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.black26,
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                  ),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.merchant,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(transaction.date),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${transaction.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
