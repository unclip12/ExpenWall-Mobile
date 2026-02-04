import '../models/transaction.dart';
import 'dart:math';

class ExpensePrediction {
  final double predicted;
  final double minPredicted;
  final double maxPredicted;
  final String insight;
  final int dataPoints;

  ExpensePrediction({
    required this.predicted,
    required this.minPredicted,
    required this.maxPredicted,
    required this.insight,
    required this.dataPoints,
  });
}

class ExpensePredictionService {
  ExpensePrediction predictNextMonthExpense(List<ExpenseTransaction> transactions) {
    final now = DateTime.now();
    final monthlyExpenses = <double>[];
    
    // Collect monthly expenses for the past 12 months
    for (int i = 1; i <= 12; i++) {
      final monthStart = DateTime(now.year, now.month - i, 1);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);
      
      final monthTotal = transactions
          .where((t) => 
              t.type == 'expense' &&
              t.date.isAfter(monthStart) &&
              t.date.isBefore(monthEnd.add(const Duration(days: 1))))
          .fold<double>(0, (sum, t) => sum + t.amount);
      
      if (monthTotal > 0) {
        monthlyExpenses.add(monthTotal);
      }
    }
    
    if (monthlyExpenses.isEmpty) {
      return ExpensePrediction(
        predicted: 0,
        minPredicted: 0,
        maxPredicted: 0,
        insight: 'Not enough data to make predictions. Start tracking expenses!',
        dataPoints: 0,
      );
    }
    
    // Calculate statistics
    final average = monthlyExpenses.reduce((a, b) => a + b) / monthlyExpenses.length;
    final sortedExpenses = List<double>.from(monthlyExpenses)..sort();
    
    // Calculate standard deviation
    final variance = monthlyExpenses
        .map((x) => pow(x - average, 2))
        .reduce((a, b) => a + b) / monthlyExpenses.length;
    final stdDev = sqrt(variance);
    
    // Weighted average (more weight to recent months)
    double weightedSum = 0;
    double weightSum = 0;
    for (int i = 0; i < monthlyExpenses.length; i++) {
      final weight = (i + 1).toDouble(); // More recent = higher weight
      weightedSum += monthlyExpenses[i] * weight;
      weightSum += weight;
    }
    final weightedAverage = weightedSum / weightSum;
    
    // Trend detection (simple linear regression)
    final trend = _calculateTrend(monthlyExpenses);
    
    // Combine weighted average with trend
    final predicted = weightedAverage + trend;
    final minPredicted = max(0, predicted - stdDev);
    final maxPredicted = predicted + stdDev;
    
    // Generate insight
    String insight;
    if (trend > 0) {
      final increasePercent = (trend / average * 100).abs();
      if (increasePercent > 10) {
        insight = '⚠️ Your spending is trending upward by ${increasePercent.toStringAsFixed(1)}%. '
            'Consider reviewing your budget.';
      } else {
        insight = 'Your spending is stable with a slight upward trend. Keep monitoring!';
      }
    } else if (trend < 0) {
      final decreasePercent = (trend / average * 100).abs();
      if (decreasePercent > 10) {
        insight = '🎉 Great job! Your spending is trending downward by ${decreasePercent.toStringAsFixed(1)}%. '
            'Keep up the good work!';
      } else {
        insight = 'Your spending is relatively stable. Good control!';
      }
    } else {
      insight = 'Your spending pattern is consistent. Maintain this balance!';
    }
    
    // Add seasonal insight if applicable
    final currentMonth = now.month;
    if (_isHighSpendingMonth(currentMonth)) {
      insight += ' Note: This month typically has higher expenses due to seasonal factors.';
    }
    
    return ExpensePrediction(
      predicted: predicted,
      minPredicted: minPredicted,
      maxPredicted: maxPredicted,
      insight: insight,
      dataPoints: monthlyExpenses.length,
    );
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;
    
    final n = values.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;
    
    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = values[i];
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }
    
    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope * n; // Project the trend to the next month
  }

  bool _isHighSpendingMonth(int month) {
    // Months with typically higher spending (holidays, festivals)
    const highSpendingMonths = [1, 10, 11, 12]; // Jan, Oct, Nov, Dec
    return highSpendingMonths.contains(month);
  }

  List<double> predictNextMonths(List<ExpenseTransaction> transactions, int months) {
    final predictions = <double>[];
    final basePrediction = predictNextMonthExpense(transactions);
    
    for (int i = 0; i < months; i++) {
      // Simple projection - in real app, use more sophisticated models
      predictions.add(basePrediction.predicted * (1 + (i * 0.02))); // 2% monthly growth assumption
    }
    
    return predictions;
  }
}
