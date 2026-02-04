# Phase 4: Money Flow Animation Integration

**Date:** February 4, 2026  
**Status:** Ready for Integration

---

## Overview

This guide shows how to trigger the enhanced MoneyFlowAnimation after saving a transaction.

---

## What You'll Get

### Visual Effect:
- **Large amount display**: `-₹500` or `+₹1000` in big, bold text
- **Pop-in animation**: Smooth scale and fade effects
- **Color-coded**: 
  - Red gradient for expenses (spending)
  - Green gradient for income (receiving)
- **Particle burst**: 
  - ≤₹100: 12 particles
  - ≤₹500: 25 particles
  - ≤₹1000: 40 particles
  - ≤₹5000: 60 particles
  - ≤₹10000: 80 particles
  - >₹10000: 120 particles! 🎉
- **Duration**: 2.5 seconds

---

## Step 1: Add Animation Method to HomeScreenV2

Add this method to your `_HomeScreenV2State` class:

```dart
import 'package:expenwall_mobile/widgets/money_flow_animation.dart';

// Inside _HomeScreenV2State class:

void _showMoneyFlowAnimation(double amount, bool isIncome) {
  showDialog(
    context: context,
    barrierDismissible: false, // Can't tap outside to close
    barrierColor: Colors.transparent, // Transparent backdrop
    useSafeArea: false, // Full screen
    builder: (context) => MoneyFlowAnimation(
      amount: amount,
      isIncome: isIncome,
      onComplete: () {
        // Auto-close dialog when animation completes
        Navigator.of(context).pop();
      },
    ),
  );
}
```

---

## Step 2: Update Your Save Transaction Method

### Before (Current):
```dart
Future<void> _saveTransaction(Transaction transaction) async {
  try {
    await _transactionService.saveTransaction(transaction);
    await _loadData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaction saved!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    // Error handling
  }
}
```

### After (With Animation):
```dart
Future<void> _saveTransaction(Transaction transaction) async {
  try {
    await _transactionService.saveTransaction(transaction);
    
    // Show money flow animation BEFORE reloading data
    if (mounted) {
      _showMoneyFlowAnimation(
        transaction.amount,
        transaction.type == TransactionType.income,
      );
      
      // Wait for animation to complete (2.5s)
      await Future.delayed(const Duration(milliseconds: 2500));
    }
    
    // Reload data after animation
    await _loadData();
    
    // Optional: Show success snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Transaction saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  } catch (e) {
    // Error handling
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

---

## Step 3: Update AddTransactionBottomSheet Usage

Your current FAB should already pass the `_saveTransaction` callback:

```dart
floatingActionButton: GlassFAB(
  onPressed: () {
    AnimatedBottomSheet.show(
      context: context,
      builder: (context) => AddTransactionBottomSheet(
        onSave: _saveTransaction, // ✅ This callback now triggers animation
        userId: widget.userId,
      ),
    );
  },
  icon: const Icon(Icons.add, color: Colors.white, size: 28),
  backgroundColor: Theme.of(context).colorScheme.primary,
),
```

---

## Alternative: Trigger Animation AFTER Bottom Sheet Closes

If you want the animation to play after the bottom sheet closes:

```dart
floatingActionButton: GlassFAB(
  onPressed: () async {
    // Open bottom sheet and wait for result
    final result = await AnimatedBottomSheet.show<Transaction?>(
      context: context,
      builder: (context) => AddTransactionBottomSheet(
        onSave: (transaction) async {
          await _transactionService.saveTransaction(transaction);
          // Return transaction to trigger animation
          Navigator.of(context).pop(transaction);
        },
        userId: widget.userId,
      ),
    );
    
    // If transaction was saved, show animation
    if (result != null) {
      _showMoneyFlowAnimation(
        result.amount,
        result.type == TransactionType.income,
      );
      
      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // Reload data
      await _loadData();
    }
  },
  icon: const Icon(Icons.add, color: Colors.white, size: 28),
  backgroundColor: Theme.of(context).colorScheme.primary,
),
```

---

## Complete Example: HomeScreenV2 with Money Flow

```dart
import 'package:flutter/material.dart';
import 'package:expenwall_mobile/widgets/animated_bottom_sheet.dart';
import 'package:expenwall_mobile/widgets/add_transaction_bottom_sheet.dart';
import 'package:expenwall_mobile/widgets/glass_button.dart';
import 'package:expenwall_mobile/widgets/money_flow_animation.dart';
import 'package:expenwall_mobile/models/transaction.dart';

class HomeScreenV2 extends StatefulWidget {
  final String userId;
  
  const HomeScreenV2({super.key, required this.userId});
  
  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  // ... existing state variables ...
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Your existing data loading logic
  }
  
  // NEW: Money flow animation method
  void _showMoneyFlowAnimation(double amount, bool isIncome) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (context) => MoneyFlowAnimation(
        amount: amount,
        isIncome: isIncome,
        onComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
  
  // UPDATED: Save transaction with animation
  Future<void> _saveTransaction(Transaction transaction) async {
    try {
      // Save to storage
      await _transactionService.saveTransaction(transaction);
      
      // Show animation
      if (mounted) {
        _showMoneyFlowAnimation(
          transaction.amount,
          transaction.type == TransactionType.income,
        );
        
        // Wait for animation to complete
        await Future.delayed(const Duration(milliseconds: 2500));
      }
      
      // Reload data
      await _loadData();
      
      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Transaction saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... existing body ...
      
      floatingActionButton: GlassFAB(
        onPressed: () {
          AnimatedBottomSheet.show(
            context: context,
            builder: (context) => AddTransactionBottomSheet(
              onSave: _saveTransaction,
              userId: widget.userId,
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white, size: 28),
        backgroundColor: Theme.of(context).colorScheme.primary,
        heroTag: 'add_transaction',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
```

---

## Testing Checklist

### Test Different Amounts:
- [ ] **₹50** → Should show 12 particles (small burst)
- [ ] **₹200** → Should show 25 particles (medium burst)
- [ ] **₹800** → Should show 40 particles (good burst)
- [ ] **₹3000** → Should show 60 particles (big burst)
- [ ] **₹8000** → Should show 80 particles (huge burst)
- [ ] **₹15000** → Should show 120 particles (massive burst!) 🎉

### Test Transaction Types:
- [ ] **Expense** → Red gradient, `-₹` prefix
- [ ] **Income** → Green gradient, `+₹` prefix

### Test Animation Flow:
- [ ] Animation starts immediately after save
- [ ] Amount displays clearly in center
- [ ] Particles burst outward from center
- [ ] Animation completes in 2.5 seconds
- [ ] Bottom sheet closes after animation
- [ ] Data refreshes after animation
- [ ] Success message shows (optional)

### Edge Cases:
- [ ] Very small amounts (₹1)
- [ ] Very large amounts (₹100,000)
- [ ] Decimal amounts (₹99.50)
- [ ] Round numbers (₹1000)

---

## Customization Options

### Change Animation Duration

```dart
// In money_flow_animation.dart (already set to 2500ms)
// To change globally, modify the duration in the widget

// Or wait for custom duration:
await Future.delayed(const Duration(milliseconds: 3000)); // 3 seconds
```

### Add Haptic Feedback

```dart
import 'package:flutter/services.dart';

void _showMoneyFlowAnimation(double amount, bool isIncome) {
  // Vibrate on animation start
  HapticFeedback.mediumImpact();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (context) => MoneyFlowAnimation(
      amount: amount,
      isIncome: isIncome,
      onComplete: () {
        // Light vibration on complete
        HapticFeedback.lightImpact();
        Navigator.of(context).pop();
      },
    ),
  );
}
```

### Add Sound Effect (Optional)

```dart
import 'package:audioplayers/audioplayers.dart';

final _audioPlayer = AudioPlayer();

void _showMoneyFlowAnimation(double amount, bool isIncome) {
  // Play sound
  _audioPlayer.play(AssetSource(
    isIncome ? 'sounds/income.mp3' : 'sounds/expense.mp3'
  ));
  
  showDialog(
    // ... existing code ...
  );
}
```

---

## Troubleshooting

### Issue: Animation not showing
**Solution:** Check that `MoneyFlowAnimation` is imported:
```dart
import 'package:expenwall_mobile/widgets/money_flow_animation.dart';
```

### Issue: Animation cuts off early
**Solution:** Make sure you're using `barrierDismissible: false` and waiting for the full duration:
```dart
await Future.delayed(const Duration(milliseconds: 2500));
```

### Issue: Particles not visible
**Solution:** Ensure your background isn't too busy. The particles use theme-aware colors.

### Issue: Animation lags
**Solution:** Test on a real device. Emulators can be slower. If still laggy, particle count is auto-scaled based on amount.

---

## Expected User Flow

1. **User taps FAB** → Bottom sheet slides up
2. **User fills transaction form** → Enters amount, merchant, etc.
3. **User taps "Save Transaction"** → Form validates
4. **Bottom sheet closes** → Smooth slide down
5. **🎉 ANIMATION PLAYS** → Large amount with particles
   - Amount appears with pop-in effect
   - Particles burst from center
   - Gradient glow effect
   - Duration: 2.5 seconds
6. **Data refreshes** → New transaction appears in list
7. **Success message** → "✅ Transaction saved!"

---

**Ready to see your money flow! 💸✨**

*Last Updated: February 4, 2026, 2:10 PM IST*
