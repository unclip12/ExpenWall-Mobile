import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../widgets/glass_card.dart';
import '../utils/currency_formatter.dart';
import '../utils/category_icons.dart';

class BudgetScreen extends StatefulWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final Function(Budget) onAddBudget;
  final Function(String) onDeleteBudget;

  const BudgetScreen({
    super.key,
    required this.budgets,
    required this.transactions,
    required this.onAddBudget,
    required this.onDeleteBudget,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddBudgetDialog,
          ),
        ],
      ),
      body: widget.budgets.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.budgets.length,
              itemBuilder: (context, index) {
                final budget = widget.budgets[index];
                return _buildBudgetCard(budget);
              },
            ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    // Calculate spent amount
    final spent = widget.transactions
        .where((t) =>
            t.type == TransactionType.expense && t.category == budget.category)
        .fold(0.0, (sum, t) => sum + t.amount);

    final percentage = (spent / budget.amount * 100).clamp(0, 100);
    final isOverBudget = spent > budget.amount;
    final isWarning = percentage >= 80 && !isOverBudget;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? Colors.red.withOpacity(0.1)
                      : isWarning
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  CategoryIcons.getIcon(budget.category),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.category.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly budget: ${CurrencyFormatter.format(budget.amount)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(budget),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyFormatter.format(spent)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isOverBudget ? Colors.red : Colors.black87,
                ),
              ),
              Text(
                'Remaining: ${CurrencyFormatter.format((budget.amount - spent).clamp(0, double.infinity))}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentage / 100).clamp(0, 1),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverBudget
                          ? [Colors.red, Colors.redAccent]
                          : isWarning
                              ? [Colors.orange, Colors.orangeAccent]
                              : [Colors.green, Colors.greenAccent],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: (isOverBudget
                                ? Colors.red
                                : isWarning
                                    ? Colors.orange
                                    : Colors.green)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% used',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOverBudget
                  ? Colors.red
                  : isWarning
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
          if (isOverBudget)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Over budget by ${CurrencyFormatter.format(spent - budget.amount)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No budgets set',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set budgets to track your spending',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddBudgetDialog,
            icon: const Icon(Icons.add),
            label: const Text('Create Budget'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBudgetDialog() {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    Category selectedCategory = Category.food;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Category>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: Category.values
                  .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Text(CategoryIcons.getIcon(cat)),
                            const SizedBox(width: 12),
                            Text(cat.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => selectedCategory = val!,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Monthly Amount',
                prefixText: '₹',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                final budget = Budget(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  category: selectedCategory,
                  amount: amount,
                  period: 'monthly',
                );
                widget.onAddBudget(budget);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text(
            'Are you sure you want to delete the budget for ${budget.category.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onDeleteBudget(budget.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
