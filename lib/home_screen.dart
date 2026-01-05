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

  void _showTaskDetails(Task task, TaskProvider taskProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _TaskDetailsModal(
          task: task,
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
                                // The modal will automatically update pending tasks to in progress
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
        // Get the latest task from the provider to ensure we have the most up-to-date data
        // Use getTaskById to get from the full list, not just filtered tasks
        final currentTask = provider.getTaskById(widget.task.id) ?? widget.task;

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentTask.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  currentTask.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.category, size: 16),
                      label: Text(currentTask.getDisplayCategoryName()),
                    ),
                    Chip(
                      avatar: const Icon(Icons.flag, size: 16),
                      label: Text('Priority: ${currentTask.priority.value}'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.person, size: 16),
                      label: Text(
                        currentTask.assignedTo.isEmpty
                            ? 'Unassigned'
                            : currentTask.assignedTo,
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          widget.onEdit(currentTask);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Task'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
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
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
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
                        // Don't close the modal, let it update to show the new status
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark as Completed'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
