import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'glass_card.dart';
import 'package:intl/intl.dart';

/// Feature C: Spending Chart Card - Fixed Version
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
  ScrollController _scrollController = ScrollController();
  late AnimationController _crownController;
  
  @override
  void initState() {
    super.initState();
    _crownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
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
            // Time period dropdown (icon only)
            _buildPeriodDropdown(theme, isDark),
            const SizedBox(width: 12),
            // Chart type selector
            _buildChartTypeSelector(theme, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown(ThemeData theme, bool isDark) {
    return PopupMenuButton<TimePeriod>(
      color: theme.colorScheme.primary.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(_getPeriodIcon(_selectedPeriod), color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
      onSelected: (TimePeriod period) {
        setState(() => _selectedPeriod = period);
      },
      itemBuilder: (context) => [
        _buildPeriodMenuItem(TimePeriod.days, 'Days', Icons.today),
        _buildPeriodMenuItem(TimePeriod.weeks, 'Weeks', Icons.view_week),
        _buildPeriodMenuItem(TimePeriod.months, 'Months', Icons.calendar_month),
        _buildPeriodMenuItem(TimePeriod.years, 'Years', Icons.calendar_today),
      ],
    );
  }

  PopupMenuItem<TimePeriod> _buildPeriodMenuItem(TimePeriod period, String label, IconData icon) {
    return PopupMenuItem<TimePeriod>(
      value: period,
      child: Container(
        decoration: BoxDecoration(
          color: _selectedPeriod == period 
            ? Colors.white.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white)),
            if (_selectedPeriod == period) ...[
              const Spacer(),
              const Icon(Icons.check, size: 18, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(ThemeData theme, bool isDark) {
    return PopupMenuButton<ChartType>(
      color: theme.colorScheme.primary.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(_getChartIcon(_selectedChartType), color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
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
      child: Container(
        decoration: BoxDecoration(
          color: _selectedChartType == type 
            ? Colors.white.withOpacity(0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: Colors.white)),
            if (_selectedChartType == type) ...[
              const Spacer(),
              const Icon(Icons.check, size: 18, color: Colors.white),
            ],
          ],
        ),
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
                    Text(_getCategoryEmoji(category), style: const TextStyle(fontSize: 14)),
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
    final data = _getFilteredData();
    
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      );
    }
    
    switch (_selectedChartType) {
      case ChartType.bar:
        return _buildBarChart(data, isDark, theme);
      case ChartType.pie:
        return _buildPieChart(data, isDark, theme);
      case ChartType.line:
        return _buildLineChart(data, isDark, theme);
      case ChartType.area:
        return _buildAreaChart(data, isDark, theme);
    }
  }

  Widget _buildBarChart(List<DailySpending> data, bool isDark, ThemeData theme) {
    final maxSpending = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final lowestIndex = data.indexOf(data.reduce((a, b) => a.amount < b.amount ? a : b));
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
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
        ),
      ),
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
    
    return Container(
      width: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown with animation
          if (showCrown)
            AnimatedBuilder(
              animation: _crownController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -4 * math.sin(_crownController.value * math.pi)),
                  child: Transform.rotate(
                    angle: 0.08 * math.sin(_crownController.value * 2 * math.pi),
                    child: const Text('👑', style: TextStyle(fontSize: 20)),
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
          
          // Bar - no animation, instant height
          Container(
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
    );
  }

  Widget _buildPieChart(List<DailySpending> data, bool isDark, ThemeData theme) {
    final total = data.fold<double>(0, (sum, item) => sum + item.amount);
    
    return Row(
      children: [
        Expanded(
          child: Center(
            child: CustomPaint(
              size: const Size(160, 160),
              painter: PieChartPainter(
                data: data,
                total: total,
                color: theme.colorScheme.primary,
                showPercentage: _showPercentageInPie,
              ),
            ),
          ),
        ),
        // Toggle button on side
        Container(
          margin: const EdgeInsets.only(right: 12, bottom: 40),
          child: IconButton(
            onPressed: () => setState(() => _showPercentageInPie = !_showPercentageInPie),
            icon: Icon(
              _showPercentageInPie ? Icons.currency_rupee : Icons.percent,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(List<DailySpending> data, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: Size.infinite,
        painter: LineChartPainter(
          data: data,
          color: theme.colorScheme.primary,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildAreaChart(List<DailySpending> data, bool isDark, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        size: Size.infinite,
        painter: AreaChartPainter(
          data: data,
          color: theme.colorScheme.primary,
          isDark: isDark,
        ),
      ),
    );
  }

  List<DailySpending> _getFilteredData() {
    var data = widget.spendingData;
    
    // Filter by category
    if (_selectedCategory != SpendingCategory.all) {
      data = data.where((item) => item.category == _selectedCategory).toList();
    }
    
    // Filter by time period
    switch (_selectedPeriod) {
      case TimePeriod.days:
        return data.take(7).toList();
      case TimePeriod.weeks:
        return _aggregateWeeks(data);
      case TimePeriod.months:
        return _aggregateMonths(data);
      case TimePeriod.years:
        return _aggregateYears(data);
    }
  }

  List<DailySpending> _aggregateWeeks(List<DailySpending> data) {
    // Group by weeks and sum amounts
    final weeks = <DailySpending>[];
    for (int i = 0; i < data.length; i += 7) {
      final weekData = data.skip(i).take(7).toList();
      if (weekData.isNotEmpty) {
        final total = weekData.fold<double>(0, (sum, item) => sum + item.amount);
        weeks.add(DailySpending(
          day: 'W${(i ~/ 7) + 1}',
          amount: total,
          date: weekData.first.date,
          category: _selectedCategory,
        ));
      }
    }
    return weeks.take(4).toList();
  }

  List<DailySpending> _aggregateMonths(List<DailySpending> data) {
    // Group by months and sum amounts
    final months = <String, double>{};
    for (var item in data) {
      final monthKey = DateFormat('MMM').format(item.date);
      months[monthKey] = (months[monthKey] ?? 0) + item.amount;
    }
    return months.entries.take(12).map((e) => DailySpending(
      day: e.key,
      amount: e.value,
      date: DateTime.now(),
      category: _selectedCategory,
    )).toList();
  }

  List<DailySpending> _aggregateYears(List<DailySpending> data) {
    // Group by years and sum amounts
    final years = <int, double>{};
    for (var item in data) {
      final year = item.date.year;
      years[year] = (years[year] ?? 0) + item.amount;
    }
    return years.entries.take(5).map((e) => DailySpending(
      day: e.key.toString(),
      amount: e.value,
      date: DateTime.now(),
      category: _selectedCategory,
    )).toList();
  }

  IconData _getPeriodIcon(TimePeriod period) {
    switch (period) {
      case TimePeriod.days: return Icons.today;
      case TimePeriod.weeks: return Icons.view_week;
      case TimePeriod.months: return Icons.calendar_month;
      case TimePeriod.years: return Icons.calendar_today;
    }
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
  final Color color;
  final bool showPercentage;

  PieChartPainter({
    required this.data,
    required this.total,
    required this.color,
    required this.showPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;
    double startAngle = -math.pi / 2;

    // Draw single-color pie with varying opacity
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].amount / total) * 2 * math.pi;
      final opacity = 0.3 + (0.7 * (i / data.length));
      
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw white separator
      final separatorPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
        
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle + sweepAngle),
          center.dy + radius * math.sin(startAngle + sweepAngle),
        ),
        separatorPaint,
      );

      startAngle += sweepAngle;
    }
    
    // Draw center circle
    final centerPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  final List<DailySpending> data;
  final Color color;
  final bool isDark;

  LineChartPainter({required this.data, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - (data[i].amount / maxAmount * chartHeight);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);
    
    // Draw points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - (data[i].amount / maxAmount * chartHeight);
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class AreaChartPainter extends CustomPainter {
  final List<DailySpending> data;
  final Color color;
  final bool isDark;

  AreaChartPainter({required this.data, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    
    // Draw filled area
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.6), color.withOpacity(0.1)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(padding, padding + chartHeight);

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - (data[i].amount / maxAmount * chartHeight);
      path.lineTo(x, y);
    }

    path.lineTo(padding + chartWidth, padding + chartHeight);
    path.close();
    canvas.drawPath(path, areaPaint);
    
    // Draw line on top
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - (data[i].amount / maxAmount * chartHeight);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, linePaint);
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
