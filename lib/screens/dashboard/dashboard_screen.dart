import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/welcome_balance_card.dart';
import '../../widgets/financial_overview_card.dart';
import '../../widgets/spending_chart_card.dart';

/// Dashboard Screen - Phase 2 Development
/// Feature A: Welcome + Total Balance (Complete)
/// Feature B: Financial Overview Card (Complete)
/// Feature C: Spending Chart - Enhanced (Implemented)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Extended dummy spending data for Feature C testing
    final spendingData = _generateExtendedSpendingData();
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.primary.withOpacity(0.8),
                    theme.colorScheme.secondary.withOpacity(0.6),
                    theme.colorScheme.tertiary.withOpacity(0.4),
                  ]
                : [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                    theme.colorScheme.tertiary,
                  ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Feature A: Welcome + Total Balance
                const WelcomeBalanceCard(
                  userName: 'Unclip',
                  totalBalance: 45230.50,
                ),
                
                const SizedBox(height: 20),
                
                // Feature B: Financial Overview
                const FinancialOverviewCard(
                  income: 50000,
                  expense: 32450,
                ),
                
                const SizedBox(height: 20),
                
                // Feature C: Enhanced Spending Chart
                SpendingChartCard(
                  spendingData: spendingData,
                ),
                
                const SizedBox(height: 24),
                
                // Phase 1 Complete Status Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.greenAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Phase 1 Complete! \u2705',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Foundation Setup:\n\n'
                        '\u2705 Liquid Morphism Themes\n'
                        '\u2705 Glass Morphism Effects\n'
                        '\u2705 5-Tab Navigation\n'
                        '\u2705 Coming Soon Screens\n'
                        '\u2705 Material 3 Design\n'
                        '\u2705 Haptic Feedback',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: (isDark ? Colors.white : Colors.white).withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Phase 2 In Progress',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Phase 2 Progress Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.construction,
                            size: 32,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Phase 2: Dashboard',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Features Progress:\n\n'
                        '\u2705 A. Welcome + Total Balance\n'
                        '\u2705 B. Financial Overview Card\n'
                        '\u2705 C. Spending Chart (Enhanced)\n'
                        '\u23f3 D. Budget Summary Cards\n'
                        '\u23f3 E. Recent Transactions\n'
                        '\u23f3 F. Add Transaction FAB',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: (isDark ? Colors.white : Colors.white).withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Generate 21 days of dummy spending data (3 pages for scrolling test)
  List<DailySpending> _generateExtendedSpendingData() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final categories = [
      SpendingCategory.food,
      SpendingCategory.transport,
      SpendingCategory.shopping,
      SpendingCategory.bills,
      SpendingCategory.entertainment,
    ];
    
    return [
      // Week 1 (21 days ago)
      DailySpending(day: 'Mon', amount: 4200, date: now.subtract(const Duration(days: 20)), category: SpendingCategory.food),
      DailySpending(day: 'Tue', amount: 3800, date: now.subtract(const Duration(days: 19)), category: SpendingCategory.transport),
      DailySpending(day: 'Wed', amount: 5100, date: now.subtract(const Duration(days: 18)), category: SpendingCategory.shopping),
      DailySpending(day: 'Thu', amount: 4500, date: now.subtract(const Duration(days: 17)), category: SpendingCategory.bills),
      DailySpending(day: 'Fri', amount: 6200, date: now.subtract(const Duration(days: 16)), category: SpendingCategory.entertainment),
      DailySpending(day: 'Sat', amount: 7500, date: now.subtract(const Duration(days: 15)), category: SpendingCategory.food),
      DailySpending(day: 'Sun', amount: 3200, date: now.subtract(const Duration(days: 14)), category: SpendingCategory.entertainment),
      
      // Week 2 (14 days ago)
      DailySpending(day: 'Mon', amount: 3900, date: now.subtract(const Duration(days: 13)), category: SpendingCategory.food),
      DailySpending(day: 'Tue', amount: 4700, date: now.subtract(const Duration(days: 12)), category: SpendingCategory.transport),
      DailySpending(day: 'Wed', amount: 5300, date: now.subtract(const Duration(days: 11)), category: SpendingCategory.bills),
      DailySpending(day: 'Thu', amount: 6100, date: now.subtract(const Duration(days: 10)), category: SpendingCategory.shopping),
      DailySpending(day: 'Fri', amount: 4800, date: now.subtract(const Duration(days: 9)), category: SpendingCategory.entertainment),
      DailySpending(day: 'Sat', amount: 8200, date: now.subtract(const Duration(days: 8)), category: SpendingCategory.food),
      DailySpending(day: 'Sun', amount: 3600, date: now.subtract(const Duration(days: 7)), category: SpendingCategory.entertainment),
      
      // Week 3 (Current week)
      DailySpending(day: 'Mon', amount: 3500, date: now.subtract(const Duration(days: 6)), category: SpendingCategory.food),
      DailySpending(day: 'Tue', amount: 5200, date: now.subtract(const Duration(days: 5)), category: SpendingCategory.transport),
      DailySpending(day: 'Wed', amount: 4100, date: now.subtract(const Duration(days: 4)), category: SpendingCategory.bills),
      DailySpending(day: 'Thu', amount: 6800, date: now.subtract(const Duration(days: 3)), category: SpendingCategory.shopping),
      DailySpending(day: 'Fri', amount: 4500, date: now.subtract(const Duration(days: 2)), category: SpendingCategory.entertainment),
      DailySpending(day: 'Sat', amount: 7200, date: now.subtract(const Duration(days: 1)), category: SpendingCategory.food),
      DailySpending(day: 'Sun', amount: 3800, date: now, category: SpendingCategory.entertainment),
    ];
  }
}
