# 🔁 Recurring Bills - Complete Implementation Guide

**Version:** v2.3.0  
**Status:** ✅ **FULLY IMPLEMENTED**  
**Date:** February 2, 2026

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [User Journey](#user-journey)
4. [Technical Architecture](#technical-architecture)
5. [File Structure](#file-structure)
6. [How It Works](#how-it-works)
7. [Testing Guide](#testing-guide)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

Recurring Bills automatically creates transactions for your subscriptions, bills, and recurring income (salary). The system creates transactions on schedule and asks for your confirmation through an interactive notification system.

### Key Benefits:
- 🤖 **Automatic Transaction Creation** - Never forget to log a recurring payment
- 🔔 **Smart Notifications** - Get notified when bills are due
- 🔄 **Flexible Actions** - Paid, Canceled, Notify Later, or Reschedule
- 🔍 **Duplicate Detection** - Prevents double-entry of same payment
- 📅 **Flexible Frequency** - Every X days/weeks/months/years

---

## ✨ Features

### 1. Create Recurring Rules

**Fields:**
- Name (e.g., "Netflix Subscription")
- Amount (₹199)
- Type (Expense or Income)
- Category & Subcategory
- Frequency: Every [number] [days/weeks/months/years]
- Start Date
- Next Due Date (auto-calculated, can override)
- Notification Time (default: 5 AM)
- Notes (optional)

**Examples:**
- Netflix: Every 1 month
- Rent: Every 1 month
- Salary: Every 1 month (Income type)
- Gym: Every 3 months  
- Insurance: Every 1 year
- Medication: Every 25 days

### 2. Auto-Transaction Creation

**How It Works:**
1. Daily at 5 AM (or custom time), app checks all recurring rules
2. If `nextOccurrence` is today, creates transaction automatically
3. Transaction appears in Expenses list immediately
4. Creates a notification asking for confirmation
5. Calculates and updates next occurrence date

**Transaction Details:**
- Uses rule's merchant name, amount, category
- Date set to next occurrence date
- Marked with note: "Auto-created from recurring rule: [name]"

### 3. Notification System with 4 Actions

**Bell Icon:**
- Located: Top-right of HomeScreen
- Shows badge with count of pending notifications
- Tap to open Notification Center
- Updates every 30 seconds automatically

**Notification Center:**
Shows all pending recurring bill confirmations.

**4 Actions:**

#### ✅ **1. Paid**
- Confirms you made the payment
- Transaction stays in list
- Notification marked as approved
- Next occurrence already scheduled

#### ❌ **2. Canceled**  
- You canceled the subscription/bill
- Shows dialog: "Delete rule or just pause?"
  - **Delete Rule:** Removes recurring rule completely
  - **Just Pause:** Marks rule as inactive (can reactivate later)
- Deletes the auto-created transaction

#### ⏰ **3. Notify Later**
- You'll pay later, remind me again
- Opens date + time picker
- Choose when to be reminded (e.g., in 5 days)
- Transaction stays, notification snoozed
- Will reappear at chosen time

#### 📅 **4. Reschedule**
- Change the payment date
- Opens date picker
- Updates next occurrence date
- Updates transaction date
- Rule continues with new schedule

**Use Cases:**
- **Paid:** "Yes, I paid my Netflix bill"
- **Canceled:** "I canceled my Spotify subscription"
- **Notify Later:** "I'll pay my electricity bill on 5th, remind me then"
- **Reschedule:** "My subscription moved from 2nd to 10th of each month"

### 4. Duplicate Detection

**Smart Linking:**
When you manually add a transaction, the app checks if the merchant name matches any recurring rule.

**Flow:**
1. You type "Netflix" in Add Transaction
2. App detects: "You have a recurring bill for Netflix Subscription (₹199)"
3. Shows banner with recurring rule icon
4. On save, asks: "Is this the same payment?"
   - **Yes:** Links to existing recurring rule
     - Deletes auto-created transaction
     - Uses your manual transaction instead
     - Marks notification as approved
   - **No:** Creates separate transaction (different payment)

**Prevents:**
- Accidentally adding duplicate entries
- Double-counting recurring payments
- Data inconsistency

### 5. Recurring Bills List

**Summary Card:**
- Active bills count
- Monthly total (calculated from all frequencies)
- Paused bills count

**Active Bills Section:**
- Shows all active recurring rules
- Each card displays:
  - Rule name
  - Amount
  - Frequency text ("Monthly", "Every 25 days", etc.)
  - Next due date
  - Toggle switch (active/paused)
- Swipe left to edit
- Tap to open edit screen

**Paused Bills Section:**
- Shows inactive rules
- Can reactivate by toggling switch
- Can delete or edit

### 6. Flexible Frequency

**Input Style:**
```
Every [___] [days/weeks/months/years ▼]
      ↑       ↑
    Number   Dropdown
```

**Examples:**
- Every **1** month → "Monthly"
- Every **2** weeks → "Every 2 weeks"
- Every **3** months → "Every 3 months"  
- Every **25** days → "Every 25 days"
- Every **1** year → "Yearly"

**Supports:**
- Days: 1-365
- Weeks: 1-52
- Months: 1-12
- Years: 1-10

---

## 👤 User Journey

### Journey 1: Create First Recurring Rule

1. **Navigate:** Home → Planning → Recurring Bills
2. **Empty State:** Shows "How it works" guide
3. **Tap:** "Create Your First Rule" button
4. **Fill Form:**
   - Name: "Netflix Subscription"
   - Amount: ₹199
   - Type: Expense
   - Frequency: Every 1 month
   - Start Date: Feb 2, 2026
   - Auto-shows: Next payment: March 2, 2026
5. **Save:** Rule created!
6. **See:** Active bill in list

### Journey 2: Receive & Confirm Notification

1. **Next Day (Feb 3):** Bell icon shows badge "1"
2. **Tap Bell:** Opens Notification Center
3. **See Notification:**
   ```
   Netflix Subscription - ₹199
   Due: Feb 3, 2026
   Did you make this payment?
   [Paid] [Canceled] [Notify Later] [Reschedule]
   ```
4. **Action:** Tap "Paid"
5. **Result:**
   - Notification disappears
   - Badge count updates
   - Transaction confirmed in list

### Journey 3: Manually Add Duplicate Payment

1. **Go to:** Add Transaction
2. **Type:** "Netflix"
3. **See Banner:** 🔁 "Matches recurring bill: Netflix Subscription"
4. **Fill:** Amount ₹199, Date, etc.
5. **Tap Save:**
6. **Dialog Appears:**
   ```
   🔁 Recurring Bill Detected
   
   You have a recurring bill for:
   Netflix Subscription - ₹199
   Monthly
   
   Is this the same payment?
   [No, Different Payment] [Yes, Same Payment]
   ```
7. **Select:** "Yes, Same Payment"
8. **Result:**
   - Auto-created transaction deleted
   - Your manual transaction kept
   - Notification auto-approved
   - Next occurrence scheduled

### Journey 4: Reschedule Payment

1. **Scenario:** Subscription moved from 2nd to 10th
2. **Open:** Notification Center
3. **Tap:** "Reschedule" on Netflix notification
4. **Pick Date:** Feb 10, 2026
5. **Result:**
   - Next occurrence updated to Feb 10
   - Transaction date changed to Feb 10
   - Future payments on 10th of each month

---

## 🏗️ Technical Architecture

### Data Models

#### RecurringRule
```dart
class RecurringRule {
  String id;              // UUID
  String userId;          // User identifier
  String name;            // "Netflix Subscription"
  double amount;          // 199.0
  String category;        // "subscriptions"
  String? subcategory;    // Optional
  TransactionType type;   // expense or income
  
  int frequencyValue;     // 1, 25, 3, etc.
  FrequencyUnit frequencyUnit; // days, weeks, months, years
  
  DateTime startDate;     // When rule starts
  DateTime nextOccurrence; // When next payment is due
  DateTime? lastCreated;  // Last auto-creation time
  
  bool isActive;          // true/false
  String? notes;
  int notificationHour;   // 0-23 (default: 5)
  int notificationMinute; // 0-59 (default: 0)
}
```

#### RecurringNotification
```dart
class RecurringNotification {
  String id;              // UUID
  String recurringRuleId; // Reference to rule
  String transactionId;   // Auto-created transaction
  DateTime createdAt;
  bool isRead;
  NotificationStatus status; // pending, approved, canceled, snoozed, rescheduled
  
  DateTime? snoozeUntil;      // For "Notify Later"
  DateTime? rescheduledDate;  // For "Reschedule"
  
  // Cached for display
  String ruleName;
  double amount;
  DateTime dueDate;
}
```

### Services

#### RecurringBillService

**Main Methods:**

```dart
// Daily check (5 AM)
checkAndCreateDueTransactions()

// 4 Action Handlers
handlePaidAction(notificationId)
handleCanceledAction(notificationId, deleteRule)
handleNotifyLaterAction(notificationId, snoozeUntil)
handleRescheduleAction(notificationId, newDate)

// Duplicate Detection
findMatchingRule(merchantName)
linkTransactionToRule(transactionId, ruleId)

// CRUD
createRule(rule)
updateRule(rule)
deleteRule(ruleId)
getActiveRules()
getPendingNotifications()
getPendingNotificationCount()
```

**Key Logic:**

1. **Next Occurrence Calculation:**
```dart
DateTime calculateNextOccurrence(current, value, unit) {
  switch (unit) {
    case days: return current.add(Duration(days: value));
    case weeks: return current.add(Duration(days: value * 7));
    case months: return DateTime(current.year, current.month + value, current.day);
    case years: return DateTime(current.year + value, current.month, current.day);
  }
}
```

2. **Duplicate Detection:**
```dart
// Case-insensitive fuzzy match
if (rule.name.toLowerCase().contains(merchant.toLowerCase()) ||
    merchant.toLowerCase().contains(rule.name.toLowerCase())) {
  return rule;
}
```

### Storage

**LocalStorageService:**
- Saves to JSON files in app documents directory
- Files: `recurring_rules_<userId>.json`, `recurring_notifications_<userId>.json`
- Auto-syncs with Google Drive (if enabled)

**File Locations:**
```
/data/user/0/com.expenwall.mobile/files/cache/
  recurring_rules_local_user.json
  recurring_notifications_local_user.json
```

### Background Scheduler

**Current Implementation:**
- Runs check when app opens
- Timer checks every 30 seconds for notifications

**Future Enhancement (v2.4.0):**
- Use `workmanager` package for true background execution
- Schedule daily task at 5 AM even if app closed
- Requires additional setup:
```dart
Workmanager().registerPeriodicTask(
  "recurring-bills-check",
  "checkRecurringBills",
  frequency: Duration(hours: 24),
  initialDelay: Duration(hours: nextRunTime),
);
```

---

## 📁 File Structure

```
lib/
├── models/
│   ├── recurring_rule.dart              # Rule data model
│   └── recurring_notification.dart      # Notification data model
│
├── services/
│   ├── recurring_bill_service.dart      # Core business logic
│   └── local_storage_service.dart       # Updated with storage methods
│
├── screens/
│   ├── recurring_bills_screen.dart      # List of all rules
│   ├── create_recurring_rule_screen.dart # Create/Edit form
│   ├── notification_center_screen.dart   # Notification list with actions
│   ├── add_transaction_screen_v2.dart   # Updated with duplicate detection
│   └── home_screen_v2.dart              # Updated with bell icon
│
└── widgets/
    ├── glass_card.dart                  # Reused UI component
    └── expandable_tab_bar.dart          # Navigation
```

---

## ⚙️ How It Works

### Scenario: Netflix Subscription (Monthly)

**Day 0 (Feb 1):** User creates rule
```json
{
  "id": "rule-123",
  "name": "Netflix Subscription",
  "amount": 199,
  "frequencyValue": 1,
  "frequencyUnit": "months",
  "startDate": "2026-02-01",
  "nextOccurrence": "2026-03-01",
  "isActive": true
}
```

**Day 30 (March 1, 5:00 AM):** Auto-check runs
```dart
if (rule.nextOccurrence.isToday) {
  // 1. Create transaction
  transaction = Transaction(
    merchant: "Netflix Subscription",
    amount: 199,
    date: "2026-03-01",
    notes: "Auto-created from recurring rule: Netflix Subscription"
  );
  
  // 2. Create notification
  notification = RecurringNotification(
    ruleName: "Netflix Subscription",
    amount: 199,
    dueDate: "2026-03-01",
    status: pending
  );
  
  // 3. Update next occurrence
  rule.nextOccurrence = "2026-04-01"; // Next month
  rule.lastCreated = now();
}
```

**Day 30 (9:00 AM):** User opens app
- Bell icon shows badge "1"
- User taps bell → Notification Center
- Sees: "Netflix Subscription - ₹199, Due: March 1"
- Taps "Paid"

**Result:**
```dart
notification.status = approved;
notification.isRead = true;
// Transaction stays in list
// Badge count updates to 0
```

**Day 60 (April 1, 5:00 AM):** Cycle repeats
- New transaction created
- New notification created
- Next occurrence: May 1

---

## 🧪 Testing Guide

### Test 1: Create Recurring Rule

**Steps:**
1. Navigate: Planning → Recurring Bills
2. Tap: "Add Recurring Bill" FAB
3. Fill:
   - Name: "Test Subscription"
   - Amount: 100
   - Type: Expense
   - Frequency: Every 1 month
   - Start Date: Today
4. Verify: Next due date auto-calculated (next month)
5. Save
6. Verify: Rule appears in Active Bills section

**Expected:**
- ✅ Rule saved successfully
- ✅ Shows in list with correct details
- ✅ Next due date correct
- ✅ Toggle switch is ON (active)

### Test 2: Edit Recurring Rule

**Steps:**
1. Tap on existing rule
2. Change amount to 150
3. Change frequency to "Every 2 months"
4. Save
5. Verify changes reflected

**Expected:**
- ✅ Changes saved
- ✅ Next due date recalculated
- ✅ Frequency text updated

### Test 3: Pause/Reactivate Rule

**Steps:**
1. Toggle switch on a rule to OFF
2. Verify: Moves to "Paused Bills" section
3. Toggle back to ON
4. Verify: Moves back to "Active Bills"

**Expected:**
- ✅ Rule pauses correctly
- ✅ Reactivates correctly
- ✅ No errors

### Test 4: Delete Rule

**Steps:**
1. Tap on a rule
2. Tap delete icon (top-right)
3. Confirm deletion
4. Verify: Rule removed from list

**Expected:**
- ✅ Confirmation dialog shown
- ✅ Rule deleted after confirmation
- ✅ No longer in list

### Test 5: Manual Due Date Check (Simulated)

**Steps:**
1. Create rule with next occurrence = today
2. Open app
3. Check if notification appears
4. Check Expenses list for auto-created transaction

**Expected:**
- ✅ Transaction created automatically
- ✅ Notification badge shows "1"
- ✅ Notification appears in center

### Test 6: Notification Actions

**Test 6a: Paid**
1. Open Notification Center
2. Tap "Paid" on a notification
3. Verify: Notification disappears, badge updates

**Test 6b: Canceled - Just Pause**
1. Tap "Canceled"
2. Select "Just Pause"
3. Verify: Rule moved to Paused, transaction deleted

**Test 6c: Canceled - Delete Rule**
1. Tap "Canceled"
2. Select "Delete Rule"
3. Verify: Rule completely removed

**Test 6d: Notify Later**
1. Tap "Notify Later"
2. Choose date 2 days ahead, time 10 AM
3. Verify: Notification snoozed
4. Check on chosen date: Notification reappears

**Test 6e: Reschedule**
1. Tap "Reschedule"
2. Choose new date (e.g., 5 days ahead)
3. Verify: Next occurrence updated, transaction date changed

**Expected:**
- ✅ All 4 actions work correctly
- ✅ UI updates reflect changes
- ✅ Data persists

### Test 7: Duplicate Detection

**Steps:**
1. Create recurring rule: "Netflix", ₹199
2. Go to Add Transaction
3. Type merchant name: "Netflix"
4. Verify: Banner shows "Matches recurring bill: Netflix"
5. Fill amount, date, save
6. Verify: Dialog asks "Is this the same payment?"
7. Select "Yes, Same Payment"
8. Verify: Linked correctly, auto-transaction deleted

**Expected:**
- ✅ Detection works on typing
- ✅ Banner visible
- ✅ Dialog appears on save
- ✅ Linking works correctly

### Test 8: Frequency Variations

**Test:**
- Every 1 day
- Every 7 days  
- Every 2 weeks
- Every 1 month
- Every 3 months
- Every 1 year
- Every 25 days (custom)

**Verify:**
- ✅ Next occurrence calculated correctly for each
- ✅ Frequency text displays properly

### Test 9: Income Recurring (Salary)

**Steps:**
1. Create rule:
   - Name: "Monthly Salary"
   - Amount: 50000
   - Type: **Income**
   - Frequency: Every 1 month
2. Verify: Creates income transaction (not expense)
3. Verify: Shows correctly in Dashboard income

**Expected:**
- ✅ Income type supported
- ✅ Transaction type correct
- ✅ Dashboard reflects income

### Test 10: Bell Icon Badge

**Steps:**
1. Create 3 different recurring rules with next occurrence = today
2. Check bell icon: Badge shows "3"
3. Handle 1 notification (Paid)
4. Check: Badge shows "2"
5. Handle all: Badge disappears

**Expected:**
- ✅ Badge count accurate
- ✅ Updates in real-time
- ✅ Disappears when 0

---

## 🐛 Troubleshooting

### Issue 1: Notifications Not Appearing

**Symptoms:**
- Bell icon badge is 0
- No notifications in center
- But transaction was created

**Causes:**
- Notification not saved to storage
- Service not initialized

**Fix:**
```dart
// Check service initialization in HomeScreen
_recurringService = RecurringBillService(
  localStorage: _localStorageService,
  userId: _userId,
);

// Verify timer is running
_notificationTimer = Timer.periodic(
  const Duration(seconds: 30), 
  (_) => _loadNotificationCount()
);
```

### Issue 2: Duplicate Transactions

**Symptoms:**
- Same transaction appears twice
- Once auto-created, once manual

**Causes:**
- Duplicate detection not triggered
- Rule name doesn't match merchant name

**Fix:**
- Ensure merchant name contains rule name (case-insensitive)
- Check `findMatchingRule()` logic
- Use exact name or add better fuzzy matching

### Issue 3: Next Occurrence Wrong

**Symptoms:**
- Next occurrence not calculating correctly
- Off by days/months

**Causes:**
- Month calculation issue (Feb 30 doesn't exist)
- Timezone mismatch

**Fix:**
```dart
// Ensure proper month handling
DateTime(
  current.year,
  current.month + value,
  math.min(current.day, daysInMonth(current.month + value)),
);
```

### Issue 4: Bell Badge Not Updating

**Symptoms:**
- Badge shows old count
- Doesn't update after action

**Causes:**
- Timer not running
- State not updating

**Fix:**
```dart
// Call after each action
await _loadNotificationCount();

// In HomeScreen dispose:
@override
void dispose() {
  _notificationTimer?.cancel();
  super.dispose();
}
```

### Issue 5: Storage Not Persisting

**Symptoms:**
- Rules disappear after app restart
- Notifications lost

**Causes:**
- File write failed
- Wrong user ID

**Fix:**
```dart
// Verify files exist:
final dir = await getApplicationDocumentsDirectory();
print('Storage path: ${dir.path}/cache/');

// Check file contents:
final file = File('${dir.path}/cache/recurring_rules_$userId.json');
if (await file.exists()) {
  print(await file.readAsString());
}
```

---

## 🎉 Success Indicators

**You'll know it's working when:**

✅ **Can create recurring rules** with flexible frequency  
✅ **Rules appear in list** with correct details  
✅ **Bell icon shows badge** when notifications pending  
✅ **Notification Center opens** and shows pending bills  
✅ **All 4 actions work** (Paid, Canceled, Notify Later, Reschedule)  
✅ **Duplicate detection triggers** when typing merchant name  
✅ **Linking works** when selecting "Yes, same payment"  
✅ **Next occurrence updates** automatically after actions  
✅ **Active/Paused toggle** moves rules between sections  
✅ **Data persists** after app restart  

---

## 🚀 Future Enhancements (v2.4.0+)

1. **True Background Scheduler**
   - Use `workmanager` package
   - Run at 5 AM even if app closed
   - Show system notifications

2. **Smart Predictions**
   - "You usually pay Netflix on 1st, but it's 3rd - reminder?"
   - Detect missed payments

3. **Recurring Templates**
   - Pre-made templates for common subscriptions
   - One-tap setup

4. **Bill Reminders**
   - Notify 1 day before due date
   - "Netflix bill tomorrow - ₹199"

5. **Statistics**
   - Total monthly recurring expenses
   - Subscription cost trends
   - Most expensive subscriptions

6. **Family Sharing**
   - Share recurring bills with family members
   - Split costs automatically

---

## 📝 Notes

- **Flexible Frequency** is a unique feature - most apps only support monthly
- **4-action system** covers all real-world scenarios
- **Duplicate detection** prevents common user errors
- **Smart linking** makes UX seamless
- All data stored locally first, synced to Google Drive if enabled

---

**Status:** ✅ **Feature Complete & Ready for Testing!**  
**Next:** Implement Split Bills feature or test thoroughly

---

*Generated: February 2, 2026*  
*ExpenWall Mobile v2.3.0*
