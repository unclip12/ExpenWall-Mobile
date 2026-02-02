import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/split_bill.dart';
import '../models/participant.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class BillDetailsScreen extends StatefulWidget {
  final String userId;
  final String billId;

  const BillDetailsScreen({
    super.key,
    required this.userId,
    required this.billId,
  });

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  late SplitBillService _splitBillService;
  SplitBill? _bill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _splitBillService = SplitBillService(
      localStorage: LocalStorageService(),
      contactService: ContactService(
        localStorage: LocalStorageService(),
        userId: widget.userId,
      ),
      userId: widget.userId,
    );
    _loadBill();
  }

  Future<void> _loadBill() async {
    setState(() => _isLoading = true);
    try {
      final bill = await _splitBillService.getBillById(widget.billId);
      setState(() {
        _bill = bill;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bill: $e')),
        );
      }
    }
  }

  Future<void> _markAsPaid(Participant participant) async {
    final amountController = TextEditingController(
      text: participant.amountOwed.toStringAsFixed(2),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${participant.contactName} as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Amount owed: ₹${participant.amountOwed.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter valid amount')),
                );
                return;
              }

              try {
                final updatedBill = await _splitBillService.markAsPaid(
                  widget.billId,
                  participant.contactId,
                  amount,
                );

                // Check for overpayment
                final updatedParticipant = updatedBill.participants
                    .firstWhere((p) => p.contactId == participant.contactId);

                if (updatedParticipant.paymentStatus ==
                    PaymentStatus.overpaid) {
                  if (mounted) {
                    Navigator.pop(context);
                    _handleOverpayment(updatedParticipant);
                  }
                } else {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('${participant.contactName} marked as paid'),
                      ),
                    );
                    _loadBill();
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleOverpayment(Participant participant) async {
    final overpaid = participant.overpaymentDifference;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💸 Overpayment Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${participant.contactName} paid ₹${overpaid.toStringAsFixed(2)} extra.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('How would you like to handle this?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark as debt (you owe them)
              await _splitBillService.handleOverpayment(
                widget.billId,
                participant.contactId,
                true,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Marked as debt. You owe ${participant.contactName} ₹${overpaid.toStringAsFixed(2)}'),
                  ),
                );
                _loadBill();
              }
            },
            child: const Text('I owe them'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Mark as credit (ignore/gift)
              await _splitBillService.handleOverpayment(
                widget.billId,
                participant.contactId,
                false,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Marked as gift/credit')),
                );
                _loadBill();
              }
            },
            child: const Text('Gift/Credit'),
          ),
        ],
      ),
    );
  }

  void _shareViaWhatsApp() {
    if (_bill == null) return;

    final text = _splitBillService.formatForWhatsApp(_bill!);
    Share.share(text, subject: 'Split Bill: ${_bill!.title}');
  }

  Future<void> _deleteBill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure? This cannot be undone.'),
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
      try {
        await _splitBillService.deleteBill(widget.billId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(child: Text('Bill not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareViaWhatsApp,
            tooltip: 'Share via WhatsApp',
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') _deleteBill();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBill,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _bill!.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_bill!.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _bill!.getStatusText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_bill!.description != null) ..[
                      const SizedBox(height: 8),
                      Text(
                        _bill!.description!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.currency_rupee, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _bill!.totalAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Split: ${_bill!.getSplitTypeText()}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items
            if (_bill!.items.isNotEmpty) ..[
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._bill!.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.name} ${item.quantity > 1 ? "x${item.quantity}" : ""}',
                                  ),
                                ),
                                Text(
                                  '₹${item.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Participants
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participants (${_bill!.participants.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._bill!.participants.map((participant) =>
                        _buildParticipantCard(participant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            if (_bill!.notes != null) ..[
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_bill!.notes!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: participant.hasPaid ? Colors.green : Colors.orange,
          child: Icon(
            participant.hasPaid ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(
          participant.contactName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Owes: ₹${participant.amountOwed.toStringAsFixed(2)}'),
            if (participant.hasPaid)
              Text(
                'Paid: ₹${participant.amountPaid.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
            if (participant.hasOverpaid)
              Text(
                'Overpaid by ₹${participant.overpaymentDifference.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.orange),
              ),
          ],
        ),
        trailing: !participant.hasPaid
            ? ElevatedButton(
                onPressed: () => _markAsPaid(participant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Mark Paid'),
              )
            : Icon(
                participant.paymentStatus == PaymentStatus.overpaid
                    ? Icons.warning
                    : Icons.check_circle,
                color: participant.paymentStatus == PaymentStatus.overpaid
                    ? Colors.orange
                    : Colors.green,
              ),
      ),
    );
  }

  Color _getStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.pending:
        return Colors.orange;
      case BillStatus.partiallyPaid:
        return Colors.blue;
      case BillStatus.fullySettled:
        return Colors.green;
    }
  }
}
