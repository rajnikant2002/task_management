import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../services/task_classifier.dart';
import 'auto_suggestion_chips.dart';

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
  TaskCategory? _selectedCategory;
  TaskPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _assignedToController.text = widget.task!.assignedTo;
      _selectedDueDate = widget.task!.dueDate;
      _selectedCategory = widget.task!.category;
      _selectedPriority = widget.task!.priority;
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

    // Create or update task directly.
    // Category & priority will be chosen automatically based on keywords.
    await _createOrUpdateTask();
  }

  Future<void> _createOrUpdateTask() async {
    // Combine title and description for classification & entity extraction
    final combinedText =
        "${_titleController.text} ${_descriptionController.text}".trim();

    // For new tasks, always use auto-detected category/priority from keywords
    // For editing, use existing values or auto-detect if not set
    final finalCategory = widget.task == null
        ? TaskClassifier.classifyCategory(
            combinedText,
          ) // Always auto-detect for new tasks
        : (_selectedCategory ?? TaskClassifier.classifyCategory(combinedText));
    final finalPriority = widget.task == null
        ? TaskClassifier.classifyPriority(
            combinedText,
          ) // Always auto-detect for new tasks
        : (_selectedPriority ?? TaskClassifier.classifyPriority(combinedText));

    // Extract entities and suggested actions (only for new tasks)
    Map<String, dynamic>? extractedEntities;
    List<String>? suggestedActions;

    if (widget.task == null) {
      // Extract entities and actions for new tasks
      extractedEntities = TaskClassifier.extractEntities(combinedText);
      if (extractedEntities.isEmpty) {
        extractedEntities = null;
      }
      suggestedActions = TaskClassifier.getSuggestedActionsByText(combinedText);
      if (suggestedActions.isEmpty) {
        suggestedActions = null;
      }
    } else {
      // For editing, preserve existing entities and actions
      extractedEntities = widget.task!.extractedEntities;
      suggestedActions = widget.task!.suggestedActions;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDueDate,
      assignedTo: _assignedToController.text,
      status: widget.task?.status ?? TaskStatus.pending,
      category: finalCategory,
      priority: finalPriority,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      extractedEntities: extractedEntities,
      suggestedActions: suggestedActions,
    );

    final taskProvider = context.read<TaskProvider>();
    try {
      if (widget.task == null) {
        await taskProvider.createTask(task);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } else {
        await taskProvider.updateTask(task);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      }
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
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
                // Live auto-suggestions based on title & description (only for new tasks)
                if (widget.task == null &&
                    (_titleController.text.isNotEmpty ||
                        _descriptionController.text.isNotEmpty))
                  AutoSuggestionChips(
                    title: _titleController.text,
                    description: _descriptionController.text,
                  ),
                if (widget.task == null &&
                    (_titleController.text.isNotEmpty ||
                        _descriptionController.text.isNotEmpty))
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
