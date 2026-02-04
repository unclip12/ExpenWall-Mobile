import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'dart:math' as math;

class ExpensePredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Predict next month's expenses with detailed breakdown
  Future<Map<String, dynamic>> predictNextMonthExpenses(
    String userId, {
    int lookbackMonths = 6,
  }) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month - lookbackMonths, 1);
      final endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get historical transactions
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final transactions = snapshot.docs
          .map((doc) => Transaction.fromFirestore(doc))
          .where((t) => t.type == 'expense')
          .toList();

      if (transactions.isEmpty) {
        return _emptyPrediction();
      }

      // Group by month
      final monthlyData = <String, List<Transaction>>{};
      for (var transaction in transactions) {
        final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
        monthlyData.putIfAbsent(monthKey, () => []).add(transaction);
      }

      // Calculate monthly totals
      final monthlyTotals = <double>[];
      final categoryMonthlyTotals = <String, List<double>>{};

      monthlyData.forEach((month, txns) {
        final total = txns.fold(0.0, (sum, t) => sum + t.amount);
        monthlyTotals.add(total);

        // Track by category
        for (var txn in txns) {
          categoryMonthlyTotals
              .putIfAbsent(txn.category, () => [])
              .add(txn.amount);
        }
      });

      // Calculate statistics
      final avgMonthly = monthlyTotals.reduce((a, b) => a + b) / monthlyTotals.length;
      final maxMonthly = monthlyTotals.reduce(math.max);
      final minMonthly = monthlyTotals.reduce(math.min);
      
      // Calculate standard deviation
      final variance = monthlyTotals
          .map((x) => math.pow(x - avgMonthly, 2))
          .reduce((a, b) => a + b) / monthlyTotals.length;
      final stdDev = math.sqrt(variance);

      // Check for trend (linear regression)
      final trend = _calculateTrend(monthlyTotals);

      // Predict next month (weighted: 50% average, 30% trend, 20% recent)
      final recentAvg = monthlyTotals.length >= 2
          ? (monthlyTotals.last + monthlyTotals[monthlyTotals.length - 2]) / 2
          : monthlyTotals.last;

      final prediction = (avgMonthly * 0.5) + 
                        (trend * 0.3) + 
                        (recentAvg * 0.2);

      // Predict by category
      final categoryPredictions = <String, double>{};
      categoryMonthlyTotals.forEach((category, amounts) {
        final catAvg = amounts.reduce((a, b) => a + b) / amounts.length;
        categoryPredictions[category] = catAvg;
      });

      // Sort categories by predicted amount
      final sortedCategories = categoryPredictions.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Calculate confidence score (0-100)
      // Lower std dev = higher confidence
      final coefficientOfVariation = (stdDev / avgMonthly) * 100;
      final confidence = math.max(0, math.min(100, 100 - coefficientOfVariation));

      return {
        'prediction': prediction,
        'minEstimate': prediction - stdDev,
        'maxEstimate': prediction + stdDev,
        'confidence': confidence,
        'averageMonthly': avgMonthly,
        'lastMonthActual': monthlyTotals.isNotEmpty ? monthlyTotals.last : 0,
        'trend': trend > avgMonthly ? 'increasing' : 'decreasing',
        'trendPercentage': ((trend - avgMonthly) / avgMonthly * 100).abs(),
        'categoryPredictions': Map.fromEntries(sortedCategories.take(5)),
        'monthsAnalyzed': monthlyTotals.length,
        'historicalRange': {
          'min': minMonthly,
          'max': maxMonthly,
        },
      };
    } catch (e) {
      print('Error predicting expenses: $e');
      return _emptyPrediction();
    }
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return values.isNotEmpty ? values.first : 0;

    // Simple linear regression
    final n = values.length;
    var sumX = 0.0;
    var sumY = 0.0;
    var sumXY = 0.0;
    var sumX2 = 0.0;

    for (var i = 0; i < n; i++) {
      sumX += i;
      sumY += values[i];
      sumXY += i * values[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict for next month
    return slope * n + intercept;
  }

  Map<String, dynamic> _emptyPrediction() {
    return {
      'prediction': 0.0,
      'minEstimate': 0.0,
      'maxEstimate': 0.0,
      'confidence': 0.0,
      'averageMonthly': 0.0,
      'lastMonthActual': 0.0,
      'trend': 'unknown',
      'trendPercentage': 0.0,
      'categoryPredictions': {},
      'monthsAnalyzed': 0,
      'historicalRange': {'min': 0.0, 'max': 0.0},
    };
  }

  // Get spending velocity (trend over time)
  Future<Map<String, dynamic>> getSpendingVelocity(
    String userId,
    int months,
  ) async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months, 1);
    final endDate = DateTime(now.year, now.month + 1, 0);

    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: 'expense')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final transactions = snapshot.docs
        .map((doc) => Transaction.fromFirestore(doc))
        .toList();

    // Calculate daily average
    final totalDays = endDate.difference(startDate).inDays;
    final totalSpent = transactions.fold(0.0, (sum, t) => sum + t.amount);
    final dailyAverage = totalSpent / totalDays;

    return {
      'dailyAverage': dailyAverage,
      'projectedMonthly': dailyAverage * 30,
      'totalSpent': totalSpent,
      'daysAnalyzed': totalDays,
    };
  }
}
