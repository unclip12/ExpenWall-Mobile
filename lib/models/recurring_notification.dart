import 'package:uuid/uuid.dart';

enum NotificationStatus {
  pending,      // Awaiting user action
  approved,     // User confirmed payment (Paid)
  canceled,     // User canceled subscription
  snoozed,      // User said "notify later"
  rescheduled,  // User rescheduled the payment
}

class RecurringNotification {
  final String id;
  final String recurringRuleId;
  final String transactionId; // Auto-created transaction
  final DateTime createdAt;
  final bool isRead;
  final NotificationStatus status;
  
  // For "Notify Later" action
  final DateTime? snoozeUntil;
  
  // For "Reschedule" action
  final DateTime? rescheduledDate;
  
  // Rule details (cached for display)
  final String ruleName;
  final double amount;
  final DateTime dueDate;

  RecurringNotification({
    required this.id,
    required this.recurringRuleId,
    required this.transactionId,
    required this.createdAt,
    this.isRead = false,
    this.status = NotificationStatus.pending,
    this.snoozeUntil,
    this.rescheduledDate,
    required this.ruleName,
    required this.amount,
    required this.dueDate,
  });

  // Factory constructor with auto ID generation
  factory RecurringNotification.create({
    required String recurringRuleId,
    required String transactionId,
    required String ruleName,
    required double amount,
    required DateTime dueDate,
  }) {
    return RecurringNotification(
      id: const Uuid().v4(),
      recurringRuleId: recurringRuleId,
      transactionId: transactionId,
      createdAt: DateTime.now(),
      ruleName: ruleName,
      amount: amount,
      dueDate: dueDate,
    );
  }

  // Copy with method for updates
  RecurringNotification copyWith({
    bool? isRead,
    NotificationStatus? status,
    DateTime? snoozeUntil,
    DateTime? rescheduledDate,
  }) {
    return RecurringNotification(
      id: id,
      recurringRuleId: recurringRuleId,
      transactionId: transactionId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      rescheduledDate: rescheduledDate ?? this.rescheduledDate,
      ruleName: ruleName,
      amount: amount,
      dueDate: dueDate,
    );
  }

  // Get status display text
  String getStatusText() {
    switch (status) {
      case NotificationStatus.pending:
        return 'Awaiting confirmation';
      case NotificationStatus.approved:
        return 'Payment confirmed';
      case NotificationStatus.canceled:
        return 'Subscription canceled';
      case NotificationStatus.snoozed:
        return 'Notify later';
      case NotificationStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  // Check if notification needs action
  bool needsAction() {
    return status == NotificationStatus.pending;
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'recurringRuleId': recurringRuleId,
    'transactionId': transactionId,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'status': status.toString().split('.').last,
    'snoozeUntil': snoozeUntil?.toIso8601String(),
    'rescheduledDate': rescheduledDate?.toIso8601String(),
    'ruleName': ruleName,
    'amount': amount,
    'dueDate': dueDate.toIso8601String(),
  };

  factory RecurringNotification.fromJson(Map<String, dynamic> json) =>
      RecurringNotification(
        id: json['id'],
        recurringRuleId: json['recurringRuleId'],
        transactionId: json['transactionId'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        status: NotificationStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status'],
        ),
        snoozeUntil: json['snoozeUntil'] != null
            ? DateTime.parse(json['snoozeUntil'])
            : null,
        rescheduledDate: json['rescheduledDate'] != null
            ? DateTime.parse(json['rescheduledDate'])
            : null,
        ruleName: json['ruleName'],
        amount: (json['amount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate']),
      );
}
