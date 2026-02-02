import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glass_card.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<RecurringBill> _bills = [];

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

  void _showAddBillDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String frequency = 'Monthly';
    int dayOfMonth = DateTime.now().day;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Recurring Bill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Bill Name',
                    hintText: 'Netflix, Rent, Internet',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() => frequency = val!),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Day of Month',
                    hintText: '1-31',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (val) {
                    final day = int.tryParse(val);
                    if (day != null && day >= 1 && day <= 31) {
                      dayOfMonth = day;
                    }
                  },
                  controller: TextEditingController(text: dayOfMonth.toString()),
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
                if (nameController.text.trim().isNotEmpty &&
                    amountController.text.trim().isNotEmpty) {
                  this.setState(() {
                    _bills.add(RecurringBill(
                      name: nameController.text.trim(),
                      amount: double.parse(amountController.text),
                      frequency: frequency,
                      dayOfMonth: dayOfMonth,
                      isActive: true,
                      nextDueDate: _calculateNextDueDate(frequency, dayOfMonth),
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _calculateNextDueDate(String frequency, int dayOfMonth) {
    final now = DateTime.now();
    switch (frequency) {
      case 'Daily':
        return DateTime(now.year, now.month, now.day + 1);
      case 'Weekly':
        return DateTime(now.year, now.month, now.day + 7);
      case 'Monthly':
        return DateTime(now.year, now.month + 1, dayOfMonth);
      case 'Yearly':
        return DateTime(now.year + 1, now.month, dayOfMonth);
      default:
        return now;
    }
  }

  void _toggleBill(int index) {
    setState(() {
      _bills[index] = RecurringBill(
        name: _bills[index].name,
        amount: _bills[index].amount,
        frequency: _bills[index].frequency,
        dayOfMonth: _bills[index].dayOfMonth,
        isActive: !_bills[index].isActive,
        nextDueDate: _bills[index].nextDueDate,
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
    final activeBills = _bills.where((b) => b.isActive).toList();
    final inactiveBills = _bills.where((b) => !b.isActive).toList();
    final totalMonthly = activeBills
        .where((b) => b.frequency == 'Monthly')
        .fold(0.0, (sum, bill) => sum + bill.amount);

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
                    _buildStat('Active', activeBills.length.toString(), Icons.autorenew),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStat('Monthly', '₹${totalMonthly.toStringAsFixed(0)}', Icons.calendar_month),
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
                        if (activeBills.isNotEmpty) ..._buildSection('Active Bills', activeBills, true),
                        if (inactiveBills.isNotEmpty) ..._buildSection('Paused', inactiveBills, false),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBillDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<RecurringBill> bills, bool isActive) {
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
        return _buildBillCard(bill, index, isActive);
      }).toList(),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildBillCard(RecurringBill bill, int index, bool isActive) {
    final daysUntilDue = bill.nextDueDate.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(bill.name + index.toString()),
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
          child: Row(
            children: [
              Switch(
                value: bill.isActive,
                onChanged: (_) => _toggleBill(index),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isActive ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bill.frequency} • ₹${bill.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          isOverdue
                              ? 'Overdue by ${-daysUntilDue} days'
                              : 'Due in $daysUntilDue days',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.autorenew,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
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
          Icon(Icons.autorenew, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No recurring bills',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add subscriptions and regular payments',
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

class RecurringBill {
  final String name;
  final double amount;
  final String frequency;
  final int dayOfMonth;
  final bool isActive;
  final DateTime nextDueDate;

  RecurringBill({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.dayOfMonth,
    required this.isActive,
    required this.nextDueDate,
  });
}
