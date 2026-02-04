import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';

class ComparisonScreen extends StatefulWidget {
  final String userId;

  const ComparisonScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  DateTime? _period1Date;
  DateTime? _period2Date;
  bool _isLoading = false;
  Map<String, dynamic>? _comparisonData;

  @override
  void initState() {
    super.initState();
    // Default: Compare current month with previous month
    final now = DateTime.now();
    _period2Date = DateTime(now.year, now.month, 1);
    _period1Date = DateTime(now.year, now.month - 1, 1);
  }

  Future<void> _selectPeriod1() async {
    final picked = await showMonthPicker(context, _period1Date);
    if (picked != null) {
      setState(() {
        _period1Date = picked;
        // Ensure period1 is before period2
        if (_period2Date != null && picked.isAfter(_period2Date!)) {
          _period2Date = DateTime(picked.year, picked.month + 1, 1);
        }
      });
      _loadComparison();
    }
  }

  Future<void> _selectPeriod2() async {
    final picked = await showMonthPicker(context, _period2Date);
    if (picked != null) {
      setState(() {
        _period2Date = picked;
        // Ensure period2 is after period1
        if (_period1Date != null && picked.isBefore(_period1Date!)) {
          _period1Date = DateTime(picked.year, picked.month - 1, 1);
        }
      });
      _loadComparison();
    }
  }

  Future<DateTime?> showMonthPicker(BuildContext context, DateTime? initialDate) async {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    
    DateTime selectedDate = initialDate ?? currentMonth;
    
    return await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Month'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearView(
              currentMonth: currentMonth,
              selectedDate: selectedDate,
              onDateSelected: (DateTime date) {
                Navigator.of(context).pop(date);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadComparison() async {
    if (_period1Date == null || _period2Date == null) return;

    setState(() => _isLoading = true);

    try {
      final period1End = DateTime(_period1Date!.year, _period1Date!.month + 1, 0);
      final period2End = DateTime(_period2Date!.year, _period2Date!.month + 1, 0);

      final comparison = await _analyticsService.comparePeriods(
        widget.userId,
        _period1Date!,
        period1End,
        _period2Date!,
        period2End,
      );

      setState(() {
        _comparisonData = comparison;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading comparison: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Periods'),
      ),
      body: Column(
        children: [
          // Period Selection
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodSelector(
                    'Previous Period',
                    _period1Date,
                    _selectPeriod1,
                    Colors.blue,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: _buildPeriodSelector(
                    'Current Period',
                    _period2Date,
                    _selectPeriod2,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Comparison Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comparisonData == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              'Select periods to compare',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadComparison,
                              child: const Text('Compare'),
                            ),
                          ],
                        ),
                      )
                    : _buildComparisonView(),
          ),
        ],
      ),
      floatingActionButton: _period1Date != null && _period2Date != null
          ? FloatingActionButton.extended(
              onPressed: _loadComparison,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            )
          : null,
    );
  }

  Widget _buildPeriodSelector(
    String label,
    DateTime? date,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('MMMM yyyy').format(date) : 'Select',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonView() {
    final period1Total = _comparisonData!['period1Total'] as double;
    final period2Total = _comparisonData!['period2Total'] as double;
    final totalDifference = _comparisonData!['totalDifference'] as double;
    final percentChange = _comparisonData!['percentChange'] as double;
    final categoryComparisons = _comparisonData!['categoryComparisons'] as List;

    final isIncrease = totalDifference > 0;
    final trendColor = isIncrease ? Colors.red : Colors.green;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Comparison Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTotalColumn(
                        'Previous',
                        period1Total,
                        Colors.blue,
                      ),
                      Icon(
                        isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 32,
                        color: trendColor,
                      ),
                      _buildTotalColumn(
                        'Current',
                        period2Total,
                        Colors.green,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isIncrease ? Icons.trending_up : Icons.trending_down,
                        color: trendColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${totalDifference.abs().toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                      Text(
                        ' (${percentChange.abs().toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 16,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: trendColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isIncrease
                          ? 'You spent more this period'
                          : 'You saved money this period! ⭐',
                      style: TextStyle(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Category Comparison Table
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Scrollable Table
          Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                columns: const [
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Previous'), numeric: true),
                  DataColumn(label: Text('Current'), numeric: true),
                  DataColumn(label: Text('Change'), numeric: true),
                  DataColumn(label: Text('Status')),
                ],
                rows: categoryComparisons.map((cat) {
                  final category = cat['category'] as String;
                  final period1Amount = cat['period1Amount'] as double;
                  final period2Amount = cat['period2Amount'] as double;
                  final difference = cat['difference'] as double;
                  final isIncrease = cat['isIncrease'] as bool;
                  final color = isIncrease ? Colors.red : Colors.green;

                  return DataRow(
                    cells: [
                      DataCell(Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      )),
                      DataCell(Text('₹${period1Amount.toStringAsFixed(0)}')),
                      DataCell(Text('₹${period2Amount.toStringAsFixed(0)}')),
                      DataCell(
                        Text(
                          '${isIncrease ? '+' : ''}₹${difference.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Icon(
                          isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                          size: 20,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// Simple Year View for Month Picker
class YearView extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const YearView({
    Key? key,
    required this.currentMonth,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 2 + i);

    return ListView(
      children: years.map((year) {
        return ExpansionTile(
          title: Text(
            year.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: year == selectedDate.year,
          children: List.generate(12, (month) {
            final date = DateTime(year, month + 1, 1);
            final isSelected = date.year == selectedDate.year &&
                date.month == selectedDate.month;
            final isFuture = date.isAfter(now);

            return ListTile(
              title: Text(
                DateFormat('MMMM').format(date),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isFuture ? Colors.grey : null,
                ),
              ),
              selected: isSelected,
              enabled: !isFuture,
              onTap: isFuture ? null : () => onDateSelected(date),
            );
          }),
        );
      }).toList(),
    );
  }
}
