import 'package:flutter/material.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class FilterChips extends StatelessWidget {
  final TaskProvider taskProvider;

  const FilterChips({super.key, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All Categories',
            isSelected: taskProvider.selectedCategory == null,
            onTap: () => taskProvider.setCategoryFilter(null),
          ),
          ...TaskCategory.values.map(
            (category) => _FilterChip(
              label: category.value,
              isSelected: taskProvider.selectedCategory == category,
              onTap: () => taskProvider.setCategoryFilter(category),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'All Priorities',
            isSelected: taskProvider.selectedPriority == null,
            onTap: () => taskProvider.setPriorityFilter(null),
          ),
          ...TaskPriority.values.map(
            (priority) => _FilterChip(
              label: priority.value,
              isSelected: taskProvider.selectedPriority == priority,
              onTap: () => taskProvider.setPriorityFilter(priority),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
