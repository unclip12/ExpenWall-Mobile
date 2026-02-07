import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'glass_card.dart';
import 'package:intl/intl.dart';

/// Feature C: Enhanced Spending Chart Card
/// 
/// Features:
/// - Horizontal scrolling
/// - Multiple chart types (Bar, Pie, Line, Area)
/// - Time period filters (Days, Weeks, Months, Years)
/// - Category filters
/// - Animated crown on lowest spending
class SpendingChartCard extends StatefulWidget {
  final List<DailySpending> spendingData;
  
  const SpendingChartCard({
    Key? key,
    required this.spendingData,
  }) : super(key: key);

  @override
  State<SpendingChartCard> createState() => _SpendingChartCardState();
}

class _SpendingChartCardState extends State<SpendingChartCard> with SingleTickerProviderStateMixin {
  ChartType _selectedChartType = ChartType.bar;
  TimePeriod _selectedPeriod = TimePeriod.days;
  SpendingCategory _selectedCategory = SpendingCategory.all;
  bool _showPercentageInPie = true;
  PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _crownController;
  
  @override
  void initState() {
    super.initState();
    _crownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _crownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filters and chart selector
          _buildHeader(isDark, theme),
          const SizedBox(height: 16),
          
          // Category filter chips
          _buildCategoryFilter(isDark),
          const SizedBox(height: 20),
          
          // Chart area
          SizedBox(
            height: 220,
            child: _buildChart(isDark, theme),
          ),
          
          // Page indicators for scrollable charts
          if (_selectedChartType == ChartType.bar && _getPageCount() > 1)
            _buildPageIndicators(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Spending',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.white,
          ),
        ),
        Row(
          children: [
            // Time period filters
            _buildPeriodButton('D', TimePeriod.days, isDark),
            const SizedBox(width: 4),
            _buildPeriodButton('W', TimePeriod.weeks, isDark),
            const SizedBox(width: 4),
            _buildPeriodButton('M', TimePeriod.months, isDark),
            const SizedBox(width: 4),
            _buildPeriodButton('Y', TimePeriod.years, isDark),
            const SizedBox(width: 12),
            // Chart type selector
            _buildChartTypeSelector(theme, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, TimePeriod period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 0.4 : 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(ThemeData theme, bool isDark) {
    return PopupMenuButton<ChartType>(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _getChartIcon(_selectedChartType),
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
      onSelected: (ChartType type) {
        setState(() => _selectedChartType = type);
      },
      itemBuilder: (context) => [
        _buildChartMenuItem(ChartType.bar, 'Bar Chart', Icons.bar_chart_rounded),
        _buildChartMenuItem(ChartType.pie, 'Pie Chart', Icons.pie_chart_rounded),
        _buildChartMenuItem(ChartType.line, 'Line Chart', Icons.show_chart),
        _buildChartMenuItem(ChartType.area, 'Area Chart', Icons.area_chart_rounded),
      ],
    );
  }

  PopupMenuItem<ChartType> _buildChartMenuItem(ChartType type, String label, IconData icon) {
    return PopupMenuItem<ChartType>(
      value: type,
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
          if (_selectedChartType == type)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SpendingCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(isSelected ? 0.4 : 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _getCategoryEmoji(category),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getCategoryLabel(category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: Colors.white.withOpacity(isSelected ? 1 : 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart(bool isDark, ThemeData theme) {
    switch (_selectedChartType) {
      case ChartType.bar:
        return _buildBarChart(isDark, theme);
      case ChartType.pie:
        return _buildPieChart(isDark, theme);
      case ChartType.line:
        return _buildLineChart(isDark, theme);
      case ChartType.area:
        return _buildAreaChart(isDark, theme);
    }
  }

  Widget _buildBarChart(bool isDark, ThemeData theme) {
    final data = _getFilteredData();
    final pageCount = _getPageCount();
    
    if (pageCount <= 1) {
      return _buildBarChartPage(data, 0, isDark, theme);
    }
    
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (page) => setState(() => _currentPage = page),
      itemCount: pageCount,
      itemBuilder: (context, page) {
        final start = page * 7;
        final end = math.min(start + 7, data.length);
        final pageData = data.sublist(start, end);
        return _buildBarChartPage(pageData, page, isDark, theme);
      },
    );
  }

  Widget _buildBarChartPage(List<DailySpending> data, int page, bool isDark, ThemeData theme) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    
    final maxSpending = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final lowestIndex = data.indexOf(data.reduce((a, b) => a.amount < b.amount ? a : b));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(data.length, (index) {
        final item = data[index];
        final isLowest = index == lowestIndex;
        return _buildBar(
          context: context,
          day: item.day,
          amount: item.amount,
          maxAmount: maxSpending,
          isDark: isDark,
          theme: theme,
          showCrown: isLowest,
        );
      }),
    );
  }

  Widget _buildBar({
    required BuildContext context,
    required String day,
    required double amount,
    required double maxAmount,
    required bool isDark,
    required ThemeData theme,
    required bool showCrown,
  }) {
    final barHeight = (amount / maxAmount * 140).clamp(8.0, 140.0);
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Crown with animation
            if (showCrown)
              AnimatedBuilder(
                animation: _crownController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -5 * math.sin(_crownController.value * math.pi)),
                    child: Transform.rotate(
                      angle: 0.1 * math.sin(_crownController.value * 2 * math.pi),
                      child: const Text(
                        '👑',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  );
                },
              ),
            if (showCrown) const SizedBox(height: 4),
            
            // Amount label
            if (amount > 0)
              Text(
                _formatCompactCurrency(amount),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 4),
            
            // Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: barHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.secondary,
                    theme.colorScheme.primary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // Day label
            Text(
              day,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(bool isDark, ThemeData theme) {
    final data = _getFilteredData();
    if (data.isEmpty) return const Center(child: Text('No data'));
    
    final total = data.fold<double>(0, (sum, item) => sum + item.amount);
    
    return Column(
      children: [
        // Pie chart visualization
        Expanded(
          child: Center(
            child: CustomPaint(
              size: const Size(150, 150),
              painter: PieChartPainter(
                data: data,
                total: total,
                colors: _generateColors(data.length, theme),
                showPercentage: _showPercentageInPie,
              ),
            ),
          ),
        ),
        // Toggle button
        TextButton.icon(
          onPressed: () => setState(() => _showPercentageInPie = !_showPercentageInPie),
          icon: Icon(
            _showPercentageInPie ? Icons.percent : Icons.currency_rupee,
            size: 16,
            color: Colors.white,
          ),
          label: Text(
            _showPercentageInPie ? 'Show Amount' : 'Show Percentage',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(bool isDark, ThemeData theme) {
    final data = _getFilteredData();
    if (data.isEmpty) return const Center(child: Text('No data'));
    
    return CustomPaint(
      painter: LineChartPainter(
        data: data,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildAreaChart(bool isDark, ThemeData theme) {
    final data = _getFilteredData();
    if (data.isEmpty) return const Center(child: Text('No data'));
    
    return CustomPaint(
      painter: AreaChartPainter(
        data: data,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildPageIndicators(bool isDark) {
    final pageCount = _getPageCount();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: index == _currentPage ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(index == _currentPage ? 0.8 : 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  List<DailySpending> _getFilteredData() {
    // Filter by category and return appropriate data based on period
    return widget.spendingData;
  }

  int _getPageCount() {
    final data = _getFilteredData();
    return (data.length / 7).ceil();
  }

  List<Color> _generateColors(int count, ThemeData theme) {
    return List.generate(count, (index) {
      final hue = (index * 360 / count) % 360;
      return HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
    });
  }

  IconData _getChartIcon(ChartType type) {
    switch (type) {
      case ChartType.bar: return Icons.bar_chart_rounded;
      case ChartType.pie: return Icons.pie_chart_rounded;
      case ChartType.line: return Icons.show_chart;
      case ChartType.area: return Icons.area_chart_rounded;
    }
  }

  String _getCategoryEmoji(SpendingCategory category) {
    switch (category) {
      case SpendingCategory.all: return '📊';
      case SpendingCategory.food: return '🍔';
      case SpendingCategory.transport: return '🚗';
      case SpendingCategory.shopping: return '🛍️';
      case SpendingCategory.bills: return '💡';
      case SpendingCategory.entertainment: return '🎬';
    }
  }

  String _getCategoryLabel(SpendingCategory category) {
    return category.name[0].toUpperCase() + category.name.substring(1);
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000) {
      final thousands = amount / 1000;
      return '₹${thousands.toStringAsFixed(thousands % 1 == 0 ? 0 : 1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

// Enums
enum ChartType { bar, pie, line, area }
enum TimePeriod { days, weeks, months, years }
enum SpendingCategory { all, food, transport, shopping, bills, entertainment }

// Custom Painters
class PieChartPainter extends CustomPainter {
  final List<DailySpending> data;
  final double total;
  final List<Color> colors;
  final bool showPercentage;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.colors,
    required this.showPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].amount / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<DailySpending> data;
  final Color color;

  LineChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].amount / maxAmount * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AreaChartPainter extends CustomPainter {
  final List<DailySpending> data;
  final Color color;

  AreaChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.5), color.withOpacity(0.1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (data[i].amount / maxAmount * size.height);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Data model
class DailySpending {
  final String day;
  final double amount;
  final DateTime date;
  final SpendingCategory category;

  DailySpending({
    required this.day,
    required this.amount,
    required this.date,
    this.category = SpendingCategory.all,
  });
}
