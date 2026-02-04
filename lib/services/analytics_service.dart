import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'dart:math' as math;

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get transactions for a date range
  Future<List<Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  // Calculate top spending categories
  Map<String, double> calculateTopCategories(List<Transaction> transactions) {
    final Map<String, double> categoryTotals = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    // Sort by value descending
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  // Calculate spending by day of week
  Map<String, double> calculateDayOfWeekSpending(List<Transaction> transactions) {
    final Map<String, double> dayTotals = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    final Map<String, int> dayCounts = {
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0,
      'Sunday': 0,
    };

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final dayName = _getDayName(transaction.date.weekday);
        dayTotals[dayName] = (dayTotals[dayName] ?? 0) + transaction.amount;
        dayCounts[dayName] = (dayCounts[dayName] ?? 0) + 1;
      }
    }

    // Calculate averages
    final Map<String, double> averages = {};
    dayTotals.forEach((day, total) {
      final count = dayCounts[day] ?? 1;
      averages[day] = count > 0 ? total / count : 0;
    });

    return averages;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Calculate merchant frequency
  Map<String, int> calculateMerchantFrequency(List<Transaction> transactions) {
    final Map<String, int> merchantCounts = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense' && transaction.merchant.isNotEmpty) {
        merchantCounts[transaction.merchant] =
            (merchantCounts[transaction.merchant] ?? 0) + 1;
      }
    }

    // Sort by frequency descending
    final sortedEntries = merchantCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries.take(10));
  }

  // Calculate spending trends (daily totals)
  Map<DateTime, double> calculateSpendingTrends(List<Transaction> transactions) {
    final Map<DateTime, double> dailyTotals = {};

    for (var transaction in transactions) {
      if (transaction.type == 'expense') {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount;
      }
    }

    // Sort by date
    final sortedEntries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Map.fromEntries(sortedEntries);
  }

  // Calculate budget headroom percentage
  Future<double> calculateBudgetHeadroom(
    String userId,
    DateTime month,
  ) async {
    try {
      // Get monthly budget
      final budgetSnapshot = await _firestore
          .collection('budgets')
          .where('userId', isEqualTo: userId)
          .where('month', isEqualTo: '${month.year}-${month.month.toString().padLeft(2, '0')}')
          .limit(1)
          .get();

      if (budgetSnapshot.docs.isEmpty) return 0;

      final budgetData = budgetSnapshot.docs.first.data();
      final totalBudget = (budgetData['totalBudget'] as num?)?.toDouble() ?? 0;

      // Get current month spending
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      
      final transactions = await getTransactionsByDateRange(
        userId,
        startOfMonth,
        endOfMonth,
      );

      final totalSpent = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);

      if (totalBudget == 0) return 0;

      return ((totalBudget - totalSpent) / totalBudget) * 100;
    } catch (e) {
      print('Error calculating budget headroom: $e');
      return 0;
    }
  }

  // Compare two periods
  Future<Map<String, dynamic>> comparePeriods(
    String userId,
    DateTime period1Start,
    DateTime period1End,
    DateTime period2Start,
    DateTime period2End,
  ) async {
    final period1Transactions = await getTransactionsByDateRange(
      userId,
      period1Start,
      period1End,
    );

    final period2Transactions = await getTransactionsByDateRange(
      userId,
      period2Start,
      period2End,
    );

    // Calculate totals
    final period1Total = period1Transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    final period2Total = period2Transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate category breakdowns
    final period1Categories = calculateTopCategories(period1Transactions);
    final period2Categories = calculateTopCategories(period2Transactions);

    // Find all unique categories
    final allCategories = <String>{};
    allCategories.addAll(period1Categories.keys);
    allCategories.addAll(period2Categories.keys);

    // Compare categories
    final categoryComparisons = <Map<String, dynamic>>[];
    for (var category in allCategories) {
      final period1Amount = period1Categories[category] ?? 0;
      final period2Amount = period2Categories[category] ?? 0;
      final difference = period2Amount - period1Amount;
      final percentChange = period1Amount > 0
          ? ((difference / period1Amount) * 100)
          : (period2Amount > 0 ? 100.0 : 0.0);

      categoryComparisons.add({
        'category': category,
        'period1Amount': period1Amount,
        'period2Amount': period2Amount,
        'difference': difference,
        'percentChange': percentChange,
        'isIncrease': difference > 0,
      });
    }

    // Sort by absolute difference
    categoryComparisons.sort((a, b) => 
      (b['difference'] as double).abs().compareTo(
        (a['difference'] as double).abs()
      )
    );

    return {
      'period1Total': period1Total,
      'period2Total': period2Total,
      'totalDifference': period2Total - period1Total,
      'percentChange': period1Total > 0
          ? (((period2Total - period1Total) / period1Total) * 100)
          : 0.0,
      'categoryComparisons': categoryComparisons,
    };
  }

  // Predict future spending
  Future<Map<String, dynamic>> predictFutureSpending(
    String userId,
    DateTime targetMonth,
  ) async {
    // Get last 3 months of data
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);
    final lastMonth = DateTime(now.year, now.month, 0);

    final historicalTransactions = await getTransactionsByDateRange(
      userId,
      threeMonthsAgo,
      lastMonth,
    );

    if (historicalTransactions.isEmpty) {
      return {
        'predictedAmount': 0.0,
        'confidence': 0.0,
        'basedOnMonths': 0,
      };
    }

    // Group by month
    final Map<String, double> monthlyTotals = {};
    for (var transaction in historicalTransactions) {
      if (transaction.type == 'expense') {
        final monthKey = '${transaction.date.year}-${transaction.date.month}';
        monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + transaction.amount;
      }
    }

    // Calculate average and standard deviation
    final totals = monthlyTotals.values.toList();
    final average = totals.reduce((a, b) => a + b) / totals.length;
    final variance = totals
        .map((x) => math.pow(x - average, 2))
        .reduce((a, b) => a + b) / totals.length;
    final stdDev = math.sqrt(variance);

    // Check if target month exists in history (for year-over-year)
    final lastYearMonth = DateTime(targetMonth.year - 1, targetMonth.month);
    final lastYearKey = '${lastYearMonth.year}-${lastYearMonth.month}';
    final lastYearAmount = monthlyTotals[lastYearKey];

    // Weighted prediction (70% average, 30% last year if available)
    final predictedAmount = lastYearAmount != null
        ? (average * 0.7) + (lastYearAmount * 0.3)
        : average;

    // Confidence based on consistency (lower std dev = higher confidence)
    final confidence = math.max(0, math.min(100, 100 - ((stdDev / average) * 100)));

    return {
      'predictedAmount': predictedAmount,
      'minEstimate': predictedAmount - stdDev,
      'maxEstimate': predictedAmount + stdDev,
      'confidence': confidence,
      'basedOnMonths': totals.length,
      'lastYearAmount': lastYearAmount,
      'averageMonthly': average,
    };
  }

  // Generate AI-powered insights
  Future<List<Map<String, dynamic>>> generateAIInsights(
    String userId,
    DateTime currentMonth,
  ) async {
    final insights = <Map<String, dynamic>>[];

    // Compare with previous month
    final currentStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final currentEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final prevStart = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    final prevEnd = DateTime(currentMonth.year, currentMonth.month, 0);

    final comparison = await comparePeriods(
      userId,
      prevStart,
      prevEnd,
      currentStart,
      currentEnd,
    );

    final categoryComparisons = comparison['categoryComparisons'] as List;

    // Add insights for top changes
    for (var i = 0; i < math.min(5, categoryComparisons.length); i++) {
      final cat = categoryComparisons[i];
      final category = cat['category'] as String;
      final difference = cat['difference'] as double;
      final percentChange = cat['percentChange'] as double;
      final isIncrease = cat['isIncrease'] as bool;

      if (difference.abs() > 100) { // Only significant changes
        insights.add({
          'type': isIncrease ? 'increase' : 'decrease',
          'category': category,
          'amount': difference.abs(),
          'percentChange': percentChange.abs(),
          'message': isIncrease
              ? 'You spent ₹${difference.abs().toStringAsFixed(0)} (${percentChange.abs().toStringAsFixed(1)}%) more on $category this month'
              : 'You saved ₹${difference.abs().toStringAsFixed(0)} (${percentChange.abs().toStringAsFixed(1)}%) on $category this month',
          'icon': isIncrease ? '📈' : '📉',
          'isGood': !isIncrease,
        });
      }
    }

    return insights;
  }
}
