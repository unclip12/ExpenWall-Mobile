import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import '../utils/category_icons.dart';
import 'add_transaction_screen_v2.dart';

/// Screen for viewing transaction details with receipt support
class TransactionDetailsScreen extends StatefulWidget {
  final Transaction transaction;
  final String userId;
  final Function(Transaction)? onUpdate;
  final VoidCallback? onDelete;

  const TransactionDetailsScreen({
    Key? key,
    required this.transaction,
    required this.userId,
    this.onUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  State<TransactionDetailsScreen> createState() => _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  
  File? _receiptImage;
  bool _isLoadingImage = false;
  bool _showFullReceipt = false;
  double _receiptScale = 1.0;
  int _receiptRotation = 0;

  @override
  void initState() {
    super.initState();
    _loadReceiptImage();
  }

  /// Load receipt image if available
  Future<void> _loadReceiptImage() async {
    if (widget.transaction.receiptImagePath == null) return;

    setState(() => _isLoadingImage = true);

    try {
      final image = await _localStorageService.getReceiptImage(
        widget.transaction.receiptImagePath!,
      );
      if (mounted) {
        setState(() {
          _receiptImage = image;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      print('Error loading receipt image: $e');
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  /// Edit transaction
  Future<void> _editTransaction() async {
    final result = await Navigator.push<Transaction>(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreenV2(
          userId: widget.userId,
          initialData: widget.transaction,
          onSave: (transaction) async {
            if (widget.onUpdate != null) {
              widget.onUpdate!(transaction);
            }
            Navigator.pop(context, transaction);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  /// Delete transaction
  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'This action cannot be undone. The receipt image will also be deleted.',
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

    if (confirm == true) {
      // Delete receipt image if exists
      if (widget.transaction.receiptImagePath != null) {
        await _localStorageService.deleteReceiptImage(
          widget.transaction.receiptImagePath!,
        );
      }

      if (widget.onDelete != null) {
        widget.onDelete!();
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  /// Toggle full receipt view
  void _toggleFullReceipt() {
    setState(() {
      _showFullReceipt = !_showFullReceipt;
      if (!_showFullReceipt) {
        _receiptScale = 1.0;
        _receiptRotation = 0;
      }
    });
  }

  /// Zoom receipt
  void _zoomReceipt(double delta) {
    setState(() {
      _receiptScale = math.max(0.5, math.min(3.0, _receiptScale + delta));
    });
  }

  /// Rotate receipt
  void _rotateReceipt() {
    setState(() {
      _receiptRotation = (_receiptRotation + 90) % 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _editTransaction,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: _deleteTransaction,
            icon: const Icon(Icons.delete),
            tooltip: 'Delete',
            color: Colors.red,
          ),
        ],
      ),
      body: _showFullReceipt && _receiptImage != null
          ? _buildFullReceiptView()
          : _buildDetailsView(),
    );
  }

  /// Build main details view
  Widget _buildDetailsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount card
          _buildAmountCard(),
          const SizedBox(height: 16),

          // Receipt thumbnail (if available)
          if (widget.transaction.receiptImagePath != null)
            _buildReceiptThumbnail(),
          if (widget.transaction.receiptImagePath != null)
            const SizedBox(height: 16),

          // Basic info
          _buildBasicInfo(),
          const SizedBox(height: 16),

          // Items (if available)
          if (widget.transaction.items != null &&
              widget.transaction.items!.isNotEmpty)
            _buildItemsList(),
          if (widget.transaction.items != null &&
              widget.transaction.items!.isNotEmpty)
            const SizedBox(height: 16),

          // Receipt metadata (if available)
          if (widget.transaction.receiptData != null)
            _buildReceiptMetadata(),
          if (widget.transaction.receiptData != null)
            const SizedBox(height: 16),

          // Notes (if available)
          if (widget.transaction.notes != null)
            _buildNotesCard(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Build amount card
  Widget _buildAmountCard() {
    final isExpense = widget.transaction.type == TransactionType.expense;
    final color = isExpense ? Colors.red : Colors.green;

    return GlassCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              widget.transaction.merchant,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(widget.transaction.date),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${widget.transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isExpense ? 'Expense' : 'Income',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build receipt thumbnail
  Widget _buildReceiptThumbnail() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.green),
                const SizedBox(width: 12),
                const Text(
                  'Receipt Attached',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _receiptImage != null ? _toggleFullReceipt : null,
                  icon: const Icon(Icons.fullscreen, size: 18),
                  label: const Text('View Full'),
                ),
              ],
            ),
          ),
          if (_isLoadingImage)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_receiptImage != null)
            InkWell(
              onTap: _toggleFullReceipt,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Image.file(
                  _receiptImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Receipt image not found',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build basic info card
  Widget _buildBasicInfo() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Category',
              '${CategoryIcons.getIcon(widget.transaction.category)} ${widget.transaction.category.label}',
            ),
            if (widget.transaction.subcategory != null)
              _buildInfoRow('Subcategory', widget.transaction.subcategory!),
            _buildInfoRow('Type', widget.transaction.type.name.toUpperCase()),
            _buildInfoRow('Currency', widget.transaction.currency),
            if (widget.transaction.walletId != null)
              _buildInfoRow('Wallet', widget.transaction.walletId!),
            if (widget.transaction.tags != null &&
                widget.transaction.tags!.isNotEmpty)
              _buildInfoRow(
                'Tags',
                widget.transaction.tags!.join(', '),
              ),
          ],
        ),
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Build items list
  Widget _buildItemsList() {
    final items = widget.transaction.items!;
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
                  'Items (${items.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total: ₹${items.fold<double>(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (item.brand != null)
                          Text(
                            item.brand!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        if (item.quantity > 1)
                          Text(
                            'Qty: ${item.quantity}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// Build receipt metadata card
  Widget _buildReceiptMetadata() {
    final receiptData = widget.transaction.receiptData!;
    final confidence = receiptData['confidence'] as double? ?? 0.0;
    final color = confidence > 0.7
        ? Colors.green
        : confidence > 0.4
            ? Colors.orange
            : Colors.red;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receipt Information',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white54),
                const SizedBox(width: 12),
                const Text(
                  'OCR Confidence',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (receiptData['rawText'] != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text(
                  'Raw OCR Text',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                iconColor: Colors.white,
                collapsedIconColor: Colors.white70,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      receiptData['rawText'],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
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

  /// Build notes card
  Widget _buildNotesCard() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.transaction.notes!,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// Build full receipt view
  Widget _buildFullReceiptView() {
    return Stack(
      children: [
        // Receipt image with zoom
        Center(
          child: GestureDetector(
            onScaleUpdate: (details) {
              _zoomReceipt((details.scale - 1) * 0.1);
            },
            child: Transform.rotate(
              angle: _receiptRotation * math.pi / 180,
              child: Transform.scale(
                scale: _receiptScale,
                child: Image.file(
                  _receiptImage!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        // Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _toggleFullReceipt,
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close',
                    iconSize: 32,
                  ),
                  IconButton(
                    onPressed: () => _zoomReceipt(-0.25),
                    icon: const Icon(Icons.zoom_out, color: Colors.white),
                    tooltip: 'Zoom Out',
                    iconSize: 32,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(_receiptScale * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _receiptScale = 1.0;
                            _receiptRotation = 0;
                          });
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Reset',
                        iconSize: 28,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _zoomReceipt(0.25),
                    icon: const Icon(Icons.zoom_in, color: Colors.white),
                    tooltip: 'Zoom In',
                    iconSize: 32,
                  ),
                  IconButton(
                    onPressed: _rotateReceipt,
                    icon: const Icon(Icons.rotate_right, color: Colors.white),
                    tooltip: 'Rotate',
                    iconSize: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}