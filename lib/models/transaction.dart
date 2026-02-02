import 'package:cloud_firestore/cloud_firestore.dart';

enum Category {
  food('Food & Dining'),
  transport('Transportation'),
  utilities('Utilities'),
  entertainment('Entertainment'),
  shopping('Shopping'),
  health('Health & Fitness'),
  groceries('Groceries'),
  income('Income'),
  education('Education'),
  personalCare('Personal Care'),
  government('Government & Official'),
  banking('Banking & Finance'),
  other('Other');

  final String label;
  const Category(this.label);
}

enum TransactionType { expense, income }
enum WalletType { bank, cash, credit, digital }
enum UnitType { gram, kg, ml, litre, piece, packet, box, other }

class TransactionItem {
  final String name;
  final String? brand;
  final double price;
  final int quantity;
  final double? weight;
  final UnitType? weightUnit;
  final double? mrp;
  final double? discount;
  final double? tax;
  final double? pricePerUnit;

  TransactionItem({
    required this.name,
    this.brand,
    required this.price,
    required this.quantity,
    this.weight,
    this.weightUnit,
    this.mrp,
    this.discount,
    this.tax,
    this.pricePerUnit,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'price': price,
        'quantity': quantity,
        'weight': weight,
        'weightUnit': weightUnit?.name,
        'mrp': mrp,
        'discount': discount,
        'tax': tax,
        'pricePerUnit': pricePerUnit,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        name: json['name'],
        brand: json['brand'],
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'],
        weight: json['weight']?.toDouble(),
        weightUnit: json['weightUnit'] != null ? UnitType.values.byName(json['weightUnit']) : null,
        mrp: json['mrp']?.toDouble(),
        discount: json['discount']?.toDouble(),
        tax: json['tax']?.toDouble(),
        pricePerUnit: json['pricePerUnit']?.toDouble(),
      );
}

class Transaction {
  final String id;
  final String? userId;
  final String merchant;
  final String? merchantEmoji;
  final DateTime date;
  final String? time;
  final double amount;
  final String currency;
  final Category category;
  final String? subcategory;
  final TransactionType type;
  final String? walletId;
  final List<TransactionItem>? items;
  final String? notes;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurringId;

  Transaction({
    required this.id,
    this.userId,
    required this.merchant,
    this.merchantEmoji,
    required this.date,
    this.time,
    required this.amount,
    this.currency = 'INR',
    required this.category,
    this.subcategory,
    required this.type,
    this.walletId,
    this.items,
    this.notes,
    this.tags,
    this.isRecurring = false,
    this.recurringId,
  });

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'merchant': merchant,
        'merchantEmoji': merchantEmoji,
        'date': Timestamp.fromDate(date),
        'time': time,
        'amount': amount,
        'currency': currency,
        'category': category.label,
        'subcategory': subcategory,
        'type': type.name,
        'walletId': walletId,
        'items': items?.map((e) => e.toJson()).toList(),
        'notes': notes,
        'tags': tags,
        'isRecurring': isRecurring,
        'recurringId': recurringId,
      };

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'],
      merchant: data['merchant'],
      merchantEmoji: data['merchantEmoji'],
      date: (data['date'] as Timestamp).toDate(),
      time: data['time'],
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] ?? 'INR',
      category: Category.values.firstWhere((e) => e.label == data['category'], orElse: () => Category.other),
      subcategory: data['subcategory'],
      type: TransactionType.values.byName(data['type']),
      walletId: data['walletId'],
      items: (data['items'] as List?)?.map((e) => TransactionItem.fromJson(e)).toList(),
      notes: data['notes'],
      tags: (data['tags'] as List?)?.cast<String>(),
      isRecurring: data['isRecurring'] ?? false,
      recurringId: data['recurringId'],
    );
  }
}
