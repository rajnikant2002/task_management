import 'package:flutter/material.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final String assignedTo;
  final TaskStatus status;
  final TaskCategory category;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    required this.assignedTo,
    required this.status,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? assignedTo,
    TaskStatus? status,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      assignedTo: assignedTo ?? this.assignedTo,
      status: status ?? this.status,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        dueDate: json['dueDate'] != null || json['due_date'] != null
            ? DateTime.tryParse(
                (json['dueDate'] ?? json['due_date']).toString(),
              )
            : null,
        assignedTo: (json['assignedTo'] ?? json['assigned_to'] ?? '')
            .toString(),
        status: TaskStatus.fromString(
          json['status']?.toString() ??
              json['task_status']?.toString() ??
              'Pending',
        ),
        category: TaskCategory.fromString(
          json['category']?.toString() ?? 'Other',
        ),
        priority: TaskPriority.fromString(
          json['priority']?.toString() ?? 'Medium',
        ),
        createdAt:
            DateTime.tryParse(
              (json['createdAt'] ?? json['created_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
        updatedAt:
            DateTime.tryParse(
              (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
            ) ??
            DateTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing Task from JSON: $e');
      print('📦 JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      // Send both camelCase and snake_case to align with backend expectations
      'dueDate': dueDate?.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'assignedTo': assignedTo,
      'assigned_to': assignedTo,
      'status': status.value,
      'task_status': status.value,
      'category': category.value,
      'priority': priority.value,
      'createdAt': createdAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum TaskStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed');

  final String value;
  const TaskStatus(this.value);

  static TaskStatus fromString(String value) {
    final normalized = value.trim();
    // Try case-sensitive match first
    for (final status in TaskStatus.values) {
      if (status.value == normalized) {
        return status;
      }
    }
    // Try case-insensitive match
    for (final status in TaskStatus.values) {
      if (status.value.toLowerCase() == normalized.toLowerCase()) {
        return status;
      }
    }
    // Handle common variations
    final lowerValue = normalized.toLowerCase();
    if (lowerValue == 'in progress' || 
        lowerValue == 'inprogress' || 
        lowerValue == 'in_progress') {
      return TaskStatus.inProgress;
    }
    if (lowerValue == 'completed' || lowerValue == 'complete') {
      return TaskStatus.completed;
    }
    if (lowerValue == 'pending') {
      return TaskStatus.pending;
    }
    return TaskStatus.pending;
  }
}

enum TaskCategory {
  work('Work'),
  personal('Personal'),
  shopping('Shopping'),
  health('Health'),
  other('Other');

  final String value;
  const TaskCategory(this.value);

  static TaskCategory fromString(String value) {
    return TaskCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskCategory.other,
    );
  }

  static Color getColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.personal:
        return Colors.green;
      case TaskCategory.shopping:
        return Colors.orange;
      case TaskCategory.health:
        return Colors.red;
      case TaskCategory.other:
        return Colors.grey;
    }
  }
}

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  final String value;
  const TaskPriority(this.value);

  static TaskPriority fromString(String value) {
    final normalized = value.trim().toLowerCase();

    // First try to match display values like "Low", "Medium", "High" ignoring case
    for (final p in TaskPriority.values) {
      if (p.value.toLowerCase() == normalized) {
        return p;
      }
    }

    // Fallback for common raw backend values like "low", "medium", "high"
    switch (normalized) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  static Color getColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
    }
  }
}
