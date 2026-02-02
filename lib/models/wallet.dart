import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String? currency;
  final bool isDefault;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = 'INR',
    this.isDefault = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type,
        'balance': balance,
        'currency': currency,
        'isDefault': isDefault,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Wallet(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'cash',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] ?? 'INR',
      isDefault: data['isDefault'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
