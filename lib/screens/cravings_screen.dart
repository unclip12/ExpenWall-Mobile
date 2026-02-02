import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class CravingsScreen extends StatefulWidget {
  const CravingsScreen({super.key});

  @override
  State<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends State<CravingsScreen> {
  final List<CravingItem> _cravings = [];
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCraving() {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _cravings.add(CravingItem(
        name: _nameController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        isDone: false,
        addedDate: DateTime.now(),
      ));
      _nameController.clear();
      _notesController.clear();
    });
  }

  void _toggleDone(int index) {
    setState(() {
      _cravings[index] = CravingItem(
        name: _cravings[index].name,
        notes: _cravings[index].notes,
        isDone: !_cravings[index].isDone,
        addedDate: _cravings[index].addedDate,
      );
    });
  }

  void _deleteCraving(int index) {
    setState(() {
      _cravings.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _cravings.where((c) => !c.isDone).toList();
    final completed = _cravings.where((c) => c.isDone).toList();

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
                _buildSummaryItem('Total', _cravings.length.toString(), Icons.favorite),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildSummaryItem('Active', active.length.toString(), Icons.restaurant),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildSummaryItem('Tried', completed.length.toString(), Icons.check_circle),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Add Craving Form
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Craving',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'Place or dish name',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _addCraving,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Craving'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Cravings
          if (active.isNotEmpty) ...[
            const Text(
              'Want to Try',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...active.asMap().entries.map((entry) {
              final index = _cravings.indexOf(entry.value);
              return _buildCravingCard(entry.value, index);
            }).toList(),
            const SizedBox(height: 24),
          ],

          // Completed Cravings
          if (completed.isNotEmpty) ...[
            const Text(
              'Tried & Tested',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...completed.asMap().entries.map((entry) {
              final index = _cravings.indexOf(entry.value);
              return _buildCravingCard(entry.value, index);
            }).toList(),
          ],

          if (_cravings.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No cravings yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add places or dishes you want to try!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

  Widget _buildCravingCard(CravingItem item, int index) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: item.isDone,
            onChanged: (_) => _toggleDone(index),
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
                    decoration: item.isDone ? TextDecoration.lineThrough : null,
                    color: item.isDone ? Colors.grey : null,
                  ),
                ),
                if (item.notes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Added ${_formatDate(item.addedDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _deleteCraving(index),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class CravingItem {
  final String name;
  final String? notes;
  final bool isDone;
  final DateTime addedDate;

  CravingItem({
    required this.name,
    this.notes,
    required this.isDone,
    required this.addedDate,
  });
}
