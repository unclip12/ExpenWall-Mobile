import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_card.dart';

class SplitBillsScreen extends StatefulWidget {
  const SplitBillsScreen({super.key});

  @override
  State<SplitBillsScreen> createState() => _SplitBillsScreenState();
}

class _SplitBillsScreenState extends State<SplitBillsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<SplitBill> _bills = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showAddSplitDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final List<String> participants = ['You'];
    final participantController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Split a Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Dinner, Movie tickets...',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Total Amount',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Split With',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...participants.map((p) => Chip(label: Text(p))).toList(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: participantController,
                        decoration: const InputDecoration(
                          hintText: 'Add person',
                          isDense: true,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: () {
                        if (participantController.text.trim().isNotEmpty) {
                          setState(() {
                            participants.add(participantController.text.trim());
                            participantController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descController.text.trim().isNotEmpty &&
                    amountController.text.trim().isNotEmpty &&
                    participants.length > 1) {
                  final amount = double.parse(amountController.text);
                  final perPerson = amount / participants.length;

                  this.setState(() {
                    _bills.add(SplitBill(
                      description: descController.text.trim(),
                      totalAmount: amount,
                      participants: participants,
                      perPersonAmount: perPerson,
                      paidBy: 'You',
                      date: DateTime.now(),
                      isSettled: false,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Split'),
            ),
          ],
        ),
      ),
    );
  }

  void _settleBill(int index) {
    setState(() {
      _bills[index] = SplitBill(
        description: _bills[index].description,
        totalAmount: _bills[index].totalAmount,
        participants: _bills[index].participants,
        perPersonAmount: _bills[index].perPersonAmount,
        paidBy: _bills[index].paidBy,
        date: _bills[index].date,
        isSettled: true,
        settledDate: DateTime.now(),
      );
    });
  }

  void _deleteBill(int index) {
    setState(() {
      _bills.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _bills.where((b) => !b.isSettled).toList();
    final settled = _bills.where((b) => b.isSettled).toList();
    final yourShare = pending.fold(0.0, (sum, bill) =>
        sum + (bill.perPersonAmount * (bill.participants.length - 1)));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _animController,
        child: Column(
          children: [
            // Stats
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Pending', pending.length.toString(), Icons.pending_actions),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStat('You Owe', '₹${yourShare.toStringAsFixed(0)}', Icons.account_balance_wallet),
                  ],
                ),
              ),
            ),

            // Bills List
            Expanded(
              child: _bills.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        if (pending.isNotEmpty) ..._buildSection('Pending', pending, false),
                        if (settled.isNotEmpty) ..._buildSection('Settled', settled, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSplitDialog,
        icon: const Icon(Icons.call_split),
        label: const Text('Split Bill'),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<SplitBill> bills, bool isSettled) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...bills.map((bill) {
        final index = _bills.indexOf(bill);
        return _buildBillCard(bill, index, isSettled);
      }).toList(),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildBillCard(SplitBill bill, int index, bool isSettled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(bill.description + index.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _deleteBill(index),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bill.description,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: isSettled ? TextDecoration.lineThrough : null,
                        color: isSettled ? Colors.grey : null,
                      ),
                    ),
                  ),
                  if (isSettled)
                    Icon(Icons.check_circle, color: Colors.green[600])
                  else
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _settleBill(index),
                      tooltip: 'Mark as settled',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total: ₹${bill.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Per person: ₹${bill.perPersonAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      '${bill.participants.length} people',
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Paid by ${bill.paidBy} • ${_formatDate(bill.date)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              if (isSettled && bill.settledDate != null)
                Text(
                  'Settled on ${_formatDate(bill.settledDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_split, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No split bills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Split expenses with friends easily',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class SplitBill {
  final String description;
  final double totalAmount;
  final List<String> participants;
  final double perPersonAmount;
  final String paidBy;
  final DateTime date;
  final bool isSettled;
  final DateTime? settledDate;

  SplitBill({
    required this.description,
    required this.totalAmount,
    required this.participants,
    required this.perPersonAmount,
    required this.paidBy,
    required this.date,
    required this.isSettled,
    this.settledDate,
  });
}
