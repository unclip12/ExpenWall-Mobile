import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/analytics_service.dart';
import '../services/expense_prediction_service.dart';
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
  
  bool _isLoading = true;
  List<InsightCardData> _insightCards = [];
  List<Map<String, dynamic>> _aiInsights = [];
  Map<String, dynamic>? _predictionData;

  // Default card order
  final List<String> _defaultCardOrder = [
    'top_categories',
    'spending_trends',
    'day_of_week',
    'merchant_frequency',
    'budget_headroom',
    'expense_prediction',
  ];

  List<String> _cardOrder = [];

  @override
  void initState() {
    super.initState();
    _loadCardOrder();
    _loadAnalytics();
  }

  Future<void> _loadCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderJson = prefs.getString('insight_card_order');
    if (orderJson != null) {
      _cardOrder = List<String>.from(json.decode(orderJson));
    } else {
      _cardOrder = List.from(_defaultCardOrder);
    }
  }

  Future<void> _saveCardOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('insight_card_order', json.encode(_cardOrder));
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get current month transactions
      final transactions = await _analyticsService.getTransactionsByDateRange(
        widget.userId,
        startOfMonth,
        endOfMonth,
      );

      // Calculate all analytics
      final topCategories = _analyticsService.calculateTopCategories(transactions);
      final spendingTrends = _analyticsService.calculateSpendingTrends(transactions);
      final dayOfWeek = _analyticsService.calculateDayOfWeekSpending(transactions);
      final merchantFreq = _analyticsService.calculateMerchantFrequency(transactions);
      final budgetHeadroom = await _analyticsService.calculateBudgetHeadroom(
        widget.userId,
        now,
      );

      // Get AI insights
      final aiInsights = await _analyticsService.generateAIInsights(
        widget.userId,
        now,
      );

      // Get expense prediction
      final prediction = await _predictionService.predictNextMonthExpenses(
        widget.userId,
        lookbackMonths: 6,
      );

      setState(() {
        _insightCards = _buildInsightCards(
          topCategories,
          spendingTrends,
          dayOfWeek,
          merchantFreq,
          budgetHeadroom,
        );
        _aiInsights = aiInsights;
        _predictionData = prediction;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  List<InsightCardData> _buildInsightCards(
    Map<String, double> topCategories,
    Map<DateTime, double> spendingTrends,
    Map<String, double> dayOfWeek,
    Map<String, int> merchantFreq,
    double budgetHeadroom,
  ) {
    return [
      InsightCardData(
        id: 'top_categories',
        title: 'Top Spending Categories',
        icon: Icons.pie_chart,
        child: InteractiveChart(
          type: ChartType.pie,
          data: topCategories,
          title: 'Category Breakdown',
        ),
      ),
      InsightCardData(
        id: 'spending_trends',
        title: 'Spending Trends',
        icon: Icons.show_chart,
        child: InteractiveChart(
          type: ChartType.line,
          data: spendingTrends.map(
            (key, value) => MapEntry(key.toString().substring(0, 10), value),
          ),
          title: 'Daily Spending',
        ),
      ),
      InsightCardData(
        id: 'day_of_week',
        title: 'Day of Week Analysis',
        icon: Icons.calendar_today,
        child: InteractiveChart(
          type: ChartType.bar,
          data: dayOfWeek,
          title: 'Average Spending by Day',
        ),
      ),
      InsightCardData(
        id: 'merchant_frequency',
        title: 'Merchant Frequency',
        icon: Icons.store,
        child: _buildMerchantList(merchantFreq),
      ),
      InsightCardData(
        id: 'budget_headroom',
        title: 'Budget Headroom',
        icon: Icons.account_balance_wallet,
        child: _buildBudgetHeadroom(budgetHeadroom),
      ),
      InsightCardData(
        id: 'expense_prediction',
        title: 'Next Month Prediction',
        icon: Icons.psychology,
        child: _buildPredictionCard(),
      ),
    ];
  }

  Widget _buildMerchantList(Map<String, int> merchantFreq) {
    if (merchantFreq.isEmpty) {
      return const Center(child: Text('No merchant data available'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: merchantFreq.length,
      itemBuilder: (context, index) {
        final entry = merchantFreq.entries.elementAt(index);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.2),
            child: Text('${index + 1}'),
          ),
          title: Text(entry.key),
          trailing: Text(
            '${entry.value} visits',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildBudgetHeadroom(double percentage) {
    final color = percentage > 50
        ? Colors.green
        : percentage > 20
            ? Colors.orange
            : Colors.red;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            percentage > 50
                ? 'Great! You\'re on track'
                : percentage > 20
                    ? 'Watch your spending'
                    : 'Budget alert!',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard() {
    if (_predictionData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final prediction = _predictionData!['prediction'] as double;
    final confidence = _predictionData!['confidence'] as double;
    final trend = _predictionData!['trend'] as String;
    final categoryPredictions = _predictionData!['categoryPredictions'] as Map<String, double>;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Predicted Spending',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${prediction.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trend == 'increasing' 
                      ? Colors.red.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      trend == 'increasing' ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: trend == 'increasing' ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend == 'increasing' ? 'Increasing' : 'Decreasing',
                      style: TextStyle(
                        color: trend == 'increasing' ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence > 70 ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Confidence: ${confidence.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Top Predicted Categories:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...categoryPredictions.entries.take(3).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _moveCardUp(int index) {
    if (index > 0) {
      setState(() {
        final card = _cardOrder.removeAt(index);
        _cardOrder.insert(index - 1, card);
        _saveCardOrder();
      });
      HapticFeedback.lightImpact();
    }
  }

  void _moveCardDown(int index) {
    if (index < _cardOrder.length - 1) {
      setState(() {
        final card = _cardOrder.removeAt(index);
        _cardOrder.insert(index + 1, card);
        _saveCardOrder();
      });
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
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
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AI Insights Section
                    if (_aiInsights.isNotEmpty) ..[
                      const Text(
                        'AI-Powered Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._aiInsights.map((insight) => _buildAIInsightCard(insight)),
                      const SizedBox(height: 24),
                    ],

                    // Reorderable Cards
                    const Text(
                      'Analytics Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildOrderedCards(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAIInsightCard(Map<String, dynamic> insight) {
    final isGood = insight['isGood'] as bool;
    final color = isGood ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(
            insight['icon'] as String,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['message'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isGood)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '⭐ Great job!',
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrderedCards() {
    final orderedCards = <Widget>[];

    for (var i = 0; i < _cardOrder.length; i++) {
      final cardId = _cardOrder[i];
      final cardData = _insightCards.firstWhere(
        (card) => card.id == cardId,
        orElse: () => _insightCards.first,
      );

      orderedCards.add(
        InsightCard(
          data: cardData,
          onMoveUp: i > 0 ? () => _moveCardUp(i) : null,
          onMoveDown: i < _cardOrder.length - 1 ? () => _moveCardDown(i) : null,
        ),
      );
    }

    return orderedCards;
  }
}

class InsightCardData {
  final String id;
  final String title;
  final IconData icon;
  final Widget child;

  InsightCardData({
    required this.id,
    required this.title,
    required this.icon,
    required this.child,
  });
}
