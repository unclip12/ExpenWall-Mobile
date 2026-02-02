import 'package:flutter/material.dart';
import '../widgets/expandable_tab_bar.dart';
import 'budget_screen.dart';
import 'recurring_bills_screen.dart';
import 'buying_list_screen.dart';
import '../models/transaction.dart';
import '../models/budget.dart';

class PlanningScreen extends StatefulWidget {
  final List<Budget> budgets;
  final List<Transaction> transactions;
  final Function(Budget) onAddBudget;
  final Function(String) onDeleteBudget;

  const PlanningScreen({
    super.key,
    required this.budgets,
    required this.transactions,
    required this.onAddBudget,
    required this.onDeleteBudget,
  });

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _selectedTab = 0;

  final List<TabItem> _tabs = const [
    TabItem(label: 'Budget', icon: Icons.account_balance_wallet),
    TabItem(label: 'Recurring', icon: Icons.autorenew),
    TabItem(label: 'Buying List', icon: Icons.shopping_cart),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Expandable Tab Bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: ExpandableTabBar(
              tabs: _tabs,
              selectedIndex: _selectedTab,
              onTabSelected: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                // Budget Tab
                BudgetScreen(
                  budgets: widget.budgets,
                  transactions: widget.transactions,
                  onAddBudget: widget.onAddBudget,
                  onDeleteBudget: widget.onDeleteBudget,
                ),

                // Recurring Bills Tab
                const RecurringBillsScreen(),

                // Buying List Tab
                const BuyingListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
