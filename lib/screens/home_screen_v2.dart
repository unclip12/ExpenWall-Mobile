import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'add_transaction_screen_v2.dart';
import 'budget_screen.dart';
import 'products_screen.dart';
import 'settings_screen_v2.dart';
import 'buying_list_screen.dart';
import 'cravings_screen.dart';
import 'recurring_bills_screen.dart';
import 'split_bills_screen.dart';
import 'notification_center_screen.dart';
import 'theme_selector_screen.dart';
import '../models/transaction.dart' as models;
import '../models/wallet.dart';
import '../models/merchant_rule.dart';
import '../models/budget.dart';
import '../models/product.dart';
import '../services/local_storage_service.dart';
import '../services/recurring_bill_service.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/expandable_tab_bar.dart';
import '../widgets/money_flow_animation.dart';
import '../widgets/glass_button.dart';
import '../widgets/animated_bottom_sheet.dart';
import '../widgets/add_transaction_bottom_sheet.dart';

class HomeScreenV2 extends StatefulWidget {
  const HomeScreenV2({super.key});

  @override
  State<HomeScreenV2> createState() => _HomeScreenV2State();
}

class _HomeScreenV2State extends State<HomeScreenV2> {
  int _currentMainTab = 0; // Main bottom nav: Dashboard, Expenses, Planning, Social, Insights
  int _planningSubTab = 0; // Budget, Recurring, Buying List
  int _socialSubTab = 0; // Split Bills, Cravings
  
  final _localStorageService = LocalStorageService();
  late RecurringBillService _recurringService;
  
  List<models.Transaction> _transactions = [];
  List<MerchantRule> _rules = [];
  List<Wallet> _wallets = [];
  List<Budget> _budgets = [];
  List<Product> _products = [];
  
  bool _isLoading = true;
  bool _isSyncing = false;
  final String _userId = 'local_user';
  String? _errorMessage;
  int _notificationCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _recurringService = RecurringBillService(
      localStorage: _localStorageService,
      userId: _userId,
    );
    _initializeData();
    _loadNotificationCount();
    
    // Refresh notification count every 30 seconds
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadNotificationCount();
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotificationCount() async {
    final count = await _recurringService.getPendingNotificationCount();
    if (mounted) {
      setState(() {
        _notificationCount = count;
      });
    }
  }

  Future<void> _openNotificationCenter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationCenterScreen(userId: _userId),
      ),
    );
    
    // Reload count after returning
    _loadNotificationCount();
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

    // Show enhanced money flow animation
    if (mounted) {
      _showMoneyFlowAnimation(
        transaction.amount,
        transaction.type == models.TransactionType.income,
      );
    }

    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2500));
  }

  void _showMoneyFlowAnimation(double amount, bool isIncome) {
    // Haptic feedback
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
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
      ),
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

  Widget _getCurrentScreen() {
    switch (_currentMainTab) {
      case 0: // Dashboard
        return DashboardScreen(
          transactions: _transactions,
          budgets: _budgets,
        );
      case 1: // Expenses
        return TransactionsScreen(
          transactions: _transactions,
          rules: _rules,
          onDeleteTransaction: _deleteTransaction,
          onUpdateTransaction: _updateTransaction,
          userId: _userId,
        );
      case 2: // Planning
        return _getPlanningScreen();
      case 3: // Social
        return _getSocialScreen();
      case 4: // Insights (Settings for now)
        return const SettingsScreenV2();
      default:
        return DashboardScreen(
          transactions: _transactions,
          budgets: _budgets,
        );
    }
  }

  Widget _getPlanningScreen() {
    switch (_planningSubTab) {
      case 0:
        return BudgetScreen(
          budgets: _budgets,
          transactions: _transactions,
          onAddBudget: _addBudget,
          onDeleteBudget: _deleteBudget,
        );
      case 1:
        return RecurringBillsScreen(userId: _userId);
      case 2:
        return const BuyingListScreen();
      default:
        return BudgetScreen(
          budgets: _budgets,
          transactions: _transactions,
          onAddBudget: _addBudget,
          onDeleteBudget: _deleteBudget,
        );
    }
  }

  Widget _getSocialScreen() {
    switch (_socialSubTab) {
      case 0:
        return SplitBillsScreen(userId: _userId);
      case 1:
        return const CravingsScreen();
      default:
        return SplitBillsScreen(userId: _userId);
    }
  }

  String _getAppBarTitle() {
    switch (_currentMainTab) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Expenses';
      case 2:
        return _getPlanningTitle();
      case 3:
        return _getSocialTitle();
      case 4:
        return 'Settings';
      default:
        return 'ExpenWall';
    }
  }

  String _getPlanningTitle() {
    switch (_planningSubTab) {
      case 0:
        return 'Budget';
      case 1:
        return 'Recurring Bills';
      case 2:
        return 'Buying List';
      default:
        return 'Planning';
    }
  }

  String _getSocialTitle() {
    switch (_socialSubTab) {
      case 0:
        return 'Split Bills';
      case 1:
        return 'Cravings';
      default:
        return 'Social';
    }
  }

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
          // Notification Bell with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: _openNotificationCenter,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Sub-tabs for Planning and Social
              if (_currentMainTab == 2) _buildPlanningSubTabs(),
              if (_currentMainTab == 3) _buildSocialSubTabs(),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _getCurrentScreen(),
              ),
            ],
          ),
          
          SyncIndicator(
            isSyncing: _isSyncing,
            hasError: _errorMessage != null,
            errorMessage: _errorMessage,
          ),
        ],
      ),
      floatingActionButton: (_currentMainTab == 0 || _currentMainTab == 1) && !_isLoading
          ? GlassFAB(
              onPressed: () {
                HapticFeedback.lightImpact();
                AnimatedBottomSheet.show(
                  context: context,
                  builder: (context) => AddTransactionBottomSheet(
                    userId: _userId,
                    onSave: (transaction) async {
                      await _addTransaction(transaction);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 32),
              backgroundColor: Theme.of(context).colorScheme.primary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ExpandableTabBar(
        tabs: [
          TabItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
          TabItem(icon: Icons.receipt_long_rounded, label: 'Expenses'),
          TabItem(icon: Icons.calendar_today, label: 'Planning'),
          TabItem(icon: Icons.people_alt, label: 'Social'),
          TabItem(icon: Icons.insights, label: 'Insights'),
        ],
        selectedIndex: _currentMainTab,
        onTabSelected: (index) => setState(() => _currentMainTab = index),
      ),
    );
  }

  Widget _buildPlanningSubTabs() {
    return ExpandableTabBar(
      tabs: [
        TabItem(icon: Icons.account_balance_wallet, label: 'Budget'),
        TabItem(icon: Icons.repeat, label: 'Recurring'),
        TabItem(icon: Icons.shopping_cart, label: 'Buying List'),
      ],
      selectedIndex: _planningSubTab,
      onTabSelected: (index) => setState(() => _planningSubTab = index),
    );
  }

  Widget _buildSocialSubTabs() {
    return ExpandableTabBar(
      tabs: [
        TabItem(icon: Icons.people, label: 'Split Bills'),
        TabItem(icon: Icons.favorite, label: 'Cravings'),
      ],
      selectedIndex: _socialSubTab,
      onTabSelected: (index) => setState(() => _socialSubTab = index),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
    );
  }
}
