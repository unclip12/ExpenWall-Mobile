// lib/widgets/insight_card.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_data.dart';
import 'glass_card.dart';

class InsightCard extends StatelessWidget {
  final InsightType type;
  final AnalyticsData analyticsData;
  final List<AIInsight> aiInsights;
  final ExpensePrediction? prediction;
  final bool onReorder;

  const InsightCard({
    Key? key,
    required this.type,
    required this.analyticsData,
    required this.aiInsights,
    this.prediction,
    this.onReorder = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 16),
            _buildContent(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    return Row(
      children: [
        if (onReorder) ...[
          Icon(Icons.drag_handle, color: secondaryText, size: 20),
          const SizedBox(width: 8),
        ],
        Icon(_getIcon(), color: primaryText, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    switch (type) {
      case InsightType.topSpendingCategories:
        return _buildTopCategories(isDark);
      case InsightType.spendingTrends:
        return _buildTrendChart(isDark);
      case InsightType.dayOfWeekAnalysis:
        return _buildDayOfWeekChart(isDark);
      case InsightType.merchantFrequency:
        return _buildMerchantList(isDark);
      case InsightType.budgetProgress:
        return _buildBudgetProgress(isDark);
      case InsightType.aiInsights:
        return _buildAIInsights(isDark);
    }
  }

  IconData _getIcon() {
    switch (type) {
      case InsightType.topSpendingCategories:
        return Icons.pie_chart;
      case InsightType.spendingTrends:
        return Icons.trending_up;
      case InsightType.dayOfWeekAnalysis:
        return Icons.calendar_today;
      case InsightType.merchantFrequency:
        return Icons.store;
      case InsightType.budgetProgress:
        return Icons.account_balance_wallet;
      case InsightType.aiInsights:
        return Icons.auto_awesome;
    }
  }

  String _getTitle() {
    switch (type) {
      case InsightType.topSpendingCategories:
        return 'Top Spending Categories';
      case InsightType.spendingTrends:
        return 'Spending Trends';
      case InsightType.dayOfWeekAnalysis:
        return 'Day of Week Analysis';
      case InsightType.merchantFrequency:
        return 'Top Merchants';
      case InsightType.budgetProgress:
        return 'Budget Progress';
      case InsightType.aiInsights:
        return 'AI-Powered Insights';
    }
  }

  Widget _buildTopCategories(bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final sortedCategories = analyticsData.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();

    if (topCategories.isEmpty) {
      return Text('No spending data', style: TextStyle(color: secondaryText));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: topCategories.map((entry) {
                final percentage =
                    (entry.value / analyticsData.totalExpenses) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...topCategories.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(color: primaryText),
                ),
                Text(
                  '₹${entry.value.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: primaryText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendChart(bool isDark) {
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    if (analyticsData.monthlyTrends.isEmpty) {
      return Text('No trend data', style: TextStyle(color: secondaryText));
    }

    final spots = analyticsData.monthlyTrends.entries
        .toList()
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = analyticsData.monthlyTrends.keys.toList();
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 10,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: (isDark ? Colors.white : Colors.black)
                  .withOpacity(0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildDayOfWeekChart(bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    if (analyticsData.dayOfWeekSpending.isEmpty) {
      return Text('No day data', style: TextStyle(color: secondaryText));
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxSpending = analyticsData.dayOfWeekSpending.values
        .reduce((a, b) => a > b ? a : b);

    return Column(
      children: days.map((day) {
        final amount = analyticsData.dayOfWeekSpending[day] ?? 0;
        final percentage = maxSpending > 0 ? amount / maxSpending : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage.toDouble(),
                backgroundColor: (isDark ? Colors.white : Colors.black)
                    .withOpacity(0.08),
                valueColor: const AlwaysStoppedAnimation(Colors.blue),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMerchantList(bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final sortedMerchants = analyticsData.merchantFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topMerchants = sortedMerchants.take(5).toList();

    if (topMerchants.isEmpty) {
      return Text('No merchant data', style: TextStyle(color: secondaryText));
    }

    return Column(
      children: topMerchants.map((entry) {
        final spending = analyticsData.merchantSpending[entry.key] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value} transactions',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${spending.toStringAsFixed(0)}',
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBudgetProgress(bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    final percentage = analyticsData.budgetUsedPercentage;
    final remaining = analyticsData.budgetAmount - analyticsData.totalExpenses;
    final color = percentage > 90
        ? Colors.red
        : percentage > 70
            ? Colors.orange
            : Colors.green;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                Text(
                  '₹${analyticsData.budgetAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Spent',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                ),
                Text(
                  '₹${analyticsData.totalExpenses.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0).toDouble(),
            minHeight: 20,
            backgroundColor:
                (isDark ? Colors.white : Colors.black).withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${percentage.toStringAsFixed(1)}% used',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₹${remaining.toStringAsFixed(0)} left',
              style: TextStyle(
                color: secondaryText,
              ),
            ),
          ],
        ),
        if (prediction != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next Month Prediction',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryText,
                        ),
                      ),
                      Text(
                        '₹${prediction!.predictedAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(prediction!.confidenceLevel * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAIInsights(bool isDark) {
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.black54;
    if (aiInsights.isEmpty) {
      return Text(
        'No significant changes detected',
        style: TextStyle(color: secondaryText),
      );
    }

    return Column(
      children: aiInsights.map((insight) {
        final color = insight.sentiment == InsightSentiment.positive
            ? Colors.green
            : insight.sentiment == InsightSentiment.negative
                ? Colors.red
                : Colors.blue;

        final icon = insight.sentiment == InsightSentiment.positive
            ? Icons.trending_down
            : insight.sentiment == InsightSentiment.negative
                ? Icons.trending_up
                : Icons.info;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.insight,
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
