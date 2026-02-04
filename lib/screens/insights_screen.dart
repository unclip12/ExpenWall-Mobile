// lib/screens/insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analytics_data.dart';
import '../services/analytics_service.dart';
import '../widgets/insight_card.dart';
import '../widgets/glass_app_bar.dart';
import 'comparison_screen.dart';

class InsightsScreen extends StatefulWidget {
  final String userId;

  const InsightsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  List<AIInsight>? _aiInsights;
  ExpensePrediction? _prediction;
  bool _isLoading = true;

  // Card order (saved to SharedPreferences in production)
  List<InsightType> _cardOrder = [
    InsightType.aiInsights,
    InsightType.topSpendingCategories,
    InsightType.spendingTrends,
    InsightType.budgetProgress,
    InsightType.dayOfWeekAnalysis,
    InsightType.merchantFrequency,
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final data = await _analyticsService.getAnalytics(
        userId: widget.userId,
        startDate: startDate,
        endDate: endDate,
      );

      final insights = await _analyticsService.generateAIInsights(
        userId: widget.userId,
        currentMonth: now,
      );

      final prediction = await _analyticsService.predictNextMonthExpenses(
        userId: widget.userId,
      );

      setState(() {
        _analyticsData = data;
        _aiInsights = insights;
        _prediction = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  void _moveCard(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final card = _cardOrder.removeAt(oldIndex);
      _cardOrder.insert(newIndex, card);
    });
    HapticFeedback.mediumImpact();
    // TODO: Save order to SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Insights & Analytics',
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
          : _analyticsData == null
              ? const Center(child: Text('No data available'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _cardOrder.length,
                    onReorder: _moveCard,
                    itemBuilder: (context, index) {
                      final type = _cardOrder[index];
                      return _buildInsightCard(type, index);
                    },
                  ),
                ),
    );
  }

  Widget _buildInsightCard(InsightType type, int index) {
    return InsightCard(
      key: ValueKey(type),
      type: type,
      analyticsData: _analyticsData!,
      aiInsights: _aiInsights ?? [],
      prediction: _prediction,
      onReorder: true,
    );
  }
}
