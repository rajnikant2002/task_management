import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'classification_preview_dialog.dart';

class TaskFormBottomSheet extends StatefulWidget {
  final Task? task;

  const TaskFormBottomSheet({super.key, this.task});

  @override
  State<TaskFormBottomSheet> createState() => _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();

  DateTime? _selectedDueDate;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _assignedToController.text = widget.task!.assignedTo;
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Create or update task.
    // For new tasks: Backend will handle all classification automatically.
    await _createOrUpdateTask();
  }

  Future<void> _createOrUpdateTask() async {
    final taskProvider = context.read<TaskProvider>();

    try {
      if (widget.task == null) {
        // NEW TASK: Send only raw user input to backend
        // Backend will handle all classification
        final rawTaskData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          if (_selectedDueDate != null)
            'due_date': _selectedDueDate!.toIso8601String(),
          'assigned_to': _assignedToController.text.trim(),
        };

        // Call backend to create task with raw input
        final createdTask = await taskProvider.createTaskRaw(rawTaskData);

        if (context.mounted) {
          // Show preview dialog with auto-generated classification
          await _showClassificationPreview(createdTask, taskProvider);
        }
      } else {
        // EDITING EXISTING TASK: Use existing logic
        final task = Task(
          id: widget.task!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: _selectedDueDate,
          assignedTo: _assignedToController.text,
          status: widget.task!.status,
          category: widget.task!.category,
          priority: widget.task!.priority,
          createdAt: widget.task!.createdAt,
          updatedAt: DateTime.now(),
          extractedEntities: widget.task!.extractedEntities,
          suggestedActions: widget.task!.suggestedActions,
        );

        await taskProvider.updateTask(task);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _showClassificationPreview(
    Task task,
    TaskProvider taskProvider,
  ) async {
    // Show preview dialog with task from backend
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ClassificationPreviewDialog(
        task: task,
        onConfirm: (categoryName, priority) async {
          // Get current category name from task
          final currentCategoryName = task
              .getDisplayCategoryName()
              .toLowerCase();

          // Check if user overrode category or priority
          final hasOverride =
              categoryName != currentCategoryName || priority != task.priority;

          if (hasOverride) {
            // Send override to backend with backend category name
            try {
              await taskProvider.updateTaskWithOverride(
                task.id,
                categoryName: categoryName,
                priority: priority,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating override: ${e.toString()}'),
                  ),
                );
              }
              // Don't close dialog on error
              return;
            }
          }

          // Close preview dialog and return success
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        },
      ),
    );

    if (confirmed == true && context.mounted) {
      // Task is already in the list from createTaskRaw
      // If override was applied, it's already updated
      // Just refresh to ensure UI is up to date
      await taskProvider.refreshTasks();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );

        // Close bottom sheet
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } else if (confirmed == false && context.mounted) {
      // User cancelled the preview dialog
      // Remove the task that was already added to the list
      try {
        await taskProvider.deleteTask(task.id);
      } catch (e) {
        // Task might not exist or already deleted - that's okay
        print('Note: Could not remove cancelled task: $e');
      }
      // Don't close bottom sheet - let user continue editing or cancel manually
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.task == null ? 'Create Task' : 'Edit Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _selectedDueDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDueDate!)
                        : 'Select Due Date',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _assignedToController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned To',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.task == null
                        ? Colors.green.shade600
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.task == null ? 'Create Task' : 'Update Task',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
