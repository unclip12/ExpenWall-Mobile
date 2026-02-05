import 'package:flutter/material.dart';
import '../models/split_bill.dart';
import '../services/split_bill_service.dart';
import '../services/contact_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/glass_card.dart';
import 'create_split_bill_screen.dart';
import 'bill_details_screen.dart';

class SplitBillsListScreen extends StatefulWidget {
  final String userId;

  const SplitBillsListScreen({super.key, required this.userId});

  @override
  State<SplitBillsListScreen> createState() => _SplitBillsListScreenState();
}

class _SplitBillsListScreenState extends State<SplitBillsListScreen>
    with SingleTickerProviderStateMixin {
  late SplitBillService _splitBillService;
  late TabController _tabController;
  List<SplitBill> _allBills = [];
  bool _isLoading = true;

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
      setState(() {
        _allBills = bills;
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

  List<SplitBill> get _pendingBills {
    return _allBills
        .where((b) => b.status != BillStatus.fullySettled)
        .toList();
  }

  List<SplitBill> get _settledBills {
    return _allBills.where((b) => b.status == BillStatus.fullySettled).toList();
  }

  Future<void> _createBill() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSplitBillScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      _loadBills();
    }
  }

  Future<void> _viewBill(SplitBill bill) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BillDetailsScreen(
          userId: widget.userId,
          billId: bill.id,
        ),
      ),
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
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBillsList(_pendingBills, true),
                _buildBillsList(_settledBills, false),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createBill,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBillsList(List<SplitBill> bills, bool isPending) {
    if (bills.isEmpty) {
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
              isPending ? 'No Pending Bills' : 'No Settled Bills',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Create a bill to split expenses'
                  : 'Settled bills will appear here',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (isPending) ..[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createBill,
                icon: const Icon(Icons.add),
                label: const Text('Create Split Bill'),
              ),
            ],
          ],
        ),
      );
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
    final statusColor = bill.status == BillStatus.fullySettled
        ? Colors.green
        : bill.status == BillStatus.partiallyPaid
            ? Colors.orange
            : Colors.red;

    return GestureDetector(
      onTap: () => _viewBill(bill),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    bill.getStatusText(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(bill.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${bill.totalParticipants} people',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '₹${bill.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (bill.status != BillStatus.fullySettled)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Pending',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        '₹${bill.totalAmountPending.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (bill.status != BillStatus.fullySettled) ..[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: bill.totalAmountPaid / bill.totalAmount,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  bill.status == BillStatus.partiallyPaid
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bill.totalPaidCount}/${bill.totalParticipants} paid',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
