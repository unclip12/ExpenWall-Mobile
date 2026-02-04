import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/insights_screen.dart';

class InsightCard extends StatelessWidget {
  final InsightCardData data;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const InsightCard({
    Key? key,
    required this.data,
    this.onMoveUp,
    this.onMoveDown,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  data.icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Reorder buttons
                _buildReorderButtons(context),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: data.child,
          ),
        ],
      ),
    );
  }

  Widget _buildReorderButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Up arrow
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onMoveUp,
          color: onMoveUp != null 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300],
          tooltip: 'Move Up',
        ),
        const SizedBox(width: 4),
        // Down arrow
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onMoveDown,
          color: onMoveDown != null 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300],
          tooltip: 'Move Down',
        ),
      ],
    );
  }
}
