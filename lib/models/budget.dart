import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';

class Budget {
  final String id;
  final String? userId;
  final Category category;
  final String? subcategory;
  final double amount;
  final String period; // 'monthly', 'weekly', 'yearly'
  final DateTime? startDate;
  final bool alertAt80;
  final bool alertAt100;
  final DateTime? createdAt;

  Budget({
    required this.id,
    this.userId,
    required this.category,
    this.subcategory,
    required this.amount,
    this.period = 'monthly',
    this.startDate,
    this.alertAt80 = true,
    this.alertAt100 = true,
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'category': category.label,
        'subcategory': subcategory,
        'amount': amount,
        'period': period,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'alertAt80': alertAt80,
        'alertAt100': alertAt100,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory Budget.fromFirestore(Map<String, dynamic> data, String id) {
    return Budget(
      id: id,
      userId: data['userId'],
      category: Category.values.firstWhere(
        (e) => e.label == data['category'],
        orElse: () => Category.other,
      ),
      subcategory: data['subcategory'],
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      period: data['period'] ?? 'monthly',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      alertAt80: data['alertAt80'] ?? true,
      alertAt100: data['alertAt100'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BudgetStatus {
  final Budget budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOverBudget;

  BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOverBudget,
  });
}
