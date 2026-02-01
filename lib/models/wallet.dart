import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletType { bank, cash, credit, digital }

class Wallet {
  final String id;
  final String? userId;
  final String name;
  final WalletType type;
  final String? color;
  final DateTime? createdAt;

  Wallet({
    required this.id,
    this.userId,
    required this.name,
    required this.type,
    this.color,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'type': type.name,
        'color': color,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      userId: data['userId'],
      name: data['name'],
      type: WalletType.values.byName(data['type']),
      color: data['color'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
