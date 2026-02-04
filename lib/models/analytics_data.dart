// lib/models/analytics_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum InsightType {
  topSpendingCategories,
  spendingTrends,
  dayOfWeekAnalysis,
  merchantFrequency,
  budgetProgress,
  aiInsights,
}

class AnalyticsData {
  final Map<String, double> categorySpending;
  final Map<String, double> monthlyTrends;
  final Map<String, double> dayOfWeekSpending;
  final Map<String, int> merchantFrequency;
  final Map<String, double> merchantSpending;
  final double totalIncome;
  final double totalExpenses;
  final double budgetAmount;
  final double budgetUsedPercentage;
  final DateTime startDate;
  final DateTime endDate;

  AnalyticsData({
    required this.categorySpending,
    required this.monthlyTrends,
    required this.dayOfWeekSpending,
    required this.merchantFrequency,
    required this.merchantSpending,
    required this.totalIncome,
    required this.totalExpenses,
    required this.budgetAmount,
    required this.budgetUsedPercentage,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() => {
        'categorySpending': categorySpending,
        'monthlyTrends': monthlyTrends,
        'dayOfWeekSpending': dayOfWeekSpending,
        'merchantFrequency': merchantFrequency,
        'merchantSpending': merchantSpending,
        'totalIncome': totalIncome,
        'totalExpenses': totalExpenses,
        'budgetAmount': budgetAmount,
        'budgetUsedPercentage': budgetUsedPercentage,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
}

class AIInsight {
  final String category;
  final double percentageChange;
  final double amount;
  final String insight;
  final InsightSentiment sentiment;
  final DateTime generatedAt;

  AIInsight({
    required this.category,
    required this.percentageChange,
    required this.amount,
    required this.insight,
    required this.sentiment,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'percentageChange': percentageChange,
        'amount': amount,
        'insight': insight,
        'sentiment': sentiment.name,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory AIInsight.fromJson(Map<String, dynamic> json) => AIInsight(
        category: json['category'] ?? '',
        percentageChange: (json['percentageChange'] ?? 0).toDouble(),
        amount: (json['amount'] ?? 0).toDouble(),
        insight: json['insight'] ?? '',
        sentiment: InsightSentiment.values.firstWhere(
          (e) => e.name == json['sentiment'],
          orElse: () => InsightSentiment.neutral,
        ),
        generatedAt: json['generatedAt'] != null
            ? DateTime.parse(json['generatedAt'])
            : DateTime.now(),
      );
}

enum InsightSentiment {
  positive, // Spending less
  negative, // Spending more
  neutral, // No significant change
}

class MonthComparison {
  final DateTime leftMonth;
  final DateTime rightMonth;
  final AnalyticsData leftData;
  final AnalyticsData rightData;
  final Map<String, ComparisonMetric> categoryComparisons;
  final double totalDifference;
  final double percentageChange;

  MonthComparison({
    required this.leftMonth,
    required this.rightMonth,
    required this.leftData,
    required this.rightData,
    required this.categoryComparisons,
    required this.totalDifference,
    required this.percentageChange,
  });
}

class ComparisonMetric {
  final String category;
  final double leftAmount;
  final double rightAmount;
  final double difference;
  final double percentageChange;
  final bool isImprovement; // Less spending = improvement

  ComparisonMetric({
    required this.category,
    required this.leftAmount,
    required this.rightAmount,
    required this.difference,
    required this.percentageChange,
    required this.isImprovement,
  });
}

class ExpensePrediction {
  final DateTime targetMonth;
  final double predictedAmount;
  final double confidenceLevel;
  final List<String> factors;
  final Map<String, double> categoryPredictions;
  final String recommendation;

  ExpensePrediction({
    required this.targetMonth,
    required this.predictedAmount,
    required this.confidenceLevel,
    required this.factors,
    required this.categoryPredictions,
    required this.recommendation,
  });

  Map<String, dynamic> toJson() => {
        'targetMonth': targetMonth.toIso8601String(),
        'predictedAmount': predictedAmount,
        'confidenceLevel': confidenceLevel,
        'factors': factors,
        'categoryPredictions': categoryPredictions,
        'recommendation': recommendation,
      };
}
