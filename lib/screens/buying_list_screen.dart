import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../models/product.dart';

class BuyingListScreen extends StatefulWidget {
  const BuyingListScreen({super.key});

  @override
  State<BuyingListScreen> createState() => _BuyingListScreenState();
}

class _BuyingListScreenState extends State<BuyingListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<ShoppingItem> _items = [];
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_itemController.text.trim().isEmpty) return;

    setState(() {
      _items.add(ShoppingItem(
        name: _itemController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        isPurchased: false,
      ));
      _itemController.clear();
      _priceController.clear();
    });
  }

  void _toggleItem(int index) {
    setState(() {
      _items[index] = ShoppingItem(
        name: _items[index].name,
        price: _items[index].price,
        isPurchased: !_items[index].isPurchased,
      );
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
    final totalAmount = unpurchased.fold(0.0, (sum, item) => sum + item.price);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _animController,
        child: Column(
          children: [
            // Stats Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('To Buy', unpurchased.length.toString(), Icons.shopping_cart),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStat('Done', purchased.length.toString(), Icons.check_circle),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStat('Total', '₹${totalAmount.toStringAsFixed(0)}', Icons.currency_rupee),
                  ],
                ),
              ),
            ),

            // Add Item Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _itemController,
                        decoration: const InputDecoration(
                          hintText: 'Item name',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.list_alt),
                        ),
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          hintText: '₹ Price',
                          border: InputBorder.none,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, size: 32),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: _addItem,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Shopping List
            Expanded(
              child: _items.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        if (unpurchased.isNotEmpty) ...
                          _buildSection('To Buy', unpurchased, false),
                        if (purchased.isNotEmpty) ...
                          _buildSection('Purchased', purchased, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<ShoppingItem> items, bool isPurchased) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...items.map((item) {
        final index = _items.indexOf(item);
        return _buildShoppingItem(item, index, isPurchased);
      }).toList(),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildShoppingItem(ShoppingItem item, int index, bool isPurchased) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(item.name + index.toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => _deleteItem(index),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: item.isPurchased,
                onChanged: (_) => _toggleItem(index),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
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
                        decoration: isPurchased ? TextDecoration.lineThrough : null,
                        color: isPurchased ? Colors.grey : null,
                      ),
                    ),
                    if (item.price > 0)
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          decoration: isPurchased ? TextDecoration.lineThrough : null,
                        ),
                      ),
                  ],
                ),
              ),
              if (isPurchased)
                Icon(Icons.check_circle, color: Colors.green[600]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
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
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Your shopping list is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items you plan to buy',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class ShoppingItem {
  final String name;
  final double price;
  final bool isPurchased;

  ShoppingItem({
    required this.name,
    required this.price,
    required this.isPurchased,
  });
}
