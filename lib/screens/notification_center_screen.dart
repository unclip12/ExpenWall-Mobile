import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_notification.dart';
import '../services/recurring_bill_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';

class NotificationCenterScreen extends StatefulWidget {
  final String userId;

  const NotificationCenterScreen({super.key, required this.userId});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late RecurringBillService _recurringService;
  List<RecurringNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringBillService(
      localStorage: LocalStorageService(),
      userId: widget.userId,
    );
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final notifications = await _recurringService.getPendingNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _handlePaid(RecurringNotification notification) async {
    await _recurringService.handlePaidAction(notification.id);
    _showSnackBar('✅ Payment confirmed!', Colors.green);
    _loadNotifications();
  }

  Future<void> _handleCanceled(RecurringNotification notification) async {
    final deleteRule = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Canceled'),
        content: const Text(
          'Do you want to delete this recurring rule completely, '
          'or just pause it for now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Just Pause'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Rule'),
          ),
        ],
      ),
    );

    if (deleteRule != null) {
      await _recurringService.handleCanceledAction(
        notification.id,
        deleteRule: deleteRule,
      );
      _showSnackBar(
        deleteRule ? '🗑️ Rule deleted' : '⏸️ Subscription paused',
        Colors.orange,
      );
      _loadNotifications();
    }
  }

  Future<void> _handleNotifyLater(RecurringNotification notification) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NotifyLaterDialog(),
    );

    if (result != null) {
      final snoozeDate = result['date'] as DateTime;
      final snoozeTime = result['time'] as TimeOfDay;
      
      final snoozeUntil = DateTime(
        snoozeDate.year,
        snoozeDate.month,
        snoozeDate.day,
        snoozeTime.hour,
        snoozeTime.minute,
      );

      await _recurringService.handleNotifyLaterAction(
        notification.id,
        snoozeUntil,
      );
      
      _showSnackBar('⏰ Will remind you on ${DateFormat('MMM d, h:mm a').format(snoozeUntil)}', Colors.blue);
      _loadNotifications();
    }
  }

  Future<void> _handleReschedule(RecurringNotification notification) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: notification.dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null) {
      await _recurringService.handleRescheduleAction(
        notification.id,
        newDate,
      );
      
      _showSnackBar('📅 Rescheduled to ${DateFormat('MMM d, y').format(newDate)}', Colors.purple);
      _loadNotifications();
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                // Mark all as read
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(_notifications[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(RecurringNotification notification) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.ruleName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${notification.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Due date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Due: ${DateFormat('MMM d, y').format(notification.dueDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Question
          const Text(
            'Did you make this payment?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          // 4 Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handlePaid(notification),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Paid'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleCanceled(notification),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Canceled'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleNotifyLater(notification),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: const Text('Notify Later'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleReschedule(notification),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Notify Later Dialog
class _NotifyLaterDialog extends StatefulWidget {
  @override
  State<_NotifyLaterDialog> createState() => _NotifyLaterDialogState();
}

class _NotifyLaterDialogState extends State<_NotifyLaterDialog> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notify Me Later'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Date'),
            subtitle: Text(DateFormat('MMM d, y').format(_selectedDate)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Time'),
            subtitle: Text(_selectedTime.format(context)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'date': _selectedDate,
              'time': _selectedTime,
            });
          },
          child: const Text('Set Reminder'),
        ),
      ],
    );
  }
}
