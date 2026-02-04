import 'package:flutter/material.dart';
import '../models/craving.dart';
import '../widgets/glass_card.dart';

class CravingAnalyticsScreen extends StatelessWidget {
  final String userId;
  final CravingAnalytics analytics;

  const CravingAnalyticsScreen({
    super.key,
    required this.userId,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate item-wise statistics
    final itemStats = _calculateItemStats(analytics.recentCravings);
    final overallTemptations = itemStats.entries.toList()
      ..sort((a, b) => b.value['count'].compareTo(a.value['count']));
    
    final resistedItems = itemStats.entries
        .where((e) => e.value['resisted'] > 0)
        .toList()
      ..sort((a, b) => b.value['resisted'].compareTo(a.value['resisted']));
    
    final gaveInItems = itemStats.entries
        .where((e) => e.value['gaveIn'] > 0)
        .toList()
      ..sort((a, b) => b.value['gaveIn'].compareTo(a.value['gaveIn']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cravings Analytics'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Saved',
                  '₹${_calculateSavedAmount(analytics.recentCravings).toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Wasted',
                  '₹${analytics.totalSpent.toStringAsFixed(0)}',
                  Icons.trending_down,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Resistance Rate',
                  '${analytics.resistanceRate.toStringAsFixed(0)}%',
                  Icons.shield,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total Cravings',
                  '${analytics.totalCravings}',
                  Icons.restaurant_menu,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Overall Temptations
          _buildSectionHeader(
            context,
            '📈 Overall Temptations',
            'All items you craved',
          ),
          const SizedBox(height: 12),
          if (overallTemptations.isEmpty)
            _buildEmptyState('No temptations logged yet')
          else
            ...overallTemptations.take(10).map((entry) {
              return _buildItemCard(
                context: context,
                name: entry.key,
                occurrences: entry.value['count'],
                amount: entry.value['totalAmount'],
                color: Colors.orange,
              );
            }),
          const SizedBox(height: 32),

          // Resistance Champions
          _buildSectionHeader(
            context,
            '🏆 Resistance Champions',
            'Items you successfully resisted',
          ),
          const SizedBox(height: 12),
          if (resistedItems.isEmpty)
            _buildEmptyState('No resisted items yet')
          else
            ...resistedItems.take(10).map((entry) {
              return _buildItemCard(
                context: context,
                name: entry.key,
                occurrences: entry.value['resisted'],
                amount: entry.value['resistedAmount'],
                color: Colors.green,
              );
            }),
          const SizedBox(height: 32),

          // Weakness Zone
          _buildSectionHeader(
            context,
            '🔥 Weakness Zone',
            'Items you gave in to',
          ),
          const SizedBox(height: 12),
          if (gaveInItems.isEmpty)
            _buildEmptyState('Great! No weaknesses yet')
          else
            ...gaveInItems.take(10).map((entry) {
              return _buildItemCard(
                context: context,
                name: entry.key,
                occurrences: entry.value['gaveIn'],
                amount: entry.value['gaveInAmount'],
                color: Colors.red,
              );
            }),

          const SizedBox(height: 32),

          // Ranking Badge
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  analytics.ranking,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Current Rank',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Keep up the great work!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required BuildContext context,
    required String name,
    required int occurrences,
    required double amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Circle with number/emoji
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getEmojiForItem(name),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$occurrences occurrence${occurrences > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (amount > 0)
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateItemStats(List<Craving> cravings) {
    final stats = <String, Map<String, dynamic>>{};

    for (final craving in cravings) {
      final name = craving.name;
      
      if (!stats.containsKey(name)) {
        stats[name] = {
          'count': 0,
          'resisted': 0,
          'gaveIn': 0,
          'totalAmount': 0.0,
          'resistedAmount': 0.0,
          'gaveInAmount': 0.0,
        };
      }

      stats[name]!['count']++;
      
      if (craving.wasResisted) {
        stats[name]!['resisted']++;
        stats[name]!['resistedAmount'] += craving.totalAmount;
      } else {
        stats[name]!['gaveIn']++;
        stats[name]!['gaveInAmount'] += craving.totalAmount;
        stats[name]!['totalAmount'] += craving.totalAmount;
      }
    }

    return stats;
  }

  double _calculateSavedAmount(List<Craving> cravings) {
    // For resisted cravings, use the average amount spent on that item when gave in
    double saved = 0.0;
    
    for (final craving in cravings) {
      if (craving.wasResisted) {
        // Find average price for this item from gave-in cravings
        final similarGaveIn = cravings.where(
          (c) => c.gaveIn && c.name.toLowerCase() == craving.name.toLowerCase(),
        ).toList();
        
        if (similarGaveIn.isNotEmpty) {
          final avgAmount = similarGaveIn.fold(
                0.0,
                (sum, c) => sum + c.totalAmount,
              ) /
              similarGaveIn.length;
          saved += avgAmount;
        }
      }
    }
    
    return saved;
  }

  String _getEmojiForItem(String name) {
    final lower = name.toLowerCase();
    
    // Common food emojis
    if (lower.contains('ice cream') || lower.contains('icecream')) return '🍦';
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('biryani') || lower.contains('rice')) return '🍛';
    if (lower.contains('chicken')) return '🍗';
    if (lower.contains('coffee')) return '☕';
    if (lower.contains('tea')) return '🍵';
    if (lower.contains('cake')) return '🍰';
    if (lower.contains('chocolate')) return '🍫';
    if (lower.contains('candy') || lower.contains('sweet')) return '🍬';
    if (lower.contains('soda') || lower.contains('coke')) return '🥤';
    if (lower.contains('fries')) return '🍟';
    if (lower.contains('donut') || lower.contains('doughnut')) return '🍩';
    if (lower.contains('cookie')) return '🍪';
    if (lower.contains('noodle') || lower.contains('ramen')) return '🍜';
    if (lower.contains('sushi')) return '🍣';
    if (lower.contains('taco')) return '🌮';
    if (lower.contains('sandwich')) return '🥪';
    
    // Default
    return '🍽️';
  }
}
