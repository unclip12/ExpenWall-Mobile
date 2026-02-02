import '../models/split_bill.dart';
import '../models/participant.dart';
import '../models/contact.dart';
import 'local_storage_service.dart';

class SplitBillService {
  final LocalStorageService localStorage;
  final String userId;

  SplitBillService({
    required this.localStorage,
    required this.userId,
  });

  // CRUD Operations
  Future<List<SplitBill>> getAllBills() async {
    return await localStorage.loadSplitBills(userId);
  }

  Future<void> saveBill(SplitBill bill) async {
    final bills = await getAllBills();
    bills.add(bill);
    await localStorage.saveSplitBills(userId, bills);
  }

  Future<void> updateBill(SplitBill bill) async {
    final bills = await getAllBills();
    final index = bills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      bills[index] = bill;
      await localStorage.saveSplitBills(userId, bills);
    }
  }

  Future<void> deleteBill(String billId) async {
    final bills = await getAllBills();
    bills.removeWhere((b) => b.id == billId);
    await localStorage.saveSplitBills(userId, bills);
  }

  // Split Calculations
  List<Participant> calculateEqualSplit({
    required double totalAmount,
    required List<Contact> contacts,
    List<String>? excludedContactIds,
  }) {
    final activeContacts = contacts.where(
      (c) => excludedContactIds == null || !excludedContactIds.contains(c.id)
    ).toList();

    if (activeContacts.isEmpty) return [];

    final shareAmount = totalAmount / activeContacts.length;

    return activeContacts.map((contact) {
      return Participant.create(
        name: contact.name,
        contactId: contact.id,
        shareAmount: double.parse(shareAmount.toStringAsFixed(2)),
      );
    }).toList();
  }

  List<Participant> calculatePercentageSplit({
    required double totalAmount,
    required Map<Contact, double> contactPercentages, // Contact -> percentage
  }) {
    return contactPercentages.entries.map((entry) {
      final contact = entry.key;
      final percentage = entry.value;
      final shareAmount = (totalAmount * percentage) / 100;

      return Participant.create(
        name: contact.name,
        contactId: contact.id,
        shareAmount: double.parse(shareAmount.toStringAsFixed(2)),
        sharePercentage: percentage,
      );
    }).toList();
  }

  // Payment Tracking
  Future<void> markParticipantAsPaid({
    required String billId,
    required String participantId,
    double? amountPaid,
  }) async {
    final bills = await getAllBills();
    final billIndex = bills.indexWhere((b) => b.id == billId);
    
    if (billIndex == -1) return;

    final bill = bills[billIndex];
    final participants = bill.participants;
    final pIndex = participants.indexWhere((p) => p.id == participantId);
    
    if (pIndex == -1) return;

    participants[pIndex] = participants[pIndex].markAsPaid(amountPaid: amountPaid);

    // Update bill status
    final updatedBill = bill.copyWith(
      participants: participants,
      status: _calculateBillStatus(participants),
      settledAt: _calculateBillStatus(participants) == SplitBillStatus.fullySettled
          ? DateTime.now()
          : null,
    );

    await updateBill(updatedBill);
  }

  Future<void> markParticipantAsUnpaid({
    required String billId,
    required String participantId,
  }) async {
    final bills = await getAllBills();
    final billIndex = bills.indexWhere((b) => b.id == billId);
    
    if (billIndex == -1) return;

    final bill = bills[billIndex];
    final participants = bill.participants;
    final pIndex = participants.indexWhere((p) => p.id == participantId);
    
    if (pIndex == -1) return;

    participants[pIndex] = participants[pIndex].markAsUnpaid();

    final updatedBill = bill.copyWith(
      participants: participants,
      status: _calculateBillStatus(participants),
      settledAt: null,
    );

    await updateBill(updatedBill);
  }

  SplitBillStatus _calculateBillStatus(List<Participant> participants) {
    final paidCount = participants.where((p) => p.hasPaid).length;
    
    if (paidCount == 0) return SplitBillStatus.pending;
    if (paidCount == participants.length) return SplitBillStatus.fullySettled;
    return SplitBillStatus.partiallySettled;
  }

  // Filtering
  Future<List<SplitBill>> getPendingBills() async {
    final bills = await getAllBills();
    return bills.where((b) => b.status != SplitBillStatus.fullySettled).toList();
  }

  Future<List<SplitBill>> getSettledBills() async {
    final bills = await getAllBills();
    return bills.where((b) => b.status == SplitBillStatus.fullySettled).toList();
  }

  // Cross-bill balance tracking
  Future<Map<String, double>> getBalancesWithContact(String contactId) async {
    final bills = await getAllBills();
    double youOwe = 0.0; // How much current user owes to this contact
    double theyOwe = 0.0; // How much this contact owes to current user

    for (final bill in bills) {
      // If current user paid and contact hasn't
      if (bill.paidBy == userId || bill.paidBy == 'You') {
        final participant = bill.participants.firstWhere(
          (p) => p.contactId == contactId,
          orElse: () => Participant.create(name: '', shareAmount: 0),
        );
        if (!participant.hasPaid && participant.shareAmount > 0) {
          theyOwe += participant.shareAmount;
        }
      }
      // If contact paid and current user hasn't
      else if (bill.paidBy == contactId) {
        final participant = bill.participants.firstWhere(
          (p) => p.contactId == userId || p.name == 'You',
          orElse: () => Participant.create(name: '', shareAmount: 0),
        );
        if (!participant.hasPaid && participant.shareAmount > 0) {
          youOwe += participant.shareAmount;
        }
      }
    }

    return {
      'youOwe': youOwe,
      'theyOwe': theyOwe,
      'net': theyOwe - youOwe, // Positive = they owe you, Negative = you owe them
    };
  }

  // Get all balances
  Future<Map<String, Map<String, double>>> getAllBalances() async {
    final bills = await getAllBills();
    final contacts = await localStorage.loadContacts(userId);
    final balances = <String, Map<String, double>>{};

    for (final contact in contacts) {
      final balance = await getBalancesWithContact(contact.id);
      if (balance['net']!.abs() > 0.01) { // Only include if non-zero
        balances[contact.id] = {
          'name': contact.name as double, // This is wrong, needs fix
          ...balance,
        };
      }
    }

    return balances;
  }

  // Summary stats
  Future<Map<String, dynamic>> getSummary() async {
    final bills = await getAllBills();
    
    int totalBills = bills.length;
    int pendingBills = bills.where((b) => b.status == SplitBillStatus.pending).length;
    int partialBills = bills.where((b) => b.status == SplitBillStatus.partiallySettled).length;
    int settledBills = bills.where((b) => b.status == SplitBillStatus.fullySettled).length;
    
    double totalAmount = bills.fold(0.0, (sum, b) => sum + b.totalAmount);
    double pendingAmount = 0.0;
    double settledAmount = 0.0;

    for (final bill in bills) {
      if (bill.status == SplitBillStatus.fullySettled) {
        settledAmount += bill.totalAmount;
      } else {
        pendingAmount += bill.totalPending;
      }
    }

    return {
      'totalBills': totalBills,
      'pendingBills': pendingBills,
      'partialBills': partialBills,
      'settledBills': settledBills,
      'totalAmount': totalAmount,
      'pendingAmount': pendingAmount,
      'settledAmount': settledAmount,
    };
  }

  // Overpayment handling
  Future<bool> handleOverpayment({
    required String billId,
    required String participantId,
    required double overpaidAmount,
    required bool addToCredit,
  }) async {
    // If addToCredit is true, store the overpayment for future use
    // If false, just acknowledge and move on
    
    // For now, we'll just update the participant's notes
    final bills = await getAllBills();
    final billIndex = bills.indexWhere((b) => b.id == billId);
    
    if (billIndex == -1) return false;

    final bill = bills[billIndex];
    final participants = bill.participants;
    final pIndex = participants.indexWhere((p) => p.id == participantId);
    
    if (pIndex == -1) return false;

    final participant = participants[pIndex];
    final newNotes = addToCredit
        ? '${participant.notes ?? ''}\nCredit: ₹${overpaidAmount.toStringAsFixed(2)}'
        : participant.notes;

    participants[pIndex] = participant.copyWith(notes: newNotes);

    await updateBill(bill.copyWith(participants: participants));
    return true;
  }
}
