import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(task.status),
          child: Icon(
            _getStatusIcon(task.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _CategoryChip(task: task),
                const SizedBox(width: 8),
                _PriorityBadge(priority: task.priority),
              ],
            ),
            if (task.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(task.dueDate!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  task.assignedTo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                color: Colors.blueGrey,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.pending;
      case TaskStatus.inProgress:
        return Icons.work;
      case TaskStatus.completed:
        return Icons.check;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final Task task;

  const _CategoryChip({required this.task});

  @override
  Widget build(BuildContext context) {
    // Use detected category name if available, otherwise use enum value
    final categoryName = task.getDisplayCategoryName();
    
    return Chip(
      label: Text(
        categoryName,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: TaskCategory.getColor(task.category),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TaskPriority.getColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TaskPriority.getColor(priority), width: 1),
      ),
      child: Text(
        priority.value,
        style: TextStyle(
          fontSize: 11,
          color: TaskPriority.getColor(priority),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
