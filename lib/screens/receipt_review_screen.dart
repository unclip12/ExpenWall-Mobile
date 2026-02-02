import 'dart:io';
import 'package:flutter/material.dart';
import '../services/receipt_ocr_service.dart';
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
  ExtractedReceipt? _receipt;
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processReceipt();
  }

  @override
  void dispose() {
    _ocrService.dispose();
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process receipt: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  /// Save receipt data and create transaction
  Future<void> _saveReceipt() async {
    if (_receipt == null) return;

    // TODO: Integrate with transaction creation
    // This will be implemented in Phase 5
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt saved! (Transaction creation coming in Phase 5)'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Review Receipt'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isProcessing && _receipt != null)
            IconButton(
              onPressed: _saveReceipt,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
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
          // Receipt image preview
          _buildImagePreview(),
          const SizedBox(height: 16),

          // Confidence indicator
          _buildConfidenceIndicator(),
          const SizedBox(height: 16),

          // Extracted data
          _buildExtractedData(),
          const SizedBox(height: 16),

          // Items list
          if (_receipt!.items.isNotEmpty) _buildItemsList(),

          const SizedBox(height: 16),

          // Raw text (collapsible)
          _buildRawTextSection(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Build image preview
  Widget _buildImagePreview() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Receipt Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.imagePath),
                width: double.infinity,
                fit: BoxFit.contain,
              ),
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

  /// Build extracted data fields
  Widget _buildExtractedData() {
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
            _buildDataField(
              icon: Icons.store,
              label: 'Merchant',
              value: _receipt!.merchantName ?? 'Not found',
              confidence: _receipt!.fieldConfidences['merchant'] ?? 0.0,
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildDataField(
              icon: Icons.calendar_today,
              label: 'Date',
              value: _receipt!.date != null
                  ? '${_receipt!.date!.day}/${_receipt!.date!.month}/${_receipt!.date!.year}'
                  : 'Not found',
              confidence: _receipt!.fieldConfidences['date'] ?? 0.0,
            ),
            const Divider(color: Colors.white24, height: 24),
            _buildDataField(
              icon: Icons.currency_rupee,
              label: 'Total Amount',
              value: _receipt!.totalAmount != null
                  ? '₹${_receipt!.totalAmount!.toStringAsFixed(2)}'
                  : 'Not found',
              confidence: _receipt!.fieldConfidences['total'] ?? 0.0,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual data field
  Widget _buildDataField({
    required IconData icon,
    required String label,
    required String value,
    required double confidence,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: isHighlight ? Colors.green[300] : Colors.white,
                  fontSize: isHighlight ? 20 : 16,
                  fontWeight:
                      isHighlight ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        if (confidence > 0.0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: confidence > 0.7
                  ? Colors.green.withOpacity(0.2)
                  : confidence > 0.4
                      ? Colors.orange.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                color: confidence > 0.7
                    ? Colors.green[300]
                    : confidence > 0.4
                        ? Colors.orange[300]
                        : Colors.red[300],
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }

  /// Build items list
  Widget _buildItemsList() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items (${_receipt!.items.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...(_receipt!.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                          ],
                        ),
                      ),
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ))),
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
