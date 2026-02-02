import 'package:flutter/material.dart';
import '../widgets/expandable_tab_bar.dart';
import 'split_bills_screen.dart';
import 'cravings_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _selectedTab = 0;

  final List<TabItem> _tabs = const [
    TabItem(label: 'Split Bills', icon: Icons.call_split),
    TabItem(label: 'Cravings', icon: Icons.favorite),
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
              children: const [
                // Split Bills Tab
                SplitBillsScreen(),

                // Cravings Tab
                CravingsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
