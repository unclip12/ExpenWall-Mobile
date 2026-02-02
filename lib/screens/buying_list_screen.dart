import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class BuyingListScreen extends StatefulWidget {
  const BuyingListScreen({super.key});

  @override
  State<BuyingListScreen> createState() => _BuyingListScreenState();
}

class _BuyingListScreenState extends State<BuyingListScreen> {
  final List<BuyingListItem> _items = [];
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemController.text.trim().isEmpty) return;

    setState(() {
      _items.add(BuyingListItem(
        name: _itemController.text.trim(),
        estimatedPrice: double.tryParse(_priceController.text) ?? 0,
        isPurchased: false,
      ));
      _itemController.clear();
      _priceController.clear();
    });
  }

  void _togglePurchased(int index) {
    setState(() {
      _items[index] = BuyingListItem(
        name: _items[index].name,
        estimatedPrice: _items[index].estimatedPrice,
        isPurchased: !_items[index].isPurchased,
      });
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final unpurchased = _items.where((i) => !i.isPurchased).toList();
    final purchased = _items.where((i) => i.isPurchased).toList();
    final totalEstimate = _items.fold<double>(0, (sum, item) => sum + item.estimatedPrice);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Summary Card
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('Items', _items.length.toString(), Icons.shopping_cart),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildSummaryItem('Estimate', '₹${totalEstimate.toStringAsFixed(0)}', Icons.currency_rupee),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildSummaryItem('Bought', purchased.length.toString(), Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add Item Form
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add to Shopping List',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _itemController,
                        decoration: const InputDecoration(
                          hintText: 'Item name',
                          prefixIcon: Icon(Icons.add_shopping_cart),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          hintText: 'Price',
                          prefixText: '₹',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addItem,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Unpurchased Items
          if (unpurchased.isNotEmpty) ..[
            const Text(
              'To Buy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...unpurchased.asMap().entries.map((entry) {
              final index = _items.indexOf(entry.value);
              return _buildItemCard(entry.value, index);
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Purchased Items
          if (purchased.isNotEmpty) ..[
            const Text(
              'Purchased',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...purchased.asMap().entries.map((entry) {
              final index = _items.indexOf(entry.value);
              return _buildItemCard(entry.value, index);
            }).toList(),
          ],

          if (_items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Your shopping list is empty',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildItemCard(BuyingListItem item, int index) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: item.isPurchased,
            onChanged: (_) => _togglePurchased(index),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                    color: item.isPurchased ? Colors.grey : null,
                  ),
                ),
                if (item.estimatedPrice > 0)
                  Text(
                    '₹${item.estimatedPrice.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteItem(index),
          ),
        ],
      ),
    );
  }
}

class BuyingListItem {
  final String name;
  final double estimatedPrice;
  final bool isPurchased;

  BuyingListItem({
    required this.name,
    required this.estimatedPrice,
    required this.isPurchased,
  });
}
