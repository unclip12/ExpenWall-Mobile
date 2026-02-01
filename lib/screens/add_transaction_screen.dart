import 'package:flutter/material.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatelessWidget {
  final Function(Transaction) onSave;

  const AddTransactionScreen({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: const Center(
        child: Text('Coming soon!'),
      ),
    );
  }
}
