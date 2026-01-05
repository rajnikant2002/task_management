import 'package:flutter/material.dart';
import '../models/task.dart';

// Helper class for backend category options
class BackendCategory {
  final String name;
  final TaskCategory enumValue;

  const BackendCategory(this.name, this.enumValue);

  String get value => name;

  static const List<BackendCategory> backendCategories = [
    BackendCategory('scheduling', TaskCategory.work),
    BackendCategory('finance', TaskCategory.work),
    BackendCategory('technical', TaskCategory.work),
    BackendCategory('safety', TaskCategory.health),
    BackendCategory('general', TaskCategory.other),
  ];

  static BackendCategory? fromName(String name) {
    try {
      return backendCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return const BackendCategory('general', TaskCategory.other);
    }
  }

  static BackendCategory? fromEnum(TaskCategory category) {
    // Map enum to backend category
    switch (category) {
      case TaskCategory.work:
        // Default to 'general' for work, but we'll use detected category name
        return const BackendCategory('general', TaskCategory.other);
      case TaskCategory.health:
        return const BackendCategory('safety', TaskCategory.health);
      case TaskCategory.other:
        return const BackendCategory('general', TaskCategory.other);
      default:
        return const BackendCategory('general', TaskCategory.other);
    }
  }
}

class ClassificationPreviewDialog extends StatelessWidget {
  final Task task;
  final TaskCategory? initialCategory;
  final TaskPriority? initialPriority;
  final Function(String categoryName, TaskPriority priority) onConfirm;

  const ClassificationPreviewDialog({
    super.key,
    required this.task,
    this.initialCategory,
    this.initialPriority,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    // Use user's selection if available, otherwise use auto-detected
    TaskPriority selectedPriority = initialPriority ?? task.priority;

    // Get detected category name (e.g., "Scheduling", "Finance") from backend
    final detectedCategoryName = task.getDisplayCategoryName().toLowerCase();

    // Find the backend category from detected name
    BackendCategory? currentBackendCategory = BackendCategory.fromName(
      detectedCategoryName,
    );
    // Ensure we always have a valid backend category (one of the 5)
    final finalBackendCategory =
        currentBackendCategory ??
        const BackendCategory('general', TaskCategory.other);

    // Track selected backend category (not enum)
    BackendCategory selectedBackendCategory = finalBackendCategory;

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
                  // Category - with override (using backend categories)
                  _BackendCategoryItem(
                    label: 'Category',
                    value: finalBackendCategory
                        .name, // Always show backend category name
                    color: TaskCategory.getColor(
                      selectedBackendCategory.enumValue,
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
                  _ClassificationItem(
                    label: 'Priority',
                    value: initialPriority != null
                        ? initialPriority!.value
                        : task.priority.value,
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
                            // Format the value nicely for display
                            // Backend sends clean arrays: ["2026-01-05"], ["Rajnikant"], ["meet"]
                            // Flutter formats them for UI display
                            String displayValue;
                            if (entry.value is List) {
                              final list = entry.value as List;
                              // Format each item in the list
                              displayValue = list
                                  .map((item) {
                                    final itemStr = item.toString();
                                    // Format dates if needed (remove time portion if present)
                                    if (entry.key == 'dates' &&
                                        itemStr.contains('T')) {
                                      return itemStr.split('T')[0];
                                    }
                                    return itemStr;
                                  })
                                  .join(', ');
                            } else {
                              displayValue = entry.value.toString();
                            }
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
                // Pass backend category name (e.g., "finance", "scheduling") instead of enum
                // Don't pop here - let onConfirm callback handle it
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
          Builder(
            builder: (context) {
              // Find the matching option or use the first one
              BackendCategory? selectedValue;
              try {
                selectedValue = options.firstWhere(
                  (opt) => opt.name == currentValue,
                );
              } catch (e) {
                selectedValue = options.isNotEmpty ? options.first : null;
              }

              return DropdownButtonFormField<BackendCategory>(
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
                  return DropdownMenuItem<BackendCategory>(
                    value: option,
                    child: Text(option.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
              );
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
