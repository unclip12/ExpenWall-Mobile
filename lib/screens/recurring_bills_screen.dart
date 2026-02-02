import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_rule.dart';
import '../services/recurring_bill_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'create_recurring_rule_screen.dart';

class RecurringBillsScreen extends StatefulWidget {
  final String userId;
  
  const RecurringBillsScreen({super.key, required this.userId});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  late RecurringBillService _recurringService;
  List<RecurringRule> _activeRules = [];
  List<RecurringRule> _pausedRules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringBillService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadRules();
  }

  Future<void> _loadRules() async {
    setState(() => _isLoading = true);
    
    final allRules = await _recurringService.getAllRules();
    
    setState(() {
      _activeRules = allRules.where((r) => r.isActive).toList();
      _pausedRules = allRules.where((r) => !r.isActive).toList();
      _isLoading = false;
    });
  }

  Future<void> _navigateToCreateEdit({RecurringRule? rule}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRecurringRuleScreen(
          userId: widget.userId,
          existingRule: rule,
        ),
      ),
    );

    if (result == true) {
      _loadRules();
    }
  }

  Future<void> _toggleRuleStatus(RecurringRule rule) async {
    final updatedRule = rule.copyWith(isActive: !rule.isActive);
    await _recurringService.updateRule(updatedRule);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedRule.isActive ? '▶️ Rule activated' : '⏸️ Rule paused',
        ),
        backgroundColor: updatedRule.isActive ? Colors.green : Colors.orange,
      ),
    );
    
    _loadRules();
  }

  double _calculateMonthlyTotal() {
    double total = 0.0;
    
    for (final rule in _activeRules) {
      // Convert to monthly equivalent
      switch (rule.frequencyUnit) {
        case FrequencyUnit.days:
          total += rule.amount * (30 / rule.frequencyValue);
          break;
        case FrequencyUnit.weeks:
          total += rule.amount * (4.33 / rule.frequencyValue);
          break;
        case FrequencyUnit.months:
          total += rule.amount * (1 / rule.frequencyValue);
          break;
        case FrequencyUnit.years:
          total += rule.amount * (1 / (rule.frequencyValue * 12));
          break;
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRules,
              child: _activeRules.isEmpty && _pausedRules.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Summary Card
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                'Active',
                                _activeRules.length.toString(),
                                Icons.sync,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildSummaryItem(
                                'Monthly',
                                '₹${_calculateMonthlyTotal().toStringAsFixed(0)}',
                                Icons.calendar_today,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey[300],
                              ),
                              _buildSummaryItem(
                                'Paused',
                                _pausedRules.length.toString(),
                                Icons.pause_circle,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Active Rules Section
                        if (_activeRules.isNotEmpty) ..[
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Active Bills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._activeRules.map((rule) => _buildRuleCard(rule)),
                          const SizedBox(height: 24),
                        ],

                        // Paused Rules Section
                        if (_pausedRules.isNotEmpty) ..[
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Paused Bills',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ..._pausedRules.map((rule) => _buildRuleCard(rule)),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add Recurring Bill'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'No Recurring Bills Yet',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Set up automatic recurring transactions\nfor subscriptions, bills, and salary',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How it works:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem('1️⃣', 'Create a recurring rule'),
                  _buildFeatureItem('2️⃣', 'Set frequency (daily, weekly, monthly, etc.)'),
                  _buildFeatureItem('3️⃣', 'Transaction auto-created on due date'),
                  _buildFeatureItem('4️⃣', 'Confirm payment or reschedule'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateEdit(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Rule'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(RecurringRule rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Dismissible(
          key: Key(rule.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            _navigateToCreateEdit(rule: rule);
            return false; // Don't actually dismiss, just open edit
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.edit, color: Colors.blue),
          ),
          child: InkWell(
            onTap: () => _navigateToCreateEdit(rule: rule),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (rule.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.repeat,
                      color: rule.isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rule.getFrequencyText(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 14,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Next: ${DateFormat('MMM d').format(rule.nextOccurrence)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Amount & Toggle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${rule.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Switch(
                        value: rule.isActive,
                        onChanged: (value) => _toggleRuleStatus(rule),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
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
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
