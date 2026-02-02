import 'package:uuid/uuid.dart';

class Participant {
  final String id;
  final String name;
  final String? contactId; // Reference to Contact if linked
  final double shareAmount;
  final double? sharePercentage; // For percentage-based splits
  final bool hasPaid;
  final DateTime? paidAt;
  final double amountPaid; // Actual amount paid (can be different if overpaid)
  final String? notes;

  Participant({
    required this.id,
    required this.name,
    this.contactId,
    required this.shareAmount,
    this.sharePercentage,
    this.hasPaid = false,
    this.paidAt,
    double? amountPaid,
    this.notes,
  }) : amountPaid = amountPaid ?? 0.0;

  factory Participant.create({
    required String name,
    String? contactId,
    required double shareAmount,
    double? sharePercentage,
    String? notes,
  }) {
    return Participant(
      id: const Uuid().v4(),
      name: name,
      contactId: contactId,
      shareAmount: shareAmount,
      sharePercentage: sharePercentage,
      notes: notes,
    );
  }

  Participant copyWith({
    String? id,
    String? name,
    String? contactId,
    double? shareAmount,
    double? sharePercentage,
    bool? hasPaid,
    DateTime? paidAt,
    double? amountPaid,
    String? notes,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      contactId: contactId ?? this.contactId,
      shareAmount: shareAmount ?? this.shareAmount,
      sharePercentage: sharePercentage ?? this.sharePercentage,
      hasPaid: hasPaid ?? this.hasPaid,
      paidAt: paidAt ?? this.paidAt,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
    );
  }

  Participant markAsPaid({double? amountPaid}) {
    return copyWith(
      hasPaid: true,
      paidAt: DateTime.now(),
      amountPaid: amountPaid ?? shareAmount,
    );
  }

  Participant markAsUnpaid() {
    return copyWith(
      hasPaid: false,
      paidAt: null,
      amountPaid: 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contactId': contactId,
      'shareAmount': shareAmount,
      'sharePercentage': sharePercentage,
      'hasPaid': hasPaid,
      'paidAt': paidAt?.toIso8601String(),
      'amountPaid': amountPaid,
      'notes': notes,
    };
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      name: json['name'] as String,
      contactId: json['contactId'] as String?,
      shareAmount: (json['shareAmount'] as num).toDouble(),
      sharePercentage: json['sharePercentage'] != null
          ? (json['sharePercentage'] as num).toDouble()
          : null,
      hasPaid: json['hasPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );
  }

  // Helper properties
  bool get hasOverpaid => amountPaid > shareAmount;

  bool get hasUnderpaid => amountPaid > 0 && amountPaid < shareAmount;

  double get overpaidAmount => hasOverpaid ? amountPaid - shareAmount : 0.0;

  double get underpaidAmount => hasUnderpaid ? shareAmount - amountPaid : 0.0;

  double get remainingAmount => hasPaid ? 0.0 : shareAmount;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  String toString() => 'Participant(name: $name, share: ₹$shareAmount, paid: $hasPaid)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
