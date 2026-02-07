import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'package:intl/intl.dart';

/// Feature C: Spending Chart Card (7 Days)
/// 
/// Displays:
/// - Bar chart showing last 7 days of spending
/// - Day labels (Mon-Sun)
/// - Visual representation of spending patterns
class SpendingChartCard extends StatelessWidget {
  final List<DailySpending> spendingData;
  
  const SpendingChartCard({
    Key? key,
    required this.spendingData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Find max spending for scaling
    final maxSpending = spendingData.isEmpty
        ? 1000.0
        : spendingData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending (7 Days)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.white,
                ),
              ),
              Icon(
                Icons.bar_chart_rounded,
                color: Colors.white.withOpacity(0.7),
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: spendingData.map((data) {
                return _buildBar(
                  context: context,
                  day: data.day,
                  amount: data.amount,
                  maxAmount: maxSpending,
                  isDark: isDark,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar({
    required BuildContext context,
    required String day,
    required double amount,
    required double maxAmount,
    required bool isDark,
  }) {
    final theme = Theme.of(context);
    final barHeight = (amount / maxAmount * 140).clamp(8.0, 140.0);
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Amount label
            if (amount > 0)
              Text(
                _formatCompactCurrency(amount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            
            // Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Day label
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format currency in compact form (₹5K, ₹12K, etc.)
  String _formatCompactCurrency(double amount) {
    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '₹${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

/// Data model for daily spending
class DailySpending {
  final String day;       // Mon, Tue, Wed, etc.
  final double amount;    // Spending amount
  final DateTime date;    // Full date

  DailySpending({
    required this.day,
    required this.amount,
    required this.date,
  });
}
