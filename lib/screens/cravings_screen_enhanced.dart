import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/craving.dart';
import '../services/craving_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_bottom_sheet.dart';
import 'log_craving_screen.dart';
import 'craving_analytics_screen.dart';

class CravingsScreenEnhanced extends StatefulWidget {
  final String userId;

  const CravingsScreenEnhanced({
    super.key,
    required this.userId,
  });

  @override
  State<CravingsScreenEnhanced> createState() => _CravingsScreenEnhancedState();
}

class _CravingsScreenEnhancedState extends State<CravingsScreenEnhanced>
    with SingleTickerProviderStateMixin {
  final CravingService _cravingService = CravingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showLogCravingSheet() {
    HapticFeedback.mediumImpact();
    AnimatedBottomSheet.show(
      context: context,
      child: LogCravingScreen(
        userId: widget.userId,
        onSaved: () {
          setState(() {}); // Refresh the list
        },
      ),
    );
  }

  void _navigateToAnalytics(CravingAnalytics analytics) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CravingAnalyticsScreen(
          userId: widget.userId,
          analytics: analytics,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<CravingAnalytics>(
        stream: _cravingService.streamAnalytics(widget.userId),
        builder: (context, analyticsSnapshot) {
          final analytics = analyticsSnapshot.data;

          return Column(
            children: [
              // Analytics Summary Card
              if (analytics != null) _buildAnalyticsSummary(analytics),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(4),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Theme.of(context).colorScheme.onPrimaryContainer,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: '💪 Resisted'),
                      Tab(text: '😋 Gave In'),
                    ],
                  ),
                ),
              ),

              // Tab Content
              Expanded(
                child: StreamBuilder<List<Craving>>(
                  stream: _cravingService.streamCravings(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final allCravings = snapshot.data ?? [];

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCravingsList(allCravings),
                        _buildCravingsList(
                          allCravings.where((c) => c.wasResisted).toList(),
                        ),
                        _buildCravingsList(
                          allCravings.where((c) => c.gaveIn).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogCravingSheet,
        icon: const Icon(Icons.add),
        label: const Text('Log Craving'),
      ),
    );
  }

  Widget _buildAnalyticsSummary(CravingAnalytics analytics) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Ranking Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analytics.ranking,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Your Rank',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _navigateToAnalytics(analytics),
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'View Analytics',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '${analytics.resistanceRate.toStringAsFixed(0)}%',
                  'Resistance',
                  Icons.shield,
                  Colors.green,
                ),
                _buildDivider(),
                _buildStatItem(
                  '${analytics.currentStreak}',
                  'Current Streak',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildDivider(),
                _buildStatItem(
                  '₹${analytics.totalSpent.toStringAsFixed(0)}',
                  'Total Spent',
                  Icons.currency_rupee,
                  Colors.red,
                ),
              ],
            ),

            if (analytics.topMerchant != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Top Merchant: ${analytics.topMerchant}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey[300],
    );
  }

  Widget _buildCravingsList(List<Craving> cravings) {
    if (cravings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No cravings logged yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to log your first craving!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: cravings.length,
      itemBuilder: (context, index) {
        return _buildCravingCard(cravings[index]);
      },
    );
  }

  Widget _buildCravingCard(Craving craving) {
    final wasResisted = craving.wasResisted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: wasResisted
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        craving.status.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        craving.status.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: wasResisted ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Date
                Text(
                  _formatDate(craving.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Craving Name
            Text(
              craving.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (craving.description != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                craving.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],

            // Items & Merchant (if gave in)
            if (craving.gaveIn) ...<Widget>[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Merchant
              if (craving.merchant != null)
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      craving.merchant!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (craving.merchantArea != null) ...<Widget>[
                      const SizedBox(width: 4),
                      Text(
                        '(${craving.merchantArea})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),

              const SizedBox(height: 8),

              // Items
              if (craving.items.isNotEmpty) ...<Widget>[
                ...craving.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (item.emoji != null)
                            Text('${item.emoji} ', style: const TextStyle(fontSize: 14)),
                          Text(
                            '${item.quantity}x ${item.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Spacer(),
                          Text(
                            '₹${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
              ],

              // Total Amount
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${craving.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Notes
            if (craving.notes != null && craving.notes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        craving.notes!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hours = diff.inHours;
      if (hours == 0) {
        final minutes = diff.inMinutes;
        return minutes <= 1 ? 'Just now' : '$minutes minutes ago';
      }
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
