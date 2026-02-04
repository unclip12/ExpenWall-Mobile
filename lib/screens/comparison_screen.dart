// lib/screens/comparison_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/analytics_data.dart';
import '../services/analytics_service.dart';
import '../widgets/glass_app_bar.dart';
import '../widgets/glass_card.dart';

class ComparisonScreen extends StatefulWidget {
  final String userId;

  const ComparisonScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  DateTime? _leftMonth;
  DateTime? _rightMonth;
  MonthComparison? _comparison;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default: Compare last month with current month
    final now = DateTime.now();
    _leftMonth = DateTime(now.year, now.month - 1, 1);
    _rightMonth = DateTime(now.year, now.month, 1);
    _loadComparison();
  }

  Future<void> _loadComparison() async {
    if (_leftMonth == null || _rightMonth == null) return;

    // Ensure left is before right
    if (_leftMonth!.isAfter(_rightMonth!)) {
      setState(() {
        final temp = _leftMonth;
        _leftMonth = _rightMonth;
        _rightMonth = temp;
      });
    }

    setState(() => _isLoading = true);

    try {
      final comparison = await _analyticsService.compareMonths(
        userId: widget.userId,
        leftMonth: _leftMonth!,
        rightMonth: _rightMonth!,
      );

      setState(() {
        _comparison = comparison;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comparison: $e')),
        );
      }
    }
  }

  Future<void> _selectMonth(bool isLeft) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isLeft ? (_leftMonth ?? DateTime.now()) : (_rightMonth ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (selectedDate != null) {
      setState(() {
        final month = DateTime(selectedDate.year, selectedDate.month, 1);
        if (isLeft) {
          _leftMonth = month;
        } else {
          _rightMonth = month;
        }
      });
      _loadComparison();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GlassAppBar(
        title: 'Month Comparison',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Read'),
                  content: const Text(
                    '• Green ↓ arrow = You spent less (improvement)\n'
                    '• Red ↑ arrow = You spent more\n'
                    '• Left side = Earlier month\n'
                    '• Right side = Later month\n'
                    '• Compare any two months to track your progress!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMonthSelector(),
                  const SizedBox(height: 24),
                  if (_comparison != null) ...[
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildComparisonTable(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: InkWell(
              onTap: () => _selectMonth(true),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'From',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _leftMonth != null
                          ? DateFormat('MMM yyyy').format(_leftMonth!)
                          : 'Select',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.arrow_forward, color: Colors.white70),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            child: InkWell(
              onTap: () => _selectMonth(false),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'To',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rightMonth != null
                          ? DateFormat('MMM yyyy').format(_rightMonth!)
                          : 'Select',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final isImprovement = _comparison!.totalDifference < 0;
    final color = isImprovement ? Colors.green : Colors.red;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImprovement ? Icons.trending_down : Icons.trending_up,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_comparison!.percentageChange.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isImprovement ? 'Less Spending! 🎉' : 'More Spending',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${_comparison!.totalDifference.abs().toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isImprovement ? 'saved' : 'extra spent',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final sortedCategories = _comparison!.categoryComparisons.entries.toList()
      ..sort((a, b) => b.value.difference.abs().compareTo(a.value.difference.abs()));

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Colors.white.withOpacity(0.1),
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      DateFormat('MMM').format(_leftMonth!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      DateFormat('MMM').format(_rightMonth!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Change',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
                rows: sortedCategories.map((entry) {
                  final metric = entry.value;
                  final color = metric.isImprovement ? Colors.green : Colors.red;
                  final icon = metric.isImprovement ? '↓' : '↑';

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          metric.category,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      DataCell(
                        Text(
                          '₹${metric.leftAmount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataCell(
                        Text(
                          '₹${metric.rightAmount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              icon,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${metric.percentageChange.abs().toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (metric.isImprovement) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
