import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';

class MerchantRule {
  final String id;
  final String merchantPattern;
  final Category category;
  final String? subcategory;
  final DateTime createdAt;

  MerchantRule({
    required this.id,
    required this.merchantPattern,
    required this.category,
    this.subcategory,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'merchantPattern': merchantPattern,
        'category': category.label,
        'subcategory': subcategory,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MerchantRule.fromFirestore(Map<String, dynamic> data, String id) {
    return MerchantRule(
      id: id,
      merchantPattern: data['merchantPattern'] ?? '',
      category: Category.values.firstWhere(
        (e) => e.label == data['category'],
        orElse: () => Category.other,
      ),
      subcategory: data['subcategory'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
