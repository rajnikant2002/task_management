import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../widgets/summary_cards.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_form_bottom_sheet.dart';
import '../widgets/filter_chips.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/skeleton_loader.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showTaskForm({Task? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TaskFormBottomSheet(task: task),
    );
  }

  Future<void> _showTaskDetails(Task task, TaskProvider taskProvider) async {
    // Always fetch latest task details (with history) before opening the modal
    Task taskToShow = task;
    try {
      taskToShow = await taskProvider.fetchTaskById(task.id);
    } catch (_) {
      // If fetch fails, fall back to the task from the list
      taskToShow = task;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _TaskDetailsModal(
          task: taskToShow,
          onEdit: (task) {
            Navigator.of(context).pop();
            _showTaskForm(task: task);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Filter by Status'),
                  content: Consumer<TaskProvider>(
                    builder: (context, provider, _) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<TaskStatus?>(
                            title: const Text('All'),
                            value: null,
                            groupValue: provider.selectedStatus,
                            onChanged: (value) {
                              provider.setStatusFilter(value);
                              Navigator.pop(context);
                            },
                          ),
                          ...TaskStatus.values.map(
                            (status) => RadioListTile<TaskStatus?>(
                              title: Text(status.value),
                              value: status,
                              groupValue: provider.selectedStatus,
                              onChanged: (value) {
                                provider.setStatusFilter(value);
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          return Column(
            children: [
              const OfflineIndicator(),
              const SummaryCards(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    taskProvider.setSearchQuery(value);
                  },
                ),
              ),
              const SizedBox(height: 8),
              const FilterChips(),
              const SizedBox(height: 8),
              Expanded(
                child: taskProvider.isLoading && taskProvider.tasks.isEmpty
                    ? const SkeletonLoader()
                    : taskProvider.error != null && taskProvider.tasks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Connection Error',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  taskProvider.error ??
                                      'Unknown error occurred',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => taskProvider.refreshTasks(),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : taskProvider.tasks.isEmpty
                    ? const Center(child: Text('No tasks found'))
                    : RefreshIndicator(
                        onRefresh: () => taskProvider.refreshTasks(),
                        child: ListView.builder(
                          itemCount: taskProvider.tasks.length,
                          itemBuilder: (context, index) {
                            final task = taskProvider.tasks[index];
                            return TaskListItem(
                              task: task,
                              onTap: () {
                                _showTaskDetails(task, taskProvider);
                              },
                              onEdit: () => _showTaskForm(task: task),
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: const Text(
                                      'Are you sure you want to delete this task?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await taskProvider.deleteTask(task.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Task deleted'),
                                      ),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }
}

class _TaskDetailsModal extends StatefulWidget {
  final Task task;
  final Function(Task) onEdit;

  const _TaskDetailsModal({required this.task, required this.onEdit});

  @override
  State<_TaskDetailsModal> createState() => _TaskDetailsModalState();
}

class _TaskDetailsModalState extends State<_TaskDetailsModal> {
  bool _hasUpdatedStatus = false;

  @override
  void initState() {
    super.initState();
    // Automatically update pending tasks to in progress when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePendingToInProgress();
    });
  }

  Future<void> _updatePendingToInProgress() async {
    if (_hasUpdatedStatus) return;

    final provider = context.read<TaskProvider>();
    final currentTask = provider.getTaskById(widget.task.id) ?? widget.task;

    // If task is pending, automatically update to in progress
    if (currentTask.status == TaskStatus.pending) {
      _hasUpdatedStatus = true;
      final updatedTask = currentTask.copyWith(status: TaskStatus.inProgress);
      await provider.updateTask(updatedTask);
      // Force a rebuild after update completes
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        // Get latest task from provider; fall back to task passed in
        final currentTask = provider.getTaskById(widget.task.id) ?? widget.task;

        return SafeArea(
          top: true,
          bottom: false, // we handle bottom with viewInsets padding below
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16 + MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Title:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTask.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.close, size: 24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentTask.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category, size: 16),
                      label: Text(
                        'Category: ${currentTask.backendCategoryName ?? 'general'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.flag, size: 16),
                      label: Text('Priority: ${currentTask.priority.value}'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(
                        'Assigned to: ${currentTask.assignedTo.isEmpty ? 'Unassigned' : currentTask.assignedTo}',
                      ),
                    ),
                    Chip(
                      avatar: const Icon(Icons.info_outline, size: 16),
                      label: Text('Status: ${currentTask.status.value}'),
                    ),
                    if (currentTask.dueDate != null)
                      Chip(
                        avatar: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          'Due: ${DateFormat('MMM dd, yyyy').format(currentTask.dueDate!)}',
                        ),
                      ),
                  ],
                ),
                if (currentTask.extractedEntities != null &&
                    currentTask.extractedEntities!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Extracted Entities:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentTask.extractedEntities!.entries
                        // Hide internal helper keys like detected_category and locations from UI
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
                                      // Filter out relative date strings
                                      if (entry.key == 'dates') {
                                        final str = item
                                            .toString()
                                            .toLowerCase();
                                        const relativeDates = [
                                          'today',
                                          'tomorrow',
                                          'yesterday',
                                          'next week',
                                          'this week',
                                        ];
                                        if (relativeDates.contains(str)) {
                                          return false;
                                        }
                                      }
                                      return true;
                                    })
                                    .map((item) {
                                      final str = item.toString();
                                      // Remove time portion from dates
                                      return entry.key == 'dates' &&
                                              str.contains('T')
                                          ? str.split('T')[0]
                                          : str;
                                    })
                                    .join(', ')
                              : entry.value.toString();

                          return Chip(
                            avatar: const Icon(Icons.label_outline, size: 16),
                            label: Text('${entry.key}: $displayValue'),
                            backgroundColor: Colors.blue.shade50,
                          );
                        })
                        .toList(),
                  ),
                ],
                if (currentTask.suggestedActions != null &&
                    currentTask.suggestedActions!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Suggested Actions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...currentTask.suggestedActions!.map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (currentTask.history != null &&
                    currentTask.history!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text(
                    'Task History:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...currentTask.history!.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getHistoryIcon(entry.action),
                                  size: 18,
                                  color: _getHistoryColor(entry.action),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatHistoryAction(entry),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM dd, yyyy HH:mm',
                                  ).format(entry.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            if (entry.field != null &&
                                (entry.oldValue != null ||
                                    entry.newValue != null)) ...[
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.only(left: 26),
                                child: Text(
                                  _formatHistoryChange(entry),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.onEdit(currentTask);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        label: const Text(
                          'Edit Task',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Task'),
                              content: const Text(
                                'Are you sure you want to delete this task?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await provider.deleteTask(currentTask.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Task deleted')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (currentTask.status != TaskStatus.completed)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updatedTask = currentTask.copyWith(
                        status: TaskStatus.completed,
                      );
                      await provider.updateTask(updatedTask);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task marked as completed'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 22),
                    label: const Text(
                      'Mark as Completed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getHistoryIcon(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Icons.add_circle_outline;
      case 'updated':
      case 'status_changed':
        return Icons.edit_outlined;
      case 'deleted':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getHistoryColor(String action) {
    switch (action.toLowerCase()) {
      case 'created':
        return Colors.green;
      case 'updated':
      case 'status_changed':
        return Colors.blue;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatHistoryAction(TaskHistoryEntry entry) {
    final action = entry.action.toLowerCase();
    if (action == 'status_changed' || action == 'updated') {
      if (entry.field != null) {
        return '${entry.field!.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)).join(' ')} changed';
      }
      return 'Task updated';
    }
    return action
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  String _formatHistoryChange(TaskHistoryEntry entry) {
    if (entry.oldValue != null && entry.newValue != null) {
      return '${entry.oldValue} → ${entry.newValue}';
    } else if (entry.newValue != null) {
      return 'Set to: ${entry.newValue}';
    } else if (entry.oldValue != null) {
      return 'Was: ${entry.oldValue}';
    }
    return '';
  }
}
