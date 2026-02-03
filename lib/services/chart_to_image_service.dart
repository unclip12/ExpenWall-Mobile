import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

/// Service to convert Flutter charts to images for PDF embedding
class ChartToImageService {
  /// Convert a widget to PNG image bytes
  static Future<Uint8List?> widgetToImage(
    Widget widget, {
    Size size = const Size(400, 300),
    double pixelRatio = 2.0,
  }) async {
    try {
      final RepaintBoundary repaintBoundary = RepaintBoundary(
        child: Container(
          width: size.width,
          height: size.height,
          color: Colors.white,
          child: widget,
        ),
      );

      final RenderRepaintBoundary boundary = RenderRepaintBoundary();
      final PipelineOwner pipelineOwner = PipelineOwner();
      final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

      final RenderObjectToWidgetElement<RenderBox> rootElement =
          RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
        child: repaintBoundary,
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      buildOwner.finalizeTree();

      pipelineOwner.rootNode = boundary;
      boundary.attach(pipelineOwner);

      boundary.layout(BoxConstraints.tight(size));
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error converting widget to image: $e');
      return null;
    }
  }

  /// Generate category pie chart
  static Future<Uint8List?> generateCategoryPieChart(
    Map<String, double> categoryTotals, {
    Size size = const Size(400, 300),
  }) async {
    if (categoryTotals.isEmpty) return null;

    final total = categoryTotals.values.reduce((a, b) => a + b);
    if (total <= 0) return null;

    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
    ];

    int colorIndex = 0;
    categoryTotals.forEach((category, amount) {
      final percentage = (amount / total) * 100;
      if (percentage > 0) {
        sections.add(
          PieChartSectionData(
            value: amount,
            title: '${percentage.toStringAsFixed(1)}%',
            color: colors[colorIndex % colors.length],
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors[colorIndex % colors.length]),
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 10,
                  color: colors[colorIndex % colors.length],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            badgePositionPercentageOffset: 1.3,
          ),
        );
        colorIndex++;
      }
    });

    final chart = Padding(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 0,
                sectionsSpace: 2,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );

    return widgetToImage(chart, size: size);
  }

  /// Generate spending trend line chart
  static Future<Uint8List?> generateTrendLineChart(
    Map<DateTime, double> dailyTotals, {
    Size size = const Size(400, 300),
    String title = 'Spending Trend',
  }) async {
    if (dailyTotals.isEmpty) return null;

    final sortedDates = dailyTotals.keys.toList()..sort();
    final spots = <FlSpot>[];
    double maxY = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      final amount = dailyTotals[sortedDates[i]] ?? 0;
      spots.add(FlSpot(i.toDouble(), amount));
      if (amount > maxY) maxY = amount;
    }

    if (spots.isEmpty) return null;

    final chart = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedDates.length) {
                          final date = sortedDates[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minX: 0,
                maxX: spots.length.toDouble() - 1,
                minY: 0,
                maxY: maxY * 1.1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.purple,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
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

    return widgetToImage(chart, size: size);
  }

  /// Generate budget comparison bar chart
  static Future<Uint8List?> generateBudgetBarChart(
    List<Budget> budgets,
    Map<String, double> actualSpending, {
    Size size = const Size(400, 300),
  }) async {
    if (budgets.isEmpty) return null;

    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < budgets.length; i++) {
      final budget = budgets[i];
      final actual = actualSpending[budget.category] ?? 0;
      final budgetAmount = budget.amount;

      if (budgetAmount > maxY) maxY = budgetAmount;
      if (actual > maxY) maxY = actual;

      // Determine color based on budget status
      Color actualColor;
      if (actual > budgetAmount) {
        actualColor = Colors.red; // Over budget
      } else if (actual > budgetAmount * 0.8) {
        actualColor = Colors.orange; // Warning (80-100%)
      } else {
        actualColor = Colors.green; // Good (under 80%)
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: budgetAmount,
              color: Colors.blue.withOpacity(0.3),
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
            BarChartRodData(
              toY: actual,
              color: actualColor,
              width: 12,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    final chart = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Budget vs Actual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Budget', Colors.blue.withOpacity(0.3)),
              const SizedBox(width: 16),
              _buildLegendItem('Actual', Colors.green),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY * 1.2,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade300,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < budgets.length) {
                          final category = budgets[index].category;
                          // Shorten category names
                          final shortName = category.length > 8
                              ? '${category.substring(0, 6)}..'
                              : category;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              shortName,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return widgetToImage(chart, size: size);
  }

  /// Build legend item widget
  static Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Calculate daily spending totals from transactions
  static Map<DateTime, double> calculateDailyTotals(
    List<Transaction> transactions,
  ) {
    final Map<DateTime, double> dailyTotals = {};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final date = DateTime(
          transaction.date.year,
          transaction.date.month,
          transaction.date.day,
        );
        dailyTotals[date] = (dailyTotals[date] ?? 0) + transaction.amount;
      }
    }

    return dailyTotals;
  }

  /// Calculate category totals from transactions
  static Map<String, double> calculateCategoryTotals(
    List<Transaction> transactions,
  ) {
    final Map<String, double> categoryTotals = {};

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        final category = transaction.category;
        categoryTotals[category] =
            (categoryTotals[category] ?? 0) + transaction.amount;
      }
    }

    return categoryTotals;
  }

  /// Calculate actual spending per budget category
  static Map<String, double> calculateActualSpending(
    List<Transaction> transactions,
    List<Budget> budgets,
  ) {
    final Map<String, double> actualSpending = {};

    for (final budget in budgets) {
      actualSpending[budget.category] = 0;
    }

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        if (actualSpending.containsKey(transaction.category)) {
          actualSpending[transaction.category] =
              actualSpending[transaction.category]! + transaction.amount;
        }
      }
    }

    return actualSpending;
  }
}
