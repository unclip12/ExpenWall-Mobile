import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';

enum BudgetPeriod { weekly, monthly }

class Budget {
  final String id;
  final String userId;
  final Category category;
  final String? subcategory;
  final double amount;
  final BudgetPeriod period;
  final DateTime startDate;
  final bool alertAt80;
  final bool alertAt100;
  final DateTime? createdAt;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    this.subcategory,
    required this.amount,
    required this.period,
    required this.startDate,
    this.alertAt80 = true,
    this.alertAt100 = true,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'category': category.label,
        'subcategory': subcategory,
        'amount': amount,
        'period': period.name,
        'startDate': Timestamp.fromDate(startDate),
        'alertAt80': alertAt80,
        'alertAt100': alertAt100,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'],
      category: Category.values.firstWhere((e) => e.label == data['category'], orElse: () => Category.other),
      subcategory: data['subcategory'],
      amount: (data['amount'] as num).toDouble(),
      period: BudgetPeriod.values.byName(data['period']),
      startDate: (data['startDate'] as Timestamp).toDate(),
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
