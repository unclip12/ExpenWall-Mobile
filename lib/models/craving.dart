import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction.dart' as models;

/// Represents an item within a craving
class CravingItem {
  final String name;
  final int quantity;
  final double pricePerUnit;
  final String? emoji;
  final String? brand;

  CravingItem({
    required this.name,
    required this.quantity,
    required this.pricePerUnit,
    this.emoji,
    this.brand,
  });

  double get totalPrice => quantity * pricePerUnit;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'pricePerUnit': pricePerUnit,
        'emoji': emoji,
        'brand': brand,
      };

  factory CravingItem.fromJson(Map<String, dynamic> json) => CravingItem(
        name: json['name'] ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
        emoji: json['emoji'],
        brand: json['brand'],
      );
}

/// Status of a craving log entry
enum CravingStatus {
  resisted,
  gaveIn;

  String get label {
    switch (this) {
      case CravingStatus.resisted:
        return 'Resisted';
      case CravingStatus.gaveIn:
        return 'Gave In';
    }
  }

  String get emoji {
    switch (this) {
      case CravingStatus.resisted:
        return '💪';
      case CravingStatus.gaveIn:
        return '😋';
    }
  }
}

/// Main Craving model representing a logged craving
class Craving {
  final String id;
  final String userId;
  final String name; // What they craved (e.g., "Pizza", "Biryani")
  final String? description;
  final CravingStatus status;
  final DateTime timestamp;
  final List<CravingItem> items; // Items if they gave in
  final String? merchant; // Merchant name (e.g., "Zomato", "Swiggy")
  final String? merchantArea; // Area/location of merchant
  final double totalAmount; // Total amount spent if gave in
  final String? transactionId; // Linked transaction if gave in
  final models.Category? category; // Category (Food & Dining, Shopping, etc.)
  final String? notes;

  Craving({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    required this.timestamp,
    this.items = const [],
    this.merchant,
    this.merchantArea,
    this.totalAmount = 0.0,
    this.transactionId,
    this.category,
    this.notes,
  });

  bool get wasResisted => status == CravingStatus.resisted;
  bool get gaveIn => status == CravingStatus.gaveIn;

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'description': description,
        'status': status.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'items': items.map((e) => e.toJson()).toList(),
        'merchant': merchant,
        'merchantArea': merchantArea,
        'totalAmount': totalAmount,
        'transactionId': transactionId,
        'category': category?.label,
        'notes': notes,
      };

  factory Craving.fromFirestore(Map<String, dynamic> data, String id) {
    return Craving(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      status: CravingStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CravingStatus.gaveIn,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      items: (data['items'] as List<dynamic>?)
              ?.map((e) => CravingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      merchant: data['merchant'],
      merchantArea: data['merchantArea'],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      transactionId: data['transactionId'],
      category: data['category'] != null
          ? models.Category.values.firstWhere(
              (e) => e.label == data['category'],
              orElse: () => models.Category.other,
            )
          : null,
      notes: data['notes'],
    );
  }

  Craving copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    CravingStatus? status,
    DateTime? timestamp,
    List<CravingItem>? items,
    String? merchant,
    String? merchantArea,
    double? totalAmount,
    String? transactionId,
    models.Category? category,
    String? notes,
  }) {
    return Craving(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      merchant: merchant ?? this.merchant,
      merchantArea: merchantArea ?? this.merchantArea,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionId: transactionId ?? this.transactionId,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }
}

/// Analytics data for cravings
class CravingAnalytics {
  final int totalCravings;
  final int resistedCount;
  final int gaveInCount;
  final double resistanceRate; // Percentage
  final double totalSpent;
  final String? topMerchant;
  final models.Category? topCategory;
  final int currentStreak; // Days resisted in a row
  final int longestStreak;
  final Map<String, int> merchantFrequency; // Merchant -> count
  final Map<String, double> merchantSpending; // Merchant -> amount
  final List<Craving> recentCravings;

  CravingAnalytics({
    required this.totalCravings,
    required this.resistedCount,
    required this.gaveInCount,
    required this.resistanceRate,
    required this.totalSpent,
    this.topMerchant,
    this.topCategory,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.merchantFrequency = const {},
    this.merchantSpending = const {},
    this.recentCravings = const [],
  });

  factory CravingAnalytics.fromCravings(List<Craving> cravings) {
    if (cravings.isEmpty) {
      return CravingAnalytics(
        totalCravings: 0,
        resistedCount: 0,
        gaveInCount: 0,
        resistanceRate: 0.0,
        totalSpent: 0.0,
      );
    }

    final resisted = cravings.where((c) => c.wasResisted).length;
    final gaveIn = cravings.where((c) => c.gaveIn).length;
    final totalSpent = cravings
        .where((c) => c.gaveIn)
        .fold(0.0, (sum, c) => sum + c.totalAmount);

    // Calculate merchant frequency and spending
    final merchantFreq = <String, int>{};
    final merchantSpend = <String, double>{};
    for (final craving in cravings.where((c) => c.gaveIn)) {
      if (craving.merchant != null) {
        merchantFreq[craving.merchant!] =
            (merchantFreq[craving.merchant!] ?? 0) + 1;
        merchantSpend[craving.merchant!] =
            (merchantSpend[craving.merchant!] ?? 0.0) + craving.totalAmount;
      }
    }

    // Find top merchant
    String? topMerchant;
    if (merchantFreq.isNotEmpty) {
      topMerchant = merchantFreq.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    // Calculate streaks
    final sortedCravings = List<Craving>.from(cravings)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    for (final craving in sortedCravings) {
      if (craving.wasResisted) {
        tempStreak++;
        if (currentStreak == 0 ||
            currentStreak == tempStreak) {
          currentStreak = tempStreak;
        }
      } else {
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        if (currentStreak == tempStreak) {
          currentStreak = 0;
        }
        tempStreak = 0;
      }
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;

    return CravingAnalytics(
      totalCravings: cravings.length,
      resistedCount: resisted,
      gaveInCount: gaveIn,
      resistanceRate: cravings.isEmpty ? 0.0 : (resisted / cravings.length) * 100,
      totalSpent: totalSpent,
      topMerchant: topMerchant,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      merchantFrequency: merchantFreq,
      merchantSpending: merchantSpend,
      recentCravings: sortedCravings.take(10).toList(),
    );
  }

  String get ranking {
    if (resistanceRate >= 80) return '🏆 Master';
    if (resistanceRate >= 60) return '🥇 Champion';
    if (resistanceRate >= 40) return '🥈 Warrior';
    if (resistanceRate >= 20) return '🥉 Fighter';
    return '🎯 Beginner';
  }
}
