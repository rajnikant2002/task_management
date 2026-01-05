import 'package:flutter/material.dart';
import '../models/task.dart';

class ClassificationPreviewDialog extends StatelessWidget {
  final TaskClassification classification;
  final TaskCategory? initialCategory;
  final TaskPriority? initialPriority;
  final Function(TaskCategory, TaskPriority) onConfirm;

  const ClassificationPreviewDialog({
    super.key,
    required this.classification,
    this.initialCategory,
    this.initialPriority,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Use user's selection if available, otherwise use auto-detected
    TaskCategory selectedCategory = initialCategory ?? classification.category;
    TaskPriority selectedPriority = initialPriority ?? classification.priority;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Auto-Classification Preview',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    initialCategory != null || initialPriority != null
                        ? 'Review and adjust the classification:'
                        : 'The system has automatically classified your task:',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  // Category - display only (no override)
                  Row(
                    children: [
                      const Text(
                        'Category: ',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TaskCategory.getColor(selectedCategory).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: TaskCategory.getColor(selectedCategory),
                          ),
                        ),
                        child: Text(
                          selectedCategory.value,
                          style: TextStyle(
                            color: TaskCategory.getColor(selectedCategory),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ClassificationItem(
                    label: 'Priority',
                    value: initialPriority != null
                        ? initialPriority!.value
                        : classification.priority.value,
                    color: TaskPriority.getColor(selectedPriority),
                    canOverride: true,
                    currentValue: selectedPriority.value,
                    options: TaskPriority.values,
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value as TaskPriority;
                      });
                    },
                  ),
                  if (classification.extractedEntities != null &&
                      classification.extractedEntities!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Extracted Entities:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: classification.extractedEntities!.entries.map((
                        entry,
                      ) {
                        return Chip(
                          label: Text('${entry.key}: ${entry.value}'),
                          backgroundColor: Colors.blue.shade50,
                        );
                      }).toList(),
                    ),
                  ],
                  if (classification.suggestedActions != null &&
                      classification.suggestedActions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Suggested Actions:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ...classification.suggestedActions!.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(action)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm(selectedCategory, selectedPriority);
                Navigator.of(context).pop();
              },
              child: const Text('Confirm & Create'),
            ),
          ],
        );
      },
    );
  }
}

class _ClassificationItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool canOverride;
  final String currentValue;
  final List<dynamic> options;
  final Function(dynamic) onChanged;

  const _ClassificationItem({
    required this.label,
    required this.value,
    required this.color,
    required this.canOverride,
    required this.currentValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color),
              ),
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (canOverride) ...[
          const SizedBox(height: 8),
          const Text(
            'Override:',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              // Find the matching option or use the first one
              dynamic selectedValue;
              try {
                selectedValue = options.firstWhere(
                  (opt) => opt.value == currentValue,
                );
              } catch (e) {
                selectedValue = options.isNotEmpty ? options.first : null;
              }

              return DropdownButtonFormField<dynamic>(
                value: selectedValue,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                isDense: true,
                items: options.map((option) {
                  return DropdownMenuItem<dynamic>(
                    value: option,
                    child: Text(option.value),
                  );
                }).toList(),
                onChanged: onChanged,
              );
            },
          ),
        ],
      ],
    );
  }
}
