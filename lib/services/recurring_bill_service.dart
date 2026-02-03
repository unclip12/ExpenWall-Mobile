import '../models/recurring_rule.dart';
import '../models/recurring_notification.dart';
import '../models/transaction.dart';
import 'local_storage_service.dart';
import 'package:uuid/uuid.dart';

class RecurringBillService {
  final LocalStorageService _localStorage;
  final String userId;

  RecurringBillService({
    required LocalStorageService localStorage,
    required this.userId,
  }) : _localStorage = localStorage;

  // ========== MAIN DAILY CHECK ==========
  
  /// Runs daily (preferably at 5 AM) to check and create due transactions
  Future<List<RecurringNotification>> checkAndCreateDueTransactions() async {
    final rules = await getActiveRules();
    final createdNotifications = <RecurringNotification>[];
    
    for (final rule in rules) {
      if (rule.isDueToday()) {
        // Create transaction automatically
        final transaction = await _createTransactionFromRule(rule);
        
        // Create notification for user to confirm
        final notification = RecurringNotification.create(
          recurringRuleId: rule.id,
          transactionId: transaction.id,
          ruleName: rule.name,
          amount: rule.amount,
          dueDate: rule.nextOccurrence,
        );
        
        // Save notification
        await _saveNotification(notification);
        createdNotifications.add(notification);
        
        // Update rule with next occurrence
        final nextOccurrence = RecurringRule.calculateNextOccurrence(
          rule.nextOccurrence,
          rule.frequencyValue,
          rule.frequencyUnit,
        );
        
        final updatedRule = rule.copyWith(
          nextOccurrence: nextOccurrence,
          lastCreated: DateTime.now(),
        );
        
        await updateRule(updatedRule);
      }
    }
    
    return createdNotifications;
  }

  // ========== 4 ACTIONS HANDLERS ==========
  
  /// Action 1: User confirms payment (Paid ✓)
  Future<void> handlePaidAction(String notificationId) async {
    final notification = await getNotification(notificationId);
    if (notification == null) return;
    
    // Mark notification as approved
    final updatedNotification = notification.copyWith(
      status: NotificationStatus.approved,
      isRead: true,
    );
    
    await _saveNotification(updatedNotification);
    
    // Transaction stays in list - no changes needed
    // Next occurrence already calculated when transaction was created
  }
  
  /// Action 2: User canceled subscription (Canceled ✗)
  Future<void> handleCanceledAction(
    String notificationId,
    {bool shouldDeleteRule = false}
  ) async {
    final notification = await getNotification(notificationId);
    if (notification == null) return;
    
    // Mark notification as canceled
    final updatedNotification = notification.copyWith(
      status: NotificationStatus.canceled,
      isRead: true,
    );
    await _saveNotification(updatedNotification);
    
    // Pause the rule (or delete if requested)
    final rule = await getRule(notification.recurringRuleId);
    if (rule != null) {
      if (shouldDeleteRule) {
        await deleteRule(rule.id);
      } else {
        final pausedRule = rule.copyWith(isActive: false);
        await updateRule(pausedRule);
      }
    }
    
    // Delete the auto-created transaction
    await _deleteTransaction(notification.transactionId);
  }
  
  /// Action 3: User wants to be notified later (Notify Later ⏰)
  Future<void> handleNotifyLaterAction(
    String notificationId,
    DateTime snoozeUntil,
  ) async {
    final notification = await getNotification(notificationId);
    if (notification == null) return;
    
    // Mark notification as snoozed
    final updatedNotification = notification.copyWith(
      status: NotificationStatus.snoozed,
      snoozeUntil: snoozeUntil,
      isRead: false, // Will reappear at snooze time
    );
    
    await _saveNotification(updatedNotification);
    
    // Transaction stays in list marked as pending
    // Will remind user at snoozeUntil time
  }
  
  /// Action 4: User reschedules the payment (Reschedule 📅)
  Future<void> handleRescheduleAction(
    String notificationId,
    DateTime newDate,
    {bool updateOnlyThisOccurrence = true}
  ) async {
    final notification = await getNotification(notificationId);
    if (notification == null) return;
    
    // Mark notification as rescheduled
    final updatedNotification = notification.copyWith(
      status: NotificationStatus.rescheduled,
      rescheduledDate: newDate,
      isRead: true,
    );
    await _saveNotification(updatedNotification);
    
    // Update the rule's next occurrence
    final rule = await getRule(notification.recurringRuleId);
    if (rule != null) {
      final updatedRule = rule.copyWith(
        nextOccurrence: newDate,
      );
      await updateRule(updatedRule);
    }
    
    // Update transaction date
    final transaction = await _getTransaction(notification.transactionId);
    if (transaction != null) {
      final updatedTransaction = Transaction(
        id: transaction.id,
        userId: transaction.userId,
        merchant: transaction.merchant,
        amount: transaction.amount,
        category: transaction.category,
        subcategory: transaction.subcategory,
        type: transaction.type,
        date: newDate,
        notes: transaction.notes,
        items: transaction.items,
        currency: transaction.currency,
      );
      await _updateTransaction(updatedTransaction);
    }
  }

  // ========== DUPLICATE DETECTION ==========
  
  /// Check if a manually added transaction matches any recurring rule
  Future<RecurringRule?> findMatchingRule(String merchantName) async {
    final rules = await getActiveRules();
    
    for (final rule in rules) {
      // Case-insensitive fuzzy match
      if (rule.name.toLowerCase().contains(merchantName.toLowerCase()) ||
          merchantName.toLowerCase().contains(rule.name.toLowerCase())) {
        return rule;
      }
    }
    
    return null;
  }
  
  /// Link a manual transaction to a recurring rule (mark notification as paid)
  Future<void> linkTransactionToRule(
    String transactionId,
    String ruleId,
  ) async {
    // Find pending notification for this rule
    final notifications = await getPendingNotifications();
    final matchingNotification = notifications.where(
      (n) => n.recurringRuleId == ruleId && n.status == NotificationStatus.pending,
    ).firstOrNull;
    
    if (matchingNotification != null) {
      // Delete the auto-created transaction
      await _deleteTransaction(matchingNotification.transactionId);
      
      // Update notification to use the manual transaction
      final updatedNotification = RecurringNotification(
        id: matchingNotification.id,
        recurringRuleId: matchingNotification.recurringRuleId,
        transactionId: transactionId, // Use manual transaction ID
        createdAt: matchingNotification.createdAt,
        isRead: true,
        status: NotificationStatus.approved,
        ruleName: matchingNotification.ruleName,
        amount: matchingNotification.amount,
        dueDate: matchingNotification.dueDate,
      );
      
      await _saveNotification(updatedNotification);
    }
  }

  // ========== CRUD OPERATIONS ==========
  
  /// Get all recurring rules for user
  Future<List<RecurringRule>> getAllRules() async {
    return await _localStorage.loadRecurringRules(userId);
  }
  
  /// Get only active rules
  Future<List<RecurringRule>> getActiveRules() async {
    final rules = await getAllRules();
    return rules.where((r) => r.isActive).toList();
  }
  
  /// Get a specific rule by ID
  Future<RecurringRule?> getRule(String ruleId) async {
    final rules = await getAllRules();
    return rules.where((r) => r.id == ruleId).firstOrNull;
  }
  
  /// Create new recurring rule
  Future<void> createRule(RecurringRule rule) async {
    final rules = await getAllRules();
    rules.add(rule);
    await _localStorage.saveRecurringRules(userId, rules);
  }
  
  /// Update existing rule
  Future<void> updateRule(RecurringRule rule) async {
    final rules = await getAllRules();
    final index = rules.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      rules[index] = rule;
      await _localStorage.saveRecurringRules(userId, rules);
    }
  }
  
  /// Delete a rule
  Future<void> deleteRule(String ruleId) async {
    final rules = await getAllRules();
    rules.removeWhere((r) => r.id == ruleId);
    await _localStorage.saveRecurringRules(userId, rules);
  }
  
  /// Get all notifications
  Future<List<RecurringNotification>> getAllNotifications() async {
    return await _localStorage.loadRecurringNotifications(userId);
  }
  
  /// Get pending notifications (need user action)
  Future<List<RecurringNotification>> getPendingNotifications() async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => n.needsAction()).toList();
  }
  
  /// Get notification count (for badge)
  Future<int> getPendingNotificationCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }
  
  /// Get a specific notification
  Future<RecurringNotification?> getNotification(String notificationId) async {
    final notifications = await getAllNotifications();
    return notifications.where((n) => n.id == notificationId).firstOrNull;
  }

  // ========== PRIVATE HELPERS ==========
  
  Future<Transaction> _createTransactionFromRule(RecurringRule rule) async {
    // Convert rule.category String to Category enum
    final category = Category.values.firstWhere(
      (cat) => cat.label == rule.category,
      orElse: () => Category.other,
    );
    
    final transaction = Transaction(
      id: const Uuid().v4(),
      userId: userId,
      merchant: rule.name,
      amount: rule.amount,
      category: category,
      subcategory: rule.subcategory,
      type: rule.type,
      date: rule.nextOccurrence,
      notes: 'Auto-created from recurring rule: ${rule.name}',
      items: [],
      currency: '₹',
    );
    
    // Save transaction
    final transactions = await _localStorage.loadTransactions(userId);
    transactions.add(transaction);
    await _localStorage.saveTransactions(userId, transactions);
    
    return transaction;
  }
  
  Future<void> _saveNotification(RecurringNotification notification) async {
    final notifications = await getAllNotifications();
    final index = notifications.indexWhere((n) => n.id == notification.id);
    
    if (index != -1) {
      notifications[index] = notification;
    } else {
      notifications.add(notification);
    }
    
    await _localStorage.saveRecurringNotifications(userId, notifications);
  }
  
  Future<void> _deleteTransaction(String transactionId) async {
    final transactions = await _localStorage.loadTransactions(userId);
    transactions.removeWhere((t) => t.id == transactionId);
    await _localStorage.saveTransactions(userId, transactions);
  }
  
  Future<Transaction?> _getTransaction(String transactionId) async {
    final transactions = await _localStorage.loadTransactions(userId);
    return transactions.where((t) => t.id == transactionId).firstOrNull;
  }
  
  Future<void> _updateTransaction(Transaction transaction) async {
    final transactions = await _localStorage.loadTransactions(userId);
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _localStorage.saveTransactions(userId, transactions);
    }
  }
}
