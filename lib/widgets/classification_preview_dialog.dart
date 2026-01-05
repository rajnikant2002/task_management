import 'package:flutter/material.dart';
import '../models/task.dart';

// Helper class for backend category options (5 categories from backend)
class BackendCategory {
  final String name;

  const BackendCategory(this.name);

  static const List<BackendCategory> backendCategories = [
    BackendCategory('scheduling'),
    BackendCategory('finance'),
    BackendCategory('technical'),
    BackendCategory('safety'),
    BackendCategory('general'),
  ];

  static BackendCategory fromName(String name) {
    try {
      return backendCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return const BackendCategory('general');
    }
  }
}

class ClassificationPreviewDialog extends StatelessWidget {
  final Task task;
  final Function(String categoryName, TaskPriority priority) onConfirm;

  const ClassificationPreviewDialog({
    super.key,
    required this.task,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Get category directly from backend (no need for getDisplayCategoryName)
    final backendCategoryName = (task.backendCategoryName ?? 'general')
        .toLowerCase();
    final currentBackendCategory = BackendCategory.fromName(
      backendCategoryName,
    );

    // Track selected values (can be overridden by user)
    BackendCategory selectedBackendCategory = currentBackendCategory;
    TaskPriority selectedPriority = task.priority;

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
                  const Text(
                    'The system has automatically classified your task:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  // Category from backend - can be overridden
                  _BackendCategoryItem(
                    label: 'Category',
                    value: currentBackendCategory.name,
                    color: TaskCategoryHelper.getColorFromBackendCategory(
                      selectedBackendCategory.name,
                    ),
                    canOverride: true,
                    currentValue: selectedBackendCategory.name,
                    options: BackendCategory.backendCategories,
                    onChanged: (value) {
                      setState(() {
                        selectedBackendCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  // Priority from backend - can be overridden
                  _ClassificationItem(
                    label: 'Priority',
                    value: task.priority.value,
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
                  if (task.extractedEntities != null &&
                      task.extractedEntities!.isNotEmpty) ...[
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
                      children: task.extractedEntities!.entries
                          // Filter out locations and detected_category (not needed per assessment)
                          .where(
                            (entry) =>
                                entry.key != 'detected_category' &&
                                entry.key != 'locations',
                          )
                          .map((entry) {
                            // Format backend data for display
                            final displayValue = entry.value is List
                                ? (entry.value as List)
                                      .where((item) {
                                        // For dates, filter out relative strings like "today", "tomorrow"
                                        if (entry.key == 'dates') {
                                          final str = item
                                              .toString()
                                              .toLowerCase();
                                          final relativeDates = [
                                            'today',
                                            'tomorrow',
                                            'yesterday',
                                            'next week',
                                            'this week',
                                          ];
                                          if (relativeDates.contains(str)) {
                                            return false; // Filter out relative dates
                                          }
                                        }
                                        return true;
                                      })
                                      .map((item) {
                                        final str = item.toString();
                                        // Remove time portion from dates (keep only YYYY-MM-DD)
                                        return entry.key == 'dates' &&
                                                str.contains('T')
                                            ? str.split('T')[0]
                                            : str;
                                      })
                                      .join(', ')
                                : entry.value.toString();

                            return Chip(
                              label: Text('${entry.key}: $displayValue'),
                              backgroundColor: Colors.blue.shade50,
                            );
                          })
                          .toList(),
                    ),
                  ],
                  if (task.suggestedActions != null &&
                      task.suggestedActions!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Suggested Actions:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ...task.suggestedActions!.map(
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
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(false);
                }
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await onConfirm(selectedBackendCategory.name, selectedPriority);
              },
              child: const Text('Confirm & Create'),
            ),
          ],
        );
      },
    );
  }
}

class _BackendCategoryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool canOverride;
  final String currentValue;
  final List<BackendCategory> options;
  final Function(BackendCategory) onChanged;

  const _BackendCategoryItem({
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
          DropdownButtonFormField<BackendCategory>(
            value: options.firstWhere(
              (opt) => opt.name == currentValue,
              orElse: () => options.first,
            ),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isDense: true,
            items: options.map((option) {
              return DropdownMenuItem<BackendCategory>(
                value: option,
                child: Text(option.name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ],
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
          DropdownButtonFormField<dynamic>(
            value: () {
              try {
                return options.firstWhere((opt) => opt.value == currentValue);
              } catch (e) {
                return options.isNotEmpty ? options.first : null;
              }
            }(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isDense: true,
            items: options.map((option) {
              return DropdownMenuItem<dynamic>(
                value: option,
                child: Text(option.value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ],
    );
  }
}
