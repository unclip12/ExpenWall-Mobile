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

// ✅ AutomaticKeepAliveClientMixin prevents rebuilds during tab switches
class _InsightsScreenState extends State<InsightsScreen> with AutomaticKeepAliveClientMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  List<AIInsight>? _aiInsights;
  ExpensePrediction? _prediction;
  bool _isLoading = true;

  // Card order (fixed list to avoid drag-state overlays blocking interactions)
  static const List<InsightType> _cardOrder = [
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

  @override
  bool get wantKeepAlive => true;

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final results = await Future.wait([
        _analyticsService.getAnalytics(
          userId: widget.userId,
          startDate: startDate,
          endDate: endDate,
        ),
        _analyticsService.generateAIInsights(
          userId: widget.userId,
          currentMonth: now,
        ),
        _analyticsService.predictNextMonthExpenses(
          userId: widget.userId,
        ),
      ]).timeout(const Duration(seconds: 20));

      final data = results[0] as AnalyticsData;
      final insights = results[1] as List<AIInsight>;
      final prediction = results[2] as ExpensePrediction;

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
        print('Error loading analytics: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    // 🔥 BULLETPROOF FIX: Triple-layer approach to eliminate grey screen
    // Layer 1: SizedBox.expand forces widget to fill PageView space
    // Layer 2: Container with solid color (never transparent)
    // Layer 3: Scaffold with explicit states (loading/empty/content)
    return SizedBox.expand(
      child: Container(
        // 🎨 SOLID BACKGROUND COLOR - This prevents grey screen
        color: isDark 
            ? const Color(0xFF0A0E1A)  // Dark purple background
            : const Color(0xFFFAF5FF),  // Light purple background
        child: Scaffold(
          backgroundColor: Colors.transparent, // Let container color show through
          body: SafeArea(
            child: _buildBody(context, isDark, theme),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, ThemeData theme) {
    // 🔄 LOADING STATE - Colorful spinner + text
    if (_isLoading) {
      return Container(
        color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFFAF5FF),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading Insights...',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 📭 EMPTY STATE - No data available
    if (_analyticsData == null) {
      return Container(
        color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFFAF5FF),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insights_outlined, 
                  size: 80, 
                  color: theme.primaryColor.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Insights Available',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Add some transactions to see\nyour spending insights',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ CONTENT STATE - Show insight cards
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      color: theme.primaryColor,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 16, 
          right: 16, 
          top: 16, 
          bottom: 100,
        ),
        itemCount: _cardOrder.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
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
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-Powered Analysis',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white60 : Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.compare_arrows,
                      color: theme.primaryColor,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComparisonScreen(userId: widget.userId),
                        ),
                      );
                    },
                    tooltip: 'Compare Months',
                    iconSize: 28,
                  ),
                ],
              ),
            );
          }
          
          final type = _cardOrder[index - 1];
          return Container(
            key: ValueKey(type),
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildInsightCard(type),
          );
        },
      ),
    );
  }

  Widget _buildInsightCard(InsightType type) {
    return InsightCard(
      type: type,
      analyticsData: _analyticsData!,
      aiInsights: _aiInsights ?? [],
      prediction: _prediction,
      onReorder: false,
    );
  }
}
