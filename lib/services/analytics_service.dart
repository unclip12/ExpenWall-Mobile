// lib/services/analytics_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import '../models/analytics_data.dart';
import 'dart:math';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get comprehensive analytics for a date range
  Future<AnalyticsData> getAnalytics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await _getTransactions(userId, startDate, endDate);

    final categorySpending = _calculateCategorySpending(transactions);
    final dayOfWeekSpending = _calculateDayOfWeekSpending(transactions);
    final merchantData = _calculateMerchantData(transactions);
    final monthlyTrends = await _calculateMonthlyTrends(userId, endDate);

    final totalExpenses = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Get budget for the period
    final budget = await _getBudgetForPeriod(userId, startDate, endDate);
    final budgetUsed = budget > 0 ? (totalExpenses / budget) * 100 : 0.0;

    return AnalyticsData(
      categorySpending: categorySpending,
      monthlyTrends: monthlyTrends,
      dayOfWeekSpending: dayOfWeekSpending,
      merchantFrequency: merchantData['frequency'] as Map<String, int>,
      merchantSpending: merchantData['spending'] as Map<String, double>,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      budgetAmount: budget,
      budgetUsedPercentage: budgetUsed,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Generate AI-powered insights
  Future<List<AIInsight>> generateAIInsights({
    required String userId,
    required DateTime currentMonth,
  }) async {
    final insights = <AIInsight>[];

    // Get current and previous month data
    final currentStart = DateTime(currentMonth.year, currentMonth.month, 1);
    final currentEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final previousStart = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    final previousEnd = DateTime(currentMonth.year, currentMonth.month, 0);

    final currentData = await getAnalytics(
      userId: userId,
      startDate: currentStart,
      endDate: currentEnd,
    );

    final previousData = await getAnalytics(
      userId: userId,
      startDate: previousStart,
      endDate: previousEnd,
    );

    // Compare categories
    for (final category in currentData.categorySpending.keys) {
      final currentAmount = currentData.categorySpending[category] ?? 0;
      final previousAmount = previousData.categorySpending[category] ?? 0;

      if (previousAmount > 0) {
        final change = ((currentAmount - previousAmount) / previousAmount) * 100;
        final difference = currentAmount - previousAmount;

        if (change.abs() > 10) {
          // Significant change
          insights.add(AIInsight(
            category: category,
            percentageChange: change.toDouble(),
            amount: difference.abs(),
            insight: _generateInsightText(category, change, difference.abs()),
            sentiment: change > 0
                ? InsightSentiment.negative
                : InsightSentiment.positive,
            generatedAt: DateTime.now(),
          ));
        }
      } else if (currentAmount > 0) {
        // New spending category
        insights.add(AIInsight(
          category: category,
          percentageChange: 100,
          amount: currentAmount,
          insight:
              'New spending in $category: ₹${currentAmount.toStringAsFixed(0)}',
          sentiment: InsightSentiment.neutral,
          generatedAt: DateTime.now(),
        ));
      }
    }

    // Check for categories with no spending (improvement)
    for (final category in previousData.categorySpending.keys) {
      if (!currentData.categorySpending.containsKey(category)) {
        final previousAmount = previousData.categorySpending[category] ?? 0;
        if (previousAmount > 0) {
          insights.add(AIInsight(
            category: category,
            percentageChange: -100,
            amount: previousAmount,
            insight:
                '🎉 No spending on $category this month! Saved ₹${previousAmount.toStringAsFixed(0)}',
            sentiment: InsightSentiment.positive,
            generatedAt: DateTime.now(),
          ));
        }
      }
    }

    return insights;
  }

  // Predict next month expenses
  Future<ExpensePrediction> predictNextMonthExpenses({
    required String userId,
  }) async {
    final now = DateTime.now();
    final targetMonth = DateTime(now.year, now.month + 1, 1);

    // Get last 6 months of data
    final transactions = <Transaction>[];
    final monthlyTotals = <double>[];
    final categoryTotals = <String, List<double>>{};

    for (int i = 0; i < 6; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final monthTransactions =
          await _getTransactions(userId, monthStart, monthEnd);
      transactions.addAll(monthTransactions);

      final monthTotal = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);
      monthlyTotals.add(monthTotal);

      // Track category spending per month
      for (final t in monthTransactions.where((t) => t.type == TransactionType.expense)) {
        categoryTotals.putIfAbsent(t.category.label, () => []);
        categoryTotals[t.category.label]!.add(t.amount);
      }
    }

    // Calculate prediction using weighted average (recent months weighted more)
    double prediction = 0;
    double totalWeight = 0;
    for (int i = 0; i < monthlyTotals.length; i++) {
      final weight = (i + 1).toDouble(); // More recent = higher weight
      prediction += monthlyTotals[i] * weight;
      totalWeight += weight;
    }
    prediction = prediction / totalWeight;

    // Calculate category predictions
    final categoryPredictions = <String, double>{};
    for (final category in categoryTotals.keys) {
      final amounts = categoryTotals[category]!;
      final avgAmount = amounts.reduce((a, b) => a + b) / amounts.length;
      categoryPredictions[category] = avgAmount;
    }

    // Calculate confidence based on variance
    final variance = _calculateVariance(monthlyTotals);
    final confidence = max(0.5, min(0.95, 1 - (variance / prediction)));

    // Generate factors
    final factors = <String>[
      'Based on last 6 months spending pattern',
      'Considers seasonal variations',
      'Weighted towards recent behavior',
    ];

    // Check for same month last year
    final lastYearMonth = DateTime(now.year - 1, targetMonth.month, 1);
    final lastYearEnd = DateTime(now.year - 1, targetMonth.month + 1, 0);
    final lastYearTransactions =
        await _getTransactions(userId, lastYearMonth, lastYearEnd);

    if (lastYearTransactions.isNotEmpty) {
      final lastYearTotal = lastYearTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      // Adjust prediction with last year's data
      prediction = (prediction * 0.7) + (lastYearTotal * 0.3);
      factors.add(
          'Includes same month last year data (₹${lastYearTotal.toStringAsFixed(0)})');
    }

    // Generate recommendation
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final currentMonthEnd = DateTime(now.year, now.month + 1, 0);
    final currentData = await getAnalytics(
      userId: userId,
      startDate: currentMonthStart,
      endDate: currentMonthEnd,
    );

    String recommendation;
    if (prediction > currentData.totalExpenses * 1.1) {
      recommendation =
          'Expected to spend more next month. Consider reviewing your budget and planning ahead.';
    } else if (prediction < currentData.totalExpenses * 0.9) {
      recommendation =
          'Great! You\'re likely to spend less next month. Keep up the good habits!';
    } else {
      recommendation =
          'Expenses expected to remain stable. Stay mindful of your spending.';
    }

    return ExpensePrediction(
      targetMonth: targetMonth,
      predictedAmount: prediction,
      confidenceLevel: confidence,
      factors: factors,
      categoryPredictions: categoryPredictions,
      recommendation: recommendation,
    );
  }

  // Create month comparison
  Future<MonthComparison> compareMonths({
    required String userId,
    required DateTime leftMonth,
    required DateTime rightMonth,
  }) async {
    // Ensure left is before right
    if (leftMonth.isAfter(rightMonth)) {
      final temp = leftMonth;
      leftMonth = rightMonth;
      rightMonth = temp;
    }

    final leftStart = DateTime(leftMonth.year, leftMonth.month, 1);
    final leftEnd = DateTime(leftMonth.year, leftMonth.month + 1, 0);
    final rightStart = DateTime(rightMonth.year, rightMonth.month, 1);
    final rightEnd = DateTime(rightMonth.year, rightMonth.month + 1, 0);

    final leftData = await getAnalytics(
      userId: userId,
      startDate: leftStart,
      endDate: leftEnd,
    );

    final rightData = await getAnalytics(
      userId: userId,
      startDate: rightStart,
      endDate: rightEnd,
    );

    // Compare categories
    final categoryComparisons = <String, ComparisonMetric>{};
    final allCategories = {
      ...leftData.categorySpending.keys,
      ...rightData.categorySpending.keys
    };

    for (final category in allCategories) {
      final leftAmount = leftData.categorySpending[category] ?? 0;
      final rightAmount = rightData.categorySpending[category] ?? 0;
      final difference = rightAmount - leftAmount;
      final percentageChange =
          leftAmount > 0 ? (difference / leftAmount) * 100 : 100.0;

      categoryComparisons[category] = ComparisonMetric(
        category: category,
        leftAmount: leftAmount,
        rightAmount: rightAmount,
        difference: difference,
        percentageChange: percentageChange.toDouble(),
        isImprovement: difference < 0, // Less spending = improvement
      );
    }

    final totalDifference = rightData.totalExpenses - leftData.totalExpenses;
    final percentageChange = leftData.totalExpenses > 0
        ? (totalDifference / leftData.totalExpenses) * 100
        : 0.0;

    return MonthComparison(
      leftMonth: leftMonth,
      rightMonth: rightMonth,
      leftData: leftData,
      rightData: rightData,
      categoryComparisons: categoryComparisons,
      totalDifference: totalDifference,
      percentageChange: percentageChange.toDouble(),
    );
  }

  // Private helper methods
  Future<List<Transaction>> _getTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList();
  }

  Map<String, double> _calculateCategorySpending(
      List<Transaction> transactions) {
    final spending = <String, double>{};
    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      spending[t.category.label] = (spending[t.category.label] ?? 0) + t.amount;
    }
    return spending;
  }

  Map<String, double> _calculateDayOfWeekSpending(
      List<Transaction> transactions) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final spending = <String, double>{};

    for (final day in days) {
      spending[day] = 0;
    }

    for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
      final dayIndex = t.date.weekday - 1;
      spending[days[dayIndex]] = (spending[days[dayIndex]] ?? 0) + t.amount;
    }

    return spending;
  }

  Map<String, dynamic> _calculateMerchantData(
      List<Transaction> transactions) {
    final frequency = <String, int>{};
    final spending = <String, double>{};

    for (final t in transactions.where((t) => t.merchant.isNotEmpty)) {
      final merchant = t.merchant;
      frequency[merchant] = (frequency[merchant] ?? 0) + 1;
      spending[merchant] = (spending[merchant] ?? 0) + t.amount;
    }

    return {'frequency': frequency, 'spending': spending};
  }

  Future<Map<String, double>> _calculateMonthlyTrends(
      String userId, DateTime endDate) async {
    final trends = <String, double>{};

    for (int i = 5; i >= 0; i--) {
      final monthStart = DateTime(endDate.year, endDate.month - i, 1);
      final monthEnd = DateTime(endDate.year, endDate.month - i + 1, 0);

      final transactions = await _getTransactions(userId, monthStart, monthEnd);
      final total = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      final monthLabel =
          '${_getMonthName(monthStart.month).substring(0, 3)} ${monthStart.year.toString().substring(2)}';
      trends[monthLabel] = total;
    }

    return trends;
  }

  Future<double> _getBudgetForPeriod(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .doc('${startDate.year}_${startDate.month}')
          .get();

      if (doc.exists) {
        return (doc.data()?['amount'] ?? 0).toDouble();
      }
    } catch (e) {
      print('Error getting budget: $e');
    }
    return 0;
  }

  String _generateInsightText(
      String category, double change, double amount) {
    if (change > 0) {
      return 'You spent ${change.toStringAsFixed(1)}% more on $category (₹${amount.toStringAsFixed(0)} increase)';
    } else {
      return '✨ You spent ${change.abs().toStringAsFixed(1)}% less on $category (₹${amount.toStringAsFixed(0)} saved)';
    }
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
