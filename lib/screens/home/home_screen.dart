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
    
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.black.withOpacity(0.9) 
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: isDark ? Colors.white54 : Colors.black54,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Planning',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Social',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
