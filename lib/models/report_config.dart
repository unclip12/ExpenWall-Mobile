/// Report Configuration Model for PDF Generation
/// Supports flexible report types, date ranges, and filters

enum ReportType {
  simple, // Simple summary with key metrics
  detailed, // Detailed transaction list
  budget, // Budget performance analysis
}

enum ReportPeriodType {
  custom, // Custom date range
  month, // Specific month
  week, // Specific week
  day, // Specific day
  year, // Entire year
  thisMonth, // Current month
  lastMonth, // Previous month
  thisQuarter, // Current quarter
  lastQuarter, // Previous quarter
}

class ReportConfig {
  final String id;
  final ReportType type;
  final ReportPeriodType periodType;
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? categoryFilters; // Filter by specific categories
  final List<String>? merchantFilters; // Filter by specific merchants
  final double? minAmount; // Minimum transaction amount
  final double? maxAmount; // Maximum transaction amount
  final bool includeReceipts; // Include receipt images
  final bool includeCharts; // Include visual charts
  final String? companyName; // Branding: Company/Personal name
  final String? notes; // Additional notes to include
  final DateTime createdAt;

  ReportConfig({
    required this.id,
    required this.type,
    required this.periodType,
    required this.startDate,
    required this.endDate,
    this.categoryFilters,
    this.merchantFilters,
    this.minAmount,
    this.maxAmount,
    this.includeReceipts = false,
    this.includeCharts = true,
    this.companyName,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Get display name for report type
  String get typeName {
    switch (type) {
      case ReportType.simple:
        return 'Simple Summary';
      case ReportType.detailed:
        return 'Detailed Report';
      case ReportType.budget:
        return 'Budget Analysis';
    }
  }

  /// Get display name for period type
  String get periodName {
    switch (periodType) {
      case ReportPeriodType.custom:
        return 'Custom Range';
      case ReportPeriodType.month:
        return 'Month';
      case ReportPeriodType.week:
        return 'Week';
      case ReportPeriodType.day:
        return 'Day';
      case ReportPeriodType.year:
        return 'Year';
      case ReportPeriodType.thisMonth:
        return 'This Month';
      case ReportPeriodType.lastMonth:
        return 'Last Month';
      case ReportPeriodType.thisQuarter:
        return 'This Quarter';
      case ReportPeriodType.lastQuarter:
        return 'Last Quarter';
    }
  }

  /// Get formatted date range string
  String get dateRangeString {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return '${startDate.day}/${startDate.month}/${startDate.year}';
    }
    return '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'periodType': periodType.name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'categoryFilters': categoryFilters,
        'merchantFilters': merchantFilters,
        'minAmount': minAmount,
        'maxAmount': maxAmount,
        'includeReceipts': includeReceipts,
        'includeCharts': includeCharts,
        'companyName': companyName,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from JSON
  factory ReportConfig.fromJson(Map<String, dynamic> json) => ReportConfig(
        id: json['id'],
        type: ReportType.values.byName(json['type']),
        periodType: ReportPeriodType.values.byName(json['periodType']),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        categoryFilters: (json['categoryFilters'] as List?)?.cast<String>(),
        merchantFilters: (json['merchantFilters'] as List?)?.cast<String>(),
        minAmount: json['minAmount']?.toDouble(),
        maxAmount: json['maxAmount']?.toDouble(),
        includeReceipts: json['includeReceipts'] ?? false,
        includeCharts: json['includeCharts'] ?? true,
        companyName: json['companyName'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  /// Create a copy with modified fields
  ReportConfig copyWith({
    String? id,
    ReportType? type,
    ReportPeriodType? periodType,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryFilters,
    List<String>? merchantFilters,
    double? minAmount,
    double? maxAmount,
    bool? includeReceipts,
    bool? includeCharts,
    String? companyName,
    String? notes,
    DateTime? createdAt,
  }) =>
      ReportConfig(
        id: id ?? this.id,
        type: type ?? this.type,
        periodType: periodType ?? this.periodType,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        categoryFilters: categoryFilters ?? this.categoryFilters,
        merchantFilters: merchantFilters ?? this.merchantFilters,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        includeReceipts: includeReceipts ?? this.includeReceipts,
        includeCharts: includeCharts ?? this.includeCharts,
        companyName: companyName ?? this.companyName,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
      );

  /// Helper: Create config for "This Month"
  static ReportConfig thisMonth(ReportType type) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return ReportConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      periodType: ReportPeriodType.thisMonth,
      startDate: start,
      endDate: end,
    );
  }

  /// Helper: Create config for "Last Month"
  static ReportConfig lastMonth(ReportType type) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0, 23, 59, 59);
    return ReportConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      periodType: ReportPeriodType.lastMonth,
      startDate: start,
      endDate: end,
    );
  }

  /// Helper: Create config for "This Year"
  static ReportConfig thisYear(ReportType type) {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return ReportConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      periodType: ReportPeriodType.year,
      startDate: start,
      endDate: end,
    );
  }
}
