import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'add_transaction_screen.dart';
import 'budget_screen.dart';
import 'products_screen.dart';
import 'settings_screen.dart';
import '../models/transaction.dart' as models;
import '../models/wallet.dart';
import '../models/merchant_rule.dart';
import '../models/budget.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/sync_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _firestoreService = FirestoreService();
  final _localStorageService = LocalStorageService();
  
  List<models.Transaction> _transactions = [];
  List<MerchantRule> _rules = [];
  List<Wallet> _wallets = [];
  List<Budget> _budgets = [];
  List<Product> _products = [];
  
  bool _isLoading = true;
  bool _isSyncing = false;
  final String _userId = 'local_user'; // Default local user ID (no auth required!)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // OFFLINE-FIRST: Load from local storage immediately (instant load)
      await _loadLocalData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Optional: Firebase sync can be added here if needed
      // For now, app works 100% offline with optional Google Drive sync via Settings
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading data: $e';
        });
      }
    }
  }

  // Load data from local storage (instant, offline-first)
  Future<void> _loadLocalData() async {
    try {
      final transactions = await _localStorageService.loadTransactions(_userId);
      final budgets = await _localStorageService.loadBudgets(_userId);
      final products = await _localStorageService.loadProducts(_userId);
      final rules = await _localStorageService.loadRules(_userId);
      // Wallets will be added later if needed
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _budgets = budgets;
          _products = products;
          _rules = rules;
        });
      }
    } catch (e) {
      print('Error loading local data: $e');
      // It's okay if there's no data yet (first launch)
    }
  }

  // Add transaction (local-first, then sync)
  Future<void> _addTransaction(models.Transaction transaction) async {
    final txWithUserId = models.Transaction(
      id: transaction.id,
      userId: _userId,
      merchant: transaction.merchant,
      amount: transaction.amount,
      category: transaction.category,
      subcategory: transaction.subcategory,
      type: transaction.type,
      date: transaction.date,
      notes: transaction.notes,
      items: transaction.items,
      currency: transaction.currency,
    );

    // Add to local list immediately
    setState(() {
      _transactions.add(txWithUserId);
    });

    // Save to local storage
    await _localStorageService.saveTransactions(_userId, _transactions);

    // Try to sync to Firebase if connected (optional)
    try {
      setState(() => _isSyncing = true);
      await _firestoreService.addTransaction(txWithUserId);
      setState(() => _isSyncing = false);
    } catch (e) {
      print('Failed to sync transaction to Firebase: $e');
      // Add to pending operations queue
      await _localStorageService.addPendingOperation(_userId, {
        'type': 'create',
        'entity': 'transaction',
        'payload': txWithUserId.toFirestore(),
      });
      setState(() => _isSyncing = false);
    }
  }

  // Delete transaction (local-first, then sync)
  Future<void> _deleteTransaction(String id) async {
    // Remove from local list immediately
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });

    // Save to local storage
    await _localStorageService.saveTransactions(_userId, _transactions);

    // Try to sync to Firebase
    try {
      setState(() => _isSyncing = true);
      await _firestoreService.deleteTransaction(_userId, id);
      setState(() => _isSyncing = false);
    } catch (e) {
      print('Failed to delete from Firebase: $e');
      await _localStorageService.addPendingOperation(_userId, {
        'type': 'delete',
        'entity': 'transaction',
        'payload': {'id': id},
      });
      setState(() => _isSyncing = false);
    }
  }

  // Add budget (local-first)
  Future<void> _addBudget(Budget budget) async {
    final budgetWithUserId = Budget(
      id: budget.id,
      userId: _userId,
      category: budget.category,
      amount: budget.amount,
      period: budget.period,
    );

    setState(() {
      _budgets.add(budgetWithUserId);
    });

    await _localStorageService.saveBudgets(_userId, _budgets);

    try {
      setState(() => _isSyncing = true);
      await _firestoreService.addBudget(budgetWithUserId);
      setState(() => _isSyncing = false);
    } catch (e) {
      print('Failed to sync budget: $e');
      setState(() => _isSyncing = false);
    }
  }

  // Delete budget (local-first)
  Future<void> _deleteBudget(String id) async {
    setState(() {
      _budgets.removeWhere((b) => b.id == id);
    });

    await _localStorageService.saveBudgets(_userId, _budgets);

    try {
      setState(() => _isSyncing = true);
      await _firestoreService.deleteBudget(_userId, id);
      setState(() => _isSyncing = false);
    } catch (e) {
      print('Failed to delete budget from Firebase: $e');
      setState(() => _isSyncing = false);
    }
  }

  List<Widget> get _screens => [
        DashboardScreen(
          transactions: _transactions,
          budgets: _budgets,
        ),
        TransactionsScreen(
          transactions: _transactions,
          rules: _rules,
          onDeleteTransaction: _deleteTransaction,
        ),
        BudgetScreen(
          budgets: _budgets,
          transactions: _transactions,
          onAddBudget: _addBudget,
          onDeleteBudget: _deleteBudget,
        ),
        ProductsScreen(products: _products),
        const SettingsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Sync indicator
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SyncDot(isSyncing: true),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _errorMessage = null;
                              });
                              _initializeData();
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : IndexedStack(
                      index: _currentIndex,
                      children: _screens,
                    ),
          
          // Sync indicator overlay
          SyncIndicator(
            isSyncing: _isSyncing,
            hasError: _errorMessage != null,
            errorMessage: _errorMessage,
          ),
        ],
      ),
      floatingActionButton: _currentIndex < 2 && !_isLoading
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      onSave: (transaction) async {
                        await _addTransaction(transaction);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                );
              },
              elevation: 8,
              child: const Icon(Icons.add, size: 32),
            )
          : null,
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
      case 2:
        return 'Budgets';
      case 3:
        return 'Products';
      case 4:
        return 'Settings';
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
                _buildNavItem(Icons.dashboard_rounded, 'Home', 0),
                _buildNavItem(Icons.receipt_long_rounded, 'Activity', 1),
                _buildNavItem(Icons.account_balance_wallet_rounded, 'Budget', 2),
                _buildNavItem(Icons.inventory_2_rounded, 'Products', 3),
                _buildNavItem(Icons.settings_rounded, 'Settings', 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
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
