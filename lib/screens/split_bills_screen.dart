import 'package:flutter/material.dart';
import '../models/split_bill.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'package:intl/intl.dart';

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
  List<SplitBill> _allBills = [];
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
      final bills = await _splitBillService.getAllBills();
      final totalPending = await _splitBillService.getTotalPendingAmount();

      setState(() {
        _allBills = bills;
        _pendingBills = bills
            .where((b) => b.status != BillStatus.fullySettled)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        _settledBills = bills
            .where((b) => b.status == BillStatus.fullySettled)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
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

  void _navigateToDetails(SplitBill bill) async {
    final result = await Navigator.pushNamed(
      context,
      '/split-bill-details',
      arguments: {'billId': bill.id, 'userId': widget.userId},
    );

    if (result == true) {
      _loadBills();
    }
  }

  void _navigateToCreate() async {
    final result = await Navigator.pushNamed(
      context,
      '/create-split-bill',
      arguments: widget.userId,
    );

    if (result == true) {
      _loadBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts),
            tooltip: 'Manage Contacts',
            onPressed: () {
              Navigator.pushNamed(context, '/contacts', arguments: widget.userId);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pending (${_pendingBills.length})',
              icon: const Icon(Icons.pending_actions),
            ),
            Tab(
              text: 'Settled (${_settledBills.length})',
              icon: const Icon(Icons.check_circle),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary card
                if (_pendingBills.isNotEmpty) _buildSummaryCard(),

                // Tab views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBillsList(_pendingBills, isPending: true),
                      _buildBillsList(_settledBills, isPending: false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreate,
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassCard(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              'Pending Bills',
              '${_pendingBills.length}',
              Icons.pending_actions,
              Colors.orange,
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildSummaryItem(
              'Total Pending',
              '₹${_totalPending.toStringAsFixed(2)}',
              Icons.currency_rupee,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBillsList(List<SplitBill> bills, {required bool isPending}) {
    if (bills.isEmpty) {
      return _buildEmptyState(isPending);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(bill);
      },
    );
  }

  Widget _buildBillCard(SplitBill bill) {
    final progressPercent = bill.totalAmountPaid / bill.totalAmount;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToDetails(bill),
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
                  _buildStatusBadge(bill.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy').format(bill.date),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.people, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${bill.participants.length} people',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '${bill.totalPaidCount}/${bill.totalParticipants} paid',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (bill.status != BillStatus.fullySettled) ..[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    minHeight: 6,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercent >= 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BillStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case BillStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.pending;
        break;
      case BillStatus.partiallyPaid:
        color = Colors.blue;
        text = 'Partial';
        icon = Icons.hourglass_half;
        break;
      case BillStatus.fullySettled:
        color = Colors.green;
        text = 'Settled';
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.pending_actions : Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isPending ? 'No pending bills' : 'No settled bills yet',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPending
                ? 'Create a bill to split expenses with friends'
                : 'Settled bills will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
