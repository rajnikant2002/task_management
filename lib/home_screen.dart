import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                              onTap: () => _showTaskForm(task: task),
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
