import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'add_transaction_screen_v2.dart';
import 'planning_screen.dart';
import 'social_screen.dart';
import 'products_screen.dart';
import 'settings_screen_v2.dart';
import '../models/transaction.dart' as models;
import '../models/wallet.dart';
import '../models/merchant_rule.dart';
import '../models/budget.dart';
import '../models/product.dart';
import '../services/local_storage_service.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/money_flow_animation.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  int _currentIndex = 0;
  final _localStorageService = LocalStorageService();
  
  List<models.Transaction> _transactions = [];
  List<MerchantRule> _rules = [];
  List<Wallet> _wallets = [];
  List<Budget> _budgets = [];
  List<Product> _products = [];
  
  bool _isLoading = true;
  bool _isSyncing = false;
  final String _userId = 'local_user';
  String? _errorMessage;
  
  // Money animation state
  bool _showMoneyAnimation = false;
  double _animationAmount = 0;
  bool _animationIsIncome = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _loadLocalData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _loadLocalData() async {
    try {
      final transactions = await _localStorageService.loadTransactions(_userId);
      final budgets = await _localStorageService.loadBudgets(_userId);
      final products = await _localStorageService.loadProducts(_userId);
      final rules = await _localStorageService.loadRules(_userId);
      
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
    }
  }

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

    setState(() {
      _transactions.add(txWithUserId);
    });

    await _localStorageService.saveTransactions(_userId, _transactions);
    
    // Show money animation
    _showMoneyAnimationEffect(
      amount: transaction.amount,
      isIncome: transaction.type == models.TransactionType.income,
    );
  }

  Future<void> _updateTransaction(models.Transaction transaction) async {
    setState(() {
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
      }
    });

    await _localStorageService.saveTransactions(_userId, _transactions);
  }

  Future<void> _deleteTransaction(String id) async {
    setState(() {
      _transactions.removeWhere((t) => t.id == id);
    });

    await _localStorageService.saveTransactions(_userId, _transactions);
  }

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
  }

  Future<void> _deleteBudget(String id) async {
    setState(() {
      _budgets.removeWhere((b) => b.id == id);
    });

    await _localStorageService.saveBudgets(_userId, _budgets);
  }

  void _showMoneyAnimationEffect({required double amount, required bool isIncome}) {
    setState(() {
      _showMoneyAnimation = true;
      _animationAmount = amount;
      _animationIsIncome = isIncome;
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
          onDeleteTransaction: _deleteTransaction,
          onUpdateTransaction: _updateTransaction,
          userId: _userId,
        ),
        PlanningScreen(
          budgets: _budgets,
          transactions: _transactions,
          onAddBudget: _addBudget,
          onDeleteBudget: _deleteBudget,
        ),
        const SocialScreen(),
        const SettingsScreenV2(),
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
          
          SyncIndicator(
            isSyncing: _isSyncing,
            hasError: _errorMessage != null,
            errorMessage: _errorMessage,
          ),
          
          // Money Flow Animation Overlay
          if (_showMoneyAnimation)
            Positioned.fill(
              child: IgnorePointer(
                child: MoneyFlowAnimation(
                  amount: _animationAmount,
                  isIncome: _animationIsIncome,
                  onComplete: () {
                    setState(() {
                      _showMoneyAnimation = false;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 || _currentIndex == 1) && !_isLoading
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreenV2(
                      userId: _userId,
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
        return 'Planning';
      case 3:
        return 'Social';
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
                _buildNavItem(Icons.calendar_today, 'Planning', 2),
                _buildNavItem(Icons.people, 'Social', 3),
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
