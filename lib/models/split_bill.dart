import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'participant.dart';

enum SplitType {
  equal,
  custom,
  percentage,
}

enum SplitBillStatus {
  pending,
  partiallySettled,
  fullySettled,
}

class SplitBillItem {
  final String name;
  final double amount;
  final int quantity;

  SplitBillItem({
    required this.name,
    required this.amount,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'quantity': quantity,
    };
  }

  factory SplitBillItem.fromJson(Map<String, dynamic> json) {
    return SplitBillItem(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}

class SplitBill {
  final String id;
  final String userId; // Creator of the bill
  final String title;
  final String? description;
  final double totalAmount;
  final List<SplitBillItem>? items;
  final String paidBy; // Contact ID or name of person who paid
  final List<Participant> participants;
  final SplitType splitType;
  final DateTime createdAt;
  final DateTime? settledAt;
  final SplitBillStatus status;
  final String? notes;
  final String? groupId; // If created from a group

  SplitBill({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.totalAmount,
    this.items,
    required this.paidBy,
    required this.participants,
    required this.splitType,
    required this.createdAt,
    this.settledAt,
    required this.status,
    this.notes,
    this.groupId,
  });

  factory SplitBill.create({
    required String userId,
    required String title,
    String? description,
    required double totalAmount,
    List<SplitBillItem>? items,
    required String paidBy,
    required List<Participant> participants,
    required SplitType splitType,
    String? notes,
    String? groupId,
  }) {
    return SplitBill(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      description: description,
      totalAmount: totalAmount,
      items: items,
      paidBy: paidBy,
      participants: participants,
      splitType: splitType,
      createdAt: DateTime.now(),
      status: SplitBillStatus.pending,
      notes: notes,
      groupId: groupId,
    );
  }

  SplitBill copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? totalAmount,
    List<SplitBillItem>? items,
    String? paidBy,
    List<Participant>? participants,
    SplitType? splitType,
    DateTime? createdAt,
    DateTime? settledAt,
    SplitBillStatus? status,
    String? notes,
    String? groupId,
  }) {
    return SplitBill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      paidBy: paidBy ?? this.paidBy,
      participants: participants ?? this.participants,
      splitType: splitType ?? this.splitType,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      groupId: groupId ?? this.groupId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'totalAmount': totalAmount,
      'items': items?.map((i) => i.toJson()).toList(),
      'paidBy': paidBy,
      'participants': participants.map((p) => p.toJson()).toList(),
      'splitType': splitType.name,
      'createdAt': createdAt.toIso8601String(),
      'settledAt': settledAt?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'groupId': groupId,
    };
  }

  factory SplitBill.fromJson(Map<String, dynamic> json) {
    return SplitBill(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List?)?.map((i) => SplitBillItem.fromJson(i)).toList(),
      paidBy: json['paidBy'] as String,
      participants: (json['participants'] as List)
          .map((p) => Participant.fromJson(p))
          .toList(),
      splitType: SplitType.values.byName(json['splitType'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      settledAt: json['settledAt'] != null
          ? DateTime.parse(json['settledAt'] as String)
          : null,
      status: SplitBillStatus.values.byName(json['status'] as String),
      notes: json['notes'] as String?,
      groupId: json['groupId'] as String?,
    );
  }

  // Helper methods
  int get totalParticipants => participants.length;

  int get paidCount => participants.where((p) => p.hasPaid).length;

  int get pendingCount => participants.where((p) => !p.hasPaid).length;

  double get totalPaid {
    return participants.where((p) => p.hasPaid).fold(0.0, (sum, p) => sum + p.shareAmount);
  }

  double get totalPending {
    return participants.where((p) => !p.hasPaid).fold(0.0, (sum, p) => sum + p.shareAmount);
  }

  bool get isFullySettled => status == SplitBillStatus.fullySettled;

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

  Color getStatusColor() {
    switch (status) {
      case SplitBillStatus.pending:
        return Colors.orange;
      case SplitBillStatus.partiallySettled:
        return Colors.blue;
      case SplitBillStatus.fullySettled:
        return Colors.green;
    }
  }

  String getStatusText() {
    switch (status) {
      case SplitBillStatus.pending:
        return 'Pending';
      case SplitBillStatus.partiallySettled:
        return 'Partially Settled';
      case SplitBillStatus.fullySettled:
        return 'Fully Settled';
    }
  }

  @override
  String toString() => 'SplitBill(id: $id, title: $title, total: $totalAmount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplitBill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
