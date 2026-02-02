import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class CravingsScreen extends StatefulWidget {
  const CravingsScreen({super.key});

  @override
  State<CravingsScreen> createState() => _CravingsScreenState();
}

class _CravingsScreenState extends State<CravingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<Craving> _cravings = [];
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

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
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddCravingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Craving'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Place/Item Name',
                hintText: 'e.g., New Restaurant, PlayStation 5',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                hintText: 'Why you want this...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                setState(() {
                  _cravings.add(Craving(
                    name: _nameController.text.trim(),
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    addedDate: DateTime.now(),
                    isDone: false,
                  ));
                });
                _nameController.clear();
                _notesController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleCraving(int index) {
    setState(() {
      _cravings[index] = Craving(
        name: _cravings[index].name,
        notes: _cravings[index].notes,
        addedDate: _cravings[index].addedDate,
        isDone: !_cravings[index].isDone,
        completedDate: !_cravings[index].isDone ? DateTime.now() : null,
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
    final pending = _cravings.where((c) => !c.isDone).toList();
    final done = _cravings.where((c) => c.isDone).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeTransition(
        opacity: _animController,
        child: Column(
          children: [
            // Stats
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Wishlist', pending.length.toString(), Icons.favorite_border),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStat('Tried', done.length.toString(), Icons.check_circle_outline),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: _cravings.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      children: [
                        if (pending.isNotEmpty) ..._buildSection('Wishlist 🔥', pending, false),
                        if (done.isNotEmpty) ..._buildSection('Tried ✅', done, true),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCravingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<Craving> cravings, bool isDone) {
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
      ...cravings.map((craving) {
        final index = _cravings.indexOf(craving);
        return _buildCravingCard(craving, index, isDone);
      }).toList(),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildCravingCard(Craving craving, int index, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(craving.name + index.toString()),
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
        onDismissed: (_) => _deleteCraving(index),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: craving.isDone,
                onChanged: (_) => _toggleCraving(index),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      craving.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                        color: isDone ? Colors.grey : null,
                      ),
                    ),
                    if (craving.notes != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          craving.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isDone
                            ? 'Tried ${_formatDate(craving.completedDate!)}'
                            : 'Added ${_formatDate(craving.addedDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone)
                Icon(Icons.check_circle, color: Colors.green[600]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No cravings yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add places or items you want to try',
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

class Craving {
  final String name;
  final String? notes;
  final DateTime addedDate;
  final bool isDone;
  final DateTime? completedDate;

  Craving({
    required this.name,
    this.notes,
    required this.addedDate,
    required this.isDone,
    this.completedDate,
  });
}
