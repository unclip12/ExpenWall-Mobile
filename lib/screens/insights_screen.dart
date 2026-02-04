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

  // Card order
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
    if (!mounted) return;
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

      if (mounted) {
        setState(() {
          _analyticsData = data;
          _aiInsights = insights;
          _prediction = prediction;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Show silent error in console, avoid snackbar on init
        print('Error loading analytics: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Ensure content is visible in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient to show through
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analyticsData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.insights_outlined, 
                        size: 64, 
                        color: isDark ? Colors.white54 : Colors.grey[400]
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No insights available yet',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  color: Theme.of(context).primaryColor,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16, 
                      right: 16, 
                      top: 16, 
                      bottom: 80 // Space for bottom nav
                    ),
                    itemCount: _cardOrder.length + 1, // +1 for header
                    onReorder: (oldIndex, newIndex) {
                      // Adjust indices because of header
                      if (oldIndex == 0) return; // Can't move header
                      if (newIndex == 0) newIndex = 1; // Can't move above header
                      _moveCard(oldIndex - 1, newIndex - 1);
                    },
                    itemBuilder: (context, index) {
                      if (index == 0) {
                         // ✅ FIX: Add header inside list so it scrolls
                        return Container(
                          key: const ValueKey('header'),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Insights',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'AI-Powered Analysis',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
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
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final type = _cardOrder[index - 1];
                      return Container(
                        key: ValueKey(type),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildInsightCard(type, index - 1),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildInsightCard(InsightType type, int index) {
    return InsightCard(
      type: type,
      analyticsData: _analyticsData!,
      aiInsights: _aiInsights ?? [],
      prediction: _prediction,
      onReorder: true,
    );
  }
}
