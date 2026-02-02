import 'package:uuid/uuid.dart';
import 'transaction.dart';

enum FrequencyUnit {
  days,
  weeks,
  months,
  years,
}

class RecurringRule {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String category;
  final String? subcategory;
  final TransactionType type;
  
  // Frequency settings
  final int frequencyValue; // e.g., 1, 25, 3
  final FrequencyUnit frequencyUnit;
  
  // Date tracking
  final DateTime startDate;
  final DateTime nextOccurrence;
  final DateTime? lastCreated;
  
  // Status
  final bool isActive;
  final String? notes;
  
  // Notification settings
  final int notificationHour; // 0-23 (default: 5 for 5 AM)
  final int notificationMinute; // 0-59 (default: 0)

  RecurringRule({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    this.subcategory,
    required this.type,
    required this.frequencyValue,
    required this.frequencyUnit,
    required this.startDate,
    required this.nextOccurrence,
    this.lastCreated,
    this.isActive = true,
    this.notes,
    this.notificationHour = 5,
    this.notificationMinute = 0,
  });

  // Calculate next occurrence based on frequency
  static DateTime calculateNextOccurrence(DateTime current, int value, FrequencyUnit unit) {
    switch (unit) {
      case FrequencyUnit.days:
        return current.add(Duration(days: value));
      case FrequencyUnit.weeks:
        return current.add(Duration(days: value * 7));
      case FrequencyUnit.months:
        return DateTime(
          current.year,
          current.month + value,
          current.day,
          current.hour,
          current.minute,
        );
      case FrequencyUnit.years:
        return DateTime(
          current.year + value,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }

  // Get frequency display text
  String getFrequencyText() {
    if (frequencyValue == 1) {
      switch (frequencyUnit) {
        case FrequencyUnit.days:
          return 'Daily';
        case FrequencyUnit.weeks:
          return 'Weekly';
        case FrequencyUnit.months:
          return 'Monthly';
        case FrequencyUnit.years:
          return 'Yearly';
      }
    }
    
    return 'Every $frequencyValue ${_getUnitText()}';
  }

  String _getUnitText() {
    switch (frequencyUnit) {
      case FrequencyUnit.days:
        return frequencyValue == 1 ? 'day' : 'days';
      case FrequencyUnit.weeks:
        return frequencyValue == 1 ? 'week' : 'weeks';
      case FrequencyUnit.months:
        return frequencyValue == 1 ? 'month' : 'months';
      case FrequencyUnit.years:
        return frequencyValue == 1 ? 'year' : 'years';
    }
  }

  // Check if rule is due today
  bool isDueToday() {
    final now = DateTime.now();
    return nextOccurrence.year == now.year &&
           nextOccurrence.month == now.month &&
           nextOccurrence.day == now.day;
  }

  // Factory constructor with auto ID generation
  factory RecurringRule.create({
    required String userId,
    required String name,
    required double amount,
    required String category,
    String? subcategory,
    required TransactionType type,
    required int frequencyValue,
    required FrequencyUnit frequencyUnit,
    required DateTime startDate,
    DateTime? nextOccurrence,
    String? notes,
    int notificationHour = 5,
    int notificationMinute = 0,
  }) {
    final id = const Uuid().v4();
    final calculatedNextOccurrence = nextOccurrence ?? 
        calculateNextOccurrence(startDate, frequencyValue, frequencyUnit);
    
    return RecurringRule(
      id: id,
      userId: userId,
      name: name,
      amount: amount,
      category: category,
      subcategory: subcategory,
      type: type,
      frequencyValue: frequencyValue,
      frequencyUnit: frequencyUnit,
      startDate: startDate,
      nextOccurrence: calculatedNextOccurrence,
      notes: notes,
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
    );
  }

  // Copy with method for updates
  RecurringRule copyWith({
    String? userId,
    String? name,
    double? amount,
    String? category,
    String? subcategory,
    TransactionType? type,
    int? frequencyValue,
    FrequencyUnit? frequencyUnit,
    DateTime? startDate,
    DateTime? nextOccurrence,
    DateTime? lastCreated,
    bool? isActive,
    String? notes,
    int? notificationHour,
    int? notificationMinute,
  }) {
    return RecurringRule(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      type: type ?? this.type,
      frequencyValue: frequencyValue ?? this.frequencyValue,
      frequencyUnit: frequencyUnit ?? this.frequencyUnit,
      startDate: startDate ?? this.startDate,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      lastCreated: lastCreated ?? this.lastCreated,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'amount': amount,
    'category': category,
    'subcategory': subcategory,
    'type': type.toString().split('.').last,
    'frequencyValue': frequencyValue,
    'frequencyUnit': frequencyUnit.toString().split('.').last,
    'startDate': startDate.toIso8601String(),
    'nextOccurrence': nextOccurrence.toIso8601String(),
    'lastCreated': lastCreated?.toIso8601String(),
    'isActive': isActive,
    'notes': notes,
    'notificationHour': notificationHour,
    'notificationMinute': notificationMinute,
  };

  factory RecurringRule.fromJson(Map<String, dynamic> json) => RecurringRule(
    id: json['id'],
    userId: json['userId'],
    name: json['name'],
    amount: (json['amount'] as num).toDouble(),
    category: json['category'],
    subcategory: json['subcategory'],
    type: TransactionType.values.firstWhere(
      (e) => e.toString().split('.').last == json['type'],
    ),
    frequencyValue: json['frequencyValue'],
    frequencyUnit: FrequencyUnit.values.firstWhere(
      (e) => e.toString().split('.').last == json['frequencyUnit'],
    ),
    startDate: DateTime.parse(json['startDate']),
    nextOccurrence: DateTime.parse(json['nextOccurrence']),
    lastCreated: json['lastCreated'] != null 
        ? DateTime.parse(json['lastCreated']) 
        : null,
    isActive: json['isActive'] ?? true,
    notes: json['notes'],
    notificationHour: json['notificationHour'] ?? 5,
    notificationMinute: json['notificationMinute'] ?? 0,
  );
}
