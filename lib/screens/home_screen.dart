import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/merchant_rule.dart';
import '../models/budget.dart';
import '../services/firestore_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();
  
  List<Transaction> _transactions = [];
  List<MerchantRule> _rules = [];
  List<Wallet> _wallets = [];
  List<Budget> _budgets = [];
  
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _userId = user.uid;
    });

    // Subscribe to real-time updates
    _firestoreService.subscribeToTransactions(user.uid).listen((transactions) {
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    });

    _firestoreService.subscribeToRules(user.uid).listen((rules) {
      if (mounted) {
        setState(() => _rules = rules);
      }
    });

    _firestoreService.subscribeToWallets(user.uid).listen((wallets) {
      if (mounted) {
        setState(() => _wallets = wallets);
      }
    });

    _firestoreService.subscribeToBudgets(user.uid).listen((budgets) {
      if (mounted) {
        setState(() => _budgets = budgets);
      }
    });
  }

  List<Widget> get _screens => [
        DashboardScreen(
          transactions: _transactions,
          budgets: _budgets,
        ),
        TransactionsScreen(
          transactions: _transactions,
          rules: _rules,
          onDeleteTransaction: (id) => _firestoreService.deleteTransaction(id),
        ),
        const SizedBox(), // Placeholder for FAB
        const SettingsScreen(),
        const SettingsScreen(), // Placeholder for Profile
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: _currentIndex == 2
          ? null
          : AppBar(
              title: Text(
                _getAppBarTitle(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                onSave: (transaction) async {
                  await _firestoreService.addTransaction(transaction);
                  Navigator.of(context).pop();
                },
              ),
            ),
          );
        },
        elevation: 8,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildGlassBottomNav(),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Transactions';
      case 3:
        return 'Settings';
      case 4:
        return 'Profile';
      default:
        return 'ExpenWall';
    }
  }

  Widget _buildGlassBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
                _buildNavItem(Icons.receipt_long_rounded, 'Activity', 1),
                const SizedBox(width: 50), // Space for FAB
                _buildNavItem(Icons.settings_rounded, 'Settings', 3),
                _buildNavItem(Icons.person_rounded, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
