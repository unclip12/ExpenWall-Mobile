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

// ✅ CRITICAL FIX: Implements AutomaticKeepAliveClientMixin to prevent rebuilds
// This keeps the screen alive during tab switches for smooth transitions
class _InsightsScreenState extends State<InsightsScreen> with AutomaticKeepAliveClientMixin {
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

  // ✅ Keep the screen alive (prevents rebuild lag during tab switching)
  @override
  bool get wantKeepAlive => true;

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
    // ✅ CRITICAL: Call super.build when using AutomaticKeepAliveClientMixin
    super.build(context);
    
    // ✅ FIX: Ensure content is visible in dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    
    // ✅ CRITICAL FIX: Use Container with explicit color to prevent grey background
    // This ensures the screen is NEVER just a blank grey void
    return Container(
      // Solid background that matches the app's theme (not transparent)
      // This prevents the "grey screen" issue
      color: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFFAF5FF),
      child: Scaffold(
        // ✅ FIX: Use theme-based background instead of transparent
        backgroundColor: Colors.transparent, // Allow container color to show
        body: SafeArea(
          child: _isLoading
              // ✅ VISIBLE LOADING STATE with theme colors
              ? Center(
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
                )
              : _analyticsData == null
                  // ✅ VISIBLE EMPTY STATE with colors and action button
                  ? Center(
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
                    )
                  // ✅ CONTENT STATE with BouncingScrollPhysics for smooth vertical scrolling
                  : RefreshIndicator(
                      onRefresh: _loadAnalytics,
                      color: theme.primaryColor,
                      child: ReorderableListView.builder(
                        // ✅ WATER: Use BouncingScrollPhysics ONLY for vertical scrolling
                        // This is for CONTENT scrolling, not navigation
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 16, 
                          right: 16, 
                          top: 16, 
                          bottom: 100 // Extra space for bottom nav
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
                            // ✅ FIX: Header with proper theme colors
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
                            child: _buildInsightCard(type, index - 1),
                          );
                        },
                      ),
                    ),
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
