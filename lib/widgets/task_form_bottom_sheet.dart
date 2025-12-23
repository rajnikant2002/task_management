import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormBottomSheet extends StatefulWidget {
  final Task? task;
  final TaskProvider taskProvider;

  const TaskFormBottomSheet({super.key, this.task, required this.taskProvider});

  @override
  State<TaskFormBottomSheet> createState() => _TaskFormBottomSheetState();
}

class _TaskFormBottomSheetState extends State<TaskFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _assignedToController = TextEditingController();

  // Listeners for reactive updates
  bool _canClassify = false;

  DateTime? _selectedDueDate;
  TaskCategory? _selectedCategory;
  TaskPriority? _selectedPriority;
  bool _isClassifying = false;
  bool _showClassification = false;

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

    // Add listeners for reactive button visibility
    _titleController.addListener(_updateCanClassify);
    _descriptionController.addListener(_updateCanClassify);
    _updateCanClassify();
  }

  void _updateCanClassify() {
    final canClassify =
        _titleController.text.isNotEmpty &&
        _descriptionController.text.isNotEmpty;
    if (_canClassify != canClassify) {
      setState(() {
        _canClassify = canClassify;
      });
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateCanClassify);
    _descriptionController.removeListener(_updateCanClassify);
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _classifyTask() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      return;
    }

    setState(() {
      _isClassifying = true;
    });

    try {
      final classification = await widget.taskProvider.classifyTask(
        _titleController.text,
        _descriptionController.text,
      );

      setState(() {
        _selectedCategory = TaskCategory.fromString(classification['category']);
        _selectedPriority = TaskPriority.fromString(classification['priority']);
        _showClassification = true;
        _isClassifying = false;
      });
    } catch (e) {
      setState(() {
        _isClassifying = false;
      });
    }
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

    if (_selectedCategory == null || _selectedPriority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and priority')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDueDate,
      assignedTo: _assignedToController.text,
      status: widget.task?.status ?? TaskStatus.pending,
      category: _selectedCategory!,
      priority: _selectedPriority!,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.task == null) {
        await widget.taskProvider.createTask(task);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task created successfully')),
          );
        }
      } else {
        await widget.taskProvider.updateTask(task);
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_showClassification) {
                      setState(() {
                        _showClassification = false;
                      });
                    }
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    if (_showClassification) {
                      setState(() {
                        _showClassification = false;
                      });
                    }
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
                const SizedBox(height: 16),
                if (_canClassify)
                  OutlinedButton(
                    onPressed: _isClassifying ? null : _classifyTask,
                    child: _isClassifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Auto-Classify'),
                  ),
                if (_showClassification) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-generated Classification:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Category: ${_selectedCategory?.value ?? 'N/A'}'),
                        Text('Priority: ${_selectedPriority?.value ?? 'N/A'}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskCategory>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<TaskPriority>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority *',
                    border: OutlineInputBorder(),
                  ),
                  items: TaskPriority.values.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _submit, child: const Text('Submit')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
