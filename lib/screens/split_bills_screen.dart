import 'package:flutter/material.dart';
import '../models/split_bill.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'create_split_bill_screen.dart';
import 'bill_details_screen.dart';
import 'contacts_screen.dart';
import 'groups_screen.dart';

class SplitBillsScreen extends StatefulWidget {
  final String userId;

  const SplitBillsScreen({super.key, required this.userId});

  @override
  State<SplitBillsScreen> createState() => _SplitBillsScreenState();
}

class _SplitBillsScreenState extends State<SplitBillsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SplitBillService _splitBillService;

  List<SplitBill> _pendingBills = [];
  List<SplitBill> _settledBills = [];
  bool _isLoading = true;
  double _totalPending = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _splitBillService = SplitBillService(
      localStorage: LocalStorageService(),
      contactService: ContactService(
        localStorage: LocalStorageService(),
        userId: widget.userId,
      ),
      userId: widget.userId,
    );
    _loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final allBills = await _splitBillService.getAllBills();
      final pending = allBills
          .where((b) => b.status != BillStatus.fullySettled)
          .toList();
      final settled =
          allBills.where((b) => b.status == BillStatus.fullySettled).toList();
      final totalPending = await _splitBillService.getTotalPendingAmount();

      // Sort by date (newest first)
      pending.sort((a, b) => b.date.compareTo(a.date));
      settled.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _pendingBills = pending;
        _settledBills = settled;
        _totalPending = totalPending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bills: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Contacts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContactsScreen(userId: widget.userId),
                ),
              ).then((_) => _loadBills());
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupsScreen(userId: widget.userId),
                ),
              ).then((_) => _loadBills());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (_pendingBills.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_pendingBills.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Settled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                if (_pendingBills.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: GlassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Pending',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '₹${_totalPending.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _pendingBills.isEmpty
                          ? _buildEmptyState('No pending bills', true)
                          : _buildBillsList(_pendingBills),
                      _settledBills.isEmpty
                          ? _buildEmptyState('No settled bills', false)
                          : _buildBillsList(_settledBills),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreateSplitBillScreen(userId: widget.userId),
            ),
          ).then((created) {
            if (created == true) _loadBills();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Bill'),
      ),
    );
  }

  Widget _buildBillsList(List<SplitBill> bills) {
    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        itemBuilder: (context, index) => _buildBillCard(bills[index]),
      ),
    );
  }

  Widget _buildBillCard(SplitBill bill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BillDetailsScreen(
                  userId: widget.userId,
                  billId: bill.id,
                ),
              ),
            ).then((_) => _loadBills());
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        bill.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(bill.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bill.getStatusText(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.currency_rupee, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      bill.totalAmount.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 4),
                    Text('${bill.participants.length} people'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(bill.date),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.splitscreen, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      bill.getSplitTypeText(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (bill.status != BillStatus.fullySettled) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: bill.totalAmountPaid / bill.totalAmount,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bill.totalPaidCount}/${bill.totalParticipants} paid',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.receipt_long_outlined : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Create your first split bill'
                : 'Completed bills will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.pending:
        return Colors.orange;
      case BillStatus.partiallyPaid:
        return Colors.blue;
      case BillStatus.fullySettled:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
