import '../models/transaction.dart';
import 'package:intl/intl.dart';

class AIInsight {
  final String category;
  final String message;
  final bool isPositive;
  final double changePercentage;

  AIInsight({
    required this.category,
    required this.message,
    required this.isPositive,
    required this.changePercentage,
  });
}

class AnalyticsService {
  Map<String, double> getTopCategories(List<ExpenseTransaction> transactions, {int limit = 5}) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(limit));
  }

  Map<String, double> getMonthlyTrends(List<ExpenseTransaction> transactions, {int months = 6}) {
    final now = DateTime.now();
    final monthlyTotals = <String, double>{};
    
    for (int i = months - 1; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yyyy').format(targetMonth);
      
      final monthTotal = transactions
          .where((t) => 
              t.type == 'expense' &&
              t.date.year == targetMonth.year &&
              t.date.month == targetMonth.month)
          .fold<double>(0, (sum, t) => sum + t.amount);
      
      monthlyTotals[monthKey] = monthTotal;
    }
    
    return monthlyTotals;
  }

  Map<String, double> getDayOfWeekAnalysis(List<ExpenseTransaction> transactions) {
    final dayTotals = <String, List<double>>{
      'Monday': [],
      'Tuesday': [],
      'Wednesday': [],
      'Thursday': [],
      'Friday': [],
      'Saturday': [],
      'Sunday': [],
    };
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense') {
        final dayName = DateFormat('EEEE').format(transaction.date);
        dayTotals[dayName]?.add(transaction.amount);
      }
    }
    
    final dayAverages = <String, double>{};
    dayTotals.forEach((day, amounts) {
      if (amounts.isNotEmpty) {
        dayAverages[day] = amounts.reduce((a, b) => a + b) / amounts.length;
      } else {
        dayAverages[day] = 0;
      }
    });
    
    return dayAverages;
  }

  Map<String, int> getMerchantFrequency(List<ExpenseTransaction> transactions, {int limit = 10}) {
    final merchantCounts = <String, int>{};
    
    for (final transaction in transactions) {
      if (transaction.merchant.isNotEmpty) {
        merchantCounts[transaction.merchant] = 
            (merchantCounts[transaction.merchant] ?? 0) + 1;
      }
    }
    
    final sortedEntries = merchantCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Map.fromEntries(sortedEntries.take(limit));
  }

  List<AIInsight> getAIInsights(List<ExpenseTransaction> transactions) {
    final insights = <AIInsight>[];
    final now = DateTime.now();
    
    // Current month
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthTransactions = transactions
        .where((t) => t.type == 'expense' && t.date.isAfter(currentMonthStart))
        .toList();
    
    // Previous month
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);
    final previousMonthEnd = DateTime(now.year, now.month, 0);
    final previousMonthTransactions = transactions
        .where((t) => 
            t.type == 'expense' &&
            t.date.isAfter(previousMonthStart) &&
            t.date.isBefore(previousMonthEnd))
        .toList();
    
    // Category comparison
    final currentCategories = <String, double>{};
    final previousCategories = <String, double>{};
    
    for (final t in currentMonthTransactions) {
      currentCategories[t.category] = (currentCategories[t.category] ?? 0) + t.amount;
    }
    
    for (final t in previousMonthTransactions) {
      previousCategories[t.category] = (previousCategories[t.category] ?? 0) + t.amount;
    }
    
    // Generate insights for each category
    final allCategories = {...currentCategories.keys, ...previousCategories.keys};
    
    for (final category in allCategories) {
      final current = currentCategories[category] ?? 0;
      final previous = previousCategories[category] ?? 0;
      
      if (previous > 0) {
        final changePercentage = ((current - previous) / previous * 100);
        
        if (changePercentage.abs() > 10) { // Only show significant changes
          final isPositive = changePercentage < 0; // Negative change is good (less spending)
          
          String message;
          if (isPositive) {
            message = 'You spent ${changePercentage.abs().toStringAsFixed(1)}% less than last month. Great job! 🎉';
          } else {
            message = 'You spent ${changePercentage.abs().toStringAsFixed(1)}% more than last month. Consider cutting back.';
          }
          
          insights.add(AIInsight(
            category: category,
            message: message,
            isPositive: isPositive,
            changePercentage: changePercentage,
          ));
        }
      } else if (current > 0) {
        insights.add(AIInsight(
          category: category,
          message: 'New spending in this category this month: ₹${current.toStringAsFixed(0)}',
          isPositive: false,
          changePercentage: 100,
        ));
      }
    }
    
    // Sort by absolute change percentage
    insights.sort((a, b) => b.changePercentage.abs().compareTo(a.changePercentage.abs()));
    
    return insights.take(5).toList();
  }

  Map<String, double> getCategoryBreakdown(
    List<ExpenseTransaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in transactions) {
      if (transaction.type == 'expense' &&
          transaction.date.isAfter(startDate) &&
          transaction.date.isBefore(endDate)) {
        categoryTotals[transaction.category] = 
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    
    return categoryTotals;
  }

  double getTotalExpense(
    List<ExpenseTransaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    return transactions
        .where((t) => 
            t.type == 'expense' &&
            t.date.isAfter(startDate) &&
            t.date.isBefore(endDate))
        .fold<double>(0, (sum, t) => sum + t.amount);
  }
}
