import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/split_bill.dart';
import '../models/participant.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'package:intl/intl.dart';

class BillDetailsScreen extends StatefulWidget {
  final String billId;
  final String userId;

  const BillDetailsScreen({
    super.key,
    required this.billId,
    required this.userId,
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
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _markAsPaid(Participant participant) async {
    final amountController = TextEditingController(
      text: participant.amountOwed.toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark ${participant.contactName} as Paid'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount owed: ₹${participant.amountOwed.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                validator: (v) {
                  if (v?.trim().isEmpty == true) return 'Required';
                  final amount = double.tryParse(v!);
                  if (amount == null || amount < participant.amountOwed) {
                    return 'Must be at least ₹${participant.amountOwed.toStringAsFixed(2)}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: You can enter more if they paid extra',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final amount = double.parse(amountController.text);
        final updatedBill = await _splitBillService.markAsPaid(
          widget.billId,
          participant.contactId,
          amount,
        );

        setState(() => _bill = updatedBill);

        // Check if overpaid (large amount)
        final overpaidParticipant = updatedBill.participants.firstWhere(
          (p) => p.contactId == participant.contactId,
        );

        if (overpaidParticipant.paymentStatus == PaymentStatus.overpaid) {
          _handleOverpayment(overpaidParticipant);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${participant.contactName} marked as paid')),
            );
          }
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

  Future<void> _handleOverpayment(Participant participant) async {
    final overpayment = participant.overpaymentDifference;

    final choice = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Overpayment Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${participant.contactName} paid ₹${overpayment.toStringAsFixed(2)} extra.',
            ),
            const SizedBox(height: 16),
            const Text(
              'What would you like to do?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• You Owe Them: They will get ₹${overpayment} back from you',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Credit for Next Time: They can use it in future bills',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Credit for Next Time'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('You Owe Them'),
          ),
        ],
      ),
    );

    if (choice != null) {
      try {
        final updatedBill = await _splitBillService.handleOverpayment(
          widget.billId,
          participant.contactId,
          choice,
        );
        setState(() => _bill = updatedBill);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                choice
                    ? 'Marked as debt - you owe them ₹${overpayment.toStringAsFixed(2)}'
                    : 'Marked as credit for future bills',
              ),
            ),
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

  Future<void> _shareViaWhatsApp() async {
    if (_bill == null) return;

    final text = _splitBillService.formatForWhatsApp(_bill!);

    try {
      await Share.share(text, subject: _bill!.title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }

  Future<void> _deleteBill() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: const Text('Are you sure you want to delete this bill?'),
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

    if (confirmed == true) {
      try {
        await _splitBillService.deleteBill(widget.billId);
        if (mounted) {
          Navigator.pop(context, true);
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
            tooltip: 'Share via WhatsApp',
            onPressed: _shareViaWhatsApp,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _deleteBill();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Bill', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBill,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title & Status
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(_bill!.status),
                      ],
                    ),
                    if (_bill!.description != null) ..[
                      const SizedBox(height: 8),
                      Text(
                        _bill!.description!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM yyyy').format(_bill!.date)),
                        const SizedBox(width: 16),
                        const Icon(Icons.people, size: 16),
                        const SizedBox(width: 4),
                        Text('${_bill!.participants.length} people'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount summary
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:'),
                        Text(
                          '₹${_bill!.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (_bill!.status != BillStatus.fullySettled) ..[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Paid:'),
                          Text(
                            '₹${_bill!.totalAmountPaid.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Pending:'),
                          Text(
                            '₹${_bill!.totalAmountPending.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Items
            if (_bill!.items.isNotEmpty) ..[
              const Text(
                'Items',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: _bill!.items
                      .map((item) => ListTile(
                            dense: true,
                            title: Text(item.name),
                            subtitle:
                                Text('₹${item.price} × ${item.quantity}'),
                            trailing: Text(
                              '₹${item.total.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Participants
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Participants',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_bill!.totalPaidCount}/${_bill!.totalParticipants} paid',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._bill!.participants.map((participant) =>
                _buildParticipantCard(participant)),

            // Notes
            if (_bill!.notes != null) ..[
              const SizedBox(height: 16),
              const Text(
                'Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_bill!.notes!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    final isPayer = participant.contactId == _bill!.paidByContactId;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: participant.hasPaid
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          child: Icon(
            participant.hasPaid ? Icons.check : Icons.pending,
            color: participant.hasPaid ? Colors.green : Colors.orange,
          ),
        ),
        title: Row(
          children: [
            Text(
              participant.contactName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (isPayer) ..[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Payer',
                  style: TextStyle(fontSize: 10, color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          participant.hasPaid
              ? 'Paid ₹${participant.amountPaid.toStringAsFixed(2)}'
              : 'Owes ₹${participant.amountOwed.toStringAsFixed(2)}',
        ),
        trailing: !participant.hasPaid
            ? ElevatedButton(
                onPressed: () => _markAsPaid(participant),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Mark Paid'),
              )
            : Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
      ),
    );
  }

  Widget _buildStatusBadge(BillStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BillStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending;
        break;
      case BillStatus.partiallyPaid:
        color = Colors.blue;
        text = 'Partial';
        icon = Icons.hourglass_half;
        break;
      case BillStatus.fullySettled:
        color = Colors.green;
        text = 'Settled';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
