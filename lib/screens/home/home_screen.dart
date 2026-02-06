import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dashboard/dashboard_screen.dart';
import '../../widgets/coming_soon_screen.dart';

/// Main Home Screen with 5-tab bottom navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // All 5 screens
  final List<Widget> _screens = [
    const DashboardScreen(),                              // Tab 0: Dashboard
    const ComingSoonScreen(                               // Tab 1: Expenses
      title: 'Expenses',
      icon: Icons.receipt_long,
      message: 'Track all your transactions\nin one place.\n\nComing Soon!',
    ),
    const ComingSoonScreen(                               // Tab 2: Planning
      title: 'Planning',
      icon: Icons.calendar_month,
      message: 'Manage budgets, bills,\nand shopping lists.\n\nComing Soon!',
    ),
    const ComingSoonScreen(                               // Tab 3: Social
      title: 'Social',
      icon: Icons.people,
      message: 'Split bills and track\nyour cravings.\n\nComing Soon!',
    ),
    const ComingSoonScreen(                               // Tab 4: Insights
      title: 'Insights',
      icon: Icons.insights,
      message: 'AI-powered analytics\nand predictions.\n\nComing Soon!',
    ),
  ];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      // Haptic feedback on tab change
      HapticFeedback.lightImpact();
      
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.5),   // Darker: was 0.15
                theme.colorScheme.secondary.withOpacity(0.45), // Darker: was 0.12
                theme.colorScheme.tertiary.withOpacity(0.4),  // Darker: was 0.1
              ],
            ),
            border: Border(
              top: BorderSide(
                color: (isDark ? Colors.white : Colors.white).withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 65,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Dashboard',
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.receipt_long_outlined,
                    activeIcon: Icons.receipt_long,
                    label: 'Expenses',
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    label: 'Planning',
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Social',
                    theme: theme,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    index: 4,
                    icon: Icons.insights_outlined,
                    activeIcon: Icons.insights,
                    label: 'Insights',
                    theme: theme,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isActive = _currentIndex == index;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.45),  // Darker: was 0.25
                      theme.colorScheme.secondary.withOpacity(0.4),  // Darker: was 0.2
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: isActive ? 26 : 24,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.white70),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
