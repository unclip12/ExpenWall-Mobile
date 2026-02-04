# Phase 3: Bottom Sheet Integration Examples

**Date:** February 4, 2026  
**Status:** Ready for Integration

---

## Overview

This guide shows exactly how to integrate the AnimatedBottomSheet into your HomeScreenV2.

---

## Step 1: Update HomeScreenV2 FAB

### Current Code (Likely):
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreenV2(
          onSave: _saveTransaction,
          userId: widget.userId,
        ),
      ),
    );
  },
  child: const Icon(Icons.add),
),
```

### New Code (Bottom Sheet):
```dart
import 'package:expenwall_mobile/widgets/animated_bottom_sheet.dart';
import 'package:expenwall_mobile/widgets/add_transaction_bottom_sheet.dart';

// ...

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
),
```

---

## Step 2: Update Imports

Add these imports to the top of your `home_screen_v2.dart`:

```dart
import 'package:expenwall_mobile/widgets/animated_bottom_sheet.dart';
import 'package:expenwall_mobile/widgets/add_transaction_bottom_sheet.dart';
import 'package:expenwall_mobile/widgets/glass_button.dart'; // For GlassFAB
```

---

## Step 3: Test the Integration

### Test Cases:

1. **Tap FAB** → Bottom sheet slides up smoothly
2. **Drag down** → Bottom sheet dismisses
3. **Tap backdrop** → Bottom sheet closes
4. **Fill form & save** → Transaction saves, bottom sheet closes
5. **Keyboard opens** → Bottom sheet adjusts automatically

---

## Alternative: Use AnimatedBottomSheet Directly

If you want more control, you can use AnimatedBottomSheet directly:

```dart
floatingActionButton: GlassFAB(
  onPressed: () {
    AnimatedBottomSheet.show(
      context: context,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionScreenV2(
          onSave: (transaction) async {
            await _saveTransaction(transaction);
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          userId: widget.userId,
        ),
      ),
    );
  },
  icon: const Icon(Icons.add, color: Colors.white, size: 28),
),
```

---

## Complete Example: HomeScreenV2 FAB Section

Here's a complete example of how your FAB should look:

```dart
class _HomeScreenV2State extends State<HomeScreenV2> {
  // ... existing code ...

  Future<void> _saveTransaction(Transaction transaction) async {
    try {
      // Your existing save logic
      await _transactionService.saveTransaction(transaction);
      
      // Reload data
      await _loadData();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Transaction saved!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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

## Customization Options

### Change Bottom Sheet Height

```dart
AnimatedBottomSheet.show(
  context: context,
  maxHeight: 0.95, // 95% of screen height (default: 0.9)
  builder: (context) => AddTransactionBottomSheet(...),
);
```

### Disable Drag-to-Dismiss

```dart
AnimatedBottomSheet.show(
  context: context,
  isDismissible: false, // User must tap close button
  builder: (context) => AddTransactionBottomSheet(...),
);
```

### Custom Animation Duration

```dart
AnimatedBottomSheet.show(
  context: context,
  animationDuration: const Duration(milliseconds: 400),
  builder: (context) => AddTransactionBottomSheet(...),
);
```

---

## Troubleshooting

### Issue: Bottom sheet not showing
**Solution:** Make sure you imported `AnimatedBottomSheet` correctly:
```dart
import 'package:expenwall_mobile/widgets/animated_bottom_sheet.dart';
```

### Issue: Keyboard pushes content off-screen
**Solution:** `AddTransactionBottomSheet` already handles this, but if using raw `AnimatedBottomSheet`, add:
```dart
Padding(
  padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).viewInsets.bottom,
  ),
  child: YourContent(),
)
```

### Issue: AddTransactionScreenV2 shows double AppBar
**Solution:** Use `AddTransactionBottomSheet` wrapper instead of raw screen.

---
## Expected Behavior

### Opening:
1. User taps FAB
2. Bottom sheet slides up from bottom (300ms animation)
3. Backdrop fades in with blur
4. Content is fully visible

### Closing:
1. User drags down past threshold (40% of sheet)
2. Sheet animates down smoothly
3. Backdrop fades out
4. Returns to HomeScreenV2

### Saving:
1. User fills form and taps "Save Transaction"
2. Transaction saves
3. Bottom sheet closes automatically
4. Money flow animation plays (Phase 4)
5. HomeScreenV2 refreshes data

---

## Next Steps (Phase 4)

After bottom sheet is working:
1. Add MoneyFlowAnimation trigger on save
2. Test with various amounts
3. Verify particle effects

---

**Ready to integrate? Just copy the code examples above!** 🚀

*Last Updated: February 4, 2026, 1:55 PM IST*
