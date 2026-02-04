import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/analytics_service.dart';
import '../services/expense_prediction_service.dart';
import '../models/transaction.dart';
import '../widgets/insight_card.dart';
import '../widgets/interactive_chart.dart';
import 'comparison_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class InsightsScreen extends StatefulWidget {
  final String userId;

  const InsightsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final ExpensePredictionService _predictionService = ExpensePredictionService();
  
  List<String> _cardOrder = [
    'top_categories',
    'spending_trends',
    'day_analysis',
    'merchant_frequency',
    'budget_headroom',
    'ai_insights',
    'predictions',
  ];

  @override
  void initState() {
    super.initState();
    _loadCardOrder();
  }

  Future<void> _loadCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString('insights_card_order');
    if (orderJson != null) {
      setState(() {
        _cardOrder = List<String>.from(json.decode(orderJson));
      });
    }
  }

  Future<void> _saveCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('insights_card_order', json.encode(_cardOrder));
  }

  void _moveCard(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _cardOrder.removeAt(oldIndex);
      _cardOrder.insert(newIndex, item);
    });
    _saveCardOrder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Insights & Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.compare_arrows),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ComparisonScreen(userId: widget.userId),
                    ),
                  );
                },
                tooltip: 'Compare Months',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {});
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final transactions = snapshot.data!.docs
                    .map((doc) => ExpenseTransaction.fromFirestore(doc))
                    .toList();

                return SliverReorderableList(
                  itemCount: _cardOrder.length,
                  onReorder: _moveCard,
                  itemBuilder: (context, index) {
                    final cardType = _cardOrder[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(cardType),
                      index: index,
                      child: _buildCard(cardType, transactions),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String cardType, List<ExpenseTransaction> transactions) {
    switch (cardType) {
      case 'top_categories':
        return _buildTopCategoriesCard(transactions);
      case 'spending_trends':
        return _buildSpendingTrendsCard(transactions);
      case 'day_analysis':
        return _buildDayAnalysisCard(transactions);
      case 'merchant_frequency':
        return _buildMerchantFrequencyCard(transactions);
      case 'budget_headroom':
        return _buildBudgetHeadroomCard(transactions);
      case 'ai_insights':
        return _buildAIInsightsCard(transactions);
      case 'predictions':
        return _buildPredictionsCard(transactions);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopCategoriesCard(List<ExpenseTransaction> transactions) {
    final categoryData = _analyticsService.getTopCategories(transactions, limit: 5);
    
    return InsightCard(
      title: 'Top Spending Categories',
      icon: Icons.pie_chart,
      iconColor: Colors.purple,
      child: Column(
        children: [
          const SizedBox(height: 16),
          InteractiveChart(
            type: ChartType.pie,
            data: categoryData,
            height: 250,
          ),
          const SizedBox(height: 16),
          ...categoryData.entries.take(5).map((entry) {
            final total = categoryData.values.fold<double>(0, (sum, val) => sum + val);
            final percentage = (entry.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.key)),
                  Text(
                    '₹${entry.value.toStringAsFixed(0)} ($percentage%)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendsCard(List<ExpenseTransaction> transactions) {
    final trendData = _analyticsService.getMonthlyTrends(transactions, months: 6);
    
    return InsightCard(
      title: 'Spending Trends Over Time',
      icon: Icons.show_chart,
      iconColor: Colors.blue,
      child: Column(
        children: [
          const SizedBox(height: 16),
          InteractiveChart(
            type: ChartType.line,
            data: trendData,
            height: 250,
          ),
        ],
      ),
    );
  }

  Widget _buildDayAnalysisCard(List<ExpenseTransaction> transactions) {
    final dayData = _analyticsService.getDayOfWeekAnalysis(transactions);
    
    return InsightCard(
      title: 'Day of Week Analysis',
      icon: Icons.calendar_today,
      iconColor: Colors.orange,
      child: Column(
        children: [
          const SizedBox(height: 16),
          InteractiveChart(
            type: ChartType.bar,
            data: dayData,
            height: 250,
          ),
          const SizedBox(height: 16),
          ...dayData.entries.map((entry) {
            final avg = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: avg / dayData.values.reduce((a, b) => a > b ? a : b),
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${avg.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMerchantFrequencyCard(List<ExpenseTransaction> transactions) {
    final merchantData = _analyticsService.getMerchantFrequency(transactions, limit: 10);
    
    return InsightCard(
      title: 'Top Merchants',
      icon: Icons.store,
      iconColor: Colors.green,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...merchantData.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                title: Text(entry.key),
                subtitle: Text('${entry.value} transactions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBudgetHeadroomCard(List<ExpenseTransaction> transactions) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((t) => t.date.isAfter(monthStart))
        .toList();
    
    final totalSpent = monthTransactions.fold<double>(
      0,
      (sum, t) => sum + (t.type == 'expense' ? t.amount : 0),
    );
    
    // Mock budget - in real app, fetch from user settings
    const budget = 50000.0;
    final remaining = budget - totalSpent;
    final percentage = (remaining / budget * 100).clamp(0, 100);
    
    return InsightCard(
      title: 'Budget Headroom',
      icon: Icons.account_balance_wallet,
      iconColor: percentage > 30 ? Colors.green : (percentage > 10 ? Colors.orange : Colors.red),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            '₹${remaining.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: percentage > 30 ? Colors.green : (percentage > 10 ? Colors.orange : Colors.red),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% remaining',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 30 ? Colors.green : (percentage > 10 ? Colors.orange : Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spent',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Budget',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '₹${budget.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsCard(List<ExpenseTransaction> transactions) {
    final insights = _analyticsService.getAIInsights(transactions);
    
    return InsightCard(
      title: 'AI-Powered Insights',
      icon: Icons.psychology,
      iconColor: Colors.deepPurple,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...insights.map((insight) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: insight.isPositive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: insight.isPositive ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    insight.isPositive ? Icons.trending_down : Icons.trending_up,
                    color: insight.isPositive ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.message,
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPredictionsCard(List<ExpenseTransaction> transactions) {
    final prediction = _predictionService.predictNextMonthExpense(transactions);
    
    return InsightCard(
      title: 'Expense Predictions',
      icon: Icons.analytics,
      iconColor: Colors.indigo,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo[100]!,
                  Colors.indigo[50]!,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Next Month Prediction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${prediction.predicted.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Range: ₹${prediction.minPredicted.toStringAsFixed(0)} - ₹${prediction.maxPredicted.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  prediction.insight,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Based on ${prediction.dataPoints} months of historical data',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return colors[category.hashCode % colors.length];
  }
}
