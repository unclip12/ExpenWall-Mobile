import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'package:intl/intl.dart';

/// Feature B: Financial Overview Card
/// 
/// Displays:
/// - Current month income vs expense
/// - Visual progress bars with percentages
/// - Net savings calculation with arrow indicator and percentage
class FinancialOverviewCard extends StatelessWidget {
  final double income;
  final double expense;
  
  const FinancialOverviewCard({
    Key? key,
    required this.income,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final savings = income - expense;
    final maxAmount = income > expense ? income : expense;
    final incomePercent = maxAmount > 0 ? (income / maxAmount * 100).round() : 0;
    final expensePercent = maxAmount > 0 ? (expense / maxAmount * 100).round() : 0;
    final savingsPercent = income > 0 ? (savings / income * 100).round() : 0;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'This Month',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Income Row
          _buildFinanceRow(
            label: 'Income',
            amount: income,
            percentage: incomePercent,
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          
          // Expense Row
          _buildFinanceRow(
            label: 'Expense',
            amount: expense,
            percentage: expensePercent,
            color: Colors.red,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          
          // Net Savings
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.white).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Net Savings:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_formatCurrency(savings.abs())} (${savingsPercent.abs()}%)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: savings >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      savings >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: savings >= 0 ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceRow({
    required String label,
    required double amount,
    required int percentage,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label and Amount
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: (isDark ? Colors.white : Colors.white).withOpacity(0.9),
              ),
            ),
            Row(
              children: [
                Text(
                  _formatCurrency(amount),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: (isDark ? Colors.white : Colors.white).withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: (isDark ? Colors.white : Colors.white).withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// Format currency in Indian format (₹ #,##,###.##)
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
