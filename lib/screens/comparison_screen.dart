import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/analytics_service.dart';

class ComparisonScreen extends StatefulWidget {
  final String userId;

  const ComparisonScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  
  DateTime? _leftDate;
  DateTime? _rightDate;
  
  @override
  void initState() {
    super.initState();
    // Default to previous month vs current month
    final now = DateTime.now();
    _leftDate = DateTime(now.year, now.month - 1, 1);
    _rightDate = DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Months'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!.docs
              .map((doc) => ExpenseTransaction.fromFirestore(doc))
              .toList();

          return Column(
            children: [
              _buildDateSelectors(),
              Expanded(
                child: _buildComparisonContent(transactions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildDateSelector(
              'Previous Period',
              _leftDate,
              (date) {
                setState(() {
                  _leftDate = date;
                  // Ensure left date is always before right date
                  if (_rightDate != null && date!.isAfter(_rightDate!)) {
                    _rightDate = DateTime(date.year, date.month + 1, 1);
                  }
                });
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward, size: 32),
          ),
          Expanded(
            child: _buildDateSelector(
              'Current Period',
              _rightDate,
              (date) {
                setState(() {
                  _rightDate = date;
                  // Ensure right date is always after left date
                  if (_leftDate != null && date!.isBefore(_leftDate!)) {
                    _leftDate = DateTime(date.year, date.month - 1, 1);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(
    String label,
    DateTime? selectedDate,
    Function(DateTime?) onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              initialDatePickerMode: DatePickerMode.year,
            );
            if (picked != null) {
              onDateSelected(DateTime(picked.year, picked.month, 1));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate != null
                      ? DateFormat('MMM yyyy').format(selectedDate)
                      : 'Select',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonContent(List<ExpenseTransaction> transactions) {
    if (_leftDate == null || _rightDate == null) {
      return const Center(
        child: Text('Please select both periods to compare'),
      );
    }

    // Validate date order
    if (_leftDate!.isAfter(_rightDate!)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Invalid Date Range',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Previous period must be before current period',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final leftStart = DateTime(_leftDate!.year, _leftDate!.month, 1);
    final leftEnd = DateTime(_leftDate!.year, _leftDate!.month + 1, 0);
    final rightStart = DateTime(_rightDate!.year, _rightDate!.month, 1);
    final rightEnd = DateTime(_rightDate!.year, _rightDate!.month + 1, 0);

    final leftTotal = _analyticsService.getTotalExpense(transactions, leftStart, leftEnd);
    final rightTotal = _analyticsService.getTotalExpense(transactions, rightStart, rightEnd);
    
    final leftCategories = _analyticsService.getCategoryBreakdown(transactions, leftStart, leftEnd);
    final rightCategories = _analyticsService.getCategoryBreakdown(transactions, rightStart, rightEnd);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalComparison(leftTotal, rightTotal),
          const SizedBox(height: 24),
          _buildCategoryComparison(leftCategories, rightCategories),
        ],
      ),
    );
  }

  Widget _buildTotalComparison(double leftTotal, double rightTotal) {
    final difference = rightTotal - leftTotal;
    final percentageChange = leftTotal > 0 ? (difference / leftTotal * 100) : 0;
    final isPositive = difference < 0; // Negative difference is good (less spending)

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Total Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM yyyy').format(_leftDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${leftTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPositive ? Colors.green[50] : Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_down : Icons.trending_up,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 32,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM yyyy').format(_rightDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${rightTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green[50] : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.star : Icons.warning,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPositive ? '' : '+'}${percentageChange.toStringAsFixed(1)}% '
                    '(₹${difference.abs().toStringAsFixed(0)})',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryComparison(
    Map<String, double> leftCategories,
    Map<String, double> rightCategories,
  ) {
    final allCategories = {...leftCategories.keys, ...rightCategories.keys}.toList()
      ..sort();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      'Category',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      DateFormat('MMM').format(_leftDate!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      DateFormat('MMM').format(_rightDate!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'Change',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: allCategories.map((category) {
                  final leftAmount = leftCategories[category] ?? 0;
                  final rightAmount = rightCategories[category] ?? 0;
                  final difference = rightAmount - leftAmount;
                  final percentageChange = leftAmount > 0
                      ? (difference / leftAmount * 100)
                      : (rightAmount > 0 ? 100 : 0);
                  final isPositive = difference < 0;

                  return DataRow(
                    cells: [
                      DataCell(Text(category)),
                      DataCell(Text('₹${leftAmount.toStringAsFixed(0)}')),
                      DataCell(Text('₹${rightAmount.toStringAsFixed(0)}')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositive
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isPositive ? Colors.green : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${percentageChange.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: isPositive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isPositive) ..[
                              const SizedBox(width: 4),
                              Icon(
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
