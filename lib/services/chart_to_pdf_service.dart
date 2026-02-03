import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

/// Service for converting Flutter charts to PDF-compatible images
class ChartToPdfService {
  /// Generate category pie chart as image bytes
  /// 
  /// Creates a pie chart showing spending distribution across categories
  /// Returns PNG image bytes that can be embedded in PDF
  static Future<Uint8List> generateCategoryPieChart(
    Map<String, double> categoryTotals, {
    double width = 500,
    double height = 400,
  }) async {
    // Sort categories by amount (highest first)
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total for percentages
    final total = sortedEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    // Take top 8 categories, group rest as "Others"
    final topCategories = sortedEntries.take(8).toList();
    final othersTotal = sortedEntries.skip(8).fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );

    // Create pie chart sections
    final sections = <PieChartSectionData>[];
    final colors = _getCategoryColors();

    for (var i = 0; i < topCategories.length; i++) {
      final entry = topCategories[i];
      final percentage = (entry.value / total) * 100;

      sections.add(
        PieChartSectionData(
          value: entry.value,
          title: '${percentage.toStringAsFixed(1)}%',
          color: colors[i % colors.length],
          radius: 120,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    // Add "Others" if needed
    if (othersTotal > 0) {
      final percentage = (othersTotal / total) * 100;
      sections.add(
        PieChartSectionData(
          value: othersTotal,
          title: '${percentage.toStringAsFixed(1)}%',
          color: Colors.grey.shade400,
          radius: 120,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
    }

    // Create the pie chart widget
    final chartWidget = Container(
      width: width,
      height: height,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                startDegreeOffset: -90,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ...topCategories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value.key;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                );
              }),
              if (othersTotal > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Others',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return await _widgetToImage(chartWidget, width, height);
  }

  /// Generate spending trend line chart as image bytes
  /// 
  /// Creates a line chart showing spending over time
  /// Returns PNG image bytes that can be embedded in PDF
  static Future<Uint8List> generateSpendingTrendChart(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate, {
    double width = 600,
    double height = 300,
  }) async {
    // Group transactions by date
    final dailySpending = <DateTime, double>{};

    for (var transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
      }
    }

    // Create data points
    final spots = <FlSpot>[];
    final daysDiff = endDate.difference(startDate).inDays;

    // Determine grouping (daily, weekly, or monthly)
    final grouping = daysDiff > 90
        ? 'monthly'
        : daysDiff > 30
            ? 'weekly'
            : 'daily';

    if (grouping == 'daily') {
      for (var i = 0; i <= daysDiff; i++) {
        final date = startDate.add(Duration(days: i));
        final dateKey = DateTime(date.year, date.month, date.day);
        final amount = dailySpending[dateKey] ?? 0;
        spots.add(FlSpot(i.toDouble(), amount));
      }
    } else if (grouping == 'weekly') {
      final weeklyData = <int, double>{};
      dailySpending.forEach((date, amount) {
        final weekIndex = date.difference(startDate).inDays ~/ 7;
        weeklyData[weekIndex] = (weeklyData[weekIndex] ?? 0) + amount;
      });
      weeklyData.forEach((week, amount) {
        spots.add(FlSpot(week.toDouble(), amount));
      });
    } else {
      // Monthly
      final monthlyData = <String, double>{};
      dailySpending.forEach((date, amount) {
        final monthKey = '${date.year}-${date.month}';
        monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
      });
      var index = 0;
      monthlyData.forEach((month, amount) {
        spots.add(FlSpot(index.toDouble(), amount));
        index++;
      });
    }

    // Find max value for Y axis
    final maxY = spots.isEmpty
        ? 1000.0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final yInterval = (maxY / 5).ceilToDouble();

    // Create line chart widget
    final chartWidget = Container(
      width: width,
      height: height,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Spending Trend (${grouping.substring(0, 1).toUpperCase()}${grouping.substring(1)})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: yInterval,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade300,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: yInterval,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '₹${(value / 1000).toStringAsFixed(0)}k',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black87,
                                ),
                              );
                            },
                            reservedSize: 50,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: spots.length > 10
                                ? (spots.length / 5).ceilToDouble()
                                : 1,
                            getTitlesWidget: (value, meta) {
                              if (grouping == 'daily') {
                                final date = startDate.add(
                                  Duration(days: value.toInt()),
                                );
                                return Text(
                                  '${date.day}/${date.month}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                );
                              } else if (grouping == 'weekly') {
                                return Text(
                                  'W${value.toInt() + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                );
                              } else {
                                return Text(
                                  'M${value.toInt() + 1}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      minX: 0,
                      maxX: spots.isEmpty ? 1 : spots.length.toDouble() - 1,
                      minY: 0,
                      maxY: maxY * 1.1,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: spots.length <= 31,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.purple,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purple.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );

    return await _widgetToImage(chartWidget, width, height);
  }

  /// Generate budget comparison bar chart as image bytes
  /// 
  /// Creates a horizontal bar chart comparing budget vs actual spending
  /// Returns PNG image bytes that can be embedded in PDF
  static Future<Uint8List> generateBudgetComparisonChart(
    List<Budget> budgets,
    Map<String, double> actualSpending, {
    double width = 600,
    double height = 400,
  }) async {
    // Prepare data
    final budgetData = <String, Map<String, double>>{};

    for (var budget in budgets) {
      final actual = actualSpending[budget.category] ?? 0;
      budgetData[budget.category] = {
        'budget': budget.amount,
        'actual': actual,
      };
    }

    // Sort by budget amount (highest first)
    final sortedCategories = budgetData.keys.toList()
      ..sort((a, b) {
        return budgetData[b]!['budget']!
            .compareTo(budgetData[a]!['budget']!);
      });

    // Take top 8 budgets
    final topCategories = sortedCategories.take(8).toList();

    // Find max value for scaling
    final maxValue = topCategories.fold<double>(0, (max, category) {
      final budget = budgetData[category]!['budget']!;
      final actual = budgetData[category]!['actual']!;
      final categoryMax = budget > actual ? budget : actual;
      return categoryMax > max ? categoryMax : max;
    });

    // Create bar chart widget
    final chartWidget = Container(
      width: width,
      height: height,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Budget vs Actual Spending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.blue.shade300,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Budget',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Actual',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: topCategories.isEmpty
                ? const Center(
                    child: Text(
                      'No budget data available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: topCategories.length,
                    itemBuilder: (context, index) {
                      final category = topCategories[index];
                      final budgetAmount =
                          budgetData[category]!['budget']!;
                      final actualAmount =
                          budgetData[category]!['actual']!;
                      final budgetPercent = budgetAmount / maxValue;
                      final actualPercent = actualAmount / maxValue;

                      // Determine color based on status
                      Color actualColor;
                      if (actualAmount > budgetAmount) {
                        actualColor = Colors.red; // Over budget
                      } else if (actualAmount > budgetAmount * 0.8) {
                        actualColor = Colors.orange; // Warning
                      } else {
                        actualColor = Colors.green; // Good
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Budget bar
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 20,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      Container(
                                        height: 20,
                                        width: (width - 200) * budgetPercent,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade300,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '₹${budgetAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Actual bar
                            Row(
                              children: [
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 20,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      Container(
                                        height: 20,
                                        width: (width - 200) * actualPercent,
                                        decoration: BoxDecoration(
                                          color: actualColor,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '₹${actualAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: actualColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return await _widgetToImage(chartWidget, width, height);
  }

  /// Convert Flutter widget to PNG image bytes
  /// 
  /// Uses RepaintBoundary to capture widget as image
  /// Returns PNG bytes suitable for PDF embedding
  static Future<Uint8List> _widgetToImage(
    Widget widget,
    double width,
    double height,
  ) async {
    final repaintBoundary = RenderRepaintBoundary();

    final renderView = RenderView(
      view: WidgetsBinding.instance.platformDispatcher.views.first,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        size: Size(width, height),
        devicePixelRatio: 2.0,
      ),
    );

    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: widget,
        ),
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Get color palette for category pie chart
  static List<Color> _getCategoryColors() {
    return [
      Colors.purple,
      Colors.blue,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];
  }
}
