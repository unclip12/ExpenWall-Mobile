import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/report_config.dart';
import '../../models/transaction.dart' as models;
import '../../services/pdf_report_service.dart';
import '../../services/local_storage_service.dart';
import 'report_preview_screen.dart';

/// Report Builder Screen - Configure and generate PDF reports
class ReportBuilderScreen extends StatefulWidget {
  const ReportBuilderScreen({super.key});

  @override
  State<ReportBuilderScreen> createState() => _ReportBuilderScreenState();
}

class _ReportBuilderScreenState extends State<ReportBuilderScreen> {
  ReportType _selectedType = ReportType.detailed;
  ReportPeriodType _selectedPeriod = ReportPeriodType.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  bool _includeReceipts = false;
  bool _includeCharts = true;
  String? _companyName;
  List<String> _selectedCategories = [];
  List<String> _selectedMerchants = [];
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        backgroundColor: theme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template Selection
            _buildSectionTitle('Select Report Template'),
            const SizedBox(height: 12),
            _buildTemplateSelector(),
            const SizedBox(height: 24),

            // Date Range Selection
            _buildSectionTitle('Select Date Range'),
            const SizedBox(height: 12),
            _buildDateRangeSelector(),
            const SizedBox(height: 24),

            // Filters
            _buildSectionTitle('Filters (Optional)'),
            const SizedBox(height: 12),
            _buildFiltersSection(),
            const SizedBox(height: 24),

            // Options
            _buildSectionTitle('Options'),
            const SizedBox(height: 12),
            _buildOptionsSection(),
            const SizedBox(height: 32),

            // Generate Button
            _buildGenerateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTemplateSelector() {
    return Column(
      children: [
        _buildTemplateCard(
          ReportType.simple,
          'Simple Summary',
          'Quick overview with key metrics, category breakdown, and top transactions',
          Icons.summarize,
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          ReportType.detailed,
          'Detailed Professional',
          'Comprehensive report with all transactions grouped by category',
          Icons.description,
        ),
        const SizedBox(height: 12),
        _buildTemplateCard(
          ReportType.budget,
          'Budget Analysis',
          'Focus on budget performance with comparisons and insights',
          Icons.account_balance_wallet,
        ),
      ],
    );
  }

  Widget _buildTemplateCard(
    ReportType type,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? theme.primaryColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryColor : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Column(
      children: [
        // Preset options
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDateChip(ReportPeriodType.thisMonth, 'This Month'),
            _buildDateChip(ReportPeriodType.lastMonth, 'Last Month'),
            _buildDateChip(ReportPeriodType.thisQuarter, 'This Quarter'),
            _buildDateChip(ReportPeriodType.year, 'This Year'),
            _buildDateChip(ReportPeriodType.custom, 'Custom'),
          ],
        ),
        if (_selectedPeriod == ReportPeriodType.custom) ..[
          const SizedBox(height: 16),
          _buildCustomDatePickers(),
        ],
      ],
    );
  }

  Widget _buildDateChip(ReportPeriodType type, String label) {
    final isSelected = _selectedPeriod == type;
    final theme = Theme.of(context);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedPeriod = type);
        }
      },
      selectedColor: theme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.primaryColor : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCustomDatePickers() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _customStartDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _customStartDate = date);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _customStartDate != null
                  ? dateFormat.format(_customStartDate!)
                  : 'Start Date',
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _customEndDate ?? DateTime.now(),
                firstDate: _customStartDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _customEndDate = date);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _customEndDate != null
                  ? dateFormat.format(_customEndDate!)
                  : 'End Date',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.category),
          title: const Text('Filter by Categories'),
          subtitle: Text(
            _selectedCategories.isEmpty
                ? 'All categories'
                : '${_selectedCategories.length} selected',
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showCategoryFilter,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.store),
          title: const Text('Filter by Merchants'),
          subtitle: Text(
            _selectedMerchants.isEmpty
                ? 'All merchants'
                : '${_selectedMerchants.length} selected',
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showMerchantFilter,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.receipt),
          title: const Text('Include Receipt Images'),
          subtitle: const Text('Attach scanned receipt images'),
          value: _includeReceipts,
          onChanged: (value) => setState(() => _includeReceipts = value),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.bar_chart),
          title: const Text('Include Charts'),
          subtitle: const Text('Add visual charts and graphs'),
          value: _includeCharts,
          onChanged: (value) => setState(() => _includeCharts = value),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.business),
          title: const Text('Company/Personal Name'),
          subtitle: Text(_companyName ?? 'ExpenWall (default)'),
          trailing: const Icon(Icons.edit),
          onTap: _editCompanyName,
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateReport,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(
          _isGenerating ? 'Generating...' : 'Generate PDF Report',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showCategoryFilter() {
    // Show category filter dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Categories'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: models.Category.values.map((cat) {
                final isSelected = _selectedCategories.contains(cat.label);
                return CheckboxListTile(
                  title: Text(cat.label),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedCategories.add(cat.label);
                      } else {
                        _selectedCategories.remove(cat.label);
                      }
                    });
                    Navigator.pop(context);
                    _showCategoryFilter();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _selectedCategories.clear());
                Navigator.pop(context);
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showMerchantFilter() {
    // Show merchant filter dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter Merchants'),
          content: const Text('Merchant filtering will be available after loading transaction data.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _editCompanyName() {
    showDialog(
      context: context,
      builder: (context) {
        String? name = _companyName;
        return AlertDialog(
          title: const Text('Company/Personal Name'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Enter name (optional)',
            ),
            controller: TextEditingController(text: name),
            onChanged: (value) => name = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _companyName = name?.isEmpty == true ? null : name);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateReport() async {
    // Validate date range for custom
    if (_selectedPeriod == ReportPeriodType.custom) {
      if (_customStartDate == null || _customEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end dates')),
        );
        return;
      }
    }

    setState(() => _isGenerating = true);

    try {
      // Get date range
      final dateRange = _getDateRange();

      // Create report config
      final config = ReportConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: _selectedType,
        periodType: _selectedPeriod,
        startDate: dateRange.$1,
        endDate: dateRange.$2,
        categoryFilters: _selectedCategories.isEmpty ? null : _selectedCategories,
        merchantFilters: _selectedMerchants.isEmpty ? null : _selectedMerchants,
        includeReceipts: _includeReceipts,
        includeCharts: _includeCharts,
        companyName: _companyName,
      );

      // Get user ID (you'll need to get this from your auth service)
      final userId = 'demo_user'; // Replace with actual user ID

      // Generate PDF
      final localStorage = context.read<LocalStorageService>();
      final pdfService = PDFReportService(localStorage);
      final file = await pdfService.generateReport(userId, config);

      setState(() => _isGenerating = false);

      // Navigate to preview
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPreviewScreen(pdfFile: file, config: config),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    }
  }

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case ReportPeriodType.thisMonth:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriodType.lastMonth:
        return (
          DateTime(now.year, now.month - 1, 1),
          DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case ReportPeriodType.thisQuarter:
        final quarterStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return (
          DateTime(now.year, quarterStart, 1),
          DateTime(now.year, quarterStart + 3, 0, 23, 59, 59),
        );
      case ReportPeriodType.year:
        return (
          DateTime(now.year, 1, 1),
          DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case ReportPeriodType.custom:
        return (_customStartDate!, _customEndDate!);
      default:
        return (now, now);
    }
  }
}
