import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  final List<RecurringBill> _bills = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Active', _bills.length.toString(), Icons.sync),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildSummaryItem(
                  'Monthly',
                  '₹${_calculateMonthlyTotal().toStringAsFixed(0)}',
                  Icons.calendar_today,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coming Soon Message
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.repeat,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Recurring Bills',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up automatic recurring transactions',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Coming in v2.3.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Planned Features:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        _buildFeatureItem('📅', 'Set up monthly/weekly/yearly bills'),
                        _buildFeatureItem('🔔', 'Automatic transaction creation'),
                        _buildFeatureItem('⏰', 'Payment reminders'),
                        _buildFeatureItem('✏️', 'Edit or pause recurring rules'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon in v2.3.0!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring Bill'),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMonthlyTotal() {
    return _bills
        .where((b) => b.frequency == 'Monthly')
        .fold(0.0, (sum, bill) => sum + bill.amount);
  }
}

class RecurringBill {
  final String name;
  final double amount;
  final String frequency;
  final DateTime nextDate;

  RecurringBill({
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDate,
  });
}
