import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/report_config.dart';
import 'local_storage_service.dart';

/// PDF Report Generation Service
/// Generates professional expense reports with analytics and insights
class PDFReportService {
  final LocalStorageService _localStorage;

  PDFReportService(this._localStorage);

  /// Generate PDF report based on configuration
  Future<File> generateReport(
    String userId,
    ReportConfig config,
  ) async {
    // Load data
    final allTransactions = await _localStorage.loadTransactions(userId);
    final allBudgets = await _localStorage.loadBudgets(userId);

    // Filter transactions by date range
    final transactions = allTransactions.where((t) {
      return t.date.isAfter(config.startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(config.endDate.add(const Duration(days: 1)));
    }).toList();

    // Apply additional filters
    final filteredTransactions = _applyFilters(transactions, config);

    // Generate PDF based on template type
    final pdf = pw.Document();

    switch (config.type) {
      case ReportType.simple:
        await _generateSimpleReport(pdf, config, filteredTransactions, allBudgets, allTransactions);
        break;
      case ReportType.detailed:
        await _generateDetailedReport(pdf, config, filteredTransactions, allBudgets, allTransactions);
        break;
      case ReportType.budget:
        await _generateBudgetReport(pdf, config, filteredTransactions, allBudgets, allTransactions);
        break;
    }

    // Save PDF to file
    return await _savePDF(pdf, config);
  }

  /// Apply filters to transactions
  List<models.Transaction> _applyFilters(
    List<models.Transaction> transactions,
    ReportConfig config,
  ) {
    var filtered = transactions;

    // Category filter
    if (config.categoryFilters != null && config.categoryFilters!.isNotEmpty) {
      filtered = filtered.where((t) {
        return config.categoryFilters!.contains(t.category.label);
      }).toList();
    }

    // Merchant filter
    if (config.merchantFilters != null && config.merchantFilters!.isNotEmpty) {
      filtered = filtered.where((t) {
        return config.merchantFilters!.contains(t.merchant);
      }).toList();
    }

    // Amount filter
    if (config.minAmount != null) {
      filtered = filtered.where((t) => t.amount >= config.minAmount!).toList();
    }
    if (config.maxAmount != null) {
      filtered = filtered.where((t) => t.amount <= config.maxAmount!).toList();
    }

    return filtered;
  }

  /// Generate Simple Summary Report
  Future<void> _generateSimpleReport(
    pw.Document pdf,
    ReportConfig config,
    List<models.Transaction> transactions,
    List<Budget> budgets,
    List<models.Transaction> allTransactions,
  ) async {
    // Calculate summary statistics
    final stats = _calculateStatistics(transactions);
    final previousStats = _calculatePreviousMonthStats(allTransactions, config);
    final categoryBreakdown = _getCategoryBreakdown(transactions);
    final topTransactions = _getTopTransactions(transactions, 10);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(config, 'Simple Summary Report'),
          pw.SizedBox(height: 20),

          // Executive Summary Card
          _buildExecutiveSummary(stats, previousStats),
          pw.SizedBox(height: 20),

          // Personalized Insights
          _buildInsightsSection(stats, previousStats),
          pw.SizedBox(height: 20),

          // Category Breakdown Header
          pw.Text(
            'Category Breakdown',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),

          // Category Table
          _buildCategoryTable(categoryBreakdown, stats.totalExpenses),
          pw.SizedBox(height: 20),

          // Top Transactions
          pw.Text(
            'Top 10 Transactions',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildTopTransactionsTable(topTransactions),
          pw.SizedBox(height: 20),

          // Key Statistics
          _buildKeyStatistics(stats, transactions),
        ],
      ),
    );
  }

  /// Generate Detailed Transaction Report
  Future<void> _generateDetailedReport(
    pw.Document pdf,
    ReportConfig config,
    List<models.Transaction> transactions,
    List<Budget> budgets,
    List<models.Transaction> allTransactions,
  ) async {
    final stats = _calculateStatistics(transactions);
    final previousStats = _calculatePreviousMonthStats(allTransactions, config);
    final categoryBreakdown = _getCategoryBreakdown(transactions);
    final transactionsByCategory = _groupTransactionsByCategory(transactions);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(config, 'Detailed Transaction Report'),
          pw.SizedBox(height: 20),

          // Executive Summary
          _buildExecutiveSummary(stats, previousStats),
          pw.SizedBox(height: 20),

          // Insights
          _buildInsightsSection(stats, previousStats),
          pw.SizedBox(height: 20),

          // Category Summary Table
          pw.Text(
            'Category Summary',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildCategoryTable(categoryBreakdown, stats.totalExpenses),
        ],
      ),
    );

    // Add pages for each category with transactions
    for (final category in transactionsByCategory.keys) {
      final categoryTransactions = transactionsByCategory[category]!;
      final categoryTotal = categoryTransactions.fold<double>(
        0,
        (sum, t) => sum + (t.type == models.TransactionType.expense ? t.amount : 0),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              category,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Total: ₹${_formatAmount(categoryTotal)} • ${categoryTransactions.length} transactions',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 15),
            _buildDetailedTransactionTable(categoryTransactions),
          ],
        ),
      );
    }
  }

  /// Generate Budget Performance Report
  Future<void> _generateBudgetReport(
    pw.Document pdf,
    ReportConfig config,
    List<models.Transaction> transactions,
    List<Budget> budgets,
    List<models.Transaction> allTransactions,
  ) async {
    final stats = _calculateStatistics(transactions);
    final previousStats = _calculatePreviousMonthStats(allTransactions, config);
    final budgetAnalysis = _analyzeBudgetPerformance(transactions, budgets);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(config, 'Budget Performance Report'),
          pw.SizedBox(height: 20),

          // Executive Summary
          _buildExecutiveSummary(stats, previousStats),
          pw.SizedBox(height: 20),

          // Budget Overview
          _buildBudgetOverview(budgetAnalysis),
          pw.SizedBox(height: 20),

          // Budget Comparison Table
          pw.Text(
            'Budget vs Actual Spending',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          _buildBudgetComparisonTable(budgetAnalysis),
          pw.SizedBox(height: 20),

          // Insights
          _buildBudgetInsights(budgetAnalysis),
        ],
      ),
    );
  }

  /// Build report header
  pw.Widget _buildHeader(ReportConfig config, String title) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  config.companyName ?? 'ExpenWall',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.purple700),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Report Date',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  dateFormat.format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.purple700, thickness: 2),
        pw.SizedBox(height: 4),
        pw.Text(
          'Period: ${config.dateRangeString}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Build executive summary section with Income, Expenses, Savings
  pw.Widget _buildExecutiveSummary(Map<String, dynamic> stats, Map<String, dynamic>? previousStats) {
    final savings = stats['totalIncome'] - stats['totalExpenses'];
    final savingsRate = stats['totalIncome'] > 0 ? (savings / stats['totalIncome'] * 100) : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.purple700, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Total Income', stats['totalIncome'], PdfColors.green600),
              _buildSummaryCard('Total Expenses', stats['totalExpenses'], PdfColors.red600),
              _buildSummaryCard(
                'Savings',
                savings,
                savings >= 0 ? PdfColors.blue600 : PdfColors.orange600,
                subtitle: '${savingsRate.toStringAsFixed(1)}% saved',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build summary card for income/expense/savings
  pw.Widget _buildSummaryCard(String label, double amount, PdfColor color, {String? subtitle}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '₹${_formatAmount(amount)}',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color),
        ),
        if (subtitle != null) ..[
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ],
      ],
    );
  }

  /// Build personalized insights section
  pw.Widget _buildInsightsSection(Map<String, dynamic> stats, Map<String, dynamic>? previousStats) {
    final insights = <String>[];

    // Month-over-month comparison
    if (previousStats != null) {
      final expenseChange = stats['totalExpenses'] - previousStats['totalExpenses'];
      final expenseChangePercent = previousStats['totalExpenses'] > 0
          ? (expenseChange / previousStats['totalExpenses'] * 100)
          : 0.0;

      if (expenseChange > 0) {
        insights.add(
          '📈 Expenses increased by ₹${_formatAmount(expenseChange.abs())} (${expenseChangePercent.toStringAsFixed(1)}%) compared to previous month.',
        );
      } else if (expenseChange < 0) {
        insights.add(
          '📉 Great job! Expenses decreased by ₹${_formatAmount(expenseChange.abs())} (${expenseChangePercent.abs().toStringAsFixed(1)}%) compared to previous month.',
        );
      }

      final savings = stats['totalIncome'] - stats['totalExpenses'];
      final prevSavings = previousStats['totalIncome'] - previousStats['totalExpenses'];
      final savingsChange = savings - prevSavings;

      if (savingsChange > 0) {
        insights.add(
          '💰 You saved ₹${_formatAmount(savingsChange.abs())} more this month! Keep up the excellent work.',
        );
      } else if (savingsChange < 0) {
        insights.add(
          '⚠️ Savings decreased by ₹${_formatAmount(savingsChange.abs())} this month. Consider reviewing your spending.',
        );
      }
    }

    // Daily average
    final avgPerDay = stats['avgPerDay'];
    insights.add('📊 Average daily spending: ₹${_formatAmount(avgPerDay)}');

    // Highest expense
    if (stats['highestExpense'] != null) {
      insights.add('🔝 Highest single expense: ₹${_formatAmount(stats['highestExpense'])}');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.purple50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💡 Personalized Insights',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...insights.map((insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(insight, style: const pw.TextStyle(fontSize: 10)),
              )),
        ],
      ),
    );
  }

  /// Build category breakdown table
  pw.Widget _buildCategoryTable(Map<String, double> breakdown, double total) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('% of Total', isHeader: true),
          ],
        ),
        // Data rows
        ...breakdown.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell('₹${_formatAmount(entry.value)}'),
              _buildTableCell('${percentage.toStringAsFixed(1)}%'),
            ],
          );
        }),
        // Total row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Total', isHeader: true),
            _buildTableCell('₹${_formatAmount(total)}', isHeader: true),
            _buildTableCell('100%', isHeader: true),
          ],
        ),
      ],
    );
  }

  /// Build top transactions table
  pw.Widget _buildTopTransactionsTable(List<models.Transaction> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Merchant', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Data rows
        ...transactions.map((t) {
          return pw.TableRow(
            children: [
              _buildTableCell(t.merchant),
              _buildTableCell(DateFormat('dd/MM').format(t.date)),
              _buildTableCell(t.category.label),
              _buildTableCell('₹${_formatAmount(t.amount)}'),
            ],
          );
        }),
      ],
    );
  }

  /// Build detailed transaction table
  pw.Widget _buildDetailedTransactionTable(List<models.Transaction> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Merchant', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
            _buildTableCell('Notes', isHeader: true),
          ],
        ),
        // Data rows
        ...transactions.map((t) {
          return pw.TableRow(
            children: [
              _buildTableCell(t.merchant),
              _buildTableCell(DateFormat('dd/MM/yy').format(t.date)),
              _buildTableCell('₹${_formatAmount(t.amount)}'),
              _buildTableCell(t.notes ?? '-'),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell helper
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Build key statistics section
  pw.Widget _buildKeyStatistics(Map<String, dynamic> stats, List<models.Transaction> transactions) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Key Statistics',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _buildStatRow('Total Transactions', '${transactions.length}'),
          _buildStatRow('Average per Day', '₹${_formatAmount(stats['avgPerDay'])}'),
          _buildStatRow('Highest Expense', '₹${_formatAmount(stats['highestExpense'] ?? 0)}'),
          _buildStatRow('Most Frequent Category', stats['topCategory'] ?? 'N/A'),
        ],
      ),
    );
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  /// Build budget overview section
  pw.Widget _buildBudgetOverview(Map<String, Map<String, dynamic>> analysis) {
    final overBudget = analysis.values.where((a) => a['percentage'] > 100).length;
    final withinBudget = analysis.values.where((a) => a['percentage'] <= 100).length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Budget Overview',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('✅ Within Budget: $withinBudget categories', style: const pw.TextStyle(fontSize: 10)),
          pw.Text('⚠️ Over Budget: $overBudget categories', style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  /// Build budget comparison table
  pw.Widget _buildBudgetComparisonTable(Map<String, Map<String, dynamic>> analysis) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple100),
          children: [
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Budget', isHeader: true),
            _buildTableCell('Actual', isHeader: true),
            _buildTableCell('Difference', isHeader: true),
            _buildTableCell('Status', isHeader: true),
          ],
        ),
        // Data rows
        ...analysis.entries.map((entry) {
          final data = entry.value;
          final difference = data['spent'] - data['budget'];
          final percentage = data['percentage'];
          final status = percentage > 100 ? 'Over' : percentage > 80 ? 'Warning' : 'Good';

          return pw.TableRow(
            children: [
              _buildTableCell(entry.key),
              _buildTableCell('₹${_formatAmount(data['budget'])}'),
              _buildTableCell('₹${_formatAmount(data['spent'])}'),
              _buildTableCell(
                '${difference >= 0 ? '+' : ''}₹${_formatAmount(difference)}',
              ),
              _buildTableCell(status),
            ],
          );
        }),
      ],
    );
  }

  /// Build budget insights
  pw.Widget _buildBudgetInsights(Map<String, Map<String, dynamic>> analysis) {
    final insights = <String>[];

    final overBudget = analysis.entries.where((e) => e.value['percentage'] > 100).toList();
    if (overBudget.isNotEmpty) {
      for (final entry in overBudget) {
        final overage = entry.value['spent'] - entry.value['budget'];
        insights.add(
          '⚠️ ${entry.key}: Over budget by ₹${_formatAmount(overage)} (${(entry.value['percentage'] - 100).toStringAsFixed(1)}%)',
        );
      }
    }

    final goodCategories = analysis.entries.where((e) => e.value['percentage'] <= 80).toList();
    if (goodCategories.isNotEmpty) {
      insights.add('✅ ${goodCategories.length} categories are well within budget!');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '💡 Budget Insights',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...insights.map((insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(insight, style: const pw.TextStyle(fontSize: 10)),
              )),
        ],
      ),
    );
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Calculate statistics from transactions
  Map<String, dynamic> _calculateStatistics(List<models.Transaction> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    double highestExpense = 0;
    String? topCategory;
    final categoryCount = <String, int>{};

    for (final t in transactions) {
      if (t.type == models.TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpenses += t.amount;
        if (t.amount > highestExpense) {
          highestExpense = t.amount;
        }
        categoryCount[t.category.label] = (categoryCount[t.category.label] ?? 0) + 1;
      }
    }

    // Find most frequent category
    if (categoryCount.isNotEmpty) {
      topCategory = categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    final days = transactions.isNotEmpty
        ? transactions.last.date.difference(transactions.first.date).inDays + 1
        : 1;
    final avgPerDay = days > 0 ? totalExpenses / days : 0;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'highestExpense': highestExpense,
      'topCategory': topCategory,
      'avgPerDay': avgPerDay,
    };
  }

  /// Calculate previous month statistics for comparison
  Map<String, dynamic>? _calculatePreviousMonthStats(
    List<models.Transaction> allTransactions,
    ReportConfig config,
  ) {
    final duration = config.endDate.difference(config.startDate);
    final prevStart = config.startDate.subtract(duration);
    final prevEnd = config.startDate.subtract(const Duration(days: 1));

    final prevTransactions = allTransactions.where((t) {
      return t.date.isAfter(prevStart.subtract(const Duration(days: 1))) &&
          t.date.isBefore(prevEnd.add(const Duration(days: 1)));
    }).toList();

    if (prevTransactions.isEmpty) return null;

    return _calculateStatistics(prevTransactions);
  }

  /// Get category breakdown
  Map<String, double> _getCategoryBreakdown(List<models.Transaction> transactions) {
    final breakdown = <String, double>{};

    for (final t in transactions) {
      if (t.type == models.TransactionType.expense) {
        breakdown[t.category.label] = (breakdown[t.category.label] ?? 0) + t.amount;
      }
    }

    // Sort by amount descending
    final sorted = Map.fromEntries(
      breakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    return sorted;
  }

  /// Get top N transactions by amount
  List<models.Transaction> _getTopTransactions(List<models.Transaction> transactions, int count) {
    final expenses = transactions.where((t) => t.type == models.TransactionType.expense).toList();
    expenses.sort((a, b) => b.amount.compareTo(a.amount));
    return expenses.take(count).toList();
  }

  /// Group transactions by category
  Map<String, List<models.Transaction>> _groupTransactionsByCategory(
    List<models.Transaction> transactions,
  ) {
    final grouped = <String, List<models.Transaction>>{};

    for (final t in transactions) {
      if (t.type == models.TransactionType.expense) {
        grouped[t.category.label] = [...(grouped[t.category.label] ?? []), t];
      }
    }

    // Sort each category's transactions by date
    for (final key in grouped.keys) {
      grouped[key]!.sort((a, b) => b.date.compareTo(a.date));
    }

    return grouped;
  }

  /// Analyze budget performance
  Map<String, Map<String, dynamic>> _analyzeBudgetPerformance(
    List<models.Transaction> transactions,
    List<Budget> budgets,
  ) {
    final analysis = <String, Map<String, dynamic>>{};

    for (final budget in budgets) {
      final spent = transactions
          .where((t) => t.category == budget.category && t.type == models.TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount);

      final percentage = budget.amount > 0 ? (spent / budget.amount * 100) : 0.0;

      analysis[budget.category.label] = {
        'budget': budget.amount,
        'spent': spent,
        'percentage': percentage,
      };
    }

    return analysis;
  }

  /// Format amount with commas
  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)},',
        );
  }

  /// Save PDF to file
  Future<File> _savePDF(pw.Document pdf, ReportConfig config) async {
    final output = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${output.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final fileName = 'report_${config.id}.pdf';
    final file = File('${reportsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
