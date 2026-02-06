import 'package:flutter/material.dart';
import 'glass_card.dart';
import 'package:intl/intl.dart';

/// Feature A: Welcome + Total Balance Card
/// 
/// Displays:
/// - Time-based greeting (Good Morning/Afternoon/Evening/Night)
/// - User's first name
/// - Animated total balance with Indian currency formatting
class WelcomeBalanceCard extends StatefulWidget {
  final String userName;
  final double totalBalance;
  
  const WelcomeBalanceCard({
    Key? key,
    required this.userName,
    required this.totalBalance,
  }) : super(key: key);

  @override
  State<WelcomeBalanceCard> createState() => _WelcomeBalanceCardState();
}

class _WelcomeBalanceCardState extends State<WelcomeBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.totalBalance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Greeting with emoji
          Text(
            '${_getGreeting()}, ${widget.userName}! ${_getGreetingEmoji()}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Animated Balance
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Text(
                _formatCurrency(_animation.value),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            'Your Total Balance',
            style: TextStyle(
              fontSize: 16,
              color: (isDark ? Colors.white : Colors.white).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Get time-based greeting
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 22) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  /// Get emoji for greeting
  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return '☀️';
    } else if (hour >= 12 && hour < 17) {
      return '🌤️';
    } else if (hour >= 17 && hour < 22) {
      return '🌆';
    } else {
      return '🌙';
    }
  }

  /// Format currency in Indian format (₹ #,##,###.##)
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
}
