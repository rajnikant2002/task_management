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
      builder: (context) => TaskFormBottomSheet(
        task: task,
        taskProvider: context.read<TaskProvider>(),
      ),
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        Chip(
                          avatar: Icon(
                            Icons.category,
                            size: 16,
                            color: TaskCategory.getColor(task.category),
                          ),
                          label: Text(task.category.value),
                          backgroundColor: TaskCategory.getColor(
                            task.category,
                          ).withOpacity(0.1),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.flag,
                            size: 16,
                            color: TaskPriority.getColor(task.priority),
                          ),
                          label: Text(task.priority.value),
                          backgroundColor: TaskPriority.getColor(
                            task.priority,
                          ).withOpacity(0.1),
                        ),
                        Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(
                            task.assignedTo.isEmpty
                                ? 'Unassigned'
                                : task.assignedTo,
                          ),
                          backgroundColor: Colors.purple.withOpacity(0.1),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.info_outline,
                            size: 16,
                            color: task.status == TaskStatus.pending
                                ? Colors.orange
                                : task.status == TaskStatus.inProgress
                                ? Colors.blue
                                : Colors.green,
                          ),
                          label: Text(task.status.value),
                          backgroundColor:
                              (task.status == TaskStatus.pending
                                      ? Colors.orange
                                      : task.status == TaskStatus.inProgress
                                      ? Colors.blue
                                      : Colors.green)
                                  .withOpacity(0.1),
                        ),
                        if (task.dueDate != null)
                          Chip(
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              DateFormat('MMM dd, yyyy').format(task.dueDate!),
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showTaskForm(task: task);
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Edit Task'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await taskProvider.deleteTask(task.id);
                                if (mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task deleted'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (task.status != TaskStatus.completed) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final updatedTask = task.copyWith(
                              status: TaskStatus.completed,
                            );
                            await taskProvider.updateTask(updatedTask);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task marked as completed'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Mark as Completed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
              OfflineIndicator(taskProvider: taskProvider),
              SummaryCards(taskProvider: taskProvider),
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
              FilterChips(taskProvider: taskProvider),
              const SizedBox(height: 8),
              Expanded(
                child: taskProvider.isLoading && taskProvider.tasks.isEmpty
                    ? const SkeletonLoader()
                    : taskProvider.error != null && taskProvider.tasks.isEmpty
                    ? Center(
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
                              'Error: ${taskProvider.error}',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => taskProvider.refreshTasks(),
                              child: const Text('Retry'),
                            ),
                          ],
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
                              onTap: () async {
                                // When user taps a task, move it to In Progress (if pending)
                                if (task.status == TaskStatus.pending) {
                                  final updatedTask = task.copyWith(
                                    status: TaskStatus.inProgress,
                                  );
                                  await taskProvider.updateTask(updatedTask);
                                  _showTaskDetails(updatedTask, taskProvider);
                                } else {
                                  _showTaskDetails(task, taskProvider);
                                }
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
