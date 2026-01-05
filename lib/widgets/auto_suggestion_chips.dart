import 'package:flutter/material.dart';
import '../services/task_classifier.dart';
import '../models/task.dart';

class AutoSuggestionChips extends StatefulWidget {
  final String title;
  final String description;
  final Function(TaskCategory)? onCategorySelected;
  final Function(TaskPriority)? onPrioritySelected;

  const AutoSuggestionChips({
    super.key,
    required this.title,
    required this.description,
    this.onCategorySelected,
    this.onPrioritySelected,
  });

  @override
  State<AutoSuggestionChips> createState() => _AutoSuggestionChipsState();
}

class _AutoSuggestionChipsState extends State<AutoSuggestionChips> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Combine title and description for classification
    final combinedText = "${widget.title} ${widget.description}".trim();

    // Get auto-detected values
    final detectedCategory = TaskClassifier.classifyCategory(combinedText);
    final detectedPriority = TaskClassifier.classifyPriority(combinedText);
    final extractedEntities = TaskClassifier.extractEntities(combinedText);
    final suggestedActions = TaskClassifier.getSuggestedActionsByText(
      combinedText,
    );

    if (combinedText.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasEntities = extractedEntities.isNotEmpty;
    final hasActions = suggestedActions.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 4),
              Text(
                "Auto-detected",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              if (hasEntities || hasActions)
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Category chip
              _buildChip(
                label:
                    "Category: ${TaskClassifier.getCategoryDisplayName(detectedCategory, combinedText)}",
                color: TaskClassifier.getCategoryColor(detectedCategory),
                onTap: widget.onCategorySelected != null
                    ? () => widget.onCategorySelected!(detectedCategory)
                    : null,
              ),
              // Priority chip
              _buildChip(
                label:
                    "Priority: ${TaskClassifier.getPriorityDisplayName(detectedPriority)}",
                color: TaskClassifier.getPriorityColor(detectedPriority),
                onTap: widget.onPrioritySelected != null
                    ? () => widget.onPrioritySelected!(detectedPriority)
                    : null,
              ),
            ],
          ),
          if (_isExpanded && (hasEntities || hasActions)) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Extracted Entities
            if (hasEntities) ...[
              _buildSectionTitle('Extracted Entities', Icons.label_outline),
              const SizedBox(height: 8),
              ..._buildEntityChips(extractedEntities),
              const SizedBox(height: 12),
            ],
            // Suggested Actions
            if (hasActions) ...[
              _buildSectionTitle('Suggested Actions', Icons.lightbulb_outline),
              const SizedBox(height: 8),
              ..._buildActionChips(suggestedActions),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.blue.shade700),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEntityChips(Map<String, dynamic> entities) {
    final chips = <Widget>[];

    if (entities.containsKey('dates') && entities['dates'] is List) {
      final dates = entities['dates'] as List;
      for (final date in dates) {
        chips.add(
          _buildEntityChip('Date: $date', Icons.calendar_today, Colors.orange),
        );
      }
    }

    if (entities.containsKey('persons') && entities['persons'] is List) {
      final persons = entities['persons'] as List;
      for (final person in persons) {
        chips.add(
          _buildEntityChip('Person: $person', Icons.person, Colors.green),
        );
      }
    }

    if (entities.containsKey('locations') && entities['locations'] is List) {
      final locations = entities['locations'] as List;
      for (final location in locations) {
        chips.add(
          _buildEntityChip(
            'Location: $location',
            Icons.location_on,
            Colors.red,
          ),
        );
      }
    }

    if (entities.containsKey('actions') && entities['actions'] is List) {
      final actions = entities['actions'] as List;
      for (final action in actions) {
        chips.add(
          _buildEntityChip('Action: $action', Icons.play_arrow, Colors.purple),
        );
      }
    }

    return chips;
  }

  Widget _buildEntityChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  List<Widget> _buildActionChips(List<String> actions) {
    return actions.map((action) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                action,
                style: TextStyle(fontSize: 11, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildChip({
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
