import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/welcome_balance_card.dart';

/// Dashboard Screen - Phase 2 Development
/// Feature A: Welcome + Total Balance (Implemented)
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Feature A: Welcome + Total Balance
                const WelcomeBalanceCard(
                  userName: 'Unclip',
                  totalBalance: 45230.50,
                ),
                
                const SizedBox(height: 24),
                
                // Phase 1 Complete Status Card (Keep for reference)
                GlassCard(
                  child: Column(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                        '\u23f3 B. Financial Overview Card\n'
                        '\u23f3 C. Spending Chart (7 days)\n'
                        '\u23f3 D. Budget Summary Cards\n'
                        '\u23f3 E. Recent Transactions\n'
                        '\u23f3 F. Add Transaction FAB',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: (isDark ? Colors.white : Colors.white).withOpacity(0.9),
                        ),
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
}
