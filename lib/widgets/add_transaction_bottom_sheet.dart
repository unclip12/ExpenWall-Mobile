import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../screens/add_transaction_screen_v2.dart';
import 'glass_app_bar.dart';

/// Wrapper for AddTransactionScreenV2 to work inside a bottom sheet
/// This removes the Scaffold wrapper and uses glass components
class AddTransactionBottomSheet extends StatelessWidget {
  final Function(Transaction) onSave;
  final Transaction? initialData;
  final String userId;

  const AddTransactionBottomSheet({
    super.key,
    required this.onSave,
    this.initialData,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Glass header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    initialData == null ? 'New Transaction' : 'Edit Transaction',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance for close button
              ],
            ),
          ),
          // Main content
          Expanded(
            child: AddTransactionScreenV2(
              onSave: (transaction) async {
                await onSave(transaction);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              initialData: initialData,
              userId: userId,
            ),
          ),
        ],
      ),
    );
  }
}
