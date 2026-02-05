import 'dart:math' as math;
import '../models/split_bill.dart';
import '../models/participant.dart';
import '../models/contact.dart';
import 'local_storage_service.dart';
import 'contact_service.dart';

class SplitBillService {
  final LocalStorageService _localStorage;
  final ContactService _contactService;
  final String userId;

  SplitBillService({
    required LocalStorageService localStorage,
    required ContactService contactService,
    required this.userId,
  })  : _localStorage = localStorage,
        _contactService = contactService;

  // ============ CRUD OPERATIONS ============

  /// Get all split bills
  Future<List<SplitBill>> getAllBills() async {
    return await _localStorage.loadSplitBills(userId);
  }

  /// Get bill by ID
  Future<SplitBill?> getBillById(String billId) async {
    final bills = await getAllBills();
    try {
      return bills.firstWhere((b) => b.id == billId);
    } catch (e) {
      return null;
    }
  }

  /// Create new split bill
  Future<SplitBill> createBill({
    required String title,
    String? description,
    required double totalAmount,
    required List<SplitBillItem> items,
    required SplitType splitType,
    required List<String> participantContactIds,
    required String paidByContactId,
    Map<String, double>? customAmounts, // For custom split
    Map<String, double>? percentages, // For percentage split
    String? notes,
  }) async {
    // Get participant names
    final contacts = await _contactService.getContactsByIds(participantContactIds);
    final contactMap = {for (var c in contacts) c.id: c};

    // Calculate split amounts
    List<Participant> participants;
    switch (splitType) {
      case SplitType.equal:
        participants = _calculateEqualSplit(
          participantContactIds,
          contactMap,
          totalAmount,
        );
        break;
      case SplitType.custom:
        if (customAmounts == null) {
          throw Exception('Custom amounts required for custom split');
        }
        participants = _calculateCustomSplit(
          participantContactIds,
          contactMap,
          customAmounts,
        );
        break;
      case SplitType.percentage:
        if (percentages == null) {
          throw Exception('Percentages required for percentage split');
        }
        participants = _calculatePercentageSplit(
          participantContactIds,
          contactMap,
          totalAmount,
          percentages,
        );
        break;
    }

    final bill = SplitBill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      title: title.trim(),
      description: description?.trim(),
      totalAmount: totalAmount,
      items: items,
      splitType: splitType,
      participants: participants,
      paidByContactId: paidByContactId,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      status: BillStatus.pending,
      notes: notes?.trim(),
    );

    final bills = await getAllBills();
    bills.add(bill);
    await _localStorage.saveSplitBills(userId, bills);

    return bill;
  }

  /// Update existing bill
  Future<SplitBill> updateBill(SplitBill bill) async {
    final bills = await getAllBills();
    final index = bills.indexWhere((b) => b.id == bill.id);

    if (index == -1) {
      throw Exception('Bill not found');
    }

    // Update status based on participants
    final updatedBill = _updateBillStatus(bill);

    bills[index] = updatedBill.copyWith(updatedAt: DateTime.now());
    await _localStorage.saveSplitBills(userId, bills);

    return bills[index];
  }

  /// Delete bill
  Future<void> deleteBill(String billId) async {
    final bills = await getAllBills();
    bills.removeWhere((b) => b.id == billId);
    await _localStorage.saveSplitBills(userId, bills);
  }

  // ============ SPLIT CALCULATIONS ============

  List<Participant> _calculateEqualSplit(
    List<String> participantIds,
    Map<String, Contact> contactMap,
    double totalAmount,
  ) {
    final amountPerPerson = totalAmount / participantIds.length;

    return participantIds.map((contactId) {
      final contact = contactMap[contactId];
      if (contact == null) {
        throw Exception('Contact not found: $contactId');
      }

      return Participant(
        contactId: contactId,
        contactName: contact.name,
        amountOwed: double.parse(amountPerPerson.toStringAsFixed(2)),
        paymentStatus: PaymentStatus.pending,
      );
    }).toList();
  }

  List<Participant> _calculateCustomSplit(
    List<String> participantIds,
    Map<String, Contact> contactMap,
    Map<String, double> customAmounts,
  ) {
    return participantIds.map((contactId) {
      final contact = contactMap[contactId];
      if (contact == null) {
        throw Exception('Contact not found: $contactId');
      }

      final amount = customAmounts[contactId];
      if (amount == null) {
        throw Exception('Amount not specified for $contactId');
      }

      return Participant(
        contactId: contactId,
        contactName: contact.name,
        amountOwed: amount,
        paymentStatus: PaymentStatus.pending,
      );
    }).toList();
  }

  List<Participant> _calculatePercentageSplit(
    List<String> participantIds,
    Map<String, Contact> contactMap,
    double totalAmount,
    Map<String, double> percentages,
  ) {
    // Validate percentages add up to 100
    final totalPercentage = percentages.values.fold(0.0, (a, b) => a + b);
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw Exception('Percentages must add up to 100%');
    }

    return participantIds.map((contactId) {
      final contact = contactMap[contactId];
      if (contact == null) {
        throw Exception('Contact not found: $contactId');
      }

      final percentage = percentages[contactId];
      if (percentage == null) {
        throw Exception('Percentage not specified for $contactId');
      }

      final amount = (totalAmount * percentage) / 100.0;

      return Participant(
        contactId: contactId,
        contactName: contact.name,
        amountOwed: double.parse(amount.toStringAsFixed(2)),
        paymentStatus: PaymentStatus.pending,
      );
    }).toList();
  }

  // ============ PAYMENT & SETTLEMENT ============

  /// Mark participant as paid
  Future<SplitBill> markAsPaid(
    String billId,
    String contactId,
    double amountPaid,
  ) async {
    final bill = await getBillById(billId);
    if (bill == null) {
      throw Exception('Bill not found');
    }

    final participantIndex =
        bill.participants.indexWhere((p) => p.contactId == contactId);
    if (participantIndex == -1) {
      throw Exception('Participant not found');
    }

    final participant = bill.participants[participantIndex];
    final difference = amountPaid - participant.amountOwed;

    // Determine payment status
    PaymentStatus status;
    double? overpaidAmount;
    bool isOverpaymentDebt = false;

    if (difference.abs() <= 0.01) {
      // Exact payment
      status = PaymentStatus.paid;
    } else if (difference > 0) {
      // Overpaid
      status = PaymentStatus.overpaid;
      overpaidAmount = difference;

      // If small overpayment (₹1-2), auto-ignore
      if (difference <= 2.0) {
        // Small overpayment - treat as exact
        status = PaymentStatus.paid;
        overpaidAmount = null;
      }
    } else {
      // Underpaid - not allowed
      throw Exception('Amount paid is less than owed');
    }

    final updatedParticipant = participant.copyWith(
      amountPaid: amountPaid,
      hasPaid: true,
      paidAt: DateTime.now(),
      paymentStatus: status,
      overpaidAmount: overpaidAmount,
      isOverpaymentDebt: isOverpaymentDebt,
    );

    final updatedParticipants = List<Participant>.from(bill.participants);
    updatedParticipants[participantIndex] = updatedParticipant;

    final updatedBill = bill.copyWith(participants: updatedParticipants);

    return await updateBill(updatedBill);
  }

  /// Handle overpayment - user decides if it's debt or credit
  Future<SplitBill> handleOverpayment(
    String billId,
    String contactId,
    bool isDebt, // true = you owe them back, false = credit for next time
  ) async {
    final bill = await getBillById(billId);
    if (bill == null) {
      throw Exception('Bill not found');
    }

    final participantIndex =
        bill.participants.indexWhere((p) => p.contactId == contactId);
    if (participantIndex == -1) {
      throw Exception('Participant not found');
    }

    final participant = bill.participants[participantIndex];
    if (participant.paymentStatus != PaymentStatus.overpaid) {
      throw Exception('Participant has not overpaid');
    }

    final updatedParticipant = participant.copyWith(
      isOverpaymentDebt: isDebt,
    );

    final updatedParticipants = List<Participant>.from(bill.participants);
    updatedParticipants[participantIndex] = updatedParticipant;

    final updatedBill = bill.copyWith(participants: updatedParticipants);

    return await updateBill(updatedBill);
  }

  /// Update bill status based on participant payments
  SplitBill _updateBillStatus(SplitBill bill) {
    final allPaid = bill.participants.every((p) => p.hasPaid);
    final somePaid = bill.participants.any((p) => p.hasPaid);

    BillStatus status;
    if (allPaid) {
      status = BillStatus.fullySettled;
    } else if (somePaid) {
      status = BillStatus.partiallyPaid;
    } else {
      status = BillStatus.pending;
    }

    return bill.copyWith(status: status);
  }

  // ============ BALANCE TRACKING ============

  /// Get total balance across all bills for a contact
  /// Returns positive if they owe you, negative if you owe them
  Future<double> getContactBalance(String contactId) async {
    final bills = await getAllBills();
    double balance = 0.0;

    for (var bill in bills) {
      final participant = bill.participants
          .where((p) => p.contactId == contactId)
          .firstOrNull;

      if (participant != null) {
        // They owe you (positive)
        if (!participant.hasPaid) {
          balance += participant.amountOwed;
        }

        // You owe them (negative) - if overpaid and marked as debt
        if (participant.hasOverpaid &&
            participant.isOverpaymentDebt) {
          balance -= participant.overpaymentDifference;
        }
      }

      // Check if you paid this bill and they owe you
      if (bill.paidByContactId == contactId) {
        for (var p in bill.participants) {
          if (p.contactId != contactId && !p.hasPaid) {
            balance -= p.amountOwed; // You paid, they owe you (negative in their balance)
          }
        }
      }
    }

    return balance;
  }

  /// Get summary of who owes who
  Future<Map<String, double>> getBalanceSummary() async {
    final bills = await getAllBills();
    final balances = <String, double>{};

    // Get all unique contact IDs
    final contactIds = <String>{};
    for (var bill in bills) {
      contactIds.add(bill.paidByContactId);
      contactIds.addAll(bill.participants.map((p) => p.contactId));
    }

    // Calculate balance for each contact
    for (var contactId in contactIds) {
      final balance = await getContactBalance(contactId);
      if (balance.abs() > 0.01) {
        // Only include non-zero balances
        balances[contactId] = balance;
      }
    }

    return balances;
  }

  /// Get pending bills for a contact
  Future<List<SplitBill>> getPendingBillsForContact(String contactId) async {
    final bills = await getAllBills();

    return bills.where((bill) {
      final participant = bill.participants
          .where((p) => p.contactId == contactId)
          .firstOrNull;

      return participant != null && !participant.hasPaid;
    }).toList();
  }

  // ============ WHATSAPP SHARE ============

  /// Format bill for WhatsApp sharing
  String formatForWhatsApp(SplitBill bill) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('📄 *Split Bill Summary*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('*${bill.title}*');
    if (bill.description != null && bill.description!.isNotEmpty) {
      buffer.writeln(bill.description);
    }
    buffer.writeln('Date: ${_formatDate(bill.date)}');
    buffer.writeln();

    // Total
    buffer.writeln('💰 *Total: ₹${bill.totalAmount.toStringAsFixed(2)}*');
    buffer.writeln('Split: ${bill.getSplitTypeText()}');
    buffer.writeln();

    // Items (if any)
    if (bill.items.isNotEmpty) {
      buffer.writeln('📝 *Items:*');
      for (var item in bill.items) {
        final itemTotal = item.total;
        if (item.quantity > 1) {
          buffer.writeln(
              '  • ${item.name}: ₹${item.price.toStringAsFixed(2)} × ${item.quantity} = ₹${itemTotal.toStringAsFixed(2)}');
        } else {
          buffer.writeln('  • ${item.name}: ₹${itemTotal.toStringAsFixed(2)}');
        }
      }
      buffer.writeln();
    }

    // Participants
    buffer.writeln('👥 *Participants (${bill.participants.length}):*');
    for (var participant in bill.participants) {
      final status = participant.hasPaid ? '✅' : '⏳';
      buffer.writeln(
          '  $status ${participant.contactName}: ₹${participant.amountOwed.toStringAsFixed(2)}');
    }
    buffer.writeln();

    // Who paid
    final payer = bill.participants
        .where((p) => p.contactId == bill.paidByContactId)
        .firstOrNull;
    if (payer != null) {
      buffer.writeln('💳 *Paid by:* ${payer.contactName}');
    }
    buffer.writeln();

    // Pending info
    final pendingCount = bill.pendingParticipants.length;
    if (pendingCount > 0) {
      buffer.writeln('⚠️ *Pending Payments:* $pendingCount');
      for (var participant in bill.pendingParticipants) {
        buffer.writeln(
            '  • ${participant.contactName}: ₹${participant.amountOwed.toStringAsFixed(2)}');
      }
    } else {
      buffer.writeln('✅ *Status:* All Settled!');
    }

    // Notes
    if (bill.notes != null && bill.notes!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('📌 *Notes:* ${bill.notes}');
    }

    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('_Generated by ExpenWall_');

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  // ============ STATISTICS ============

  /// Get total amount in pending bills
  Future<double> getTotalPendingAmount() async {
    final bills = await getAllBills();
    double total = 0.0;
    for (var bill in bills) {
      if (bill.status != BillStatus.fullySettled) {
        total += bill.totalAmountPending;
      }
    }
    return total;
  }

  /// Get count of pending bills
  Future<int> getPendingBillsCount() async {
    final bills = await getAllBills();
    return bills.where((b) => b.status != BillStatus.fullySettled).length;
  }

  /// Get bills by status
  Future<List<SplitBill>> getBillsByStatus(BillStatus status) async {
    final bills = await getAllBills();
    return bills.where((b) => b.status == status).toList();
  }
}
