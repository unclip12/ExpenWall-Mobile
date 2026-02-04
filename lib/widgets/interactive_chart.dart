import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

enum ChartType { pie, line, bar }

class InteractiveChart extends StatefulWidget {
  final ChartType type;
  final Map<String, double> data;
  final String title;

  const InteractiveChart({
    Key? key,
    required this.type,
    required this.data,
    required this.title,
  }) : super(key: key);

  @override
  State<InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<InteractiveChart> {
  int _touchedIndex = -1;
  String? _selectedLabel;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: _buildChart(),
        ),
        if (_selectedLabel != null) ..[
          const SizedBox(height: 16),
          _buildSelectedInfo(),
        ],
      ],
    );
  }

  Widget _buildChart() {
    switch (widget.type) {
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
    }
  }

  Widget _buildPieChart() {
    final colors = _generateColors(widget.data.length);
    final total = widget.data.values.reduce((a, b) => a + b);

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                _selectedLabel = null;
                return;
              }
              _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              _selectedLabel = widget.data.keys.elementAt(_touchedIndex);
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: widget.data.entries.map((entry) {
          final index = widget.data.keys.toList().indexOf(entry.key);
          final isTouched = index == _touchedIndex;
          final fontSize = isTouched ? 18.0 : 14.0;
          final radius = isTouched ? 110.0 : 100.0;
          final percentage = (entry.value / total * 100);

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = <FlSpot>[];
    var index = 0;
    
    for (var entry in widget.data.entries) {
      spots.add(FlSpot(index.toDouble(), entry.value));
      index++;
    }

    final maxY = widget.data.values.reduce(math.max);
    final minY = widget.data.values.reduce(math.min);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.data.length) return const Text('');
                final date = widget.data.keys.elementAt(value.toInt());
                // Show only date (last 5 chars of date string)
                final label = date.length > 5 ? date.substring(date.length - 5) : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.5),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response != null && response.lineBarSpots != null) {
              final spot = response.lineBarSpots!.first;
              setState(() {
                _touchedIndex = spot.x.toInt();
                _selectedLabel = widget.data.keys.elementAt(_touchedIndex);
              });
            }
          },
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '₹${barSpot.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxY = widget.data.values.reduce(math.max);
    final colors = _generateColors(widget.data.length);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  barTouchResponse == null ||
                  barTouchResponse.spot == null) {
                _touchedIndex = -1;
                _selectedLabel = null;
                return;
              }
              _touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              _selectedLabel = widget.data.keys.elementAt(_touchedIndex);
            });
          },
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '₹${rod.toY.toStringAsFixed(0)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= widget.data.length) return const Text('');
                final label = widget.data.keys.elementAt(value.toInt());
                // Shorten day names
                final shortLabel = label.length > 3 ? label.substring(0, 3) : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    shortLabel,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: widget.data.entries.map((entry) {
          final index = widget.data.keys.toList().indexOf(entry.key);
          final isTouched = index == _touchedIndex;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: colors[index % colors.length],
                width: isTouched ? 25 : 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
      ),
    );
  }

  Widget _buildSelectedInfo() {
    if (_selectedLabel == null) return const SizedBox();

    final value = widget.data[_selectedLabel];
    final total = widget.data.values.reduce((a, b) => a + b);
    final percentage = (value! / total * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _selectedLabel!,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(0)} ($percentage%)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _generateColors(int count) {
    return List.generate(
      count,
      (index) => Color.fromRGBO(
        (index * 50) % 255,
        (index * 100) % 255,
        (index * 150) % 255,
        1.0,
      ),
    );
  }
}
