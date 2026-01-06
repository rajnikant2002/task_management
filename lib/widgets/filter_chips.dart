import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, _) {
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
              // Use backend categories (scheduling, finance, technical, safety, general)
              ...[
                'scheduling',
                'finance',
                'technical',
                'safety',
                'general',
              ].map(
                (categoryName) => _FilterChip(
                  label: categoryName,
                  isSelected: taskProvider.selectedCategory == categoryName,
                  onTap: () => taskProvider.setCategoryFilter(categoryName),
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
      },
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
