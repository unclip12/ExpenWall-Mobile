import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/split_bill.dart';
import '../models/contact.dart';

class SplitCalculatorDialog extends StatefulWidget {
  final double totalAmount;
  final List<Contact> participants;
  final SplitType splitType;
  final Map<String, double> customAmounts;
  final Map<String, double> percentages;
  final Function(SplitType, Map<String, double>, Map<String, double>) onSave;

  const SplitCalculatorDialog({
    super.key,
    required this.totalAmount,
    required this.participants,
    required this.splitType,
    required this.customAmounts,
    required this.percentages,
    required this.onSave,
  });

  @override
  State<SplitCalculatorDialog> createState() => _SplitCalculatorDialogState();
}

class _SplitCalculatorDialogState extends State<SplitCalculatorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SplitType _selectedType;
  late Map<String, double> _customAmounts;
  late Map<String, double> _percentages;
  late Map<String, TextEditingController> _amountControllers;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.splitType;
    _customAmounts = Map.from(widget.customAmounts);
    _percentages = Map.from(widget.percentages);

    // Initialize controllers for custom amounts
    _amountControllers = {};
    for (var contact in widget.participants) {
      final amount = _customAmounts[contact.id] ?? 0.0;
      _amountControllers[contact.id] = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(2) : '',
      );
    }

    // Initialize percentages if empty (equal split)
    if (_percentages.isEmpty) {
      final equalPercent = 100.0 / widget.participants.length;
      for (var contact in widget.participants) {
        _percentages[contact.id] = equalPercent;
      }
    }

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedType.index,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedType = SplitType.values[_tabController.index];
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _getEqualAmount() {
    return widget.totalAmount / widget.participants.length;
  }

  double _getCustomTotal() {
    return _amountControllers.values
        .map((c) => double.tryParse(c.text) ?? 0.0)
        .fold(0.0, (a, b) => a + b);
  }

  double _getPercentageTotal() {
    return _percentages.values.fold(0.0, (a, b) => a + b);
  }

  bool _validateCustom() {
    final total = _getCustomTotal();
    return (total - widget.totalAmount).abs() < 0.01;
  }

  bool _validatePercentage() {
    final total = _getPercentageTotal();
    return (total - 100.0).abs() < 0.01;
  }

  void _save() {
    if (_selectedType == SplitType.custom) {
      if (!_validateCustom()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Custom amounts must equal total amount'),
          ),
        );
        return;
      }
      // Update custom amounts from controllers
      for (var contact in widget.participants) {
        _customAmounts[contact.id] =
            double.parse(_amountControllers[contact.id]!.text);
      }
    } else if (_selectedType == SplitType.percentage) {
      if (!_validatePercentage()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Percentages must add up to 100%'),
          ),
        );
        return;
      }
    }

    widget.onSave(_selectedType, _customAmounts, _percentages);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Split Calculator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:'),
                  Text(
                    '₹${widget.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Equal'),
                Tab(text: 'Custom'),
                Tab(text: 'Percentage'),
              ],
            ),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEqualSplit(),
                  _buildCustomSplit(),
                  _buildPercentageSplit(),
                ],
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEqualSplit() {
    final amountPerPerson = _getEqualAmount();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Split equally among all participants',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((contact) => ListTile(
              title: Text(contact.name),
              trailing: Text(
                '₹${amountPerPerson.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildCustomSplit() {
    final customTotal = _getCustomTotal();
    final isValid = _validateCustom();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Enter custom amounts for each person',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((contact) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextFormField(
                      controller: _amountControllers[contact.id],
                      decoration: const InputDecoration(
                        prefixText: '₹',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            )),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '₹${customTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Must equal ₹${widget.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildPercentageSplit() {
    final percentTotal = _getPercentageTotal();
    final isValid = _validatePercentage();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Adjust percentage for each person',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...widget.participants.map((contact) {
          final percent = _percentages[contact.id] ?? 0.0;
          final amount = (widget.totalAmount * percent) / 100.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: percent,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        label: '${percent.toStringAsFixed(1)}%',
                        onChanged: (value) {
                          setState(() {
                            _percentages[contact.id] = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${percent.toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${percentTotal.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!isValid)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Must equal 100%',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
