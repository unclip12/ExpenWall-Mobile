import 'participant.dart';

enum SplitType {
  equal,
  custom,
  percentage,
}

enum BillStatus {
  pending,
  partiallyPaid,
  fullySettled,
}

class SplitBillItem {
  final String name;
  final double price;
  final int quantity;

  SplitBillItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory SplitBillItem.fromJson(Map<String, dynamic> json) {
    return SplitBillItem(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }

  double get total => price * quantity;
}

class SplitBill {
  final String id;
  final String userId; // Creator's user ID
  final String title;
  final String? description;
  final double totalAmount;
  final List<SplitBillItem> items;
  final SplitType splitType;
  final List<Participant> participants;
  final String paidByContactId; // Who paid initially
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BillStatus status;
  final String? notes;

  SplitBill({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.totalAmount,
    required this.items,
    required this.splitType,
    required this.participants,
    required this.paidByContactId,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    required this.status,
    this.notes,
  });

  factory SplitBill.fromJson(Map<String, dynamic> json) {
    return SplitBill(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List)
          .map((item) => SplitBillItem.fromJson(item))
          .toList(),
      splitType: SplitType.values.byName(json['splitType'] as String),
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      paidByContactId: json['paidByContactId'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      status: BillStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
      'splitType': splitType.name,
      'participants': participants.map((p) => p.toJson()).toList(),
      'paidByContactId': paidByContactId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'status': status.name,
      'notes': notes,
    };
  }

  SplitBill copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? totalAmount,
    List<SplitBillItem>? items,
    SplitType? splitType,
    List<Participant>? participants,
    String? paidByContactId,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    BillStatus? status,
    String? notes,
  }) {
    return SplitBill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      splitType: splitType ?? this.splitType,
      participants: participants ?? this.participants,
      paidByContactId: paidByContactId ?? this.paidByContactId,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  int get totalPaidCount =>
      participants.where((p) => p.hasPaid).length;

  int get totalParticipants => participants.length;

  double get totalAmountPaid =>
      participants.where((p) => p.hasPaid).fold(0.0, (sum, p) => sum + p.amountPaid);

  double get totalAmountPending =>
      totalAmount - totalAmountPaid;

  bool get isFullySettled => status == BillStatus.fullySettled;

  List<Participant> get pendingParticipants =>
      participants.where((p) => !p.hasPaid).toList();

  List<Participant> get paidParticipants =>
      participants.where((p) => p.hasPaid).toList();

  String getSplitTypeText() {
    switch (splitType) {
      case SplitType.equal:
        return 'Split Equally';
      case SplitType.custom:
        return 'Custom Split';
      case SplitType.percentage:
        return 'Percentage Split';
    }
  }

  String getStatusText() {
    switch (status) {
      case BillStatus.pending:
        return 'Pending';
      case BillStatus.partiallyPaid:
        return 'Partially Paid';
      case BillStatus.fullySettled:
        return 'Settled';
    }
  }

  @override
  String toString() {
    return 'SplitBill(id: $id, title: $title, total: ₹$totalAmount, participants: ${participants.length}, status: ${status.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplitBill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
