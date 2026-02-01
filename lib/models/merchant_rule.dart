import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart';

class MerchantRule {
  final String id;
  final String? userId;
  final String originalName;
  final String renamedTo;
  final Category? forcedCategory;
  final String? forcedSubcategory;
  final String? emoji;
  final DateTime? createdAt;

  MerchantRule({
    required this.id,
    this.userId,
    required this.originalName,
    required this.renamedTo,
    this.forcedCategory,
    this.forcedSubcategory,
    this.emoji,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'originalName': originalName,
        'renamedTo': renamedTo,
        'forcedCategory': forcedCategory?.label,
        'forcedSubcategory': forcedSubcategory,
        'emoji': emoji,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory MerchantRule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MerchantRule(
      id: doc.id,
      userId: data['userId'],
      originalName: data['originalName'],
      renamedTo: data['renamedTo'],
      forcedCategory: data['forcedCategory'] != null ? Category.values.firstWhere((e) => e.label == data['forcedCategory']) : null,
      forcedSubcategory: data['forcedSubcategory'],
      emoji: data['emoji'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
