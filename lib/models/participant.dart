enum PaymentStatus {
  pending,
  paid,
  overpaid,
}

class Participant {
  final String contactId; // Reference to Contact
  final String contactName; // Cached for display
  final double amountOwed; // How much they should pay
  final double amountPaid; // How much they actually paid
  final bool hasPaid; // Payment status
  final DateTime? paidAt; // When they paid
  final PaymentStatus paymentStatus;
  final double? overpaidAmount; // If paid extra
  final bool isOverpaymentDebt; // User confirmed as debt vs credit
  final String? notes;

  Participant({
    required this.contactId,
    required this.contactName,
    required this.amountOwed,
    this.amountPaid = 0.0,
    this.hasPaid = false,
    this.paidAt,
    required this.paymentStatus,
    this.overpaidAmount,
    this.isOverpaymentDebt = false,
    this.notes,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      contactId: json['contactId'] as String,
      contactName: json['contactName'] as String,
      amountOwed: (json['amountOwed'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0.0,
      hasPaid: json['hasPaid'] as bool? ?? false,
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      paymentStatus: PaymentStatus.values.byName(json['paymentStatus'] as String),
      overpaidAmount: (json['overpaidAmount'] as num?)?.toDouble(),
      isOverpaymentDebt: json['isOverpaymentDebt'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contactId': contactId,
      'contactName': contactName,
      'amountOwed': amountOwed,
      'amountPaid': amountPaid,
      'hasPaid': hasPaid,
      'paidAt': paidAt?.toIso8601String(),
      'paymentStatus': paymentStatus.name,
      'overpaidAmount': overpaidAmount,
      'isOverpaymentDebt': isOverpaymentDebt,
      'notes': notes,
    };
  }

  Participant copyWith({
    String? contactId,
    String? contactName,
    double? amountOwed,
    double? amountPaid,
    bool? hasPaid,
    DateTime? paidAt,
    PaymentStatus? paymentStatus,
    double? overpaidAmount,
    bool? isOverpaymentDebt,
    String? notes,
  }) {
    return Participant(
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      amountOwed: amountOwed ?? this.amountOwed,
      amountPaid: amountPaid ?? this.amountPaid,
      hasPaid: hasPaid ?? this.hasPaid,
      paidAt: paidAt ?? this.paidAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      overpaidAmount: overpaidAmount ?? this.overpaidAmount,
      isOverpaymentDebt: isOverpaymentDebt ?? this.isOverpaymentDebt,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  double get remainingAmount => amountOwed - amountPaid;

  bool get hasOverpaid => amountPaid > amountOwed;

  double get overpaymentDifference {
    if (hasOverpaid) {
      return amountPaid - amountOwed;
    }
    return 0.0;
  }

  bool get isSmallOverpayment {
    // Consider ₹1-2 as small overpayment
    if (hasOverpaid) {
      return overpaymentDifference <= 2.0;
    }
    return false;
  }

  String getPaymentStatusText() {
    switch (paymentStatus) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.overpaid:
        return 'Overpaid';
    }
  }

  @override
  String toString() {
    return 'Participant($contactName: owed=₹$amountOwed, paid=₹$amountPaid, status=${paymentStatus.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant && other.contactId == contactId;
  }

  @override
  int get hashCode => contactId.hashCode;
}
